## GardenView — renders the garden grid using immediate-mode 2D drawing.
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const _TerrainTilesheet = preload("res://src/rendering/terrain_tilesheet.gd")
const SeedStateScript = preload("res://src/seeds/SeedState.gd")
const BuildingPlacementSessionScript = preload("res://src/grid/BuildingPlacementSession.gd")
const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")
const _HOUSE_STRUCTURE_TEXTURE: Texture2D = preload("res://assets/structures/house/frames/idle/down/frame_0000.png")
const _ORIGIN_SHRINE_STRUCTURE_TEXTURE: Texture2D = preload("res://assets/structures/origin_shrine/frames/idle/down/frame_0000.png")
const _MATERIAL_GROWTH_ATLAS: Texture2D = preload("res://assets/materials/material_growth_atlas.png")
const _TERRAIN_TILESET_PATH: String = "res://assets/tiles/satori_terrain_tilesheet.png"
const _EDGE_DECAL_PATH: String = "res://assets/tiles/satori_edge_decal.png"

## Hex circumradius in pixels (centre to vertex).
const TILE_RADIUS: float = 20.0

## Depth of the 2.5D voxel side-face in world units (appears as ~7px on screen at zoom=2).
const VOXEL_DEPTH: float = 3.5
const TERRAIN_TILE_DRAW_SIZE: float = 44.0
const EDGE_DECAL_DRAW_SIZE: float = 42.0
const EDGE_DECAL_MEADOW_INSET: float = 3.0
const WATER_TILE_ANIMATION_FPS: float = 4.0

const _HOUSE_STRUCTURE_DRAW_SIZE: float = 32.0
const _ORIGIN_SHRINE_STRUCTURE_DRAW_SIZE: float = 34.0
const _MATERIAL_GROWTH_ATLAS_COLUMNS: int = 4
const _MATERIAL_GROWTH_ATLAS_ROWS: int = 4
const _MATERIAL_NODE_DRAW_SIZE: float = 48.0

## Number of background stars.
const _STAR_COUNT: int = 150
## Number of floating mist wisps (6 ambient + 4 edge-biased).
const _MIST_COUNT: int = 10

## RNG seeds for deterministic background elements.
const _STAR_SEED: int = 0xC0FFEE
const _MIST_SEED: int = 0xD1F0A7
const _GRAIN_SEED: int = 0x5A7201

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
var _unique_block_coords: Array[Vector2i] = []
var _unique_block_timer: float = 0.0
var _satori_amount: int = 0
var _satori_cap: int = 250
var _satori_era: StringName = &"stillness"

## Continuous time accumulator for background animations.
var _anim_time: float = 0.0
## Pre-computed star data: [norm_x, norm_y, px_size, phase, speed, hue_tint]
var _bg_stars: Array = []
## Pre-computed mist wisp data: [nx, ny, w_frac, h_frac, alpha, pulse_spd, drift_spd, phase, amp_x, amp_y]
var _bg_mists: Array = []
var _terrain_tileset_texture: Texture2D = null
var _edge_decal_texture: Texture2D = null
var _structure_catalog: RefCounted = StructureCatalogDataScript.new()
var _structure_texture_cache: Dictionary = {}

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
	BiomeType.Value.STONE:  10,
	BiomeType.Value.RIVER:  10,
	BiomeType.Value.EMBER_FIELD: 10,
	BiomeType.Value.MEADOW: 10,
	BiomeType.Value.WETLANDS:  20,
}

# ---------------------------------------------------------------------------
# Named-discovery overlays  discovery_id → Array[Vector2i] (triggering coords)
# ---------------------------------------------------------------------------

var _discovery_overlays: Dictionary = {}
const _BUILD_GATED_DISCOVERY_IDS: Dictionary = {
	"disc_origin_shrine": true,
	"disc_bridge_of_sighs": true,
	"disc_lotus_pagoda": true,
	"disc_monks_rest": true,
	"disc_star_gazing_deck": true,
	"disc_sun_dial": true,
	"disc_whale_bone_arch": true,
	"disc_echoing_cavern": true,
	"disc_bamboo_chime": true,
	"disc_floating_pavilion": true,
}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	var save_service: Node = get_node_or_null("/root/SaveGameService")
	if save_service != null and save_service.has_method("start_session"):
		save_service.start_session()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_terrain_tilesheet()
	GameState.tile_placed.connect(_on_tile_placed)
	GameState.tile_mixed.connect(_on_tile_mixed)
	GameState.mix_rejected.connect(_on_mix_rejected)
	if GameState.has_signal("material_node_spawned"):
		GameState.material_node_spawned.connect(func(_coord: Vector2i, _material_id: StringName, _amount: int) -> void: queue_redraw())
	if GameState.has_signal("material_node_harvested"):
		GameState.material_node_harvested.connect(func(_coord: Vector2i, _material_id: StringName, _amount: int) -> void: queue_redraw())

	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)
	if scan_service != null and scan_service.has_signal("discovery_blocked"):
		scan_service.discovery_blocked.connect(_on_discovery_blocked)
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if satori_service != null:
		if satori_service.has_signal("satori_changed"):
			satori_service.satori_changed.connect(_on_satori_changed)
		if satori_service.has_signal("era_changed"):
			satori_service.era_changed.connect(_on_era_changed)
		if satori_service.has_method("get_current_satori"):
			_satori_amount = int(satori_service.get_current_satori())
		if satori_service.has_method("get_current_cap"):
			_satori_cap = int(satori_service.get_current_cap())
		if satori_service.has_method("get_current_era"):
			_satori_era = satori_service.get_current_era()

	_init_background_data()
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	if _mix_timer > 0.0:
		_mix_timer -= delta
	if _reject_timer > 0.0:
		_reject_timer -= delta
	if _unique_block_timer > 0.0:
		_unique_block_timer -= delta
	queue_redraw()  # always redraw for background animation


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

func _on_discovery_blocked(_discovery_id: String, coords: Array[Vector2i], _reason: String) -> void:
	_unique_block_coords = coords.duplicate()
	_unique_block_timer = 0.9
	queue_redraw()

func _on_satori_changed(current: int, cap: int) -> void:
	_satori_amount = current
	_satori_cap = cap
	queue_redraw()

func _on_era_changed(new_era: StringName) -> void:
	_satori_era = new_era
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

	# 0. Dark textured background
	_draw_background()

	# 1. Draw base tiles
	var build_icons_to_draw: Array[Dictionary] = []
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		var in_large: bool = _is_in_large_cluster(coord, tile.biome)
		var base_color: Color = _biome_color(tile.biome)
		if in_large:
			base_color = base_color.darkened(0.18)
		_draw_tile(coord, base_color, tile.biome)
		_draw_tile_decorations(coord, tile.biome, in_large)
		var is_build_block: bool = bool(tile.metadata.get("is_build_block", false))
		var is_completed_building: bool = bool(tile.metadata.get("is_building_complete", false))
		var is_built_structure: bool = bool(tile.metadata.get("shrine_built", false)) or bool(tile.metadata.get("is_origin_shrine", false)) or bool(tile.metadata.get("is_water_dropoff", false))
		if is_build_block or is_completed_building or is_built_structure:
			var structure_discovery_id: String = str(tile.metadata.get("structure_discovery_id", tile.metadata.get("build_discovery_id", "")))
			build_icons_to_draw.append({
				"coord": coord,
				"biome": tile.biome,
				"structure_id": structure_discovery_id,
				"under_construction": is_build_block,
				"completed": is_completed_building or is_built_structure,
				"is_origin_shrine": bool(tile.metadata.get("is_origin_shrine", false)),
				"is_water_dropoff": bool(tile.metadata.get("is_water_dropoff", false)),
				"is_wayfarer_torii": structure_discovery_id == "disc_wayfarer_torii",
			})

	# 1.1 Draw biome edge decals after every base tile, so neighbouring terrain
	# cannot cover them based on dictionary iteration order.
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		_draw_shoreline_edges(coord, tile.biome)

	# 1.5 Draw pending seed previews (ephemeral tiles in growth pipeline).
	_draw_pending_seed_previews()

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
		if _BUILD_GATED_DISCOVERY_IDS.has(discovery_id) and not _is_any_build_tile_built(disc_coords):
			continue
		_draw_discovery_overlay(discovery_id, disc_coords)

	# 3.5 Completed/active structures should remain visually above biome overlays.
	for icon_data_variant: Variant in build_icons_to_draw:
		var icon_data: Dictionary = icon_data_variant as Dictionary
		_draw_build_block_icon(
			icon_data.get("coord", Vector2i.ZERO),
			int(icon_data.get("biome", 0)),
			str(icon_data.get("structure_id", "")),
			bool(icon_data.get("under_construction", false)),
			bool(icon_data.get("completed", false)),
			bool(icon_data.get("is_origin_shrine", false)),
			bool(icon_data.get("is_water_dropoff", false)),
			bool(icon_data.get("is_wayfarer_torii", false))
		)

	# 4. Shrine build/interact status overlays.
	_draw_material_nodes()
	_draw_shrine_status_overlays()

	# 5. Animations
	if _mix_timer > 0.0:
		var t: float = _mix_timer / 0.4
		var mc: Vector2 = _HexUtils.axial_to_pixel(_mix_coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(mc, TILE_RADIUS + (1.0 - t) * 8.0), Color(1.0, 1.0, 1.0, t * 0.8))

	if _reject_timer > 0.0:
		var t: float = _reject_timer / 0.3
		var rc: Vector2 = _HexUtils.axial_to_pixel(_reject_coord, TILE_RADIUS)
		var rpts: PackedVector2Array = _hex_polygon(rc, TILE_RADIUS)
		draw_colored_polygon(rpts, Color(1.0, 1.0, 0.0, 0.5 * t) if _reject_reason == "same_type" else Color(1.0, 0.2, 0.2, 0.6 * t))

	if _unique_block_timer > 0.0 and not _unique_block_coords.is_empty():
		var pulse: float = _unique_block_timer / 0.9
		for blocked_coord: Vector2i in _unique_block_coords:
			var bc: Vector2 = _HexUtils.axial_to_pixel(blocked_coord, TILE_RADIUS)
			var bpts: PackedVector2Array = _hex_polygon(bc, TILE_RADIUS + (1.0 - pulse) * 4.0)
			draw_colored_polygon(bpts, Color(1.0, 0.15, 0.2, 0.22 * pulse))
			var border: PackedVector2Array = PackedVector2Array(bpts)
			border.append(bpts[0])
			draw_polyline(border, Color(1.0, 0.2, 0.25, 0.95 * pulse), 2.4)

	# 6. Hover
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

	# 7. Screen-edge mist vignette (drawn last so it overlays everything)
	_draw_edge_mist()
	_draw_build_progress_overlays()
	_draw_building_placement_preview()
	_draw_interact_hover_popover()


func _draw_pending_seed_previews() -> void:
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_tracker"):
		return
	var tracker: GrowthSlotTracker = growth_service.get_tracker()
	if tracker == null:
		return
	for seed: SeedInstance in tracker.active_seeds:
		if seed == null:
			continue
		var elapsed: float = Time.get_unix_time_from_system() - seed.planted_at
		var remaining: float = max(0.0, seed.growth_duration - elapsed)
		if seed.state == SeedStateScript.Value.GROWING and remaining <= 0.0 and seed.evaluate_growth():
			# Promote state immediately so UI switches from timer to confirm prompt.
			pass
		var base: Color = _biome_color(seed.produces_biome)
		var center: Vector2 = _HexUtils.axial_to_pixel(seed.hex_coord, TILE_RADIUS)
		_draw_tile(seed.hex_coord, Color(base.r, base.g, base.b, 0.55))
		var outline: PackedVector2Array = _hex_polygon(center, TILE_RADIUS + 2.0)
		outline.append(outline[0])
		if seed.state == SeedStateScript.Value.READY:
			draw_polyline(outline, Color(1.0, 1.0, 1.0, 0.9), 2.0)
			_draw_seed_overlay_text(center, "Confirm", 12, Color(1.0, 0.97, 0.86, 0.95))
		else:
			draw_polyline(outline, Color(0.70, 0.82, 1.0, 0.75), 1.5)
			var secs: int = int(ceil(remaining))
			_draw_seed_overlay_text(center, "%ds" % secs, 12, Color(0.78, 0.90, 1.0, 0.92))


