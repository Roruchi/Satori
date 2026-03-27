## TileSelectorHex — draws the four base-biome selector buttons as miniature
## hex tiles, matching the GardenView 2.5D visual language.
## Designed to live inside a CanvasLayer so all coordinates are screen pixels.
extends Node2D

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")

## Emitted when the player clicks a biome hex.
signal biome_selected(biome: int)

## Hex circumradius in screen pixels.
const _RADIUS: float = 30.0
## Voxel side-face depth in screen pixels.
const _DEPTH: float = 5.0
## Gap between adjacent hex centres.
const _GAP: float = 16.0
## Backdrop padding values used both for drawing and layout.
const _BACKDROP_PAD_TOP: float = 14.0
const _BACKDROP_PAD_BOTTOM: float = 28.0
## Extra space between selector backdrop and bottom HUD bar.
const _BOTTOM_SAFE_GAP: float = 10.0
## Font size for biome labels.
const _LABEL_SIZE: int = 11

var _selected: int = BiomeType.Value.STONE
var _hover_idx: int = -1
var _centers: Array[Vector2] = []
var _seed_biomes: Array[int] = []
var _seed_labels: Array[String] = []
var _seed_colors: Array[Color] = []
var _bottom_bar: Control = null


func _ready() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root != null:
		_bottom_bar = scene_root.get_node_or_null("HUD/Root/BottomBar") as Control
	_rebuild_centers()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_refresh_from_pouch(false)
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_signal("seed_added_to_pouch"):
		alchemy.seed_added_to_pouch.connect(func(_recipe: SeedRecipe) -> void: _refresh_from_pouch(true))
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_signal("pouch_updated"):
		growth.pouch_updated.connect(func() -> void: _refresh_from_pouch(true))
	set_process_input(true)


func _on_viewport_resized() -> void:
	_rebuild_centers()
	queue_redraw()


func _rebuild_centers() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var spacing: float = _RADIUS * 2.0 + _GAP
	var item_count: int = maxi(1, _seed_biomes.size())
	var total_w: float = spacing * float(maxi(0, item_count - 1))
	var sx: float = vp.x * 0.5 - total_w * 0.5
	var cy: float = vp.y - _RADIUS - _DEPTH - _BACKDROP_PAD_BOTTOM
	if _bottom_bar != null:
		var safe_bottom: float = _bottom_bar.position.y - _BOTTOM_SAFE_GAP
		cy = safe_bottom - (_RADIUS + _DEPTH + _BACKDROP_PAD_BOTTOM)
	_centers.clear()
	for i: int in range(item_count):
		_centers.append(Vector2(sx + float(i) * spacing, cy))


func _refresh_from_pouch(emit_selection: bool) -> void:
	_seed_biomes.clear()
	_seed_labels.clear()
	_seed_colors.clear()
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_method("get_pouch"):
		var pouch: SeedPouch = growth.get_pouch()
		if pouch != null:
			for i: int in range(pouch.size()):
				var recipe: SeedRecipe = pouch.get_at(i)
				if recipe == null:
					continue
				var uses: int = pouch.get_uses_at(i)
				_seed_biomes.append(recipe.produces_biome)
				_seed_labels.append("%s x%d" % [_label_for_biome(recipe.produces_biome), uses])
				_seed_colors.append(_color_for_biome(recipe.produces_biome))
	if _seed_biomes.is_empty():
		_selected = BiomeType.Value.NONE
	else:
		if not _seed_biomes.has(_selected):
			_selected = _seed_biomes[0]
			if emit_selection:
				biome_selected.emit(_selected)
	_rebuild_centers()
	queue_redraw()


## Programmatically select a biome without emitting biome_selected.
func select(biome: int) -> void:
	_selected = biome
	queue_redraw()


