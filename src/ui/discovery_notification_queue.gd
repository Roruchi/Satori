class_name DiscoveryNotificationQueue
extends Node

var _queue: Array[DiscoveryPayload] = []
var _active: bool = false
var _timer: float = 0.0
var _dismiss_token: int = 0

signal notification_shown(payload: DiscoveryPayload)
signal notification_dismissed()

func enqueue(payload: DiscoveryPayload) -> void:
	_queue.append(payload)
	if not _active:
		_advance()

func get_queue_size() -> int:
	return _queue.size()

func is_active() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_dismiss_current()

func _advance() -> void:
	_dismiss_token += 1
	if _queue.is_empty():
		_active = false
		return
	_active = true
	var payload: DiscoveryPayload = _queue.pop_front()
	_timer = payload.duration_seconds
	notification_shown.emit(payload)
	var token: int = _dismiss_token
	if is_inside_tree() and _timer > 0.0:
		get_tree().create_timer(_timer).timeout.connect(func() -> void:
			_dismiss_current(token)
		)

func _dismiss_current(token: int = -1) -> void:
	if token >= 0 and token != _dismiss_token:
		return
	if not _active:
		return
	notification_dismissed.emit()
	_advance()
