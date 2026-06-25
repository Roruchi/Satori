class_name SpiritWanderer
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 20.0
const SPIRIT_RADIUS: float = 8.0
const HOUSED_LABEL_COLOR: Color = Color(1.0, 1.0, 1.0)
const UNHOUSED_LABEL_COLOR: Color = Color(1.0, 0.35, 0.35)
const HOUSING_COLOR_REFRESH_SECONDS: float = 0.5
const SPRITE_FRAMES_PATH_TEMPLATE: String = "res://assets/spirits/%s/sprite_frames.tres"
const DEFAULT_SPRITE_SCALE: float = 0.62
const SPRITE_Y_OFFSET: float = -4.0
const PLACEHOLDER_LABEL_Y: float = -30.0
const SPRITE_LABEL_Y: float = -48.0
const SPRITE_FRAME_SIZE: float = 64.0
const SPRITE_LABEL_PADDING: float = 28.0

signal moved_to(spirit_id: String, coord: Vector2i)

var spirit_id: String = ""
var wander_bounds: Rect2i = Rect2i()
## Island the spirit belongs to.  When non-empty, candidate wander tiles are
## restricted to tiles with the same island_id so spirits never cross Ku tiles.
var _island_id: String = ""
var _speed: float = 2.0
var _target_world: Vector2 = Vector2.ZERO
var _wait_time: float = 0.0
var _display_color: Color = Color.WHITE
var _label: Label
var _preferred_biomes: Array[int] = []
var _disliked_biomes: Array[int] = []
var _housing_color_refresh_remaining: float = 0.0
var _sprite: AnimatedSprite2D = null
var _last_direction: String = "down"
var _is_using_sprite_art: bool = false
var _is_housed: bool = false
var _sprite_scale: float = DEFAULT_SPRITE_SCALE

func setup(instance: SpiritInstance, catalog_entry: Dictionary) -> void:
	spirit_id = instance.spirit_id
	wander_bounds = instance.wander_bounds
	_island_id = instance.island_id
	_speed = float(catalog_entry.get("wander_speed", 2.0)) * TILE_RADIUS * 0.25
	_sprite_scale = maxf(0.1, float(catalog_entry.get("sprite_scale", DEFAULT_SPRITE_SCALE)))
	var color: Color = catalog_entry.get("color_hint", Color.WHITE)
	_display_color = color
	_preferred_biomes.clear()
	if catalog_entry.has("preferred_biomes"):
		var preferred_variant: Variant = catalog_entry["preferred_biomes"]
		if preferred_variant is Array:
			for biome_variant in preferred_variant:
				_preferred_biomes.append(int(biome_variant))
	_disliked_biomes.clear()
	if catalog_entry.has("disliked_biomes"):
		var disliked_variant: Variant = catalog_entry["disliked_biomes"]
		if disliked_variant is Array:
			for biome_variant in disliked_variant:
				_disliked_biomes.append(int(biome_variant))
	var display_name: String = str(catalog_entry.get("display_name", spirit_id))
	if _label != null:
		_label.text = display_name
		_load_sprite_art()
		_update_housing_label_color(true)
	var start_world: Vector2 = _coord_to_world(instance.spawn_coord)
	position = start_world
	queue_redraw()
	_pick_new_target()

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-52.0, PLACEHOLDER_LABEL_Y)
	_label.size = Vector2(104.0, 22.0)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	if not spirit_id.is_empty():
		_load_sprite_art()
	queue_redraw()

func _draw() -> void:
	if _is_using_sprite_art:
		return
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
		_housing_color_refresh_remaining -= delta
		if _housing_color_refresh_remaining <= 0.0:
			_update_housing_label_color()
		_update_sprite_animation(false, Vector2.ZERO)
		if _wait_time <= 0.0:
			_pick_new_target()
		return
	_housing_color_refresh_remaining -= delta
	if _housing_color_refresh_remaining <= 0.0:
		_update_housing_label_color()
	var diff: Vector2 = _target_world - position
	if diff.length() < 0.1:
		_update_sprite_animation(false, diff)
		var coord: Vector2i = _world_to_coord(position)
		if _is_disliked_coord(coord):
			_pick_new_target()
			return
		moved_to.emit(spirit_id, coord)
		_wait_time = randf_range(1.5, 4.0)
		return
	_update_sprite_animation(true, diff)
	position += diff.normalized() * _speed * delta

