## GardenView — renders the garden grid using immediate-mode 2D drawing.
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")

## Hex circumradius in pixels (centre to vertex).
const TILE_RADIUS: float = 20.0

# ---------------------------------------------------------------------------
# Hover state
# ---------------------------------------------------------------------------

var _hover_coord: Vector2i = Vector2i(-9999, -9999)
var _hover_valid: bool = false
var _hover_mix: bool = false

# ---------------------------------------------------------------------------
# Transient animations
# ---------------------------------------------------------------------------

var _mix_coord: Vector2i = Vector2i(-9999, -9999)
var _mix_timer: float = 0.0
var _reject_coord: Vector2i = Vector2i(-9999, -9999)
var _reject_reason: String = ""
var _reject_timer: float = 0.0

# ---------------------------------------------------------------------------
# Cluster cache  (unified, keyed by biome)
# _cluster_maps[biome]: Dictionary   coord → cluster_id
# _cluster_groups[biome]: Dictionary  cluster_id → Array[Vector2i]
# ---------------------------------------------------------------------------

var _cluster_maps: Dictionary = {}
var _cluster_groups: Dictionary = {}
var _clusters_dirty: bool = true

## Minimum cluster size to show a biome overlay.
## Matches the size_threshold in the corresponding PatternDefinition .tres.
const _CLUSTER_THRESHOLDS: Dictionary = {
	BiomeType.Value.FOREST: 10,
	BiomeType.Value.WATER:  10,
	BiomeType.Value.STONE:  10,
	BiomeType.Value.EARTH:  25,
	BiomeType.Value.SWAMP:  20,
}

# ---------------------------------------------------------------------------
# Named-discovery overlays  discovery_id → Array[Vector2i] (triggering coords)
# ---------------------------------------------------------------------------

var _discovery_overlays: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	GameState.tile_placed.connect(_on_tile_placed)
	GameState.tile_mixed.connect(_on_tile_mixed)
	GameState.mix_rejected.connect(_on_mix_rejected)

	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)

	queue_redraw()


func _process(delta: float) -> void:
	var needs_redraw := false
	if _mix_timer > 0.0:
		_mix_timer -= delta
		needs_redraw = true
	if _reject_timer > 0.0:
		_reject_timer -= delta
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	_clusters_dirty = true
	queue_redraw()


func _on_tile_mixed(coord: Vector2i, _tile: GardenTile) -> void:
	_mix_coord = coord
	_mix_timer = 0.4
	_clusters_dirty = true
	queue_redraw()


func _on_mix_rejected(coord: Vector2i, reason: String) -> void:
	_reject_coord = coord
	_reject_reason = reason
	_reject_timer = 0.3
	queue_redraw()


func _on_discovery_triggered(discovery_id: String, coords: Array[Vector2i]) -> void:
	_discovery_overlays[discovery_id] = coords
	queue_redraw()


## Called by PlacementController each frame.
func set_hover(coord: Vector2i, valid: bool, mix: bool) -> void:
	if _hover_coord == coord and _hover_valid == valid and _hover_mix == mix:
		return
	_hover_coord = coord
	_hover_valid = valid
	_hover_mix = mix
	queue_redraw()


