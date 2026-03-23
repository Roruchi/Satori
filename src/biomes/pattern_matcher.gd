class_name PatternMatcher
extends RefCounted

signal discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i])

var _loader: PatternLoader
var _spatial_query: SpatialQuery
var _patterns: Array[PatternDefinition] = []
var _discovery_registry: DiscoveryRegistry
var _cluster_matcher: ClusterMatcher
var _shape_matcher: ShapeMatcher
var _ratio_proximity_matcher: RatioProximityMatcher
var _compound_matcher: CompoundMatcher

func _init() -> void:
	_loader = PatternLoader.new()
	_spatial_query = SpatialQuery.new()
	_discovery_registry = DiscoveryRegistry.new()
	_cluster_matcher = ClusterMatcher.new()
	_shape_matcher = ShapeMatcher.new()
	_ratio_proximity_matcher = RatioProximityMatcher.new()
	_compound_matcher = CompoundMatcher.new()
	reload_patterns()

func reload_patterns() -> void:
	_patterns = _loader.load_patterns()

func reload_patterns_from_dir(pattern_dir: String) -> void:
	_patterns = _loader.load_patterns(pattern_dir)

func set_patterns(patterns: Array[PatternDefinition]) -> void:
	_patterns = patterns.duplicate()

func set_discovery_registry(registry: DiscoveryRegistry) -> void:
	_discovery_registry = registry

func get_discovery_registry() -> DiscoveryRegistry:
	return _discovery_registry

func scan_grid(grid: RefCounted) -> Array[DiscoverySignal]:
	var discoveries: Array[DiscoverySignal] = []
	if _patterns.is_empty():
		return discoveries
	if not grid.has_method("get_tile") or not grid.has_method("has_tile"):
		return discoveries
	if grid.tiles.is_empty():
		return discoveries
	var in_scan_discoveries: Dictionary = {}

	for pattern in _patterns:
		if pattern.pattern_type == PatternDefinition.PatternType.COMPOUND:
			continue
		var payload := _evaluate_pattern(pattern, grid, in_scan_discoveries)
		if payload != null:
			discoveries.append(payload)
			in_scan_discoveries[payload.discovery_id] = true

	var processed_compound_ids: Dictionary = {}
	var progress := true
	while progress:
		progress = false
		for pattern in _patterns:
			if pattern.pattern_type != PatternDefinition.PatternType.COMPOUND:
				continue
			if processed_compound_ids.has(pattern.discovery_id):
				continue

			var payload := _evaluate_pattern(pattern, grid, in_scan_discoveries)
			if payload == null:
				continue

			discoveries.append(payload)
			in_scan_discoveries[payload.discovery_id] = true
			processed_compound_ids[payload.discovery_id] = true
			progress = true

	for pattern in _patterns:
		if pattern.pattern_type == PatternDefinition.PatternType.COMPOUND and in_scan_discoveries.has(pattern.discovery_id):
			processed_compound_ids[pattern.discovery_id] = true

	for pattern in _patterns:
		if pattern.pattern_type == PatternDefinition.PatternType.COMPOUND and processed_compound_ids.has(pattern.discovery_id):
			continue
		if pattern.pattern_type == PatternDefinition.PatternType.COMPOUND:
			var payload := _evaluate_pattern(pattern, grid, in_scan_discoveries)
			if payload != null:
				discoveries.append(payload)
				in_scan_discoveries[payload.discovery_id] = true

	discoveries.sort_custom(func(a: DiscoverySignal, b: DiscoverySignal) -> bool:
		return a.discovery_id < b.discovery_id
	)
	return discoveries

func _evaluate_pattern(pattern: PatternDefinition, grid: RefCounted, in_scan_discoveries: Dictionary) -> DiscoverySignal:
	match pattern.pattern_type:
		PatternDefinition.PatternType.CLUSTER:
			return _cluster_matcher.evaluate(pattern, grid, _spatial_query)
		PatternDefinition.PatternType.SHAPE:
			return _shape_matcher.evaluate(pattern, grid, _spatial_query)
		PatternDefinition.PatternType.RATIO_PROXIMITY:
			return _ratio_proximity_matcher.evaluate(pattern, grid, _spatial_query)
		PatternDefinition.PatternType.COMPOUND:
			if not _compound_matcher.prerequisites_met(pattern, _discovery_registry, in_scan_discoveries):
				return null
			if not pattern.shape_recipe.is_empty():
				return _shape_matcher.evaluate(pattern, grid, _spatial_query)
			if pattern.neighbour_requirements.has("radius"):
				return _ratio_proximity_matcher.evaluate(pattern, grid, _spatial_query)
			return _cluster_matcher.evaluate(pattern, grid, _spatial_query)
	return null

func scan_and_emit(grid: RefCounted) -> Array[DiscoverySignal]:
	var discoveries := scan_grid(grid)
	var emitted_discoveries: Array[DiscoverySignal] = []
	var newly_discovered_ids: Array[String] = []

	for payload in discoveries:
		if _discovery_registry.has_discovery(payload.discovery_id):
			continue
		discovery_triggered.emit(payload.discovery_id, payload.triggering_coords)
		emitted_discoveries.append(payload)
		newly_discovered_ids.append(payload.discovery_id)

	if not newly_discovered_ids.is_empty():
		_discovery_registry.mark_discoveries_atomically(newly_discovered_ids)

	return emitted_discoveries

