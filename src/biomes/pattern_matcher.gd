class_name PatternMatcher
extends RefCounted

signal discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i])
signal discovery_blocked(discovery_id: String, triggering_coords: Array[Vector2i], reason: String)
const UNIQUE_ALREADY_BUILT_REASON: String = "unique_already_built"

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
	var cluster_region_cache: Dictionary = {}

	for pattern in _patterns:
		if pattern.pattern_type == PatternDefinition.PatternType.COMPOUND:
			continue
		if _discovery_registry.has_discovery(pattern.discovery_id):
			continue
		var payload: DiscoverySignal = _evaluate_pattern(pattern, grid, in_scan_discoveries, cluster_region_cache)
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
			if _discovery_registry.has_discovery(pattern.discovery_id):
				processed_compound_ids[pattern.discovery_id] = true
				continue

			var payload: DiscoverySignal = _evaluate_pattern(pattern, grid, in_scan_discoveries, cluster_region_cache)
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
			if _discovery_registry.has_discovery(pattern.discovery_id):
				continue
			var payload: DiscoverySignal = _evaluate_pattern(pattern, grid, in_scan_discoveries, cluster_region_cache)
			if payload != null:
				discoveries.append(payload)
				in_scan_discoveries[payload.discovery_id] = true

	discoveries.sort_custom(func(a: DiscoverySignal, b: DiscoverySignal) -> bool:
		return a.discovery_id < b.discovery_id
	)
	return discoveries

func _evaluate_pattern(pattern: PatternDefinition, grid: RefCounted, in_scan_discoveries: Dictionary, cluster_region_cache: Dictionary) -> DiscoverySignal:
	match pattern.pattern_type:
		PatternDefinition.PatternType.CLUSTER:
			return _evaluate_cluster_pattern(pattern, grid, cluster_region_cache)
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
			return _evaluate_cluster_pattern(pattern, grid, cluster_region_cache)
	return null

func _evaluate_cluster_pattern(pattern: PatternDefinition, grid: RefCounted, cluster_region_cache: Dictionary) -> DiscoverySignal:
	if pattern.required_biomes.is_empty():
		return null
	var required_biome: int = pattern.required_biomes[0]
	var cache_key: String = str(required_biome)
	var best_region: Array[Vector2i] = []
	if cluster_region_cache.has(cache_key):
		var cached_variant: Variant = cluster_region_cache.get(cache_key, [])
		if cached_variant is Array:
			for coord_variant: Variant in cached_variant as Array:
				if coord_variant is Vector2i:
					best_region.append(coord_variant as Vector2i)
	else:
		best_region = _cluster_matcher.find_best_region_for_biome(required_biome, grid, _spatial_query)
		cluster_region_cache[cache_key] = best_region
	return _cluster_matcher.discovery_for_region(pattern, best_region)

func scan_and_emit(grid: RefCounted) -> Array[DiscoverySignal]:
	var discoveries := scan_grid(grid)
	var emitted_discoveries: Array[DiscoverySignal] = []
	var newly_discovered_ids: Array[String] = []
	var emitted_this_scan: Dictionary = {}

	for payload in discoveries:
		if _discovery_registry.has_discovery(payload.discovery_id):
			continue
		if emitted_this_scan.has(payload.discovery_id):
			continue
		var satori_service: Node = Engine.get_main_loop().root.get_node_or_null("/root/SatoriService")
		if satori_service != null and satori_service.has_method("can_build_structure"):
			if not satori_service.can_build_structure(payload.discovery_id):
				discovery_blocked.emit(payload.discovery_id, payload.triggering_coords, UNIQUE_ALREADY_BUILT_REASON)
				if satori_service.has_method("block_structure_build"):
					satori_service.block_structure_build(payload.discovery_id, UNIQUE_ALREADY_BUILT_REASON)
				continue
		discovery_triggered.emit(payload.discovery_id, payload.triggering_coords)
		emitted_discoveries.append(payload)
		if not payload.discovery_id.begins_with("spirit_"):
			newly_discovered_ids.append(payload.discovery_id)
		emitted_this_scan[payload.discovery_id] = true

	if not newly_discovered_ids.is_empty():
		_discovery_registry.mark_discoveries_atomically(newly_discovered_ids)

	return emitted_discoveries