# ---------------------------------------------------------------------------
# Main draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _clusters_dirty:
		_recompute_all_clusters()
		_clusters_dirty = false

	# 1. Draw base tiles
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		var in_large: bool = _is_in_large_cluster(coord, tile.biome)
		var base_color: Color = _biome_color(tile.biome)
		if in_large:
			base_color = base_color.darkened(0.18)
		_draw_tile(coord, base_color)
		_draw_tile_decorations(coord, tile.biome, in_large)
		if tile.locked:
			var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
			draw_circle(Vector2(tc.x + TILE_RADIUS * 0.6, tc.y - TILE_RADIUS * 0.5), 4.0, Color(1.0, 0.85, 0.0))

	# 2. Biome cluster overlays
	for biome: int in _CLUSTER_THRESHOLDS:
		var threshold: int = _CLUSTER_THRESHOLDS[biome]
		if not _cluster_groups.has(biome):
			continue
		for cluster_id: int in _cluster_groups[biome]:
			var members: Array = _cluster_groups[biome][cluster_id]
			if members.size() >= threshold:
				_draw_cluster_overlay(biome, members)

	# 3. Named-discovery overlays (shape / proximity / compound patterns)
	for discovery_id: String in _discovery_overlays:
		var disc_coords: Array[Vector2i] = _discovery_overlays[discovery_id]
		_draw_discovery_overlay(discovery_id, disc_coords)

	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)

	# 4. Animations
	if _mix_timer > 0.0:
		var t: float = _mix_timer / 0.4
		var mc: Vector2 = _HexUtils.axial_to_pixel(_mix_coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(mc, TILE_RADIUS + (1.0 - t) * 8.0), Color(1.0, 1.0, 1.0, t * 0.8))

	if _reject_timer > 0.0:
		var t: float = _reject_timer / 0.3
		var rc: Vector2 = _HexUtils.axial_to_pixel(_reject_coord, TILE_RADIUS)
		var rpts: PackedVector2Array = _hex_polygon(rc, TILE_RADIUS)
		draw_colored_polygon(rpts, Color(1.0, 1.0, 0.0, 0.5 * t) if _reject_reason == "same_type" else Color(1.0, 0.2, 0.2, 0.6 * t))

	# 5. Hover
	if _hover_valid:
		var hc: Vector2 = _HexUtils.axial_to_pixel(_hover_coord, TILE_RADIUS)
		var hpts: PackedVector2Array = _hex_polygon(hc, TILE_RADIUS)
		draw_colored_polygon(hpts, Color(1.0, 1.0, 1.0, 0.35))
		var border: PackedVector2Array = PackedVector2Array(hpts)
		border.append(hpts[0])
		draw_polyline(border, Color.WHITE, 2.0)
	elif _hover_mix:
		var hc: Vector2 = _HexUtils.axial_to_pixel(_hover_coord, TILE_RADIUS)
		var border: PackedVector2Array = _hex_polygon(hc, TILE_RADIUS)
		border.append(border[0])
		draw_polyline(border, Color(1.0, 0.6, 0.1, 0.9), 2.5)


# ---------------------------------------------------------------------------
# Tile drawing helpers
# ---------------------------------------------------------------------------

func _draw_tile(coord: Vector2i, color: Color) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var pts: PackedVector2Array = _hex_polygon(center, TILE_RADIUS)
	draw_colored_polygon(pts, color)
	var border: PackedVector2Array = PackedVector2Array(pts)
	border.append(pts[0])
	draw_polyline(border, color.darkened(0.25), 1.0)


