class_name SpiritService
extends Node

signal spirit_summoned(spirit_id: String, instance: SpiritInstance)
signal riddle_hint_triggered(spirit_id: String, riddle_text: String)
signal sky_whale_event_triggered()

const _PatternLoaderScript = preload("res://src/biomes/pattern_loader.gd")

var _catalog: SpiritCatalog
var _spawner: SpiritSpawner
var _riddle_evaluator: SpiritRiddleEvaluator
var _sky_whale_evaluator: SkyWhaleEvaluator
var _active_instances: Dictionary = {}
var _riddle_shown: Dictionary = {}
var _spirit_patterns: Array[PatternDefinition] = []

func _ready() -> void:
	_catalog = SpiritCatalog.new()
	_catalog.load_from_data(SpiritCatalogData.new())
	_riddle_evaluator = SpiritRiddleEvaluator.new()
	_sky_whale_evaluator = SkyWhaleEvaluator.new()
	_spawner = SpiritSpawner.new()
	var loader: PatternLoader = _PatternLoaderScript.new()
	_spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("tile_placed"):
		game_state.tile_placed.connect(_on_tile_placed)
	call_deferred("_setup_spawner")
	call_deferred("restore_from_persistence")

func set_spawner_parent(parent: Node) -> void:
	_spawner.set_parent(parent)

func _setup_spawner() -> void:
	var garden_view: Node = get_node_or_null("../GardenView")
	if garden_view == null:
		return
	var spirit_layer: Node2D = garden_view.get_node_or_null("SpiritLayer2D")
	if spirit_layer == null:
		spirit_layer = Node2D.new()
		spirit_layer.name = "SpiritLayer2D"
		garden_view.add_child(spirit_layer)
	_spawner.set_parent(spirit_layer)

func restore_from_persistence() -> void:
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence == null:
		return
	for data: Dictionary in persistence.get_instances():
		var instance: SpiritInstance = SpiritInstance.deserialize(data)
		if instance.spirit_id.is_empty():
			continue
		_active_instances[instance.spirit_id] = instance
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		_spawner.spawn(instance, entry)

func _on_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	if not discovery_id.begins_with("spirit_"):
		return
	if discovery_id == SkyWhaleEvaluator.SPIRIT_ID:
		return  # Sky Whale is triggered by tile_placed balance check, not by PatternMatcher
	if _active_instances.has(discovery_id):
		return
	_summon_spirit(discovery_id, triggering_coords)

func _summon_spirit(spirit_id: String, coords: Array[Vector2i]) -> void:
	var entry: Dictionary = _catalog.lookup(spirit_id)
	var wander_radius: int = int(entry.get("wander_radius", 4))
	var bounds: Rect2i = SpiritWanderBounds.from_coords(coords, wander_radius)
	var spawn: Vector2i = SpiritWanderBounds.centroid(coords)
	var instance: SpiritInstance = SpiritInstance.create(spirit_id, spawn, bounds)
	_active_instances[spirit_id] = instance
	_spawner.spawn(instance, entry)
	spirit_summoned.emit(spirit_id, instance)
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = game_state.grid
	if _sky_whale_evaluator.evaluate(grid) and not _active_instances.has(SkyWhaleEvaluator.SPIRIT_ID):
		_summon_sky_whale(grid)
	_evaluate_riddle_hints(grid)

func _evaluate_riddle_hints(grid: RefCounted) -> void:
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	var registry: DiscoveryRegistry = DiscoveryRegistry.new()
	if persistence != null and persistence.has_method("get_discovered_ids"):
		var ids: Array[String] = persistence.get_discovered_ids()
		registry.mark_discoveries(ids)
	for pattern: PatternDefinition in _spirit_patterns:
		var sid: String = pattern.discovery_id
		if _active_instances.has(sid):
			continue
		if _riddle_shown.has(sid):
			continue
		if _riddle_evaluator.evaluate_partial(pattern, grid, registry):
			_riddle_shown[sid] = true
			var entry: Dictionary = _catalog.lookup(sid)
			var riddle: String = str(entry.get("riddle_text", ""))
			riddle_hint_triggered.emit(sid, riddle)

func _summon_sky_whale(grid: RefCounted) -> void:
	var bounds: Rect2i = grid.garden_bounds
	var center: Vector2i = bounds.position + bounds.size / 2
	var entry: Dictionary = _catalog.lookup(SkyWhaleEvaluator.SPIRIT_ID)
	var wander_radius: int = int(entry.get("wander_radius", 50))
	var expanded_bounds: Rect2i = Rect2i(
		bounds.position - Vector2i(wander_radius, wander_radius),
		bounds.size + Vector2i(wander_radius * 2, wander_radius * 2)
	)
	var instance: SpiritInstance = SpiritInstance.create(SkyWhaleEvaluator.SPIRIT_ID, center, expanded_bounds)
	_active_instances[SkyWhaleEvaluator.SPIRIT_ID] = instance
	_spawner.spawn(instance, entry)
	spirit_summoned.emit(SkyWhaleEvaluator.SPIRIT_ID, instance)
	sky_whale_event_triggered.emit()
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)
