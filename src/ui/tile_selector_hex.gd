## TileSelectorHex — draws the four base-biome selector buttons as miniature
## hex tiles, matching the GardenView 2.5D visual language.
## Designed to live inside a CanvasLayer so all coordinates are screen pixels.
extends Node2D

## Emitted when the player clicks a biome hex.
signal biome_selected(biome: int)

## Hex circumradius in screen pixels.
const _RADIUS: float = 30.0
## Voxel side-face depth in screen pixels.
const _DEPTH: float = 5.0
## Gap between adjacent hex centres.
const _GAP: float = 16.0
## Font size for biome labels.
const _LABEL_SIZE: int = 11

## The four selectable base biomes — order matches _LABELS and _COLORS.
const _BIOMES: Array = [
	BiomeType.Value.STONE,
	BiomeType.Value.RIVER,
	BiomeType.Value.EMBER_FIELD,
	BiomeType.Value.MEADOW,
]

const _LABELS: Array = ["Stone", "River", "Ember", "Meadow"]

## Colours matching GardenView._biome_color() for the four base biomes.
const _COLORS: Array = [
	Color(0.620, 0.620, 0.620),   # STONE
	Color(0.129, 0.588, 0.953),   # RIVER
	Color(0.922, 0.42, 0.18),     # EMBER
	Color(0.298, 0.686, 0.314),   # MEADOW
]

var _selected: int = BiomeType.Value.STONE
var _hover_idx: int = -1
var _centers: Array[Vector2] = []


func _ready() -> void:
	_rebuild_centers()
	get_viewport().size_changed.connect(_on_viewport_resized)
	set_process_input(true)


func _on_viewport_resized() -> void:
	_rebuild_centers()
	queue_redraw()


func _rebuild_centers() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var spacing: float = _RADIUS * 2.0 + _GAP
	var total_w: float = spacing * 3.0
	var sx: float = vp.x * 0.5 - total_w * 0.5
	var cy: float = vp.y - _RADIUS - _DEPTH - 28.0
	_centers.clear()
	for i: int in range(4):
		_centers.append(Vector2(sx + float(i) * spacing, cy))


## Programmatically select a biome without emitting biome_selected.
func select(biome: int) -> void:
	_selected = biome
	queue_redraw()


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
			if idx >= 0:
				_selected = _BIOMES[idx]
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
	var pad_top: float = 14.0
	var pad_bot: float = 28.0   # room for labels
	var bw: float = spacing * 3.0 + _RADIUS * 2.0 + pad_x * 2.0
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

	# --- Hex tiles ---
	for i: int in range(4):
		_draw_hex(i)


func _draw_hex(idx: int) -> void:
	var c: Vector2 = _centers[idx]
	var base_col: Color = Color(_COLORS[idx])
	var biome: int = _BIOMES[idx]
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
	var label: String = _LABELS[idx]
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