func _draw_tile_decorations(coord: Vector2i, biome: int, in_large_cluster: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var cx: float = center.x
	var cy: float = center.y
	var half: float = TILE_RADIUS

	match biome:
		BiomeType.Value.FOREST:
			if in_large_cluster:
				var count: int = rng.randi_range(1, 2)
				for _i: int in range(count):
					draw_circle(Vector2(cx + rng.randf_range(-half * 0.55, half * 0.55), cy + rng.randf_range(-half * 0.55, half * 0.55)), rng.randf_range(2.5, 4.5), Color(0.1, 0.38, 0.1, 0.55))
			else:
				var count: int = rng.randi_range(3, 5)
				for _i: int in range(count):
					draw_circle(Vector2(cx + rng.randf_range(-half * 0.6, half * 0.6), cy + rng.randf_range(-half * 0.6, half * 0.6)), rng.randf_range(3.0, 6.0), Color(0.12, 0.42, 0.12, 0.75))

		BiomeType.Value.WATER:
			for w: int in range(2):
				var y_off: float = -5.0 + w * 9.0
				var pts := PackedVector2Array()
				for i: int in range(6):
					var tt: float = float(i) / 5.0
					pts.append(Vector2(cx - half * 0.7 + tt * TILE_RADIUS * 1.4, cy + y_off + sin(tt * PI * 2.0) * 3.0))
				draw_polyline(pts, Color(0.65, 0.88, 1.0, 0.55), 1.5)

		BiomeType.Value.STONE:
			var count: int = rng.randi_range(2, 3)
			for _i: int in range(count):
				var sx: float = cx + rng.randf_range(-half * 0.6, half * 0.6)
				var sy: float = cy + rng.randf_range(-half * 0.6, half * 0.6)
				draw_line(Vector2(sx, sy), Vector2(sx + rng.randf_range(-9.0, 9.0), sy + rng.randf_range(-9.0, 9.0)), Color(0.32, 0.32, 0.32, 0.8), 1.5)

		BiomeType.Value.EARTH:
			var count: int = rng.randi_range(4, 6)
			for _i: int in range(count):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.65, half * 0.65), cy + rng.randf_range(-half * 0.65, half * 0.65)), 2.0, Color(0.5, 0.32, 0.12, 0.7))

		BiomeType.Value.SWAMP:
			var count: int = rng.randi_range(3, 5)
			for _i: int in range(count):
				var ox: float = rng.randf_range(-half * 0.65, half * 0.65)
				var stalk_h: float = rng.randf_range(9.0, 14.0)
				var base_y: float = cy + half * 0.45
				draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox, base_y - stalk_h), Color(0.22, 0.52, 0.12, 0.9), 2.0)
				draw_circle(Vector2(cx + ox, base_y - stalk_h), 2.5, Color(0.42, 0.22, 0.05, 0.9))

		BiomeType.Value.TUNDRA:
			var count: int = rng.randi_range(4, 6)
			for _i: int in range(count):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.7, half * 0.7), cy + rng.randf_range(-half * 0.7, half * 0.7)), rng.randf_range(1.5, 3.0), Color(1.0, 1.0, 1.0, 0.75))

		BiomeType.Value.MUDFLAT:
			var count: int = rng.randi_range(2, 4)
			for _i: int in range(count):
				draw_arc(Vector2(cx + rng.randf_range(-half * 0.6, half * 0.6), cy + rng.randf_range(-half * 0.6, half * 0.6)), rng.randf_range(3.0, 6.0), 0.0, TAU, 10, Color(0.28, 0.16, 0.06, 0.7), 1.5)

		BiomeType.Value.MOSSY_CRAG:
			draw_line(Vector2(cx - half * 0.55, cy + rng.randf_range(-3.0, 3.0)), Vector2(cx + half * 0.55, cy + rng.randf_range(-3.0, 3.0)), Color(0.38, 0.38, 0.28, 0.8), 1.5)
			var count: int = rng.randi_range(2, 4)
			for _i: int in range(count):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.6, half * 0.6), cy + rng.randf_range(-half * 0.6, half * 0.6)), rng.randf_range(2.5, 4.5), Color(0.18, 0.52, 0.14, 0.65))

		BiomeType.Value.SAVANNAH:
			var count: int = rng.randi_range(3, 5)
			for _i: int in range(count):
				var ox: float = rng.randf_range(-half * 0.65, half * 0.65)
				var base_y: float = cy + half * 0.38
				draw_line(Vector2(cx + ox - 2, base_y), Vector2(cx + ox - 4, base_y - rng.randf_range(7.0, 11.0)), Color(0.60, 0.52, 0.08, 0.9), 1.5)
				draw_line(Vector2(cx + ox + 2, base_y), Vector2(cx + ox + 4, base_y - rng.randf_range(7.0, 11.0)), Color(0.60, 0.52, 0.08, 0.9), 1.5)

		BiomeType.Value.CANYON:
			for row: int in range(3):
				var y_off: float = -8.0 + row * 8.0
				draw_line(Vector2(cx - half * 0.7 + rng.randf_range(0.0, 4.0), cy + y_off), Vector2(cx + half * 0.7 - rng.randf_range(0.0, 4.0), cy + y_off), Color(0.50, 0.20, 0.07, 0.75), 1.5)


