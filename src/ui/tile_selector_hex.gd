## TileSelectorHex — draws the four base-biome selector buttons as miniature
## hex tiles, matching the GardenView 2.5D visual language.
## Designed to live inside a CanvasLayer so all coordinates are screen pixels.
extends Node2D

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")

## Emitted when the player clicks a biome hex.
signal biome_selected(biome: int)
## Emitted when the player clicks a building inventory stack.
signal building_selected(type_key: StringName)

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
var _selected_entry_kind: StringName = &"plant_recipe"
var _selected_building_type_key: StringName = &""
var _hover_idx: int = -1
var _centers: Array[Vector2] = []
var _entry_kinds: Array[StringName] = []
var _seed_biomes: Array[int] = []
var _seed_labels: Array[String] = []
var _seed_colors: Array[Color] = []
var _building_type_keys: Array[StringName] = []
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
	var item_count: int = 3 if _entry_kinds.is_empty() else maxi(1, _entry_kinds.size())
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
	_entry_kinds.clear()
	_seed_biomes.clear()
	_seed_labels.clear()
	_seed_colors.clear()
	_building_type_keys.clear()
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_method("get_pouch"):
		var pouch: SeedPouch = growth.get_pouch()
		if pouch != null:
			for i: int in range(pouch.size()):
				if pouch.get_entry_kind_at(i) == &"building_item":
					var building_entry: BuildingInventoryEntry = pouch.get_building_at(i)
					if building_entry == null or building_entry.count <= 0:
						continue
					_entry_kinds.append(&"building_item")
					_seed_biomes.append(BiomeType.Value.NONE)
					_seed_labels.append("%s x%d" % [_label_for_building(building_entry.type_key), building_entry.count])
					_seed_colors.append(_color_for_building(building_entry.type_key))
					_building_type_keys.append(building_entry.type_key)
					continue
				var recipe: SeedRecipe = pouch.get_at(i)
				if recipe == null:
					continue
				var uses: int = pouch.get_uses_at(i)
				_entry_kinds.append(&"plant_recipe")
				_seed_biomes.append(recipe.produces_biome)
				_seed_labels.append("%s x%d" % [_label_for_biome(recipe.produces_biome), uses])
				_seed_colors.append(_color_for_biome(recipe.produces_biome))
				_building_type_keys.append(&"")
	if _entry_kinds.is_empty():
		_selected = BiomeType.Value.NONE
		_selected_entry_kind = &"plant_recipe"
		_selected_building_type_key = &""
	else:
		var selected_still_available: bool = _has_selected_entry()
		if not selected_still_available:
			_select_entry_at(0)
			if emit_selection and _entry_kinds[0] == &"plant_recipe":
				biome_selected.emit(_selected)
		elif emit_selection and _selected_entry_kind == &"plant_recipe" and not _seed_biomes.has(_selected):
			_selected = _seed_biomes[0]
			biome_selected.emit(_selected)
	_rebuild_centers()
	queue_redraw()


## Programmatically select a biome without emitting biome_selected.
func select(biome: int) -> void:
	_selected = biome
	_selected_entry_kind = &"plant_recipe"
	_selected_building_type_key = &""
	queue_redraw()


func get_selected_biome() -> int:
	if _selected_entry_kind == &"plant_recipe" and _selected != BiomeType.Value.NONE:
		return _selected
	for biome: int in _seed_biomes:
		if biome != BiomeType.Value.NONE:
			return biome
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
			if idx >= 0 and idx < _entry_kinds.size():
				_select_entry_at(idx)
				if _entry_kinds[idx] == &"building_item":
					building_selected.emit(_building_type_keys[idx])
				else:
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
	var item_count: int = maxi(1, _entry_kinds.size())
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

	if _entry_kinds.is_empty():
		var font: Font = ThemeDB.fallback_font
		var title_text: String = "No placeables yet"
		var hint_text: String = "Open Ritual to shape one"
		var title_size: Vector2 = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var hint_size: Vector2 = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var center_x: float = bx + bw * 0.5
		var title_pos: Vector2 = Vector2(center_x - title_size.x * 0.5, _centers[0].y - 2.0)
		var hint_pos: Vector2 = Vector2(center_x - hint_size.x * 0.5, _centers[0].y + 17.0)
		draw_string(font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.96, 0.94, 0.88, 0.96))
		draw_string(font, hint_pos, hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.78, 0.76, 0.84, 0.88))
		return

	for i: int in range(_entry_kinds.size()):
		if _entry_kinds[i] == &"building_item":
			_draw_building_badge(i)
		else:
			_draw_hex(i)


func _draw_hex(idx: int) -> void:
	var c: Vector2 = _centers[idx]
	var base_col: Color = Color(_seed_colors[idx])
	var is_sel: bool = _is_entry_selected(idx)
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

