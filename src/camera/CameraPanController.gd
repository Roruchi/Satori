## CameraPanController — handles all camera navigation input.
## Responsible for: keyboard panning (arrow / WASD), mouse-drag panning,
##   mouse-wheel zoom, keyboard zoom (+/-), single-finger touch drag,
##   pinch-to-zoom (US3), momentum panning (US2), and double-tap re-centre (US4).
## Exposes is_drag_gesture() so PlacementController can suppress tap-placement after a drag.
extends Node2D

const PAN_SPEED: float = 300.0

## Minimum pointer travel (screen pixels) before a press is classified as a drag.
@export var drag_threshold_px: float = 8.0

## US2 — Momentum panning
@export var friction: float = 8.0         ## Deceleration multiplier (higher = stops faster)
@export var max_velocity: float = 2000.0  ## Maximum momentum speed in world px/s

## US3 / PC-Web zoom — Camera zoom limits and per-step increment
@export var zoom_min: float = 0.5   ## Minimum zoom level (zoomed out, shows more of the garden)
@export var zoom_max: float = 4.0   ## Maximum zoom level (zoomed in, shows less of the garden)
@export var zoom_step: float = 0.15 ## Zoom increment per mouse-wheel tick or keyboard press

## US4 — Double-tap re-centre
@export var double_tap_threshold_ms: float = 300.0 ## Max milliseconds between taps
@export var double_tap_radius_px: float = 40.0     ## Max screen-pixel distance between taps

@onready var _camera: Camera2D = $"../Camera2D"

# --- drag state ---
var _dragging: bool = false        # pointer / finger is currently pressed
var _total_drag_px: float = 0.0    # cumulative movement since last press
var _was_drag: bool = false        # true once movement exceeds drag_threshold_px

# --- momentum (US2) ---
const _VELOCITY_SAMPLE_COUNT: int = 5
var _pan_velocity: Vector2 = Vector2.ZERO
var _velocity_samples: Array[Vector2] = []  # recent screen-space deltas for velocity estimate

# --- pinch-zoom state (US3) ---
var _touch_points: Dictionary = {}         # touch index (int) -> screen position (Vector2)
var _pinch_active: bool = false
var _pinch_initial_distance: float = 0.0
var _pinch_initial_zoom: float = 1.0

# --- double-tap state (US4) ---
var _last_tap_time: int = 0
var _last_tap_pos: Vector2 = Vector2.ZERO


## Returns true when the most recent press-release cycle exceeded the drag threshold.
## PlacementController calls this on release to decide whether to place a tile.
func is_drag_gesture() -> bool:
	return _was_drag


func _process(delta: float) -> void:
	# Keyboard panning (held keys, smooth)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		_camera.position += direction * PAN_SPEED * delta
		_pan_velocity = Vector2.ZERO  # keyboard input cancels momentum

	# Momentum decay (US2)
	if _pan_velocity.length_squared() > 1.0:
		_camera.position += _pan_velocity * delta
		_pan_velocity = _pan_velocity.lerp(Vector2.ZERO, friction * delta)
		if _pan_velocity.length() < 1.0:
			_pan_velocity = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	match mb.button_index:
		MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_primary_press(mb.position)
			else:
				_on_primary_release()
		MOUSE_BUTTON_WHEEL_UP:
			# Scroll up → zoom in (tiles appear larger)
			if mb.pressed:
				_apply_zoom(zoom_step)
		MOUSE_BUTTON_WHEEL_DOWN:
			# Scroll down → zoom out (tiles appear smaller, more of garden visible)
			if mb.pressed:
				_apply_zoom(-zoom_step)


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if not _dragging:
		return
	_total_drag_px += mm.relative.length()
	if _total_drag_px > drag_threshold_px:
		_was_drag = true
	_camera.position -= mm.relative / _camera.zoom
	_record_velocity_sample(mm.relative)


## Keyboard zoom: + / = / numpad+ to zoom in; - / numpad- to zoom out (PC / web)
func _handle_key(key: InputEventKey) -> void:
	if not key.pressed:
		return
	match key.keycode:
		KEY_EQUAL, KEY_KP_ADD:
			_apply_zoom(zoom_step)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_apply_zoom(-zoom_step)