# ---------------------------------------------------------------------------
# Cluster BFS (unified)
# ---------------------------------------------------------------------------

func _recompute_all_clusters() -> void:
	_cluster_maps.clear()
	_cluster_groups.clear()
	for biome: int in _CLUSTER_THRESHOLDS:
		_recompute_clusters_for_biome(biome)


func _recompute_clusters_for_biome(biome: int) -> void:
	var coord_map: Dictionary = {}
	var groups: Dictionary = {}
	var next_id: int = 0

	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		if tile.biome != biome:
			continue
		if coord_map.has(coord):
			continue

		var cluster_id: int = next_id
		next_id += 1
		var members: Array[Vector2i] = []
		var queue: Array[Vector2i] = [coord]
		coord_map[coord] = cluster_id

		while not queue.is_empty():
			var cur: Vector2i = queue.pop_front()
			members.append(cur)
			for d: Vector2i in _HexUtils.HEX_NEIGHBORS:
				var nb: Vector2i = cur + d
				if coord_map.has(nb):
					continue
				if not GameState.grid.tiles.has(nb):
					continue
				if (GameState.grid.tiles[nb] as GardenTile).biome != biome:
					continue
				coord_map[nb] = cluster_id
				queue.append(nb)

		groups[cluster_id] = members

	_cluster_maps[biome] = coord_map
	_cluster_groups[biome] = groups


func _is_in_large_cluster(coord: Vector2i, biome: int) -> bool:
	if not _CLUSTER_THRESHOLDS.has(biome):
		return false
	var cmap: Dictionary = _cluster_maps.get(biome, {})
	if not cmap.has(coord):
		return false
	var cid: int = cmap[coord]
	var groups: Dictionary = _cluster_groups.get(biome, {})
	if not groups.has(cid):
		return false
	return (groups[cid] as Array).size() >= _CLUSTER_THRESHOLDS[biome]


# ---------------------------------------------------------------------------
# Biome cluster overlay dispatch
# ---------------------------------------------------------------------------

func _draw_cluster_overlay(biome: int, members: Array) -> void:
	match biome:
		BiomeType.Value.FOREST: _draw_forest_overlay(members)
		BiomeType.Value.WATER:  _draw_river_overlay(members)
		BiomeType.Value.STONE:  _draw_mountain_overlay(members)
		BiomeType.Value.EARTH:  _draw_barren_expanse_overlay(members)
		BiomeType.Value.SWAMP:  _draw_peat_bog_overlay(members)


## Dense forest: dark canopy tint + tall trees.
func _draw_forest_overlay(members: Array) -> void:
	var canopy_tint := Color(0.06, 0.30, 0.06, 0.40)
	var trunk_col   := Color(0.30, 0.18, 0.06, 0.92)
	var leaf_col    := Color(0.06, 0.35, 0.06, 0.88)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), canopy_tint)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xDEAD
		if rng.randf() >= 0.45:
			continue
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x + rng.randf_range(-4.0, 4.0)
		var cy: float = tc.y + rng.randf_range(-3.0, 3.0)
		var canopy_r: float = rng.randf_range(6.0, 9.5)
		draw_line(Vector2(cx, cy + canopy_r * 0.5), Vector2(cx, cy - rng.randf_range(14.0, 20.0) * 0.35), trunk_col, 2.5)
		draw_circle(Vector2(cx, cy - canopy_r * 0.25), canopy_r, leaf_col)
		draw_circle(Vector2(cx - canopy_r * 0.55, cy + canopy_r * 0.30), canopy_r * 0.72, leaf_col)
		draw_circle(Vector2(cx + canopy_r * 0.55, cy + canopy_r * 0.30), canopy_r * 0.72, leaf_col)


