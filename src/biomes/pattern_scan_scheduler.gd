class_name PatternScanScheduler
extends Node

const PatternMatcherScript = preload("res://src/biomes/pattern_matcher.gd")

signal scan_requested(scan_id: int, placement_coord: Vector2i)
signal scan_completed(scan_id: int, duration_ms: float)
signal discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i])
signal discovery_blocked(discovery_id: String, triggering_coords: Array[Vector2i], reason: String)
signal scan_metrics_updated(last_duration_ms: float, average_duration_ms: float, max_duration_ms: float, scan_count: int)

var _queue: Array[Vector2i] = []
var _is_scanning: bool = false
var _scan_counter: int = 0
var _total_scan_duration_ms: float = 0.0
var _max_scan_duration_ms: float = 0.0
var _last_scan_duration_ms: float = 0.0
var _matcher: RefCounted
var _grid_provider: Callable

func _init() -> void:
	_attach_matcher(PatternMatcherScript.new())

func _attach_matcher(matcher: RefCounted) -> void:
	if _matcher != null and _matcher.has_signal("discovery_triggered") and _matcher.discovery_triggered.is_connected(_on_matcher_discovery_triggered):
		_matcher.discovery_triggered.disconnect(_on_matcher_discovery_triggered)
	if _matcher != null and _matcher.has_signal("discovery_blocked") and _matcher.discovery_blocked.is_connected(_on_matcher_discovery_blocked):
		_matcher.discovery_blocked.disconnect(_on_matcher_discovery_blocked)
	_matcher = matcher
	_matcher.discovery_triggered.connect(_on_matcher_discovery_triggered)
	if _matcher.has_signal("discovery_blocked"):
		_matcher.discovery_blocked.connect(_on_matcher_discovery_blocked)

func set_matcher_for_testing(matcher: RefCounted) -> void:
	_attach_matcher(matcher)

func set_grid_provider(provider: Callable) -> void:
	_grid_provider = provider

func hydrate_registry(ids: Array[String]) -> void:
	_matcher.get_discovery_registry().mark_discoveries(ids)

func get_queue_size() -> int:
	return _queue.size()

func get_last_scan_duration_ms() -> float:
	return _last_scan_duration_ms

func get_average_scan_duration_ms() -> float:
	if _scan_counter == 0:
		return 0.0
	return _total_scan_duration_ms / float(_scan_counter)

func get_max_scan_duration_ms() -> float:
	return _max_scan_duration_ms

func _ready() -> void:
	if _grid_provider.is_null():
		_grid_provider = Callable(self, "_default_grid_provider")

	# GameState emits tile_placed and tile_mixed on grid changes.
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		if game_state.has_signal("tile_placed"):
			game_state.tile_placed.connect(_on_tile_placed)
		if game_state.has_signal("tile_mixed"):
			game_state.tile_mixed.connect(_on_tile_mixed)
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_signal("bloom_confirmed"):
		growth_service.bloom_confirmed.connect(_on_bloom_confirmed)

	# Hydrate registry from persisted discoveries on startup
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence != null and persistence.has_method("get_discovered_ids"):
		var ids: Array[String] = persistence.get_discovered_ids()
		if not ids.is_empty():
			_matcher.get_discovery_registry().mark_discoveries(ids)

	# Hydrate registry with already-summoned spirit IDs so spirit patterns
	# do not re-trigger after an app restart.
	var spirit_persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if spirit_persistence != null and spirit_persistence.has_method("get_summoned_ids"):
		var spirit_ids: Array[String] = spirit_persistence.get_summoned_ids()
		if not spirit_ids.is_empty():
			_matcher.get_discovery_registry().mark_discoveries(spirit_ids)

func _default_grid_provider() -> RefCounted:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return null
	return game_state.get("grid")

func _on_matcher_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	discovery_triggered.emit(discovery_id, triggering_coords)

func _on_matcher_discovery_blocked(discovery_id: String, triggering_coords: Array[Vector2i], reason: String) -> void:
	discovery_blocked.emit(discovery_id, triggering_coords, reason)

func _on_tile_placed(coord: Vector2i, _tile: GardenTile) -> void:
	enqueue_scan(coord)


func _on_tile_mixed(coord: Vector2i, _tile: GardenTile) -> void:
	enqueue_scan(coord)

func _on_bloom_confirmed(coord: Vector2i, _biome: int) -> void:
	enqueue_scan(coord)

func enqueue_scan(placement_coord: Vector2i) -> void:
	_queue.append(placement_coord)
	if not _is_scanning:
		call_deferred("_run_next_scan")

func _run_next_scan() -> void:
	if _is_scanning or _queue.is_empty():
		return

	_is_scanning = true
	while not _queue.is_empty():
		var placement_coord: Vector2i = _queue.pop_front()
		_scan_counter += 1
		var scan_id := _scan_counter

		var start_usec := Time.get_ticks_usec()
		scan_requested.emit(scan_id, placement_coord)

		var grid: RefCounted = _grid_provider.call()
		if grid != null:
			_matcher.scan_and_emit(grid)

		var duration_ms := float(Time.get_ticks_usec() - start_usec) / 1000.0
		_last_scan_duration_ms = duration_ms
		_total_scan_duration_ms += duration_ms
		if duration_ms > _max_scan_duration_ms:
			_max_scan_duration_ms = duration_ms

		scan_completed.emit(scan_id, duration_ms)
		scan_metrics_updated.emit(
			_last_scan_duration_ms,
			get_average_scan_duration_ms(),
			get_max_scan_duration_ms(),
			_scan_counter
		)

	_is_scanning = false
	if not _queue.is_empty():
		call_deferred("_run_next_scan")
