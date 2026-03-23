## CameraPanController — handles all camera navigation input.
## Responsible for: keyboard panning (arrow / WASD), mouse-drag panning, single-finger touch drag.
## Exposes is_drag_gesture() so PlacementController can suppress tap-placement after a drag.
extends Node2D

const PAN_SPEED: float = 300.0

## Minimum pointer travel (screen pixels) before a press is classified as a drag.
@export var drag_threshold_px: float = 8.0

@onready var _camera: Camera2D = $"../Camera2D"

# --- drag state ---
var _dragging: bool = false         # pointer / finger is currently pressed
var _total_drag_px: float = 0.0     # cumulative movement since last press
var _was_drag: bool = false         # true once movement exceeds drag_threshold_px


## Returns true when the most recent press-release cycle exceeded the drag threshold.
## PlacementController calls this on release to decide whether to place a tile.
func is_drag_gesture() -> bool:
	return _was_drag


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		_camera.position += direction * PAN_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_dragging = true
		_total_drag_px = 0.0
		_was_drag = false
	else:
		_dragging = false


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if not _dragging:
		return
	_total_drag_px += mm.relative.length()
	if _total_drag_px > drag_threshold_px:
		_was_drag = true
	_camera.position -= mm.relative / _camera.zoom


func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
	if touch.index != 0:
		return  # ignore second finger here; pinch-zoom handles multi-touch
	if touch.pressed:
		_dragging = true
		_total_drag_px = 0.0
		_was_drag = false
	else:
		_dragging = false


func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
	if drag.index != 0:
		return  # only track the primary touch point
	_total_drag_px += drag.relative.length()
	if _total_drag_px > drag_threshold_px:
		_was_drag = true
	_camera.position -= drag.relative / _camera.zoom