func _draw_seed_overlay_text(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos: Vector2 = Vector2(center.x - text_size.x * 0.5, center.y + 4.0)
	draw_string(font, pos + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.6))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_shrine_status_overlays() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	var hud: Node = get_node_or_null("../HUD")
	var interact_mode: bool = hud != null and hud.has_method("is_interact_mode") and hud.is_interact_mode()
	var build_mode: bool = hud != null and hud.has_method("is_build_mode") and hud.is_build_mode()
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		var is_origin_shrine: bool = bool(tile.metadata.get("is_origin_shrine", false))
		var is_water_dropoff: bool = bool(tile.metadata.get("is_water_dropoff", false))
		if build_mode and bool(tile.metadata.get("shrine_buildable", false)) and not bool(tile.metadata.get("shrine_built", false)) and not str(tile.metadata.get("build_discovery_id", "")).is_empty():
			var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
			_draw_seed_overlay_text(center + Vector2(-10.0, -10.0), "Build", 11, Color(0.94, 0.90, 0.65, 0.90))
		if alchemy == null or not alchemy.has_method("has_shrine_charge"):
			continue
		if not is_origin_shrine and not is_water_dropoff and not bool(tile.metadata.get("shrine_built", false)):
			continue
		if not is_origin_shrine and not is_water_dropoff and str(tile.metadata.get("shrine_spirit_id", "")).is_empty():
			continue
		if not alchemy.has_shrine_charge(coord):
			continue
		var ring_center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var indicator_col: Color = Color(0.72, 0.90, 1.0, 0.88) if is_water_dropoff and not is_origin_shrine else Color(0.95, 0.92, 0.74, 0.85)
		draw_arc(ring_center, TILE_RADIUS * 0.55, 0.0, TAU, 24, indicator_col, 2.0)
		draw_circle(ring_center + Vector2(0.0, -TILE_RADIUS * 0.85), 5.0, indicator_col)
		if interact_mode:
			var collect_label: String = "Collect Water Essence" if is_water_dropoff and not is_origin_shrine else "Collect Essence"
			_draw_seed_overlay_text(ring_center + Vector2(-36.0, -16.0), collect_label, 11, indicator_col)
		else:
			var ready_label: String = "Water Essence Ready" if is_water_dropoff and not is_origin_shrine else "Essence Ready"
			_draw_seed_overlay_text(ring_center + Vector2(-34.0, -16.0), ready_label, 10, indicator_col)

func _draw_material_nodes() -> void:
	var hud: Node = get_node_or_null("../HUD")
	var interact_mode: bool = hud != null and hud.has_method("is_interact_mode") and hud.is_interact_mode()
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		if tile == null:
			continue
		if bool(tile.metadata.get("is_building_complete", false)):
			continue
		var node_variant: Variant = tile.metadata.get("material_node", null)
		if not (node_variant is Dictionary):
			continue
		var material_node: Dictionary = node_variant as Dictionary
		var state: StringName = StringName(str(material_node.get("state", &"")))
		if state == &"collected":
			continue
		_draw_material_node_visual(coord, material_node, interact_mode)

func _draw_material_node_visual(coord: Vector2i, material_node: Dictionary, interact_mode: bool) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var material_id: StringName = StringName(str(material_node.get("material_id", &"")))
	var state: StringName = StringName(str(material_node.get("state", &"")))
	var ready: bool = state == &"ready"
	var stage: int = _material_growth_stage(material_node)
	if ready:
		_draw_collect_ring(center, _material_color(material_id), coord)
	else:
		_draw_growth_ring(center, _material_color(material_id), material_node)
	if not _draw_material_atlas_node(center, material_id, stage):
		match material_id:
			&"living_wood":
				_draw_living_wood_node(coord, stage)
			&"reed_fiber":
				_draw_reed_fiber_node(coord, stage)
			&"spirit_stone":
				_draw_spirit_stone_node(coord, stage)
			&"ember_clay":
				_draw_ember_clay_node(coord, stage)
			_:
				draw_circle(center, 6.0, _material_color(material_id))
	if ready:
		var label: String = "Tap: %s" % _material_label(material_id) if interact_mode else _material_label(material_id)
		_draw_seed_overlay_text(center + Vector2(-36.0, -29.0), label, 10, _material_color(material_id).lightened(0.35))

func _material_growth_stage(material_node: Dictionary) -> int:
	if StringName(str(material_node.get("state", &""))) == &"ready":
		return 3
	return clampi(int(material_node.get("growth_stage", 0)), 0, 3)

func _material_growth_scale(stage: int) -> float:
	var scales: Array = [0.42, 0.62, 0.82, 1.0]
	return float(scales[clampi(stage, 0, scales.size() - 1)])

func _draw_material_atlas_node(center: Vector2, material_id: StringName, stage: int) -> bool:
	var source_region: Rect2 = _material_atlas_region(material_id, stage)
	if source_region.size == Vector2.ZERO:
		return false
	var draw_size: float = _material_atlas_draw_size(stage)
	var destination: Rect2 = Rect2(center - Vector2(draw_size * 0.5, draw_size * 0.58), Vector2(draw_size, draw_size))
	draw_texture_rect_region(_MATERIAL_GROWTH_ATLAS, destination, source_region)
	return true

func _material_atlas_region(material_id: StringName, stage: int) -> Rect2:
	var row: int = _material_atlas_row(material_id)
	if row < 0:
		return Rect2()
	var clamped_stage: int = clampi(stage, 0, _MATERIAL_GROWTH_ATLAS_COLUMNS - 1)
	var cell_size: Vector2 = Vector2(
		float(_MATERIAL_GROWTH_ATLAS.get_width()) / float(_MATERIAL_GROWTH_ATLAS_COLUMNS),
		float(_MATERIAL_GROWTH_ATLAS.get_height()) / float(_MATERIAL_GROWTH_ATLAS_ROWS)
	)
	return Rect2(Vector2(cell_size.x * float(clamped_stage), cell_size.y * float(row)), cell_size)

func _material_atlas_row(material_id: StringName) -> int:
	match material_id:
		&"living_wood":
			return 0
		&"reed_fiber":
			return 1
		&"spirit_stone":
			return 2
		&"ember_clay":
			return 3
		_:
			return -1

func _material_atlas_draw_size(stage: int) -> float:
	var stage_scale: Array = [0.68, 0.82, 0.95, 1.08]
	return _MATERIAL_NODE_DRAW_SIZE * float(stage_scale[clampi(stage, 0, stage_scale.size() - 1)])

func _draw_growth_ring(center: Vector2, color: Color, material_node: Dictionary) -> void:
	var duration: float = maxf(0.1, float(material_node.get("growth_duration", 60.0)))
	var elapsed: float = clampf(float(material_node.get("growth_elapsed", 0.0)), 0.0, duration)
	var progress: float = elapsed / duration
	var ring_radius: float = TILE_RADIUS * 0.68
	draw_arc(center, ring_radius, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.22), 1.6)
	draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, Color(color.r, color.g, color.b, 0.74), 2.2)

func _draw_collect_ring(center: Vector2, color: Color, coord: Vector2i) -> void:
	var pulse: float = 0.5 + 0.5 * sin(_anim_time * 2.4 + float(hash(coord) % 19))
	var ring_radius: float = TILE_RADIUS * (0.70 + pulse * 0.05)
	var ring_color: Color = Color(color.r, color.g, color.b, 0.36 + pulse * 0.24)
	draw_arc(center, ring_radius, 0.0, TAU, 32, ring_color, 2.4)
	draw_arc(center, ring_radius + 3.2, deg_to_rad(28.0), deg_to_rad(134.0), 10, Color(1.0, 1.0, 1.0, 0.34 + pulse * 0.22), 1.5)

func _draw_living_wood_node(coord: Vector2i, stage: int) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var in_large_cluster: bool = _is_in_large_cluster(coord, BiomeType.Value.MEADOW)
	var scale: float = _material_growth_scale(stage) * (1.16 if in_large_cluster else 1.0)
	var trunk_base: Vector2 = center + Vector2(0.0, 6.0)
	draw_circle(center + Vector2(0.0, 7.0), 5.0 + scale * 3.0, Color(0.08, 0.18, 0.08, 0.24))
	if stage == 0:
		draw_line(center + Vector2(0.0, 5.0), center + Vector2(0.0, -5.0), Color(0.39, 0.28, 0.15, 0.96), 1.8)
		draw_circle(center + Vector2(-2.8, -4.2), 3.2, Color(0.42, 0.76, 0.30, 0.96))
		draw_circle(center + Vector2(3.0, -5.2), 2.8, Color(0.64, 0.88, 0.38, 0.95))
		return
	draw_line(trunk_base, center + Vector2(0.0, -6.0 * scale), Color(0.38, 0.24, 0.12, 0.98), 4.0 * scale)
	if stage >= 2:
		draw_line(center + Vector2(-3.0, -1.0), center + Vector2(-9.0 * scale, -9.0 * scale), Color(0.38, 0.24, 0.12, 0.90), 2.0 * scale)
		draw_line(center + Vector2(3.0, -2.0), center + Vector2(9.0 * scale, -11.0 * scale), Color(0.38, 0.24, 0.12, 0.90), 2.0 * scale)
	draw_circle(center + Vector2(0.0, -12.0 * scale), 6.2 * scale, Color(0.40, 0.72, 0.28, 0.96))
	if stage >= 2:
		draw_circle(center + Vector2(-7.0 * scale, -10.0 * scale), 5.4 * scale, Color(0.32, 0.62, 0.24, 0.96))
		draw_circle(center + Vector2(8.0 * scale, -9.0 * scale), 5.0 * scale, Color(0.24, 0.55, 0.22, 0.96))
	if stage >= 3:
		draw_circle(center + Vector2(1.5, -13.0 * scale), 2.5 * scale, Color(0.82, 0.96, 0.52, 0.94))

func _draw_reed_fiber_node(coord: Vector2i, stage: int) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var scale: float = _material_growth_scale(stage)
	var water_shadow: Color = Color(0.03, 0.14, 0.24, 0.40)
	draw_circle(center + Vector2(1.0, 2.0), 5.0 + scale * 4.5, water_shadow)
	var reed_offsets: Array = [-7.0, -3.5, 2.5, 6.5]
	for index: int in range(stage + 1):
		var reed_x: float = float(reed_offsets[index])
		var base: Vector2 = center + Vector2(reed_x, 6.0)
		var height: float = (6.0 + float(stage) * 3.0) * (0.92 + float(index) * 0.06)
		draw_line(base, base + Vector2(1.4, -height), Color(0.58, 0.82, 0.38, 0.95), 1.4 + scale * 0.5)
		if stage >= 2:
			draw_circle(base + Vector2(1.5, -height), 1.4 + scale * 0.5, Color(0.86, 0.77, 0.34, 0.90))
	if stage < 3:
		return
	var fish_center: Vector2 = center + Vector2(2.5, -3.0 + sin(_anim_time * 2.2) * 1.2)
	var fish_col: Color = Color(0.72, 0.94, 1.0, 0.94)
	draw_colored_polygon(PackedVector2Array([
		fish_center + Vector2(-8.0, 0.0),
		fish_center + Vector2(-2.5, -4.0),
		fish_center + Vector2(6.0, -2.4),
		fish_center + Vector2(8.5, 0.0),
		fish_center + Vector2(6.0, 2.4),
		fish_center + Vector2(-2.5, 4.0),
	]), fish_col)
	draw_colored_polygon(PackedVector2Array([
		fish_center + Vector2(-8.0, 0.0),
		fish_center + Vector2(-13.0, -4.0),
		fish_center + Vector2(-13.0, 4.0),
	]), Color(0.44, 0.78, 0.95, 0.92))
	draw_circle(fish_center + Vector2(5.0, -0.8), 0.9, Color(0.02, 0.08, 0.12, 0.90))

func _draw_spirit_stone_node(coord: Vector2i, stage: int) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var scale: float = _material_growth_scale(stage)
	draw_circle(center + Vector2(0.0, 6.5), 4.5 + scale * 4.2, Color(0.05, 0.06, 0.08, 0.34))
	var crystal_col: Color = Color(0.74, 0.82, 0.90, 0.96)
	var glow_col: Color = Color(0.84, 0.96, 1.0, 0.58)
	var crystals: Array = [
		{"offset": Vector2(-6.0, 1.0), "height": 13.0, "width": 5.0},
		{"offset": Vector2(0.0, -2.0), "height": 17.0, "width": 6.5},
		{"offset": Vector2(6.0, 2.0), "height": 11.0, "width": 4.5},
		{"offset": Vector2(1.0, 6.0), "height": 8.0, "width": 3.8},
	]
	for index: int in range(stage + 1):
		var crystal: Dictionary = crystals[index]
		var offset: Vector2 = crystal["offset"]
		var height: float = float(crystal["height"]) * scale
		var width: float = float(crystal["width"]) * scale
		var base: Vector2 = center + offset
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-width, 4.0),
			base + Vector2(0.0, -height),
			base + Vector2(width, 4.0),
			base + Vector2(0.0, 7.0),
		]), crystal_col)
		if stage >= 2:
			draw_line(base + Vector2(0.0, -height + 1.0), base + Vector2(0.0, 5.5), glow_col, 1.2)

func _draw_ember_clay_node(coord: Vector2i, stage: int) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var scale: float = _material_growth_scale(stage)
	draw_circle(center + Vector2(0.0, 5.0), 4.5 + scale * 4.8, Color(0.16, 0.04, 0.02, 0.45))
	var clay_col: Color = Color(0.70, 0.28, 0.16, 0.96)
	var ember_col: Color = Color(1.0, 0.72, 0.25, 0.94)
	var shards: Array = [
		{"offset": Vector2(-5.0, 2.0), "radius": 5.0},
		{"offset": Vector2(2.5, -2.0), "radius": 6.5},
		{"offset": Vector2(7.0, 4.0), "radius": 4.2},
		{"offset": Vector2(0.0, 6.0), "radius": 3.6},
	]
	for index: int in range(stage + 1):
		var shard: Dictionary = shards[index]
		var offset: Vector2 = shard["offset"]
		var radius: float = float(shard["radius"]) * scale
		var shard_center: Vector2 = center + offset
		draw_colored_polygon(PackedVector2Array([
			shard_center + Vector2(-radius, 2.0),
			shard_center + Vector2(-radius * 0.2, -radius),
			shard_center + Vector2(radius, -radius * 0.2),
			shard_center + Vector2(radius * 0.35, radius),
		]), clay_col)
		if stage >= 2:
			draw_circle(shard_center + Vector2(1.0, -1.0), radius * 0.24, ember_col)

