class_name SpiritWanderer
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 20.0
const SPIRIT_RADIUS: float = 8.0

var spirit_id: String = ""
var wander_bounds: Rect2i = Rect2i()
var _speed: float = 2.0
var _target_world: Vector2 = Vector2.ZERO
var _wait_time: float = 0.0
var _display_color: Color = Color.WHITE
var _label: Label
var _preferred_biomes: Array[int] = []

func setup(instance: SpiritInstance, catalog_entry: Dictionary) -> void:
	spirit_id = instance.spirit_id
	wander_bounds = instance.wander_bounds
	_speed = float(catalog_entry.get("wander_speed", 2.0)) * TILE_RADIUS * 0.25
	var color: Color = catalog_entry.get("color_hint", Color.WHITE)
	_display_color = color
	_preferred_biomes.clear()
	if catalog_entry.has("preferred_biomes"):
		var preferred_variant: Variant = catalog_entry["preferred_biomes"]
		if preferred_variant is Array:
			for biome_variant in preferred_variant:
				_preferred_biomes.append(int(biome_variant))
	var display_name: String = str(catalog_entry.get("display_name", spirit_id))
	if _label != null:
		_label.text = display_name
	var start_world: Vector2 = _coord_to_world(instance.spawn_coord)
	position = start_world
	queue_redraw()
	_pick_new_target()

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-52.0, -30.0)
	_label.size = Vector2(104.0, 22.0)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	queue_redraw()

func _draw() -> void:
	var outer_r: float = SPIRIT_RADIUS + 5.5
	var inner_r: float = SPIRIT_RADIUS
	var core_r: float = SPIRIT_RADIUS * 0.55

	# Outer atmospheric glow (large, very transparent)
	draw_circle(Vector2.ZERO, outer_r + 4.0, Color(_display_color.r, _display_color.g, _display_color.b, 0.10))
	# Glow ring
	draw_circle(Vector2.ZERO, outer_r, Color(_display_color.r, _display_color.g, _display_color.b, 0.22))
	# Drop shadow (offset)
	draw_circle(Vector2(2.0, 2.5), inner_r, Color(0.0, 0.0, 0.0, 0.35))
	# Main spirit body
	draw_circle(Vector2.ZERO, inner_r, _display_color)
	# Inner highlight ring
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 24, _display_color.lightened(0.30), 1.8)
	# Bright inner core
	draw_circle(Vector2.ZERO, core_r, _display_color.lightened(0.45))
	# Specular highlight dot (upper-right)
	draw_circle(Vector2(inner_r * 0.32, -inner_r * 0.32), core_r * 0.50, Color(1.0, 1.0, 1.0, 0.75))
	# Cross/sparkle lines emanating from centre
	for i: int in range(4):
		var angle: float = deg_to_rad(float(i) * 45.0 + 22.5)
		var arm: float = outer_r * 0.80
		var start: Vector2 = Vector2(cos(angle), sin(angle)) * inner_r * 0.85
		var end: Vector2 = Vector2(cos(angle), sin(angle)) * arm
		draw_line(start, end, Color(_display_color.r, _display_color.g, _display_color.b, 0.50), 1.2)

func _process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		if _wait_time <= 0.0:
			_pick_new_target()
		return
	var diff: Vector2 = _target_world - position
	if diff.length() < 0.1:
		_wait_time = randf_range(1.5, 4.0)
		return
	position += diff.normalized() * _speed * delta

func _pick_new_target() -> void:
	var effective_bounds: Rect2i = _get_effective_bounds()
	if effective_bounds.size == Vector2i.ZERO:
		return
	var candidates: Array[Vector2i] = _get_candidate_coords(effective_bounds)
	if candidates.is_empty():
		return
	var target_coord: Vector2i = candidates[randi() % candidates.size()]
	_target_world = _coord_to_world(target_coord)

func _get_candidate_coords(effective_bounds: Rect2i) -> Array[Vector2i]:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return []
	var grid: RefCounted = game_state.get("grid")
	if grid == null or not grid.has_method("has_tile") or not grid.has_method("get_tile"):
		return []
	var preferred_candidates: Array[Vector2i] = []
	var occupied_candidates: Array[Vector2i] = []
	for x: int in range(effective_bounds.position.x, effective_bounds.position.x + effective_bounds.size.x):
		for y: int in range(effective_bounds.position.y, effective_bounds.position.y + effective_bounds.size.y):
			var coord: Vector2i = Vector2i(x, y)
			if not grid.has_tile(coord):
				continue
			occupied_candidates.append(coord)
			if _preferred_biomes.is_empty():
				continue
			var tile: GardenTile = grid.get_tile(coord)
			if tile != null and _preferred_biomes.has(tile.biome):
				preferred_candidates.append(coord)
	if not preferred_candidates.is_empty():
		return preferred_candidates
	return occupied_candidates

func _get_effective_bounds() -> Rect2i:
	if wander_bounds.size == Vector2i.ZERO:
		return Rect2i()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return wander_bounds
	var grid: RefCounted = game_state.get("grid")
	if grid == null or not grid.has_method("get"):
		return wander_bounds
	var garden_bounds: Rect2i = grid.get("garden_bounds")
	if garden_bounds.size == Vector2i.ZERO:
		return wander_bounds
	var clipped: Rect2i = wander_bounds.intersection(garden_bounds)
	if clipped.size == Vector2i.ZERO:
		return wander_bounds
	return clipped

func _coord_to_world(coord: Vector2i) -> Vector2:
	var px: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	return px

func update_bounds(new_bounds: Rect2i) -> void:
	wander_bounds = new_bounds