## River: flowing current lines and blue shimmer across the body.
func _draw_river_overlay(members: Array) -> void:
	var shimmer := Color(0.30, 0.70, 1.0, 0.30)
	var flow    := Color(0.50, 0.82, 1.0, 0.70)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), shimmer)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xF10E0
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# 2 curved flow lines
		for w: int in range(2):
			var y_off: float = rng.randf_range(-7.0, 7.0)
			var pts := PackedVector2Array()
			for i: int in range(7):
				var tt: float = float(i) / 6.0
				pts.append(Vector2(cx - TILE_RADIUS * 0.85 + tt * TILE_RADIUS * 1.7, cy + y_off + sin(tt * PI * 2.5 + rng.randf_range(0.0, TAU)) * 4.0))
			draw_polyline(pts, flow, 1.5)


## Mountain peak: grey peaks with snow caps.
func _draw_mountain_overlay(members: Array) -> void:
	var snow_white := Color(0.92, 0.95, 1.0, 0.85)
	var peak_grey  := Color(0.48, 0.50, 0.55, 0.75)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xBEEF
		if rng.randf() >= 0.55:
			continue
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x + rng.randf_range(-3.0, 3.0)
		var cy: float = tc.y + rng.randf_range(-2.0, 2.0)
		var peak_h: float = rng.randf_range(10.0, 16.0)
		var base_w: float = rng.randf_range(8.0, 13.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - peak_h), Vector2(cx + base_w, cy + peak_h * 0.35), Vector2(cx - base_w, cy + peak_h * 0.35)]), peak_grey)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - peak_h), Vector2(cx + base_w * 0.45, cy - peak_h * 0.35), Vector2(cx - base_w * 0.45, cy - peak_h * 0.35)]), snow_white)


## Barren expanse: dry cracked earth — radiating fissure lines.
func _draw_barren_expanse_overlay(members: Array) -> void:
	var crack_col := Color(0.40, 0.22, 0.06, 0.70)
	var dust_col  := Color(0.82, 0.70, 0.45, 0.25)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), dust_col)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xD8910
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# 3-5 radiating cracks from a random hub point
		var hx: float = cx + rng.randf_range(-4.0, 4.0)
		var hy: float = cy + rng.randf_range(-4.0, 4.0)
		var crack_count: int = rng.randi_range(3, 5)
		for _i: int in range(crack_count):
			var angle: float = rng.randf_range(0.0, TAU)
			var length: float = rng.randf_range(6.0, 13.0)
			draw_line(Vector2(hx, hy), Vector2(hx + cos(angle) * length, hy + sin(angle) * length), crack_col, 1.2)


## Peat bog: murky tint + dense tall reeds with seed heads.
func _draw_peat_bog_overlay(members: Array) -> void:
	var murk := Color(0.10, 0.20, 0.08, 0.40)
	var stem := Color(0.18, 0.42, 0.10, 0.92)
	var head := Color(0.35, 0.18, 0.04, 0.95)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), murk)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xB0650
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		var count: int = rng.randi_range(4, 7)
		for _i: int in range(count):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.7, TILE_RADIUS * 0.7)
			var h: float  = rng.randf_range(12.0, 20.0)
			var base_y: float = cy + TILE_RADIUS * 0.5
			draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox, base_y - h), stem, 1.8)
			# Bulrush seed head — a small filled rect approximated with a circle
			draw_circle(Vector2(cx + ox, base_y - h + 3.0), 2.8, head)


# ---------------------------------------------------------------------------
# Named-discovery overlay dispatch
# ---------------------------------------------------------------------------

func _draw_discovery_overlay(discovery_id: String, coords: Array[Vector2i]) -> void:
	match discovery_id:
		"disc_glade":              _draw_glade_overlay(coords)
		"disc_lotus_pond":         _draw_lotus_pond_overlay(coords)
		"disc_boreal_forest":      _draw_boreal_forest_overlay(coords)
		"disc_great_reef":         _draw_great_reef_overlay(coords)
		"disc_mirror_archipelago": _draw_mirror_archipelago_overlay(coords)
		"disc_waterfall":          _draw_waterfall_overlay(coords)
		"disc_obsidian_expanse":   _draw_obsidian_expanse_overlay(coords)
		# Cluster-based discoveries (deep_stand, river, mountain_peak, barren_expanse,
		# peat_bog) are already rendered via _draw_cluster_overlay; no extra marker needed.


