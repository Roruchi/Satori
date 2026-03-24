class_name SpiritWanderer
extends Node3D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 1.0
const SPIRIT_HEIGHT: float = 0.8

var spirit_id: String = ""
var wander_bounds: Rect2i = Rect2i()
var _speed: float = 2.0
var _target_world: Vector3 = Vector3.ZERO
var _wait_time: float = 0.0
var _mesh_instance: MeshInstance3D
var _label: Label3D

func setup(instance: SpiritInstance, catalog_entry: Dictionary) -> void:
	spirit_id = instance.spirit_id
	wander_bounds = instance.wander_bounds
	_speed = float(catalog_entry.get("wander_speed", 2.0))
	var color: Color = catalog_entry.get("color_hint", Color.WHITE)
	var display_name: String = str(catalog_entry.get("display_name", spirit_id))
	if _mesh_instance != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
		_mesh_instance.material_override = mat
	if _label != null:
		_label.text = display_name
	var start_world: Vector3 = _coord_to_world(instance.spawn_coord)
	global_position = start_world
	_pick_new_target()

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	_mesh_instance.mesh = sphere
	add_child(_mesh_instance)
	_label = Label3D.new()
	_label.font_size = 24
	_label.no_depth_test = true
	_label.position = Vector3(0.0, 0.6, 0.0)
	add_child(_label)

func _process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		if _wait_time <= 0.0:
			_pick_new_target()
		return
	var diff: Vector3 = _target_world - global_position
	if diff.length() < 0.1:
		_wait_time = randf_range(1.5, 4.0)
		return
	global_position += diff.normalized() * _speed * delta

func _pick_new_target() -> void:
	if wander_bounds.size == Vector2i.ZERO:
		return
	var rx: int = wander_bounds.position.x + randi() % max(wander_bounds.size.x, 1)
	var ry: int = wander_bounds.position.y + randi() % max(wander_bounds.size.y, 1)
	_target_world = _coord_to_world(Vector2i(rx, ry))

func _coord_to_world(coord: Vector2i) -> Vector3:
	var px: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	return Vector3(px.x, SPIRIT_HEIGHT, px.y)

func update_bounds(new_bounds: Rect2i) -> void:
	wander_bounds = new_bounds