func _draw_interact_hover_popover() -> void:
	var hud: Node = get_node_or_null("../HUD")
	if hud != null and hud.has_method("hide_world_popover"):
		hud.hide_world_popover()
	var interact_mode: bool = hud != null and hud.has_method("is_interact_mode") and hud.is_interact_mode()
	if not interact_mode:
		return
	var tile: GardenTile = GameState.grid.get_tile(_hover_coord)
	if tile == null:
		return
	var is_house: bool = bool(tile.metadata.get("is_building_complete", false)) and not bool(tile.metadata.get("shrine_built", false))
	var is_structure: bool = bool(tile.metadata.get("shrine_built", false)) or bool(tile.metadata.get("is_origin_shrine", false)) or bool(tile.metadata.get("is_water_dropoff", false))
	var material_node: Dictionary = {}
	var node_variant: Variant = tile.metadata.get("material_node", null)
	if node_variant is Dictionary:
		material_node = node_variant as Dictionary
	var has_material: bool = not material_node.is_empty() and StringName(str(material_node.get("state", &""))) != &"collected"
	var has_ready_material: bool = has_material and StringName(str(material_node.get("state", &""))) == &"ready"
	if not is_house and not is_structure and not has_material:
		return
	var lines: Array[String] = []
	if has_material:
		lines.append("Material: %s" % _material_label(StringName(str(material_node.get("material_id", &"")))))
		if has_ready_material:
			lines.append("Tap to harvest")
		else:
			var duration: float = maxf(0.1, float(material_node.get("growth_duration", 60.0)))
			var elapsed: float = clampf(float(material_node.get("growth_elapsed", 0.0)), 0.0, duration)
			lines.append("Growing: %ds" % int(ceil(duration - elapsed)))
	if is_house:
		lines.append("Type: %s" % _structure_label_for_tile(tile))
		var owner_label: String = "Owner: Unbound"
		var spirit_service: Node = _resolve_spirit_service()
		if spirit_service != null and spirit_service.has_method("get_house_owner_at_coord"):
			var owner_info: Dictionary = spirit_service.get_house_owner_at_coord(_hover_coord)
			if not owner_info.is_empty():
				owner_label = "Owner: %s" % str(owner_info.get("display_name", owner_info.get("spirit_id", "Unknown")))
		lines.append(owner_label)
	if is_structure:
		lines.append("Type: %s" % _structure_label_for_tile(tile))
		var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
		if alchemy != null and alchemy.has_method("get_shrine_charge_counts"):
			var counts: Dictionary = alchemy.get_shrine_charge_counts(_hover_coord)
			lines.append("Essence: %s" % _format_shrine_counts(counts))
	if lines.is_empty():
		return
	if hud != null and hud.has_method("show_world_popover"):
		var anchor_world: Vector2 = _HexUtils.axial_to_pixel(_hover_coord, TILE_RADIUS)
		var anchor_screen: Vector2 = get_global_transform_with_canvas() * anchor_world
		hud.show_world_popover(anchor_screen, lines)

func _structure_label_for_tile(tile: GardenTile) -> String:
	if tile == null:
		return "Structure"
	if bool(tile.metadata.get("is_origin_shrine", false)):
		return "Origin Shrine"
	var structure_id: String = str(tile.metadata.get("structure_discovery_id", ""))
	match structure_id:
		"building_meadow_dwelling":
			return "Meadow Dwelling"
		"building_scorched_hollow":
			return "Scorched Hollow"
		"building_reed_nest":
			return "Reed Nest"
		"building_stone_basin":
			return "Stone Basin"
		"building_house":
			return "House (%s)" % _biome_label(tile.biome)
	if structure_id.begins_with("building_"):
		return _humanize_structure_id(structure_id)
	var discovery_id: String = str(tile.metadata.get("build_discovery_id", ""))
	if not discovery_id.is_empty():
		return _humanize_discovery_id(discovery_id)
	if bool(tile.metadata.get("is_water_dropoff", false)):
		return "Water Dropoff Shrine"
	return "Shrine"

func _format_shrine_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "Empty"
	var element_ids: Array[int] = []
	for key_variant: Variant in counts.keys():
		element_ids.append(int(key_variant))
	element_ids.sort()
	var parts: PackedStringArray = PackedStringArray()
	for element_id: int in element_ids:
		var amount: int = int(counts.get(element_id, 0))
		if amount <= 0:
			continue
		parts.append("%s x%d" % [_godai_name(element_id), amount])
	if parts.is_empty():
		return "Empty"
	return ", ".join(parts)

func _godai_name(element_id: int) -> String:
	match element_id:
		0:
			return "Chi"
		1:
			return "Sui"
		2:
			return "Ka"
		3:
			return "Fu"
		4:
			return "Ku"
		_:
			return "?"

func _material_label(material_id: StringName) -> String:
	match material_id:
		&"living_wood":
			return "Living Wood"
		&"reed_fiber":
			return "Reed Fiber"
		&"spirit_stone":
			return "Spirit Stone"
		&"ember_clay":
			return "Ember Clay"
		_:
			return str(material_id).replace("_", " ").capitalize()

func _material_color(material_id: StringName) -> Color:
	match material_id:
		&"living_wood":
			return Color(0.70, 0.95, 0.38, 0.96)
		&"reed_fiber":
			return Color(0.62, 0.90, 1.0, 0.96)
		&"spirit_stone":
			return Color(0.82, 0.92, 1.0, 0.96)
		&"ember_clay":
			return Color(1.0, 0.56, 0.24, 0.96)
		_:
			return Color(0.94, 0.92, 0.82, 0.96)

func _biome_label(biome: int) -> String:
	match biome:
		BiomeType.Value.STONE:
			return "Stone"
		BiomeType.Value.RIVER:
			return "River"
		BiomeType.Value.EMBER_FIELD:
			return "Ember"
		BiomeType.Value.MEADOW:
			return "Meadow"
		BiomeType.Value.WETLANDS:
			return "Wetlands"
		BiomeType.Value.KU:
			return "Ku"
		_:
			return "Mixed"

func _humanize_discovery_id(discovery_id: String) -> String:
	var raw: String = discovery_id
	if raw.begins_with("disc_"):
		raw = raw.substr(5)
	var words: PackedStringArray = PackedStringArray()
	for part: String in raw.split("_"):
		if part.is_empty():
			continue
		words.append(part.substr(0, 1).to_upper() + part.substr(1))
	if words.is_empty():
		return "Structure"
	return " ".join(words)

func _humanize_structure_id(structure_id: String) -> String:
	var raw: String = structure_id
	if raw.begins_with("building_"):
		raw = raw.substr(9)
	var words: PackedStringArray = PackedStringArray()
	for part: String in raw.split("_"):
		if part.is_empty():
			continue
		words.append(part.substr(0, 1).to_upper() + part.substr(1))
	if words.is_empty():
		return "Structure"
	return " ".join(words)

func _resolve_spirit_service() -> Node:
	var direct: Node = get_node_or_null("/root/SpiritService")
	if direct != null:
		return direct
	var garden_path: Node = get_node_or_null("/root/Garden/SpiritService")
	if garden_path != null:
		return garden_path
	var voxel_path: Node = get_node_or_null("/root/VoxelGarden/SpiritService")
	if voxel_path != null:
		return voxel_path
	return null

func _draw_build_progress_overlays() -> void:
	var now: float = Time.get_unix_time_from_system()
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		if tile == null:
			continue
		if not bool(tile.metadata.get("is_build_block", false)):
			continue
		if bool(tile.metadata.get("is_building_complete", false)):
			continue
		var countdown_started: bool = bool(tile.metadata.get("build_countdown_started", false))
		if not countdown_started:
			var pending_center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
			var pending_highlight: PackedVector2Array = _hex_polygon(pending_center, TILE_RADIUS - 2.0)
			var recipe_valid: bool = bool(tile.metadata.get("project_recipe_valid", false))
			var fill_col: Color = Color(0.28, 0.82, 0.48, 0.25) if recipe_valid else Color(0.35, 0.63, 1.0, 0.24)
			var border_col: Color = Color(0.32, 0.95, 0.56, 0.95) if recipe_valid else Color(0.42, 0.72, 1.0, 0.95)
			draw_colored_polygon(pending_highlight, fill_col)
			var pending_border: PackedVector2Array = PackedVector2Array(pending_highlight)
			pending_border.append(pending_highlight[0])
			draw_polyline(pending_border, border_col, 2.0)
			var invalid_flash_started_at: float = float(tile.metadata.get("project_invalid_flash_started_at", -1.0))
			if invalid_flash_started_at >= 0.0:
				var elapsed_flash: float = now - invalid_flash_started_at
				if elapsed_flash <= 2.0:
					var flash_alpha: float = elapsed_flash if elapsed_flash <= 1.0 else (2.0 - elapsed_flash)
					flash_alpha = clampf(flash_alpha, 0.0, 1.0)
					draw_polyline(pending_border, Color(1.0, 0.18, 0.15, 0.95 * flash_alpha), 3.3)
					var invalid_feedback: String = str(tile.metadata.get("project_invalid_feedback", "Cannot confirm yet."))
					_draw_seed_overlay_text(pending_center + Vector2(-46.0, 2.0), invalid_feedback, 9, Color(1.0, 0.82, 0.72, 0.95 * flash_alpha))
			_draw_seed_overlay_text(pending_center + Vector2(-28.0, -26.0), "Confirm", 10, Color(0.96, 0.93, 0.80, 0.96))
			_draw_seed_overlay_text(pending_center + Vector2(-34.0, -12.0), "RMB Cancel", 10, Color(0.95, 0.78, 0.72, 0.94))
			continue
		var started_at: float = float(tile.metadata.get("build_started_at", now))
		var duration: float = float(tile.metadata.get("build_duration", 10.0))
		var remaining: int = int(ceil(maxf(0.0, duration - (now - started_at))))
		var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		_draw_seed_overlay_text(center + Vector2(-18.0, -18.0), "Build %ds" % remaining, 10, Color(0.96, 0.90, 0.74, 0.92))

func _draw_build_block_icon(coord: Vector2i, biome: int, structure_id: String, under_construction: bool, completed: bool, is_origin_shrine: bool = false, is_water_dropoff: bool = false, is_wayfarer_torii: bool = false) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	if completed:
		if is_origin_shrine:
			_draw_structure_texture(center, _ORIGIN_SHRINE_STRUCTURE_TEXTURE, _ORIGIN_SHRINE_STRUCTURE_DRAW_SIZE)
			return
		var structure_texture: Texture2D = _structure_texture_for_id(structure_id)
		if structure_texture != null:
			_draw_structure_texture(center, structure_texture, _structure_draw_size_for_id(structure_id))
			return
	var palette: Dictionary = _building_palette_for_biome(biome)
	var roof_col: Color = Color(palette.get("roof", Color(0.60, 0.34, 0.20, 0.92)))
	var wall_col: Color = Color(palette.get("wall", Color(0.82, 0.75, 0.62, 0.88)))
	var accent_col: Color = Color(palette.get("accent", Color(0.95, 0.90, 0.70, 0.92)))
	if under_construction:
		roof_col = roof_col.darkened(0.22)
		wall_col = wall_col.darkened(0.18)
	elif completed:
		roof_col = roof_col.lightened(0.08)
		wall_col = wall_col.lightened(0.06)
	var w: float = TILE_RADIUS * 0.85
	var h: float = TILE_RADIUS * 0.55
	var body_rect: Rect2 = Rect2(center + Vector2(-w * 0.5, -h * 0.15), Vector2(w, h))
	var roof: PackedVector2Array = PackedVector2Array([
		center + Vector2(-w * 0.6, -h * 0.15),
		center + Vector2(0.0, -h * 0.75),
		center + Vector2(w * 0.6, -h * 0.15),
	])
	draw_colored_polygon(roof, roof_col)
	draw_rect(body_rect, wall_col)
	draw_rect(body_rect, Color(0.32, 0.24, 0.14, 0.95), false, 1.3)
	var door_rect: Rect2 = Rect2(center + Vector2(-w * 0.10, h * 0.10), Vector2(w * 0.20, h * 0.30))
	draw_rect(door_rect, Color(0.36, 0.24, 0.14, 0.95))
	if completed:
		draw_circle(center + Vector2(w * 0.36, -h * 0.30), 2.8, accent_col)
	elif under_construction:
		draw_line(center + Vector2(-w * 0.45, -h * 0.10), center + Vector2(w * 0.45, h * 0.45), Color(0.44, 0.33, 0.18, 0.95), 1.4)
		draw_line(center + Vector2(-w * 0.45, h * 0.45), center + Vector2(w * 0.45, -h * 0.10), Color(0.44, 0.33, 0.18, 0.95), 1.4)

	if is_origin_shrine:
		# Distinct shrine marker: ring + core + simple cross-sigil.
		var shrine_center: Vector2 = center + Vector2(0.0, -h * 0.48)
		draw_circle(shrine_center, 6.8, Color(0.08, 0.10, 0.16, 0.85))
		draw_arc(shrine_center, 7.4, 0.0, TAU, 24, Color(0.98, 0.90, 0.58, 0.98), 1.8)
		draw_circle(shrine_center, 2.1, Color(1.0, 0.96, 0.80, 0.95))
		draw_line(shrine_center + Vector2(-3.0, 0.0), shrine_center + Vector2(3.0, 0.0), Color(0.98, 0.90, 0.58, 0.98), 1.5)
		draw_line(shrine_center + Vector2(0.0, -3.0), shrine_center + Vector2(0.0, 3.0), Color(0.98, 0.90, 0.58, 0.98), 1.5)
	elif is_wayfarer_torii:
		# Torii marker: two pillars with top beam, tinted by biome palette.
		var gate_center: Vector2 = center + Vector2(0.0, -h * 0.42)
		var beam_col: Color = roof_col.lightened(0.20)
		var post_col: Color = wall_col.darkened(0.10)
		draw_rect(Rect2(gate_center + Vector2(-8.5, -6.0), Vector2(17.0, 2.6)), beam_col)
		draw_rect(Rect2(gate_center + Vector2(-6.2, -3.4), Vector2(2.4, 8.8)), post_col)
		draw_rect(Rect2(gate_center + Vector2(3.8, -3.4), Vector2(2.4, 8.8)), post_col)
		draw_circle(gate_center + Vector2(0.0, -1.8), 1.1, accent_col)
	elif is_water_dropoff:
		# Subtle water-drop marker for water essence dropoff structures.
		var drop_center: Vector2 = center + Vector2(0.0, -h * 0.50)
		draw_circle(drop_center, 5.6, Color(0.10, 0.20, 0.32, 0.80))
		draw_circle(drop_center + Vector2(0.0, -1.2), 2.8, Color(0.70, 0.90, 1.0, 0.95))
		draw_arc(drop_center, 4.9, 0.0, TAU, 20, Color(0.80, 0.95, 1.0, 0.92), 1.4)