func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_touch_points[touch.index] = touch.position
		if touch.index == 0:
			_on_primary_press(touch.position)
		elif touch.index == 1:
			_start_pinch()
	else:
		_touch_points.erase(touch.index)
		if touch.index == 0:
			if _pinch_active:
				# First finger lifted while pinching — exit pinch, reset state
				_pinch_active = false
				_pan_velocity = Vector2.ZERO
				_dragging = false
				_velocity_samples.clear()
			else:
				_on_primary_release()
		elif touch.index == 1:
			_pinch_active = false
			# Re-enter single-finger pan mode with zero initial velocity
			_pan_velocity = Vector2.ZERO


func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
	_touch_points[drag.index] = drag.position
	# While pinching, update zoom rather than panning
	if _pinch_active and _touch_points.size() >= 2:
		_update_pinch()
		return
	if drag.index != 0:
		return  # only primary finger drives panning
	_total_drag_px += drag.relative.length()
	if _total_drag_px > drag_threshold_px:
		_was_drag = true
	_camera.position -= drag.relative / _camera.zoom
	_record_velocity_sample(drag.relative)


# ---------------------------------------------------------------------------
# Primary press / release helpers
# ---------------------------------------------------------------------------

func _on_primary_press(pos: Vector2) -> void:
	# Double-tap detection (US4): two presses within threshold time and radius
	var now: int = Time.get_ticks_msec()
	if now - _last_tap_time < int(double_tap_threshold_ms) \
			and pos.distance_to(_last_tap_pos) < double_tap_radius_px:
		_recentre_camera()
		_last_tap_time = 0  # reset so a third tap doesn't immediately re-trigger
		return

	_last_tap_time = now
	_last_tap_pos = pos

	_dragging = true
	_total_drag_px = 0.0
	_was_drag = false
	_pan_velocity = Vector2.ZERO  # new touch cancels any in-flight momentum (US2)
	_velocity_samples.clear()


func _on_primary_release() -> void:
	_dragging = false
	# Compute launch velocity from recent drag samples (US2)
	if _velocity_samples.size() > 0:
		var avg: Vector2 = Vector2.ZERO
		for sample: Vector2 in _velocity_samples:
			avg += sample
		avg /= float(_velocity_samples.size())
		# Scale per-frame delta to approximate pixels/second (assumes ~60 fps; good enough
		# for momentum feel — users on 90/120 Hz displays will see slightly shorter drift,
		# which is acceptable for this casual input style).
		_pan_velocity = (-avg * 60.0 / _camera.zoom.x).limit_length(max_velocity)
	_velocity_samples.clear()


# ---------------------------------------------------------------------------
# Velocity sampling for momentum (US2)
# ---------------------------------------------------------------------------

func _record_velocity_sample(screen_delta: Vector2) -> void:
	_velocity_samples.append(screen_delta)
	while _velocity_samples.size() > _VELOCITY_SAMPLE_COUNT:
		_velocity_samples.pop_front()


# ---------------------------------------------------------------------------
# Zoom helpers — PC / web (mouse wheel, keyboard) and touch (pinch)
# ---------------------------------------------------------------------------

## Apply an additive zoom delta and clamp to [zoom_min, zoom_max].
func _apply_zoom(delta_z: float) -> void:
	var new_z: float = clamp(_camera.zoom.x + delta_z, zoom_min, zoom_max)
	_camera.zoom = Vector2(new_z, new_z)


# --- Pinch-zoom (US3) ---

func _start_pinch() -> void:
	if _touch_points.size() < 2:
		return
	_pinch_initial_distance = _pinch_current_distance()
	_pinch_initial_zoom = _camera.zoom.x
	_pinch_active = true
	_pan_velocity = Vector2.ZERO  # discard pan momentum when pinch starts


func _update_pinch() -> void:
	if _touch_points.size() < 2 or _pinch_initial_distance <= 0.0:
		return
	var scale: float = _pinch_current_distance() / _pinch_initial_distance
	var new_z: float = clamp(_pinch_initial_zoom * scale, zoom_min, zoom_max)
	_camera.zoom = Vector2(new_z, new_z)


## Returns the current screen-space distance between the two active touch points.
func _pinch_current_distance() -> float:
	var keys: Array = _touch_points.keys()
	var a: Vector2 = _touch_points[keys[0]]
	var b: Vector2 = _touch_points[keys[1]]
	return a.distance_to(b)


# ---------------------------------------------------------------------------
# Double-tap re-centre (US4)
# ---------------------------------------------------------------------------

func _recentre_camera() -> void:
	_camera.position = Vector2.ZERO
	_pan_velocity = Vector2.ZERO
	_dragging = false
	_velocity_samples.clear()
	# Mark as a consumed gesture so PlacementController does not place a tile
	_was_drag = true