## Glade: earth centre ringed by forest — draw sunbeam rays from the centre.
func _draw_glade_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	# Centre tile is the first coord (earth)
	var center: Vector2 = _HexUtils.axial_to_pixel(coords[0], TILE_RADIUS)
	var ray_col := Color(1.0, 0.95, 0.55, 0.75)
	for i: int in range(8):
		var angle: float = deg_to_rad(float(i) * 45.0)
		var inner: float = TILE_RADIUS * 0.25
		var outer: float = TILE_RADIUS * 0.85
		draw_line(center + Vector2(cos(angle), sin(angle)) * inner, center + Vector2(cos(angle), sin(angle)) * outer, ray_col, 1.8)
	draw_circle(center, 4.0, Color(1.0, 0.92, 0.35, 0.9))


## Lotus pond: water centre ringed by earth — draw a lotus flower.
func _draw_lotus_pond_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var center: Vector2 = _HexUtils.axial_to_pixel(coords[0], TILE_RADIUS)
	var petal_col  := Color(0.95, 0.55, 0.65, 0.85)
	var center_col := Color(1.0, 0.92, 0.20, 0.95)
	# 6 petals
	for i: int in range(6):
		var angle: float = deg_to_rad(float(i) * 60.0)
		var tip: Vector2 = center + Vector2(cos(angle), sin(angle)) * TILE_RADIUS * 0.75
		var pl: Vector2  = center + Vector2(cos(angle + 0.4), sin(angle + 0.4)) * TILE_RADIUS * 0.45
		var pr: Vector2  = center + Vector2(cos(angle - 0.4), sin(angle - 0.4)) * TILE_RADIUS * 0.45
		draw_colored_polygon(PackedVector2Array([center, pl, tip, pr]), petal_col)
	draw_circle(center, 4.5, center_col)


## Boreal forest: forest near tundra — snow-dusted conifer on the triggering tile.
func _draw_boreal_forest_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0xB04EA
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x + rng.randf_range(-3.0, 3.0)
		var cy: float = tc.y
		# Conifer silhouette: 3 stacked triangles
		for tier: int in range(3):
			var tier_w: float = (8.0 - float(tier) * 2.0)
			var tier_y: float = cy - 4.0 - float(tier) * 7.0
			draw_colored_polygon(PackedVector2Array([Vector2(cx, tier_y - 7.0), Vector2(cx + tier_w, tier_y), Vector2(cx - tier_w, tier_y)]), Color(0.15, 0.35, 0.18, 0.88))
			# Snow on tip of each tier
			draw_colored_polygon(PackedVector2Array([Vector2(cx, tier_y - 7.0), Vector2(cx + tier_w * 0.4, tier_y - 3.5), Vector2(cx - tier_w * 0.4, tier_y - 3.5)]), Color(0.90, 0.95, 1.0, 0.80))


## Great reef: water with stone nearby — colourful coral structures.
func _draw_great_reef_overlay(coords: Array[Vector2i]) -> void:
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0xC04A1
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# 3-5 coral branches: angled forked lines in warm colours
		var count: int = rng.randi_range(3, 5)
		for _i: int in range(count):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.6, TILE_RADIUS * 0.6)
			var base_y: float = cy + TILE_RADIUS * 0.5
			var h: float = rng.randf_range(8.0, 15.0)
			var coral_col := Color(rng.randf_range(0.7, 1.0), rng.randf_range(0.3, 0.7), rng.randf_range(0.2, 0.5), 0.90)
			draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox, base_y - h), coral_col, 2.0)
			# Two fork tips
			draw_line(Vector2(cx + ox, base_y - h), Vector2(cx + ox - 4.0, base_y - h - 5.0), coral_col, 1.5)
			draw_line(Vector2(cx + ox, base_y - h), Vector2(cx + ox + 4.0, base_y - h - 5.0), coral_col, 1.5)