func _should_draw_house_structure_sprite(structure_id: String) -> bool:
	if structure_id.is_empty():
		return true
	return ["building_house", "building_meadow_dwelling", "building_reed_nest"].has(structure_id)

func _structure_texture_for_id(structure_id: String) -> Texture2D:
	if structure_id.is_empty():
		return _HOUSE_STRUCTURE_TEXTURE
	if _structure_texture_cache.has(structure_id):
		return _structure_texture_cache[structure_id] as Texture2D
	var texture: Texture2D = null
	var asset_path: String = _structure_catalog.get_asset_path(structure_id)
	if not asset_path.is_empty() and FileAccess.file_exists(asset_path):
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(asset_path))
		if image != null:
			texture = ImageTexture.create_from_image(image)
	if texture == null and _should_draw_house_structure_sprite(structure_id):
		texture = _HOUSE_STRUCTURE_TEXTURE
	_structure_texture_cache[structure_id] = texture
	return texture

func _structure_draw_size_for_id(structure_id: String) -> float:
	if structure_id == "disc_origin_shrine":
		return _ORIGIN_SHRINE_STRUCTURE_DRAW_SIZE
	if structure_id.begins_with("disc_"):
		return 34.0
	return _HOUSE_STRUCTURE_DRAW_SIZE

func _draw_structure_texture(center: Vector2, texture: Texture2D, draw_size: float) -> void:
	if texture == null:
		return
	var size: Vector2 = Vector2(draw_size, draw_size)
	var top_left: Vector2 = center - Vector2(size.x * 0.5, size.y * 0.68)
	draw_texture_rect(texture, Rect2(top_left, size), false)

func _building_palette_for_biome(biome: int) -> Dictionary:
	match biome:
		BiomeType.Value.STONE:
			return {"roof": Color(0.52, 0.52, 0.56, 0.95), "wall": Color(0.72, 0.72, 0.74, 0.90), "accent": Color(0.92, 0.92, 0.96, 0.95)}
		BiomeType.Value.RIVER:
			return {"roof": Color(0.20, 0.40, 0.62, 0.95), "wall": Color(0.66, 0.78, 0.90, 0.90), "accent": Color(0.92, 0.97, 1.0, 0.95)}
		BiomeType.Value.EMBER_FIELD:
			return {"roof": Color(0.64, 0.28, 0.18, 0.95), "wall": Color(0.82, 0.58, 0.46, 0.90), "accent": Color(1.0, 0.82, 0.55, 0.95)}
		BiomeType.Value.MEADOW:
			return {"roof": Color(0.26, 0.52, 0.24, 0.95), "wall": Color(0.76, 0.84, 0.70, 0.90), "accent": Color(0.92, 1.0, 0.88, 0.95)}
		_:
			return {"roof": Color(0.60, 0.34, 0.20, 0.92), "wall": Color(0.82, 0.75, 0.62, 0.88), "accent": Color(0.95, 0.90, 0.70, 0.92)}

func _draw_satori_overlay() -> void:
	var font: Font = ThemeDB.fallback_font
	var label: String = "Satori %d/%d  •  Era %s" % [_satori_amount, _satori_cap, str(_satori_era).capitalize()]
	var pos: Vector2 = Vector2(20.0, 28.0)
	draw_string(font, pos + Vector2(1.0, 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.0, 0.0, 0.0, 0.7))
	draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.94, 0.90, 0.78, 0.96))

func _is_any_build_tile_built(coords: Array[Vector2i]) -> bool:
	for coord: Vector2i in coords:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		if bool(tile.metadata.get("shrine_built", false)):
			return true
	return false


# ---------------------------------------------------------------------------
# Tile drawing helpers
# ---------------------------------------------------------------------------

func _draw_tile(
	coord: Vector2i,
	color: Color,
	biome: int = BiomeType.Value.NONE
) -> void:
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var pts: PackedVector2Array = _hex_polygon(center, TILE_RADIUS)

	# --- 2.5D voxel side-faces ---
	# Pointy-top hex vertices (i=0 is top, going clockwise):
	#   0=top, 1=upper-right, 2=lower-right, 3=bottom, 4=lower-left, 5=upper-left
	# With top-down view and light from upper-right, the visible "side walls"
	# are on the left and lower-left edges (edges 4→5 and 5→0).
	# We extrude these edges straight downward to simulate voxel height.
	for edge_index: int in [3, 4, 5]:
		var a: Vector2 = pts[edge_index]
		var b: Vector2 = pts[(edge_index + 1) % 6]
		var a_low: Vector2 = Vector2(a.x, a.y + VOXEL_DEPTH)
		var b_low: Vector2 = Vector2(b.x, b.y + VOXEL_DEPTH)
		var shade: float = 0.52 if edge_index == 4 else 0.44
		draw_colored_polygon(PackedVector2Array([a, b, b_low, a_low]), color.darkened(shade))

	# --- Main top face ---
	if _terrain_tileset_texture != null and _TerrainTilesheet.supports_biome(biome):
		_draw_tilesheet_top(coord, center, biome)
	else:
		draw_colored_polygon(pts, color)

	# --- Directional edge shading (light from upper-right) ---
	for i: int in range(6):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 6]
		if i == 0 or i == 1:  # Top + upper-right: bright highlight
			draw_line(a, b, color.lightened(0.32), 2.0)
		elif i == 4 or i == 5:  # Lower-left + upper-left: shadow
			draw_line(a, b, color.darkened(0.28), 1.5)

	# --- Crisp outer border ---
	var border: PackedVector2Array = PackedVector2Array(pts)
	border.append(pts[0])
	draw_polyline(border, color.darkened(0.45), 1.0)


func _draw_tilesheet_top(
	coord: Vector2i,
	center: Vector2,
	biome: int
) -> void:
	var frame: int = _terrain_frame_for_coord(coord, biome)
	var region: Rect2 = _TerrainTilesheet.region_for(coord, biome, frame)
	var size := Vector2(TERRAIN_TILE_DRAW_SIZE, TERRAIN_TILE_DRAW_SIZE)
	var rect := Rect2(center - size * 0.5, size)
	draw_texture_rect_region(_terrain_tileset_texture, rect, region)


func _load_terrain_tilesheet() -> void:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(_TERRAIN_TILESET_PATH))
	if image == null:
		push_warning("GardenView: terrain tilesheet could not be loaded from %s" % _TERRAIN_TILESET_PATH)
		return
	_terrain_tileset_texture = ImageTexture.create_from_image(image)
	var edge_image: Image = Image.load_from_file(ProjectSettings.globalize_path(_EDGE_DECAL_PATH))
	if edge_image == null:
		push_warning("GardenView: edge decal could not be loaded from %s" % _EDGE_DECAL_PATH)
		return
	_edge_decal_texture = ImageTexture.create_from_image(edge_image)


func _draw_shoreline_edges(coord: Vector2i, biome: int) -> void:
	if biome != BiomeType.Value.MEADOW:
		return
	for offset: Vector2i in _HexUtils.HEX_NEIGHBORS:
		var neighbour: GardenTile = GameState.grid.get_tile(coord + offset)
		if neighbour == null or neighbour.biome != BiomeType.Value.RIVER:
			continue
		_draw_shoreline_edge(coord, offset)


func _draw_shoreline_edge(coord: Vector2i, water_offset: Vector2i) -> void:
	if _edge_decal_texture == null:
		return
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var water_direction: Vector2 = _HexUtils.axial_to_pixel(water_offset, 1.0).normalized()
	var edge_distance: float = TILE_RADIUS * cos(deg_to_rad(30.0))
	var decal_center: Vector2 = center + water_direction * edge_distance - water_direction * EDGE_DECAL_MEADOW_INSET
	var region: Rect2 = _TerrainTilesheet.edge_decal_region_for(coord + water_offset)
	var size := Vector2(EDGE_DECAL_DRAW_SIZE, EDGE_DECAL_DRAW_SIZE)
	var rect := Rect2(-size * 0.5, size)
	var rotation: float = water_direction.angle() - PI * 0.5
	draw_set_transform(decal_center, rotation, Vector2.ONE)
	draw_texture_rect_region(_edge_decal_texture, rect, region)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _terrain_frame_for_coord(coord: Vector2i, biome: int) -> int:
	if biome != BiomeType.Value.RIVER or _TerrainTilesheet.TERRAIN_FRAME_COUNT <= 1:
		return 0
	var phase: int = posmod(hash(coord), _TerrainTilesheet.TERRAIN_FRAME_COUNT)
	return posmod(int(floor(_anim_time * WATER_TILE_ANIMATION_FPS)) + phase, _TerrainTilesheet.TERRAIN_FRAME_COUNT)