func get_selected_biome() -> int:
	if _selected != BiomeType.Value.NONE:
		return _selected
	if not _seed_biomes.is_empty():
		return _seed_biomes[0]
	return BiomeType.Value.STONE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var old: int = _hover_idx
		_hover_idx = _hit_test((event as InputEventMouseMotion).position)
		if _hover_idx != old:
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var idx: int = _hit_test(mb.position)
			if idx >= 0 and idx < _seed_biomes.size():
				_selected = _seed_biomes[idx]
				biome_selected.emit(_selected)
				queue_redraw()
				get_viewport().set_input_as_handled()


func _hit_test(screen_pos: Vector2) -> int:
	for i: int in range(_centers.size()):
		if _centers[i].distance_to(screen_pos) <= _RADIUS:
			return i
	return -1


func _draw() -> void:
	if _centers.is_empty():
		_rebuild_centers()
		if _centers.is_empty():
			return

	# --- Dark backdrop panel ---
	var spacing: float = _RADIUS * 2.0 + _GAP
	var pad_x: float = 18.0
	var pad_top: float = _BACKDROP_PAD_TOP
	var pad_bot: float = _BACKDROP_PAD_BOTTOM   # room for labels
	var item_count: int = maxi(1, _seed_biomes.size())
	var bw: float = spacing * float(maxi(0, item_count - 1)) + _RADIUS * 2.0 + pad_x * 2.0
	var bh: float = _RADIUS * 2.0 + _DEPTH + pad_top + pad_bot
	var bx: float = _centers[0].x - _RADIUS - pad_x
	var by: float = _centers[0].y - _RADIUS - pad_top
	draw_rect(
		Rect2(Vector2(bx, by), Vector2(bw, bh)),
		Color(0.05, 0.04, 0.11, 0.84)
	)
	# Subtle border matching the edge-mist purple
	draw_rect(
		Rect2(Vector2(bx, by), Vector2(bw, bh)),
		Color(0.28, 0.24, 0.46, 0.60),
		false,
		1.0
	)
	# Top edge accent line
	draw_line(
		Vector2(bx + 6.0, by),
		Vector2(bx + bw - 6.0, by),
		Color(0.42, 0.36, 0.65, 0.45),
		1.0
	)

	if _seed_biomes.is_empty():
		var font: Font = ThemeDB.fallback_font
		var empty_text: String = "Mix to craft seeds"
		var text_size: Vector2 = font.get_string_size(empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var text_pos: Vector2 = Vector2(_centers[0].x - text_size.x * 0.5, _centers[0].y + 5.0)
		draw_string(font, text_pos, empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.86, 0.86, 0.86, 0.90))
		return

	# --- Seed tiles ---
	for i: int in range(_seed_biomes.size()):
		_draw_hex(i)


