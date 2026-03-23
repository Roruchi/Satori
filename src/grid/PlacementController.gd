## PlacementController — translates mouse input into tile placement requests.
## Suppresses placement when a drag gesture was in progress (checked via CameraPanController).
extends Node2D

const TILE_SIZE: int = 32

@onready var _garden_view: Node2D = $"../GardenView"
@onready var _camera_pan: Node2D = $"../CameraPanController"

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x / TILE_SIZE), roundi(world_pos.y / TILE_SIZE))

func _process(_delta: float) -> void:
	var coord := _world_to_tile(get_global_mouse_position())
	var valid: bool = GameState.grid.is_placement_valid(coord)
	_garden_view.set_hover(coord, valid)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _camera_pan.is_drag_gesture():
				return
			var coord := _world_to_tile(get_global_mouse_position())
			GameState.try_place_tile(coord)