func _draw_tile_decorations(coord: Vector2i, biome: int, in_large_cluster: bool) -> void:
	if _TerrainTilesheet.supports_biome(biome):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var cx: float = center.x
	var cy: float = center.y
	var half: float = TILE_RADIUS

	match biome:
		BiomeType.Value.STONE:
			# Rock shapes — small triangular & rectangular outlines
			var count: int = rng.randi_range(2, 4)
			for _i: int in range(count):
				var rx: float = cx + rng.randf_range(-half * 0.55, half * 0.55)
				var ry: float = cy + rng.randf_range(-half * 0.50, half * 0.50)
				var rw: float = rng.randf_range(3.5, 6.5)
				var rh: float = rng.randf_range(2.0, 4.5)
				draw_colored_polygon(PackedVector2Array([
					Vector2(rx - rw, ry + rh + 1.5), Vector2(rx + rw, ry + rh + 1.5),
					Vector2(rx + rw + 1.5, ry + rh * 2.0), Vector2(rx - rw + 1.5, ry + rh * 2.0)
				]), Color(0.15, 0.15, 0.18, 0.35))
				draw_colored_polygon(PackedVector2Array([
					Vector2(rx, ry - rh), Vector2(rx + rw, ry + rh),
					Vector2(rx - rw, ry + rh)
				]), Color(0.48, 0.48, 0.52, 0.85))
				draw_line(Vector2(rx - rw * 0.6, ry - rh * 0.4), Vector2(rx + rw * 0.2, ry - rh * 0.7), Color(0.80, 0.82, 0.85, 0.60), 1.2)
			draw_line(Vector2(cx + rng.randf_range(-8.0, -3.0), cy + rng.randf_range(-8.0, 0.0)), Vector2(cx + rng.randf_range(3.0, 8.0), cy + rng.randf_range(0.0, 8.0)), Color(0.28, 0.28, 0.30, 0.65), 1.0)

		BiomeType.Value.RIVER:
			# Ripple lines + sparkle dots
			for w: int in range(3):
				var y_off: float = -7.0 + w * 7.0
				var pts := PackedVector2Array()
				for i: int in range(7):
					var tt: float = float(i) / 6.0
					pts.append(Vector2(cx - half * 0.72 + tt * TILE_RADIUS * 1.44, cy + y_off + sin(tt * PI * 2.0 + rng.randf() * 0.8) * 2.5))
				var alpha: float = 0.70 if w == 1 else 0.45
				draw_polyline(pts, Color(0.72, 0.92, 1.0, alpha), 1.5)
			var sparks: int = rng.randi_range(2, 4)
			for _s: int in range(sparks):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.65, half * 0.65), cy + rng.randf_range(-half * 0.65, half * 0.65)), 1.2, Color(1.0, 1.0, 1.0, 0.80))

		BiomeType.Value.EMBER_FIELD:
			# Ember cracks and glowing cinders
			for _e: int in range(rng.randi_range(3, 5)):
				var ex: float = cx + rng.randf_range(-half * 0.55, half * 0.55)
				var ey: float = cy + rng.randf_range(-half * 0.55, half * 0.55)
				draw_circle(Vector2(ex, ey), rng.randf_range(1.8, 3.4), Color(1.0, 0.72, 0.24, 0.82))
				draw_circle(Vector2(ex, ey), rng.randf_range(0.6, 1.5), Color(1.0, 0.96, 0.70, 0.92))
			for _c: int in range(3):
				var sx: float = cx + rng.randf_range(-half * 0.65, half * 0.65)
				var sy: float = cy + rng.randf_range(-half * 0.65, half * 0.65)
				draw_line(Vector2(sx, sy), Vector2(sx + rng.randf_range(-7.0, 7.0), sy + rng.randf_range(-7.0, 7.0)), Color(0.36, 0.10, 0.06, 0.78), 1.3)

		BiomeType.Value.MEADOW:
			if in_large_cluster:
				# Canopy clusters — 2 large overlapping circles with shadow
				var count: int = rng.randi_range(2, 3)
				for _i: int in range(count):
					var ox: float = rng.randf_range(-half * 0.45, half * 0.45)
					var oy: float = rng.randf_range(-half * 0.40, half * 0.40)
					var r: float = rng.randf_range(4.5, 7.0)
					# Shadow
					draw_circle(Vector2(cx + ox + 1.5, cy + oy + 2.0), r, Color(0.03, 0.18, 0.03, 0.35))
					# Canopy
					draw_circle(Vector2(cx + ox, cy + oy), r, Color(0.08, 0.36, 0.10, 0.78))
					draw_circle(Vector2(cx + ox - r * 0.35, cy + oy + r * 0.25), r * 0.72, Color(0.10, 0.42, 0.12, 0.65))
			else:
				# Individual trees — trunk + 3-lobe canopy
				var count: int = rng.randi_range(2, 4)
				for _i: int in range(count):
					var ox: float = rng.randf_range(-half * 0.55, half * 0.55)
					var oy: float = rng.randf_range(-half * 0.45, half * 0.45)
					var r: float = rng.randf_range(3.5, 5.5)
					# Shadow
					draw_circle(Vector2(cx + ox + 1.5, cy + oy + 2.0), r, Color(0.0, 0.12, 0.0, 0.30))
					# Trunk
					draw_line(Vector2(cx + ox, cy + oy + r * 0.5), Vector2(cx + ox, cy + oy + r * 1.25), Color(0.32, 0.20, 0.07, 0.95), 2.0)
					# Canopy (3 overlapping circles for volume)
					draw_circle(Vector2(cx + ox, cy + oy - r * 0.2), r, Color(0.12, 0.42, 0.13, 0.90))
					draw_circle(Vector2(cx + ox - r * 0.60, cy + oy + r * 0.30), r * 0.72, Color(0.10, 0.38, 0.11, 0.80))
					draw_circle(Vector2(cx + ox + r * 0.60, cy + oy + r * 0.30), r * 0.72, Color(0.10, 0.38, 0.11, 0.80))
					# Highlight on canopy top
					draw_circle(Vector2(cx + ox - r * 0.20, cy + oy - r * 0.45), r * 0.35, Color(0.30, 0.70, 0.25, 0.45))

		BiomeType.Value.FOREST:
			if in_large_cluster:
				var count: int = rng.randi_range(2, 3)
				for _i: int in range(count):
					var ox: float = rng.randf_range(-half * 0.45, half * 0.45)
					var oy: float = rng.randf_range(-half * 0.40, half * 0.40)
					var r: float = rng.randf_range(4.5, 7.0)
					draw_circle(Vector2(cx + ox + 1.5, cy + oy + 2.0), r, Color(0.03, 0.18, 0.03, 0.35))
					draw_circle(Vector2(cx + ox, cy + oy), r, Color(0.08, 0.36, 0.10, 0.78))
					draw_circle(Vector2(cx + ox - r * 0.35, cy + oy + r * 0.25), r * 0.72, Color(0.10, 0.42, 0.12, 0.65))
			else:
				var count: int = rng.randi_range(2, 4)
				for _i: int in range(count):
					var ox: float = rng.randf_range(-half * 0.55, half * 0.55)
					var oy: float = rng.randf_range(-half * 0.45, half * 0.45)
					var r: float = rng.randf_range(3.5, 5.5)
					draw_circle(Vector2(cx + ox + 1.5, cy + oy + 2.0), r, Color(0.0, 0.12, 0.0, 0.30))
					draw_line(Vector2(cx + ox, cy + oy + r * 0.5), Vector2(cx + ox, cy + oy + r * 1.25), Color(0.32, 0.20, 0.07, 0.95), 2.0)
					draw_circle(Vector2(cx + ox, cy + oy - r * 0.2), r, Color(0.12, 0.42, 0.13, 0.90))
					draw_circle(Vector2(cx + ox - r * 0.60, cy + oy + r * 0.30), r * 0.72, Color(0.10, 0.38, 0.11, 0.80))
					draw_circle(Vector2(cx + ox + r * 0.60, cy + oy + r * 0.30), r * 0.72, Color(0.10, 0.38, 0.11, 0.80))
					draw_circle(Vector2(cx + ox - r * 0.20, cy + oy - r * 0.45), r * 0.35, Color(0.30, 0.70, 0.25, 0.45))

		BiomeType.Value.WATER:
			# Ripple lines + sparkle dots
			for w: int in range(3):
				var y_off: float = -7.0 + w * 7.0
				var pts := PackedVector2Array()
				for i: int in range(7):
					var tt: float = float(i) / 6.0
					pts.append(Vector2(cx - half * 0.72 + tt * TILE_RADIUS * 1.44, cy + y_off + sin(tt * PI * 2.0 + rng.randf() * 0.8) * 2.5))
				var alpha: float = 0.70 if w == 1 else 0.45
				draw_polyline(pts, Color(0.72, 0.92, 1.0, alpha), 1.5)
			# 2-4 sparkle dots
			var sparks: int = rng.randi_range(2, 4)
			for _s: int in range(sparks):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.65, half * 0.65), cy + rng.randf_range(-half * 0.65, half * 0.65)), 1.2, Color(1.0, 1.0, 1.0, 0.80))

		BiomeType.Value.EARTH:
			# Soil texture: pebbles + thin cross-hatch marks
			var count: int = rng.randi_range(5, 8)
			for _i: int in range(count):
				var pebble_x: float = cx + rng.randf_range(-half * 0.68, half * 0.68)
				var pebble_y: float = cy + rng.randf_range(-half * 0.68, half * 0.68)
				var pebble_r: float = rng.randf_range(1.2, 2.8)
				draw_circle(Vector2(pebble_x, pebble_y), pebble_r, Color(0.52, 0.32, 0.12, 0.65))
				draw_circle(Vector2(pebble_x - pebble_r * 0.4, pebble_y - pebble_r * 0.4), pebble_r * 0.4, Color(0.68, 0.48, 0.22, 0.50))
			# 2 faint texture lines
			for _t: int in range(2):
				var lx: float = cx + rng.randf_range(-half * 0.5, half * 0.5)
				var ly: float = cy + rng.randf_range(-half * 0.5, half * 0.5)
				draw_line(Vector2(lx, ly), Vector2(lx + rng.randf_range(-6.0, 6.0), ly + rng.randf_range(-6.0, 6.0)), Color(0.45, 0.26, 0.08, 0.45), 1.0)

		BiomeType.Value.SWAMP:
			# Tall reeds with seed heads + murky water glints
			var count: int = rng.randi_range(3, 5)
			for _i: int in range(count):
				var ox: float = rng.randf_range(-half * 0.65, half * 0.65)
				var stalk_h: float = rng.randf_range(10.0, 16.0)
				var base_y: float = cy + half * 0.45
				var lean: float = rng.randf_range(-2.0, 2.0)
				draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox + lean, base_y - stalk_h), Color(0.22, 0.55, 0.14, 0.92), 2.0)
				# Seed head
				draw_circle(Vector2(cx + ox + lean, base_y - stalk_h), 3.0, Color(0.45, 0.24, 0.06, 0.92))
				draw_circle(Vector2(cx + ox + lean, base_y - stalk_h + 1.5), 1.5, Color(0.58, 0.32, 0.10, 0.70))
			# Water shimmer under the reeds
			draw_arc(Vector2(cx, cy + 4.0), half * 0.5, 0.0, PI, 10, Color(0.20, 0.55, 0.30, 0.35), 1.2)

		BiomeType.Value.TUNDRA:
			# Snow patches + ice crystal sparkles
			var count: int = rng.randi_range(4, 7)
			for _i: int in range(count):
				var patch_x: float = cx + rng.randf_range(-half * 0.68, half * 0.68)
				var patch_y: float = cy + rng.randf_range(-half * 0.68, half * 0.68)
				var patch_r: float = rng.randf_range(2.0, 4.0)
				draw_circle(Vector2(patch_x, patch_y), patch_r, Color(0.92, 0.96, 1.0, 0.80))
				# Glint
				draw_circle(Vector2(patch_x - patch_r * 0.35, patch_y - patch_r * 0.35), patch_r * 0.30, Color(1.0, 1.0, 1.0, 0.95))
			# Ice crystal lines (6-pointed)
			var crystal_x: float = cx + rng.randf_range(-half * 0.3, half * 0.3)
			var crystal_y: float = cy + rng.randf_range(-half * 0.3, half * 0.3)
			for arm_index: int in range(3):
				var angle: float = deg_to_rad(float(arm_index) * 60.0)
				var arm_len: float = rng.randf_range(4.5, 7.5)
				draw_line(Vector2(crystal_x - cos(angle) * arm_len, crystal_y - sin(angle) * arm_len), Vector2(crystal_x + cos(angle) * arm_len, crystal_y + sin(angle) * arm_len), Color(0.80, 0.92, 1.0, 0.75), 1.2)

		BiomeType.Value.MUDFLAT:
			# Mud puddles (ovals) + cracked earth marks
			var count: int = rng.randi_range(2, 4)
			for _i: int in range(count):
				var puddle_x: float = cx + rng.randf_range(-half * 0.55, half * 0.55)
				var puddle_y: float = cy + rng.randf_range(-half * 0.55, half * 0.55)
				var puddle_r: float = rng.randf_range(4.0, 7.0)
				draw_arc(Vector2(puddle_x, puddle_y), puddle_r, 0.0, TAU, 14, Color(0.22, 0.14, 0.05, 0.72), 2.5)
				draw_arc(Vector2(puddle_x, puddle_y), puddle_r * 0.5, 0.0, TAU, 8, Color(0.32, 0.20, 0.08, 0.50), 1.2)
			# Crack marks
			for _c: int in range(2):
				var lx: float = cx + rng.randf_range(-half * 0.4, half * 0.4)
				var ly: float = cy + rng.randf_range(-half * 0.4, half * 0.4)
				draw_line(Vector2(lx, ly), Vector2(lx + rng.randf_range(-7.0, 7.0), ly + rng.randf_range(-7.0, 7.0)), Color(0.18, 0.10, 0.03, 0.60), 1.0)

		BiomeType.Value.MOSSY_CRAG:
			# Flat rock shelf + moss patches
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - half * 0.60, cy + rng.randf_range(-1.5, 1.5)),
				Vector2(cx + half * 0.60, cy + rng.randf_range(-1.5, 1.5)),
				Vector2(cx + half * 0.50, cy + rng.randf_range(3.0, 6.0)),
				Vector2(cx - half * 0.50, cy + rng.randf_range(3.0, 6.0)),
			]), Color(0.36, 0.36, 0.28, 0.70))
			draw_line(Vector2(cx - half * 0.55, cy + rng.randf_range(-2.0, 2.0)), Vector2(cx + half * 0.55, cy + rng.randf_range(-2.0, 2.0)), Color(0.30, 0.30, 0.22, 0.80), 1.5)
			# Moss circles
			var count: int = rng.randi_range(3, 5)
			for _i: int in range(count):
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.60, half * 0.60), cy + rng.randf_range(-half * 0.55, half * 0.55)), rng.randf_range(2.5, 4.5), Color(0.18, 0.52, 0.16, 0.68))
				draw_circle(Vector2(cx + rng.randf_range(-half * 0.55, half * 0.55), cy + rng.randf_range(-half * 0.45, half * 0.45)), 1.2, Color(0.30, 0.68, 0.22, 0.55))

		BiomeType.Value.SAVANNAH:
			# Acacia silhouette (flat-top canopy) + dry grass blades
			var count: int = rng.randi_range(2, 4)
			for _i: int in range(count):
				var ox: float = rng.randf_range(-half * 0.60, half * 0.60)
				var base_y: float = cy + half * 0.40
				var trunk_h: float = rng.randf_range(9.0, 14.0)
				# Shadow
				draw_line(Vector2(cx + ox + 1.5, base_y + 1.5), Vector2(cx + ox + 2.0, base_y - trunk_h * 0.9), Color(0.30, 0.20, 0.03, 0.28), 1.5)
				# Trunk
				draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox, base_y - trunk_h), Color(0.52, 0.35, 0.10, 0.90), 2.0)
				# Flat acacia canopy (wide ellipse at the top)
				var canopy_w: float = rng.randf_range(7.5, 11.5)
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx + ox - canopy_w, base_y - trunk_h),
					Vector2(cx + ox + canopy_w, base_y - trunk_h),
					Vector2(cx + ox + canopy_w * 0.75, base_y - trunk_h + 4.5),
					Vector2(cx + ox - canopy_w * 0.75, base_y - trunk_h + 4.5),
				]), Color(0.52, 0.42, 0.10, 0.88))
				# Highlight on canopy
				draw_line(Vector2(cx + ox - canopy_w * 0.7, base_y - trunk_h), Vector2(cx + ox + canopy_w * 0.7, base_y - trunk_h), Color(0.75, 0.65, 0.22, 0.55), 1.5)
			# Dry grass blades
			for _g: int in range(rng.randi_range(3, 5)):
				var gx: float = cx + rng.randf_range(-half * 0.65, half * 0.65)
				var gy: float = cy + rng.randf_range(-half * 0.50, half * 0.50)
				draw_line(Vector2(gx, gy + 3.0), Vector2(gx + rng.randf_range(-3.5, 3.5), gy - rng.randf_range(5.0, 8.0)), Color(0.70, 0.60, 0.18, 0.75), 1.0)

		BiomeType.Value.CANYON:
			# Layered stratum lines + eroded wall blocks
			var layer_count: int = 4
			for row: int in range(layer_count):
				var y_off: float = -9.0 + row * 6.0
				var inset: float = float(row) * 1.5
				var layer_color: Color = Color(0.55 - row * 0.05, 0.22 - row * 0.03, 0.08 - row * 0.01, 0.80)
				draw_line(
					Vector2(cx - half * 0.72 + inset + rng.randf_range(0.0, 3.0), cy + y_off),
					Vector2(cx + half * 0.72 - inset - rng.randf_range(0.0, 3.0), cy + y_off),
					layer_color, 2.0
				)
				# Glint highlight
				draw_line(
					Vector2(cx - half * 0.60 + inset, cy + y_off - 1.0),
					Vector2(cx + half * 0.40 - inset, cy + y_off - 1.0),
					Color(0.75, 0.45, 0.22, 0.35), 1.0
				)
			# Eroded block on the wall
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + rng.randf_range(2.0, 6.0), cy - 4.0),
				Vector2(cx + rng.randf_range(7.0, 11.0), cy - 4.0),
				Vector2(cx + rng.randf_range(7.0, 10.0), cy + 3.0),
				Vector2(cx + rng.randf_range(2.0, 5.0), cy + 3.0),
			]), Color(0.62, 0.28, 0.12, 0.65))


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
		BiomeType.Value.STONE:  _draw_mountain_overlay(members)
		BiomeType.Value.RIVER:  _draw_river_overlay(members)
		BiomeType.Value.EMBER_FIELD: _draw_obsidian_expanse_overlay(members)
		BiomeType.Value.MEADOW: _draw_forest_overlay(members)
		BiomeType.Value.WETLANDS:  _draw_peat_bog_overlay(members)
		BiomeType.Value.FROSTLANDS: _draw_frostlands_overlay(members)
		BiomeType.Value.FOREST: _draw_forest_overlay(members)
		BiomeType.Value.WATER:  _draw_river_overlay(members)
		BiomeType.Value.EARTH:  _draw_barren_expanse_overlay(members)
		BiomeType.Value.SWAMP:  _draw_peat_bog_overlay(members)