## Mirror archipelago: water with scattered earth — silver shimmer rings.
func _draw_mirror_archipelago_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var shimmer := Color(0.85, 0.92, 1.0, 0.60)
	for coord: Vector2i in coords:
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		# Concentric reflection rings
		for r: int in range(2, 5):
			draw_arc(tc, float(r) * 3.5, 0.0, TAU, 24, Color(shimmer.r, shimmer.g, shimmer.b, shimmer.a / float(r)), 1.2)
		draw_circle(tc, 3.0, Color(1.0, 1.0, 1.0, 0.75))


## Waterfall: water next to stone — cascading vertical lines.
func _draw_waterfall_overlay(coords: Array[Vector2i]) -> void:
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0xFA11
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		var fall_col := Color(0.55, 0.85, 1.0, 0.80)
		# 4-6 vertical cascade lines with slight waver
		for _i: int in range(rng.randi_range(4, 6)):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.55, TILE_RADIUS * 0.55)
			var pts := PackedVector2Array()
			for j: int in range(5):
				var tt: float = float(j) / 4.0
				pts.append(Vector2(cx + ox + sin(tt * PI * 3.0 + rng.randf()) * 2.0, cy - TILE_RADIUS * 0.7 + tt * TILE_RADIUS * 1.4))
			draw_polyline(pts, fall_col, 1.5)
		# Mist at base
		draw_colored_polygon(_hex_polygon(Vector2(cx, cy + TILE_RADIUS * 0.55), TILE_RADIUS * 0.35), Color(0.80, 0.90, 1.0, 0.30))


## Obsidian expanse: canyon near water — glassy dark crystalline facets.
func _draw_obsidian_expanse_overlay(coords: Array[Vector2i]) -> void:
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0x0B51D
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# Dark glassy tint
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS), Color(0.05, 0.05, 0.12, 0.45))
		# 3-4 crystalline shards
		var shard_count: int = rng.randi_range(3, 4)
		for _i: int in range(shard_count):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.5, TILE_RADIUS * 0.5)
			var oy: float = rng.randf_range(-TILE_RADIUS * 0.4, TILE_RADIUS * 0.4)
			var sw: float = rng.randf_range(3.0, 5.0)
			var sh: float = rng.randf_range(8.0, 14.0)
			draw_colored_polygon(PackedVector2Array([Vector2(cx + ox, cy + oy - sh), Vector2(cx + ox + sw, cy + oy + sh * 0.4), Vector2(cx + ox - sw, cy + oy + sh * 0.4)]), Color(0.10, 0.12, 0.25, 0.85))
			# Glint highlight
			draw_line(Vector2(cx + ox, cy + oy - sh), Vector2(cx + ox + sw * 0.5, cy + oy - sh * 0.3), Color(0.60, 0.70, 1.0, 0.70), 1.0)


# ---------------------------------------------------------------------------
# Hex polygon helper
# ---------------------------------------------------------------------------

static func _hex_polygon(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(6):
		var angle: float = deg_to_rad(-90.0 + 60.0 * float(i))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts


# ---------------------------------------------------------------------------
# Biome colour palette
# ---------------------------------------------------------------------------

static func _biome_color(biome: int) -> Color:
	match biome:
		BiomeType.Value.FOREST:     return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WATER:      return Color(0.129, 0.588, 0.953)
		BiomeType.Value.STONE:      return Color(0.620, 0.620, 0.620)
		BiomeType.Value.EARTH:      return Color(0.757, 0.580, 0.376)
		BiomeType.Value.SWAMP:      return Color(0.25, 0.40, 0.20)
		BiomeType.Value.TUNDRA:     return Color(0.75, 0.88, 0.95)
		BiomeType.Value.MUDFLAT:    return Color(0.42, 0.28, 0.15)
		BiomeType.Value.MOSSY_CRAG: return Color(0.45, 0.52, 0.35)
		BiomeType.Value.SAVANNAH:   return Color(0.78, 0.65, 0.25)
		BiomeType.Value.CANYON:     return Color(0.72, 0.35, 0.18)
	return Color(0.502, 0.502, 0.502)