func _draw_building_badge(idx: int) -> void:
	var c: Vector2 = _centers[idx]
	var base_col: Color = Color(_seed_colors[idx])
	var is_sel: bool = _is_entry_selected(idx)
	var is_hov: bool = _hover_idx == idx and not is_sel
	var col: Color = base_col if is_sel else base_col.darkened(0.22)
	if is_hov:
		col = base_col.darkened(0.08)

	var r: float = _RADIUS
	var pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.62, -r * 0.82),
		c + Vector2(r * 0.62, -r * 0.82),
		c + Vector2(r * 0.82, -r * 0.62),
		c + Vector2(r * 0.82, r * 0.62),
		c + Vector2(r * 0.62, r * 0.82),
		c + Vector2(-r * 0.62, r * 0.82),
		c + Vector2(-r * 0.82, r * 0.62),
		c + Vector2(-r * 0.82, -r * 0.62),
	])
	var lowered: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in pts:
		lowered.append(p + Vector2(0.0, _DEPTH))
	for edge: int in [3, 4, 5]:
		draw_colored_polygon(PackedVector2Array([
			pts[edge],
			pts[(edge + 1) % pts.size()],
			lowered[(edge + 1) % pts.size()],
			lowered[edge],
		]), col.darkened(0.50))
	draw_colored_polygon(pts, col)

	var border: PackedVector2Array = PackedVector2Array(pts)
	border.append(pts[0])
	var border_col: Color = Color(0.96, 0.95, 0.86, 0.96) if is_sel else Color(0.78, 0.76, 0.68, 0.78)
	draw_polyline(border, border_col, 2.5 if is_sel else 1.6)
	draw_arc(c, _RADIUS + 3.5, 0.0, TAU, 24, Color(0.96, 0.95, 0.86, 0.24) if is_sel else Color(0.0, 0.0, 0.0, 0.0), 1.5)

	var roof: PackedVector2Array = PackedVector2Array([
		c + Vector2(-15.0, -4.0),
		c + Vector2(0.0, -16.0),
		c + Vector2(15.0, -4.0),
	])
	draw_colored_polygon(roof, Color(0.32, 0.24, 0.16, 0.96))
	draw_line(roof[0], roof[1], Color(0.95, 0.88, 0.62, 0.95), 2.0)
	draw_line(roof[1], roof[2], Color(0.95, 0.88, 0.62, 0.95), 2.0)
	var body_rect: Rect2 = Rect2(c + Vector2(-12.0, -3.0), Vector2(24.0, 17.0))
	draw_rect(body_rect, Color(0.86, 0.78, 0.60, 0.96))
	draw_rect(body_rect, Color(0.30, 0.22, 0.15, 0.95), false, 1.5)
	draw_rect(Rect2(c + Vector2(-3.0, 4.0), Vector2(6.0, 10.0)), Color(0.34, 0.24, 0.15, 0.96))

	var font: Font = ThemeDB.fallback_font
	var label: String = _seed_labels[idx]
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _LABEL_SIZE).x
	var lpos: Vector2 = Vector2(c.x - tw * 0.5, c.y + _RADIUS + _DEPTH + 13.0)
	draw_string(font, lpos + Vector2(1.0, 1.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _LABEL_SIZE, Color(0.0, 0.0, 0.0, 0.55))
	var text_col: Color = Color(1.0, 0.96, 0.76, 1.0) if is_sel else Color(0.82, 0.79, 0.68, 0.92)
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


func _label_for_building(type_key: StringName) -> String:
	var form_name: String = _form_display_name(type_key)
	if not form_name.is_empty():
		return form_name
	var raw: String = str(type_key)
	if raw.begins_with("building_"):
		raw = raw.substr("building_".length())
	if raw.begins_with("form_"):
		raw = raw.substr("form_".length())
	return raw.capitalize()

func _form_display_name(type_key: StringName) -> String:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_method("get_form_display_name"):
		return str(alchemy.get_form_display_name(type_key))
	return ""


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


static func _color_for_building(type_key: StringName) -> Color:
	var raw_key: String = str(type_key)
	if raw_key.begins_with("form_"):
		return Color(0.74, 0.52, 0.32)
	match type_key:
		&"building_meadow_dwelling":
			return Color(0.54, 0.70, 0.48)
		&"building_scorched_hollow":
			return Color(0.82, 0.42, 0.24)
		&"building_reed_nest":
			return Color(0.42, 0.70, 0.66)
		&"building_stone_basin":
			return Color(0.54, 0.58, 0.66)
		&"building_house":
			return Color(0.62, 0.70, 0.58)
	return Color(0.58, 0.64, 0.62)


func _select_entry_at(idx: int) -> void:
	if idx < 0 or idx >= _entry_kinds.size():
		return
	_selected_entry_kind = _entry_kinds[idx]
	if _selected_entry_kind == &"building_item":
		_selected_building_type_key = _building_type_keys[idx]
	else:
		_selected_building_type_key = &""
		_selected = _seed_biomes[idx]


func _has_selected_entry() -> bool:
	if _entry_kinds.is_empty():
		return false
	for idx: int in range(_entry_kinds.size()):
		if _is_entry_selected(idx):
			return true
	return false


func _is_entry_selected(idx: int) -> bool:
	if idx < 0 or idx >= _entry_kinds.size():
		return false
	if _entry_kinds[idx] != _selected_entry_kind:
		return false
	if _selected_entry_kind == &"building_item":
		return _building_type_keys[idx] == _selected_building_type_key
	return _seed_biomes[idx] == _selected