## Dense forest: dark canopy tint + tall trees.
func _draw_forest_overlay(members: Array) -> void:
	var canopy_tint := Color(0.04, 0.26, 0.04, 0.38)
	var trunk_col   := Color(0.30, 0.18, 0.06, 0.95)
	var leaf_dark   := Color(0.06, 0.30, 0.07, 0.90)
	var leaf_mid    := Color(0.10, 0.40, 0.12, 0.88)
	var leaf_light  := Color(0.22, 0.58, 0.18, 0.72)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), canopy_tint)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xDEAD
		if rng.randf() >= 0.48:
			continue
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x + rng.randf_range(-4.0, 4.0)
		var cy: float = tc.y + rng.randf_range(-3.0, 3.0)
		var canopy_r: float = rng.randf_range(6.5, 10.0)
		# Shadow
		draw_circle(Vector2(cx + 2.5, cy + 3.0), canopy_r * 0.9, Color(0.0, 0.08, 0.0, 0.30))
		# Trunk
		draw_line(Vector2(cx, cy + canopy_r * 0.55), Vector2(cx, cy - rng.randf_range(16.0, 22.0) * 0.38), trunk_col, 3.0)
		# 3-lobe canopy with depth
		draw_circle(Vector2(cx, cy - canopy_r * 0.22), canopy_r, leaf_dark)
		draw_circle(Vector2(cx - canopy_r * 0.58, cy + canopy_r * 0.32), canopy_r * 0.74, leaf_dark)
		draw_circle(Vector2(cx + canopy_r * 0.58, cy + canopy_r * 0.32), canopy_r * 0.74, leaf_dark)
		# Mid-tone overlay
		draw_circle(Vector2(cx, cy - canopy_r * 0.28), canopy_r * 0.72, leaf_mid)
		draw_circle(Vector2(cx - canopy_r * 0.50, cy + canopy_r * 0.22), canopy_r * 0.55, leaf_mid)
		# Highlight
		draw_circle(Vector2(cx + canopy_r * 0.22, cy - canopy_r * 0.52), canopy_r * 0.30, leaf_light)


## River: flowing current lines and blue shimmer across the body.
func _draw_river_overlay(members: Array) -> void:
	var shimmer := Color(0.25, 0.65, 1.0, 0.28)
	var flow    := Color(0.55, 0.88, 1.0, 0.75)
	var deep    := Color(0.05, 0.28, 0.70, 0.20)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), deep)
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), shimmer)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xF10E0
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# 3 curved flow lines with varying alpha
		for w: int in range(3):
			var y_off: float = rng.randf_range(-8.0, 8.0)
			var pts := PackedVector2Array()
			for i: int in range(8):
				var tt: float = float(i) / 7.0
				pts.append(Vector2(cx - TILE_RADIUS * 0.88 + tt * TILE_RADIUS * 1.76, cy + y_off + sin(tt * PI * 2.5 + rng.randf_range(0.0, TAU)) * 3.5))
			var flow_alpha: float = 0.80 if w == 1 else 0.50
			draw_polyline(pts, Color(flow.r, flow.g, flow.b, flow_alpha), 1.5 if w == 1 else 1.0)
		# Sparkle dots
		for _s: int in range(rng.randi_range(2, 4)):
			var sx: float = cx + rng.randf_range(-TILE_RADIUS * 0.70, TILE_RADIUS * 0.70)
			var sy: float = cy + rng.randf_range(-TILE_RADIUS * 0.70, TILE_RADIUS * 0.70)
			draw_circle(Vector2(sx, sy), 1.5, Color(1.0, 1.0, 1.0, 0.85))


## Mountain peak: grey peaks with snow caps.
func _draw_mountain_overlay(members: Array) -> void:
	var snow_white := Color(0.94, 0.97, 1.0, 0.92)
	var peak_grey  := Color(0.50, 0.52, 0.58, 0.82)
	var shadow_col := Color(0.28, 0.30, 0.35, 0.50)
	var mid_grey   := Color(0.62, 0.64, 0.68, 0.70)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xBEEF
		if rng.randf() >= 0.60:
			continue
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x + rng.randf_range(-3.0, 3.0)
		var cy: float = tc.y + rng.randf_range(-2.0, 2.0)
		var peak_h: float = rng.randf_range(12.0, 18.0)
		var base_w: float = rng.randf_range(9.0, 14.0)
		# Shadow
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + 2.5, cy - peak_h + 3.0),
			Vector2(cx + base_w + 3.0, cy + peak_h * 0.38 + 2.0),
			Vector2(cx - base_w * 0.5 + 3.0, cy + peak_h * 0.38 + 2.0)
		]), shadow_col)
		# Main peak body
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - peak_h), Vector2(cx + base_w, cy + peak_h * 0.38), Vector2(cx - base_w, cy + peak_h * 0.38)]), peak_grey)
		# Mid face highlight (right side)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - peak_h),
			Vector2(cx + base_w, cy + peak_h * 0.38),
			Vector2(cx + base_w * 0.10, cy + peak_h * 0.38)
		]), mid_grey)
		# Snow cap (upper third)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - peak_h),
			Vector2(cx + base_w * 0.46, cy - peak_h * 0.34),
			Vector2(cx - base_w * 0.46, cy - peak_h * 0.34)
		]), snow_white)
		# Snow highlight line
		draw_line(Vector2(cx, cy - peak_h), Vector2(cx + base_w * 0.25, cy - peak_h * 0.55), Color(1.0, 1.0, 1.0, 0.60), 1.2)
		# Rocky crags on mid section
		for _c: int in range(2):
			var cax: float = cx + rng.randf_range(-base_w * 0.5, base_w * 0.5)
			var cay: float = cy + rng.randf_range(-peak_h * 0.1, peak_h * 0.30)
			draw_line(Vector2(cax, cay), Vector2(cax + rng.randf_range(-4.0, 4.0), cay - rng.randf_range(3.0, 7.0)), Color(0.35, 0.35, 0.40, 0.70), 1.0)


## Barren expanse: dry cracked earth — radiating fissure lines.
func _draw_barren_expanse_overlay(members: Array) -> void:
	var crack_col := Color(0.38, 0.20, 0.05, 0.72)
	var dust_col  := Color(0.80, 0.68, 0.40, 0.28)
	var bleach    := Color(0.92, 0.82, 0.58, 0.18)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), dust_col)
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), bleach)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xD8910
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		# Radiating cracks from a hub point
		var hx: float = cx + rng.randf_range(-5.0, 5.0)
		var hy: float = cy + rng.randf_range(-5.0, 5.0)
		var crack_count: int = rng.randi_range(4, 6)
		for _i: int in range(crack_count):
			var angle: float = rng.randf_range(0.0, TAU)
			var length: float = rng.randf_range(7.0, 14.0)
			var ex: float = hx + cos(angle) * length
			var ey: float = hy + sin(angle) * length
			draw_line(Vector2(hx, hy), Vector2(ex, ey), crack_col, 1.3)
			# Sub-crack branching
			if rng.randf() > 0.5:
				var branch_len: float = length * 0.45
				var branch_angle: float = angle + rng.randf_range(-0.6, 0.6)
				draw_line(Vector2(ex, ey), Vector2(ex + cos(branch_angle) * branch_len, ey + sin(branch_angle) * branch_len), Color(crack_col.r, crack_col.g, crack_col.b, 0.45), 0.8)
		# Sun-bleached pebble
		draw_circle(Vector2(hx, hy), rng.randf_range(1.5, 3.0), Color(0.78, 0.65, 0.38, 0.65))


## Peat bog: murky tint + dense tall reeds with seed heads.
func _draw_peat_bog_overlay(members: Array) -> void:
	var murk := Color(0.08, 0.18, 0.06, 0.42)
	var stem := Color(0.18, 0.45, 0.11, 0.94)
	var head := Color(0.38, 0.20, 0.05, 0.96)
	var mist := Color(0.35, 0.52, 0.28, 0.15)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), murk)
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), mist)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xB0650
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		var count: int = rng.randi_range(5, 8)
		for _i: int in range(count):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.72, TILE_RADIUS * 0.72)
			var h: float  = rng.randf_range(13.0, 22.0)
			var lean: float = rng.randf_range(-1.5, 1.5)
			var base_y: float = cy + TILE_RADIUS * 0.52
			# Shadow stem
			draw_line(Vector2(cx + ox + 1.5, base_y + 1.5), Vector2(cx + ox + lean + 2.0, base_y - h + 1.5), Color(0.05, 0.12, 0.02, 0.30), 1.5)
			# Stem
			draw_line(Vector2(cx + ox, base_y), Vector2(cx + ox + lean, base_y - h), stem, 2.0)
			# Bulrush seed head
			draw_circle(Vector2(cx + ox + lean, base_y - h + 3.5), 3.2, head)
			draw_circle(Vector2(cx + ox + lean, base_y - h + 1.0), 1.8, Color(head.r * 1.15, head.g * 1.1, head.b * 1.0, 0.75))


## Frostlands: pale snow haze with crystalline streaks and sparkle points.
func _draw_frostlands_overlay(members: Array) -> void:
	var frost_haze := Color(0.82, 0.93, 1.0, 0.28)
	var ice_line := Color(0.86, 0.96, 1.0, 0.78)
	var sparkle := Color(1.0, 1.0, 1.0, 0.85)
	for m: Variant in members:
		draw_colored_polygon(_hex_polygon(_HexUtils.axial_to_pixel(m as Vector2i, TILE_RADIUS), TILE_RADIUS), frost_haze)
	var rng := RandomNumberGenerator.new()
	for m: Variant in members:
		var coord: Vector2i = m as Vector2i
		rng.seed = hash(coord) ^ 0xF2057
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		for _i: int in range(3):
			var angle: float = rng.randf_range(0.0, TAU)
			var arm: float = rng.randf_range(5.0, 9.0)
			draw_line(
				Vector2(cx - cos(angle) * arm, cy - sin(angle) * arm),
				Vector2(cx + cos(angle) * arm, cy + sin(angle) * arm),
				ice_line,
				1.2
			)
		var spark_count: int = rng.randi_range(2, 4)
		for _s: int in range(spark_count):
			draw_circle(
				Vector2(cx + rng.randf_range(-TILE_RADIUS * 0.55, TILE_RADIUS * 0.55), cy + rng.randf_range(-TILE_RADIUS * 0.55, TILE_RADIUS * 0.55)),
				rng.randf_range(0.8, 1.6),
				sparkle
			)


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
		# --- Tier 2 Structural Landmarks ---
		"disc_origin_shrine":      _draw_origin_shrine_overlay(coords)
		"disc_bridge_of_sighs":    _draw_bridge_of_sighs_overlay(coords)
		"disc_lotus_pagoda":       _draw_lotus_pagoda_overlay(coords)
		"disc_monks_rest":         _draw_monks_rest_overlay(coords)
		"disc_star_gazing_deck":   _draw_star_gazing_deck_overlay(coords)
		"disc_sun_dial":           _draw_sun_dial_overlay(coords)
		"disc_whale_bone_arch":    _draw_whale_bone_arch_overlay(coords)
		"disc_echoing_cavern":     _draw_echoing_cavern_overlay(coords)
		"disc_bamboo_chime":       _draw_bamboo_chime_overlay(coords)
		"disc_floating_pavilion":  _draw_floating_pavilion_overlay(coords)


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
# Background — stars, floating mist, animated void
# ---------------------------------------------------------------------------