func _draw_hex(idx: int) -> void:
	var c: Vector2 = _centers[idx]
	var base_col: Color = Color(_seed_colors[idx])
	var biome: int = _seed_biomes[idx]
	var is_sel: bool = _selected == biome
	var is_hov: bool = _hover_idx == idx and not is_sel

	var col: Color = base_col if is_sel else base_col.darkened(0.35)
	if is_hov:
		col = base_col.darkened(0.18)

	var pts: PackedVector2Array = _hex_polygon(c, _RADIUS)

	# --- 2.5D side faces (edges 3, 4, 5 — same logic as GardenView._draw_tile) ---
	for edge: int in [3, 4, 5]:
		var a: Vector2 = pts[edge]
		var b: Vector2 = pts[(edge + 1) % 6]
		var al: Vector2 = Vector2(a.x, a.y + _DEPTH)
		var bl: Vector2 = Vector2(b.x, b.y + _DEPTH)
		var shade: float = 0.52 if edge == 4 else 0.44
		draw_colored_polygon(PackedVector2Array([a, b, bl, al]), col.darkened(shade))

	# --- Top face ---
	draw_colored_polygon(pts, col)

	# --- Directional edge shading (light from upper-right) ---
	for i: int in range(6):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 6]
		if i == 0 or i == 1:
			draw_line(a, b, col.lightened(0.32), 2.0)
		elif i == 4 or i == 5:
			draw_line(a, b, col.darkened(0.28), 1.5)

	# --- Outer border ---
	var border: PackedVector2Array = PackedVector2Array(pts)
	border.append(pts[0])
	if is_sel:
		draw_polyline(border, Color(1.0, 1.0, 1.0, 0.92), 2.5)
		draw_arc(c, _RADIUS + 3.5, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.28), 1.5)
	elif is_hov:
		draw_polyline(border, Color(1.0, 1.0, 1.0, 0.55), 1.5)
	else:
		draw_polyline(border, col.darkened(0.45), 1.0)

	# --- Biome label ---
	var font: Font = ThemeDB.fallback_font
	var label: String = _seed_labels[idx]
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _LABEL_SIZE).x
	var lpos: Vector2 = Vector2(c.x - tw * 0.5, c.y + _RADIUS + _DEPTH + 13.0)
	# Drop shadow
	draw_string(font, lpos + Vector2(1.0, 1.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _LABEL_SIZE, Color(0.0, 0.0, 0.0, 0.55))
	var text_col: Color = Color.WHITE if is_sel else Color(0.72, 0.72, 0.72, 0.85)
	draw_string(font, lpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, _LABEL_SIZE, text_col)


static func _hex_polygon(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(6):
		var angle: float = deg_to_rad(-90.0 + 60.0 * float(i))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts


static func _label_for_biome(biome: int) -> String:
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
		BiomeType.Value.BADLANDS:
			return "Badlands"
		BiomeType.Value.WHISTLING_CANYONS:
			return "Canyons"
		BiomeType.Value.PRISMATIC_TERRACES:
			return "Terraces"
		BiomeType.Value.FROSTLANDS:
			return "Frost"
		BiomeType.Value.THE_ASHFALL:
			return "Ashfall"
		BiomeType.Value.SACRED_STONE:
			return "Sacred"
		BiomeType.Value.MOONLIT_POOL:
			return "Moonlit"
		BiomeType.Value.EMBER_SHRINE:
			return "Shrine"
		BiomeType.Value.CLOUD_RIDGE:
			return "Cloud"
		BiomeType.Value.KU:
			return "Ku"
	return "Seed"


static func _color_for_biome(biome: int) -> Color:
	match biome:
		BiomeType.Value.STONE:
			return Color(0.620, 0.620, 0.620)
		BiomeType.Value.RIVER:
			return Color(0.129, 0.588, 0.953)
		BiomeType.Value.EMBER_FIELD:
			return Color(0.922, 0.42, 0.18)
		BiomeType.Value.MEADOW:
			return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WETLANDS:
			return Color(0.42, 0.56, 0.48)
		BiomeType.Value.BADLANDS:
			return Color(0.82, 0.68, 0.35)
		BiomeType.Value.WHISTLING_CANYONS:
			return Color(0.84, 0.76, 0.50)
		BiomeType.Value.PRISMATIC_TERRACES:
			return Color(0.56, 0.72, 0.86)
		BiomeType.Value.FROSTLANDS:
			return Color(0.83, 0.94, 1.0)
		BiomeType.Value.THE_ASHFALL:
			return Color(0.46, 0.24, 0.18)
		BiomeType.Value.SACRED_STONE:
			return Color(0.78, 0.78, 0.68)
		BiomeType.Value.MOONLIT_POOL:
			return Color(0.50, 0.58, 0.60)
		BiomeType.Value.EMBER_SHRINE:
			return Color(0.80, 0.36, 0.22)
		BiomeType.Value.CLOUD_RIDGE:
			return Color(0.70, 0.74, 0.82)
		BiomeType.Value.KU:
			return Color(0.05, 0.02, 0.10)
	return Color(0.502, 0.502, 0.502)