func _pick_new_target() -> void:
	var effective_bounds: Rect2i = _get_effective_bounds()
	if effective_bounds.size == Vector2i.ZERO:
		_update_sprite_animation(false, Vector2.ZERO)
		return
	var candidates: Array[Vector2i] = _get_candidate_coords(effective_bounds)
	if candidates.is_empty():
		_update_sprite_animation(false, Vector2.ZERO)
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
	# When this spirit belongs to an island, check if the grid supports island IDs.
	var use_island_filter: bool = (
		not _island_id.is_empty() and grid.has_method("get_island_id")
	)
	var preferred_candidates: Array[Vector2i] = []
	var occupied_candidates: Array[Vector2i] = []
	for x: int in range(effective_bounds.position.x, effective_bounds.position.x + effective_bounds.size.x):
		for y: int in range(effective_bounds.position.y, effective_bounds.position.y + effective_bounds.size.y):
			var coord: Vector2i = Vector2i(x, y)
			if not grid.has_tile(coord):
				continue
			# Spirits stay on their own island — skip tiles on a different island
			# (including KU tiles which have an empty island_id).
			if use_island_filter and grid.get_island_id(coord) != _island_id:
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

func _world_to_coord(world_pos: Vector2) -> Vector2i:
	return _HexUtils.pixel_to_axial(world_pos, TILE_RADIUS)

func _is_disliked_coord(coord: Vector2i) -> bool:
	if _disliked_biomes.is_empty():
		return false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	var grid: RefCounted = game_state.get("grid")
	if grid == null:
		return false
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return false
	return _disliked_biomes.has(tile.biome)

func update_bounds(new_bounds: Rect2i) -> void:
	wander_bounds = new_bounds

func set_island_id(new_island_id: String) -> void:
	_island_id = new_island_id

func _load_sprite_art() -> void:
	if spirit_id.is_empty():
		return
	var sprite_path: String = SPRITE_FRAMES_PATH_TEMPLATE % spirit_id
	if not ResourceLoader.exists(sprite_path, "SpriteFrames"):
		_set_sprite_art_enabled(false)
		return
	var resource: Resource = ResourceLoader.load(sprite_path, "SpriteFrames")
	var frames: SpriteFrames = resource as SpriteFrames
	if frames == null:
		_set_sprite_art_enabled(false)
		return
	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		_sprite.name = "SpiritSprite"
		_sprite.position = Vector2(0.0, SPRITE_Y_OFFSET)
		add_child(_sprite)
		move_child(_sprite, 0)
	_sprite.scale = Vector2.ONE * _sprite_scale
	_sprite.sprite_frames = frames
	_set_sprite_art_enabled(true)
	_update_sprite_animation(false, Vector2.ZERO)

func _set_sprite_art_enabled(enabled: bool) -> void:
	_is_using_sprite_art = enabled
	if _sprite != null:
		_sprite.visible = enabled
	if _label != null:
		var scaled_sprite_half_height: float = SPRITE_FRAME_SIZE * _sprite_scale * 0.5
		var scaled_sprite_label_y: float = minf(SPRITE_LABEL_Y, -(scaled_sprite_half_height + SPRITE_LABEL_PADDING))
		var label_y: float = scaled_sprite_label_y if enabled else PLACEHOLDER_LABEL_Y
		_label.position = Vector2(_label.position.x, label_y)
	queue_redraw()

func _update_sprite_animation(is_moving: bool, move_delta: Vector2) -> void:
	if not _is_using_sprite_art or _sprite == null or _sprite.sprite_frames == null:
		return
	if move_delta.length() > 0.01:
		_last_direction = _direction_for_delta(move_delta)
	var anim_prefix: String = "walk" if is_moving else "idle"
	if not is_moving and _is_housed:
		anim_prefix = "sleep"
	var animation_name: String = "%s_%s" % [anim_prefix, _last_direction]
	if not _sprite.sprite_frames.has_animation(animation_name):
		animation_name = "idle_%s" % _last_direction
	if not _sprite.sprite_frames.has_animation(animation_name):
		animation_name = "idle_down"
	if not _sprite.sprite_frames.has_animation(animation_name):
		return
	if _sprite.animation != animation_name:
		_sprite.play(animation_name)
	elif not _sprite.is_playing():
		_sprite.play()

func _direction_for_delta(move_delta: Vector2) -> String:
	if absf(move_delta.x) > absf(move_delta.y):
		return "right" if move_delta.x > 0.0 else "left"
	return "down" if move_delta.y > 0.0 else "up"

func _update_housing_label_color(force_refresh: bool = false) -> void:
	if _label == null:
		return
	if not force_refresh and _housing_color_refresh_remaining > 0.0:
		return
	_housing_color_refresh_remaining = HOUSING_COLOR_REFRESH_SECONDS
	var spirit_service: Node = _resolve_spirit_service()
	if spirit_service == null or not spirit_service.has_method("is_spirit_housed"):
		_is_housed = false
		_label.add_theme_color_override("font_color", HOUSED_LABEL_COLOR)
		return
	_is_housed = bool(spirit_service.is_spirit_housed(spirit_id, _island_id))
	_label.add_theme_color_override("font_color", HOUSED_LABEL_COLOR if _is_housed else UNHOUSED_LABEL_COLOR)

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
	var root: Node = get_tree().root if get_tree() != null else null
	if root == null:
		return null
	var discovered: Node = root.find_child("SpiritService", true, false)
	return discovered