## Pre-compute all star and mist wisp data once in _ready().
## Each star: [norm_x, norm_y, px_size, phase, speed, hue_tint]
## Each wisp: [nx, ny, w_frac, h_frac, alpha_base, pulse_spd, drift_spd, phase, amp_x, amp_y]
func _init_background_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _STAR_SEED

	_bg_stars.clear()
	for _i: int in range(_STAR_COUNT):
		_bg_stars.append([
			rng.randf(),                     # norm_x  [0, 1] screen fraction
			rng.randf(),                     # norm_y  [0, 1] screen fraction
			rng.randf_range(0.7, 2.2),       # pixel size
			rng.randf() * TAU,               # twinkle phase
			rng.randf_range(0.4, 2.5),       # twinkle speed
			rng.randf_range(-1.0, 1.0),      # hue tint  (−1 warm, +1 cool-blue)
		])

	_bg_mists.clear()
	var mrng := RandomNumberGenerator.new()
	mrng.seed = _MIST_SEED

	# 6 ambient wisps scattered randomly across the screen
	for _i: int in range(6):
		_bg_mists.append([
			mrng.randf_range(-0.05, 1.05),   # nx
			mrng.randf_range(-0.05, 1.05),   # ny
			mrng.randf_range(0.20, 0.50),    # width fraction of screen
			mrng.randf_range(0.12, 0.28),    # height fraction of screen
			mrng.randf_range(0.025, 0.060),  # alpha_base
			mrng.randf_range(0.12, 0.30),    # pulse speed
			mrng.randf_range(0.025, 0.070),  # drift speed
			mrng.randf() * TAU,              # phase offset
			mrng.randf_range(0.025, 0.075),  # drift amplitude X (fraction of screen width)
			mrng.randf_range(0.010, 0.040),  # drift amplitude Y (fraction of screen height)
		])

	# 4 edge-biased wisps (one per screen edge) — slightly larger and denser
	var edge_anchors: Array = [
		[0.08, 0.50],  # left
		[0.92, 0.50],  # right
		[0.50, 0.07],  # top
		[0.50, 0.93],  # bottom
	]
	for ea: Array in edge_anchors:
		_bg_mists.append([
			float(ea[0]) + mrng.randf_range(-0.08, 0.08),
			float(ea[1]) + mrng.randf_range(-0.08, 0.08),
			mrng.randf_range(0.30, 0.60),    # wider
			mrng.randf_range(0.18, 0.38),
			mrng.randf_range(0.030, 0.080),  # slightly more visible
			mrng.randf_range(0.08, 0.22),
			mrng.randf_range(0.010, 0.040),  # slower drift
			mrng.randf() * TAU,
			mrng.randf_range(0.010, 0.040),
			mrng.randf_range(0.005, 0.020),
		])


## Return the world-space Rect2 currently visible on screen, derived from the
## active Camera2D position and zoom.  Falls back to a viewport-centred rect
## when no camera is found.
func _get_world_screen_rect() -> Rect2:
	var vp_size: Vector2 = get_viewport_rect().size
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return Rect2(Vector2(-vp_size.x * 0.5, -vp_size.y * 0.5), vp_size)
	var center: Vector2 = cam.get_screen_center_position()
	var half: Vector2 = vp_size / (cam.zoom * 2.0)
	return Rect2(center - half, half * 2.0)


## Draw the animated background: dark cosmic void, drifting mist wisps, and
## twinkling stars.  All coordinates are in world space based on the visible
## screen rect so the elements remain screen-relative during camera panning.
func _draw_background() -> void:
	var sr: Rect2 = _get_world_screen_rect()
	var sw: float = sr.size.x
	var sh: float = sr.size.y
	var sx: float = sr.position.x
	var sy: float = sr.position.y

	# --- Void base (padded so no gap appears when camera pans) ---
	var pad: float = 60.0
	draw_rect(Rect2(Vector2(sx - pad, sy - pad), Vector2(sw + pad * 2.0, sh + pad * 2.0)),
		Color(0.04, 0.03, 0.07))

	# --- Floating mist wisps (drawn before stars so they appear behind) ---
	for wisp: Array in _bg_mists:
		var drift_t: float = _anim_time * float(wisp[6]) + float(wisp[7])
		var offset_x: float = sin(drift_t) * float(wisp[8]) * sw
		var offset_y: float = cos(drift_t * 0.72 + 1.4) * float(wisp[9]) * sh
		var wx: float = sx + float(wisp[0]) * sw + offset_x
		var wy: float = sy + float(wisp[1]) * sh + offset_y
		var wisp_w: float = float(wisp[2]) * sw
		var wisp_h: float = float(wisp[3]) * sh
		var alpha: float = float(wisp[4]) * (0.58 + 0.42 * sin(_anim_time * float(wisp[5]) + float(wisp[7])))
		# Approximate ellipse with a 16-gon polygon
		var pts := PackedVector2Array()
		pts.resize(16)
		for j: int in range(16):
			var ang: float = TAU * float(j) / 16.0
			pts[j] = Vector2(wx + cos(ang) * wisp_w * 0.5, wy + sin(ang) * wisp_h * 0.5)
		draw_colored_polygon(pts, Color(0.48, 0.58, 0.82, alpha))

	# --- Twinkling stars ---
	for star: Array in _bg_stars:
		var world_x: float = sx + float(star[0]) * sw
		var world_y: float = sy + float(star[1]) * sh
		var px_size: float = float(star[2])
		var phase: float = float(star[3])
		var spd: float = float(star[4])
		var hue: float = float(star[5])

		var twinkle: float = 0.45 + 0.55 * sin(_anim_time * spd + phase)
		var alpha: float = maxf(0.0, twinkle * (0.40 + 0.50 * (px_size - 0.7) / 1.5))

		# Warm tint: hue > 0 → slightly warm yellow, hue < 0 → cool blue-white
		var star_r: float = clampf(0.88 - hue * 0.07, 0.0, 1.0)
		var star_g: float = clampf(0.93 - hue * 0.03, 0.0, 1.0)
		var star_b: float = 1.0
		draw_circle(Vector2(world_x, world_y), px_size, Color(star_r, star_g, star_b, alpha))

		# Cross-hair glint for large bright stars
		if px_size > 1.5 and twinkle > 0.75:
			var gl: float = px_size * 3.2 * twinkle
			var gc: Color = Color(star_r, star_g, star_b, alpha * 0.42)
			draw_line(Vector2(world_x - gl, world_y), Vector2(world_x + gl, world_y), gc, 0.7)
			draw_line(Vector2(world_x, world_y - gl), Vector2(world_x, world_y + gl), gc, 0.7)

	# --- Subtle earthen grain (world-space, seeded, capped) ---
	var rng := RandomNumberGenerator.new()
	rng.seed = _GRAIN_SEED
	var grain_count: int = mini(int(sw * sh * 0.0013), 240)
	for _i: int in range(grain_count):
		var gx: float = sx + rng.randf() * sw
		var gy: float = sy + rng.randf() * sh
		var gr: float = rng.randf_range(0.5, 1.8)
		var bright: float = rng.randf_range(0.08, 0.16)
		draw_circle(Vector2(gx, gy), gr, Color(bright * 0.88, bright * 0.62, bright * 0.28, 0.48))


## Draw an animated screen-edge mist vignette.
## Uses per-vertex alpha on draw_polygon() to create smooth gradient bands.
## Also places animated wisp puffs near each corner.
func _draw_edge_mist() -> void:
	var sr: Rect2 = _get_world_screen_rect()
	var sw: float = sr.size.x
	var sh: float = sr.size.y
	var sx: float = sr.position.x
	var sy: float = sr.position.y

	var fade_x: float = sw * 0.18
	var fade_y: float = sh * 0.18

	# Breathing animation: alpha gently pulses ±8 %
	var pulse: float = 0.40 + 0.08 * sin(_anim_time * 0.28)
	var mc_r: float = 0.08
	var mc_g: float = 0.10
	var mc_b: float = 0.22

	var edge_col: Color = Color(mc_r, mc_g, mc_b, pulse)
	var clear_col: Color = Color(mc_r, mc_g, mc_b, 0.0)

	# Left edge
	draw_polygon(PackedVector2Array([
		Vector2(sx, sy),
		Vector2(sx + fade_x, sy),
		Vector2(sx + fade_x, sy + sh),
		Vector2(sx, sy + sh),
	]), PackedColorArray([edge_col, clear_col, clear_col, edge_col]))

	# Right edge
	draw_polygon(PackedVector2Array([
		Vector2(sx + sw, sy),
		Vector2(sx + sw - fade_x, sy),
		Vector2(sx + sw - fade_x, sy + sh),
		Vector2(sx + sw, sy + sh),
	]), PackedColorArray([edge_col, clear_col, clear_col, edge_col]))

	# Top edge
	draw_polygon(PackedVector2Array([
		Vector2(sx, sy),
		Vector2(sx + sw, sy),
		Vector2(sx + sw, sy + fade_y),
		Vector2(sx, sy + fade_y),
	]), PackedColorArray([edge_col, edge_col, clear_col, clear_col]))

	# Bottom edge
	draw_polygon(PackedVector2Array([
		Vector2(sx, sy + sh),
		Vector2(sx + sw, sy + sh),
		Vector2(sx + sw, sy + sh - fade_y),
		Vector2(sx, sy + sh - fade_y),
	]), PackedColorArray([edge_col, edge_col, clear_col, clear_col]))

	# --- Animated wisps drifting in from the screen edges ---
	# 6 wisps evenly distributed around the perimeter, drifting inward slowly
	for wi: int in range(6):
		var wp: float = float(wi) * TAU / 6.0
		var wisp_alpha: float = 0.055 + 0.025 * sin(_anim_time * 0.18 + wp)
		var drift_x: float = sin(_anim_time * 0.10 + wp * 1.3) * sw * 0.025
		var drift_y: float = cos(_anim_time * 0.08 + wp * 0.9) * sh * 0.020

		var wx: float = sx
		var wy: float = sy
		var ww: float = sw * 0.30
		var wh: float = sh * 0.30
		# Cycle: 0,3 → left/right; 1,4 → top/bottom; 2,5 → corner puffs
		match wi % 3:
			0:
				wx = sx + sw * (0.02 if wi < 3 else 0.98) + drift_x
				wy = sy + sh * (0.35 + float(wi / 3) * 0.30) + drift_y
				ww = sw * 0.30
				wh = sh * 0.40
			1:
				wx = sx + sw * (0.35 + float(wi / 3) * 0.30) + drift_x
				wy = sy + sh * (0.03 if wi < 3 else 0.97) + drift_y
				ww = sw * 0.40
				wh = sh * 0.28
			_:
				wx = sx + sw * (0.10 if wi < 3 else 0.90) + drift_x
				wy = sy + sh * (0.10 if wi < 3 else 0.90) + drift_y
				ww = sw * 0.25
				wh = sh * 0.22

		var w_pts := PackedVector2Array()
		w_pts.resize(14)
		for j: int in range(14):
			var ang: float = TAU * float(j) / 14.0
			w_pts[j] = Vector2(wx + cos(ang) * ww * 0.5, wy + sin(ang) * wh * 0.5)
		draw_colored_polygon(w_pts, Color(0.42, 0.52, 0.78, wisp_alpha))


# ---------------------------------------------------------------------------
# Tier 2 Landmark overlays
# ---------------------------------------------------------------------------

## Origin Shrine: golden sacred cross at the world origin + blue halo on Water arms.
func _draw_origin_shrine_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var gold := Color(1.0, 0.85, 0.20, 0.95)
	var halo := Color(0.45, 0.80, 1.0, 0.55)
	for coord: Vector2i in coords:
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS * 0.55), halo)
	# Bright gold cross arms radiating from (0,0)
	var origin: Vector2 = _HexUtils.axial_to_pixel(Vector2i.ZERO, TILE_RADIUS)
	var arm: float = TILE_RADIUS * 0.85
	var thick: float = 4.0
	draw_line(origin + Vector2(-arm, 0), origin + Vector2(arm, 0), gold, thick)
	draw_line(origin + Vector2(0, -arm), origin + Vector2(0, arm), gold, thick)
	draw_circle(origin, 5.5, gold)


## Bridge of Sighs: stone arch arc over the Water tile.
func _draw_bridge_of_sighs_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var arch_col := Color(0.70, 0.68, 0.62, 0.90)
	var water_shimmer := Color(0.40, 0.75, 1.0, 0.45)
	for coord: Vector2i in coords:
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS * 0.5), water_shimmer)
		# Single arc above each tile
		draw_arc(tc, TILE_RADIUS * 0.65, deg_to_rad(200.0), deg_to_rad(340.0), 14, arch_col, 3.0)


## Lotus Pagoda: a stylised tiered pagoda silhouette on each Swamp tile.
func _draw_lotus_pagoda_overlay(coords: Array[Vector2i]) -> void:
	var pagoda_col := Color(0.80, 0.55, 0.20, 0.88)
	var roof_col   := Color(0.60, 0.18, 0.18, 0.90)
	for coord: Vector2i in coords:
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y - TILE_RADIUS * 0.3
		# Three stacked trapezoidal tiers
		for tier: int in range(3):
			var tw: float = 7.0 - float(tier) * 2.0
			var th: float = 4.0
			var ty: float = cy + float(tier) * (th + 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(cx - tw, ty + th), Vector2(cx + tw, ty + th), Vector2(cx + tw - 1.5, ty), Vector2(cx - tw + 1.5, ty)]), pagoda_col)
			draw_line(Vector2(cx - tw - 2.0, ty + th * 0.5), Vector2(cx + tw + 2.0, ty + th * 0.5), roof_col, 1.5)
		# Spire
		draw_line(Vector2(cx, cy - 2.0), Vector2(cx, cy - 10.0), pagoda_col, 2.0)
		draw_circle(Vector2(cx, cy - 10.0), 2.0, roof_col)


## Monk's Rest: concentric meditation rings on the enclosed Earth tile.
func _draw_monks_rest_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	# Centre tile is coords[0] (Earth)
	var center_tc: Vector2 = _HexUtils.axial_to_pixel(coords[0], TILE_RADIUS)
	var ring_col := Color(0.90, 0.80, 0.55, 0.70)
	for r: int in range(2, 6):
		draw_arc(center_tc, float(r) * 3.0, 0.0, TAU, 20, Color(ring_col.r, ring_col.g, ring_col.b, ring_col.a / float(r)), 1.5)
	draw_circle(center_tc, 3.0, Color(0.95, 0.88, 0.45, 0.95))
	# Forest ring: small leaf dot on each surrounding tile
	var leaf_col := Color(0.15, 0.50, 0.15, 0.80)
	var rng := RandomNumberGenerator.new()
	for i: int in range(1, coords.size()):
		var tc: Vector2 = _HexUtils.axial_to_pixel(coords[i], TILE_RADIUS)
		rng.seed = hash(coords[i]) ^ 0xF01E5
		draw_circle(tc + Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0)), 4.5, leaf_col)


## Star-Gazing Deck: twinkling star cluster above the tile.
func _draw_star_gazing_deck_overlay(coords: Array[Vector2i]) -> void:
	var star_col  := Color(1.0, 0.98, 0.85, 0.92)
	var glow_col  := Color(0.60, 0.75, 1.0, 0.35)
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0x57A4
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS * 0.55), glow_col)
		var star_count: int = rng.randi_range(3, 6)
		for _i: int in range(star_count):
			var sx: float = tc.x + rng.randf_range(-TILE_RADIUS * 0.7, TILE_RADIUS * 0.7)
			var sy: float = tc.y + rng.randf_range(-TILE_RADIUS * 0.7, TILE_RADIUS * 0.7)
			var sr: float = rng.randf_range(1.0, 2.5)
			draw_circle(Vector2(sx, sy), sr, star_col)
			# 4-point star cross
			draw_line(Vector2(sx - sr * 2.0, sy), Vector2(sx + sr * 2.0, sy), star_col, 0.8)
			draw_line(Vector2(sx, sy - sr * 2.0), Vector2(sx, sy + sr * 2.0), star_col, 0.8)


## Sun-Dial: golden radiating rays from the Stone centre tile.
func _draw_sun_dial_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var center_tc: Vector2 = _HexUtils.axial_to_pixel(coords[0], TILE_RADIUS)
	var ray_col := Color(1.0, 0.88, 0.20, 0.85)
	var core_col := Color(1.0, 0.70, 0.10, 0.95)
	for i: int in range(12):
		var angle: float = deg_to_rad(float(i) * 30.0)
		var inner: float = TILE_RADIUS * 0.22
		var outer: float = TILE_RADIUS * (0.80 if i % 2 == 0 else 0.50)
		draw_line(center_tc + Vector2(cos(angle), sin(angle)) * inner, center_tc + Vector2(cos(angle), sin(angle)) * outer, ray_col, 1.5)
	draw_circle(center_tc, 5.0, core_col)
	# Earth neighbour tiles: subtle dust ring
	var dust := Color(0.80, 0.65, 0.30, 0.30)
	for i: int in range(1, coords.size()):
		var tc: Vector2 = _HexUtils.axial_to_pixel(coords[i], TILE_RADIUS)
		draw_arc(tc, TILE_RADIUS * 0.45, 0.0, TAU, 16, dust, 2.5)


## Whale-Bone Arch: bleached bone-arch curves over each Canyon tile.
func _draw_whale_bone_arch_overlay(coords: Array[Vector2i]) -> void:
	var bone_col := Color(0.92, 0.88, 0.80, 0.88)
	var shadow   := Color(0.40, 0.30, 0.20, 0.35)
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0xB04E
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS), shadow)
		# Curved bone arc
		var arc_r: float = rng.randf_range(7.0, 11.0)
		var arc_cx: float = tc.x + rng.randf_range(-3.0, 3.0)
		var arc_cy: float = tc.y + arc_r * 0.3
		draw_arc(Vector2(arc_cx, arc_cy), arc_r, deg_to_rad(195.0), deg_to_rad(345.0), 14, bone_col, 3.0)
		# Two end knobs
		draw_circle(Vector2(arc_cx - arc_r * 0.85, arc_cy + arc_r * 0.25), 2.5, bone_col)
		draw_circle(Vector2(arc_cx + arc_r * 0.85, arc_cy + arc_r * 0.25), 2.5, bone_col)


## Echoing Cavern: dark cave-mouth glow on the ring tiles; void shimmer on centre.
func _draw_echoing_cavern_overlay(coords: Array[Vector2i]) -> void:
	var cave_tint := Color(0.08, 0.06, 0.10, 0.55)
	var glow_col  := Color(0.55, 0.35, 0.80, 0.70)
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		draw_colored_polygon(_hex_polygon(tc, TILE_RADIUS), cave_tint)
		rng.seed = hash(coord) ^ 0xCA5E
		# Concentric glow rings
		for r: int in range(1, 4):
			draw_arc(tc, float(r) * 4.5, 0.0, TAU, 18, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a / float(r + 1)), 1.5)
		# Stalactite nubs
		var nubs: int = rng.randi_range(2, 4)
		for _i: int in range(nubs):
			var nx: float = tc.x + rng.randf_range(-TILE_RADIUS * 0.55, TILE_RADIUS * 0.55)
			var ny: float = tc.y - TILE_RADIUS * 0.60
			draw_colored_polygon(PackedVector2Array([Vector2(nx, ny), Vector2(nx + 2.0, ny + 5.0), Vector2(nx - 2.0, ny + 5.0)]), Color(0.30, 0.25, 0.35, 0.80))


## Bamboo Chime discovery marker: frosty wind-chime rods and ice pendants.
func _draw_bamboo_chime_overlay(coords: Array[Vector2i]) -> void:
	var rod_col := Color(0.82, 0.92, 1.0, 0.92)
	var thread_col  := Color(0.66, 0.80, 0.92, 0.90)
	var pendant_col := Color(0.92, 0.98, 1.0, 0.82)
	var rng := RandomNumberGenerator.new()
	for coord: Vector2i in coords:
		rng.seed = hash(coord) ^ 0xBAB0
		var tc: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		var cx: float = tc.x
		var cy: float = tc.y
		var count: int = rng.randi_range(2, 4)
		for _i: int in range(count):
			var ox: float = rng.randf_range(-TILE_RADIUS * 0.5, TILE_RADIUS * 0.5)
			var rod_top_y: float = cy - rng.randf_range(14.0, 20.0)
			var rod_bottom_y: float = rod_top_y + rng.randf_range(6.0, 10.0)
			draw_line(Vector2(cx + ox, rod_top_y), Vector2(cx + ox, rod_bottom_y), rod_col, 2.2)
			var thread_len: float = rng.randf_range(4.0, 7.0)
			draw_line(Vector2(cx + ox, rod_bottom_y), Vector2(cx + ox, rod_bottom_y + thread_len), thread_col, 1.2)
			var pendant_center: Vector2 = Vector2(cx + ox, rod_bottom_y + thread_len + 2.0)
			draw_colored_polygon(PackedVector2Array([
				pendant_center + Vector2(0.0, -2.2),
				pendant_center + Vector2(2.2, 1.8),
				pendant_center + Vector2(-2.2, 1.8),
			]), pendant_col)
			draw_circle(pendant_center + Vector2(0.0, -0.8), 0.9, Color(1.0, 1.0, 1.0, 0.75))


## Floating Pavilion: a small floating pavilion structure on the Swamp tile.
func _draw_floating_pavilion_overlay(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var tc: Vector2 = _HexUtils.axial_to_pixel(coords[0], TILE_RADIUS)
	var cx: float = tc.x
	var cy: float = tc.y
	var water_ring := Color(0.40, 0.75, 1.0, 0.45)
	var floor_col  := Color(0.75, 0.60, 0.35, 0.90)
	var roof_col   := Color(0.60, 0.20, 0.12, 0.88)
	var pillar_col := Color(0.82, 0.68, 0.40, 0.92)
	# Ripple rings showing it floats
	for r: int in range(2, 5):
		draw_arc(tc, float(r) * 4.5, 0.0, TAU, 20, Color(water_ring.r, water_ring.g, water_ring.b, water_ring.a / float(r)), 1.2)
	# Platform floor
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 9.0, cy + 2.0), Vector2(cx + 9.0, cy + 2.0), Vector2(cx + 7.0, cy - 1.0), Vector2(cx - 7.0, cy - 1.0)]), floor_col)
	# Four corner pillars
	for px: float in [-6.0, 6.0]:
		draw_line(Vector2(cx + px, cy - 1.0), Vector2(cx + px, cy - 10.0), pillar_col, 2.0)
	# Curved roof
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 10.0, cy - 9.0), Vector2(cx + 10.0, cy - 9.0), Vector2(cx + 5.0, cy - 16.0), Vector2(cx - 5.0, cy - 16.0)]), roof_col)
	draw_line(Vector2(cx, cy - 16.0), Vector2(cx, cy - 20.0), pillar_col, 1.5)
	draw_circle(Vector2(cx, cy - 20.0), 2.5, roof_col)


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
		BiomeType.Value.STONE:      return Color(0.620, 0.620, 0.620)
		BiomeType.Value.RIVER:      return Color(0.129, 0.588, 0.953)
		BiomeType.Value.EMBER_FIELD:return Color(0.922, 0.42, 0.18)
		BiomeType.Value.MEADOW:     return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WETLANDS:   return Color(0.42, 0.56, 0.48)
		BiomeType.Value.BADLANDS:   return Color(0.78, 0.65, 0.25)
		BiomeType.Value.WHISTLING_CANYONS: return Color(0.84, 0.76, 0.50)
		BiomeType.Value.PRISMATIC_TERRACES: return Color(0.75, 0.88, 0.95)
		BiomeType.Value.FROSTLANDS: return Color(0.83, 0.94, 1.0)
		BiomeType.Value.THE_ASHFALL: return Color(0.42, 0.28, 0.15)
		BiomeType.Value.SACRED_STONE: return Color(0.72, 0.72, 0.62)
		BiomeType.Value.MOONLIT_POOL: return Color(0.45, 0.52, 0.35)
		BiomeType.Value.EMBER_SHRINE:return Color(0.72, 0.35, 0.18)
		BiomeType.Value.CLOUD_RIDGE:return Color(0.72, 0.80, 0.88)
		BiomeType.Value.KU:         return Color(0.05, 0.02, 0.10)
		BiomeType.Value.FOREST:     return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WATER:      return Color(0.129, 0.588, 0.953)
		BiomeType.Value.EARTH:      return Color(0.757, 0.580, 0.376)
		BiomeType.Value.SWAMP:      return Color(0.25, 0.40, 0.20)
		BiomeType.Value.TUNDRA:     return Color(0.75, 0.88, 0.95)
		BiomeType.Value.MUDFLAT:    return Color(0.42, 0.28, 0.15)
		BiomeType.Value.MOSSY_CRAG: return Color(0.45, 0.52, 0.35)
		BiomeType.Value.SAVANNAH:   return Color(0.78, 0.65, 0.25)
		BiomeType.Value.CANYON:     return Color(0.72, 0.35, 0.18)
	return Color(0.502, 0.502, 0.502)

func _draw_building_placement_preview() -> void:
	var placement_ctrl: Node = get_node_or_null("../PlacementController")
	if placement_ctrl == null or not placement_ctrl.has_method("get_active_building_session"):
		return
	var session_variant: Variant = placement_ctrl.get_active_building_session()
	if not (session_variant is BuildingPlacementSession):
		return
	var session: BuildingPlacementSession = session_variant as BuildingPlacementSession
	if not session.active:
		return
	var overlay_color: Color = Color(0.2, 0.9, 0.2, 0.35) if session.is_valid else Color(0.9, 0.2, 0.2, 0.35)
	var border_color: Color = Color(0.3, 1.0, 0.3, 0.85) if session.is_valid else Color(1.0, 0.3, 0.3, 0.85)
	for tile_coord: Vector2i in session.footprint_tiles:
		var center: Vector2 = _HexUtils.axial_to_pixel(tile_coord, TILE_RADIUS)
		var pts: PackedVector2Array = _hex_polygon(center, TILE_RADIUS)
		draw_colored_polygon(pts, overlay_color)
		var border: PackedVector2Array = PackedVector2Array(pts)
		border.append(pts[0])
		draw_polyline(border, border_color, 2.5)
