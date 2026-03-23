extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func _make_cluster_pattern(discovery_id: String, biome: int, threshold: int) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = discovery_id
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [biome]
	pattern.size_threshold = threshold
	return pattern

func _populate_rect(grid: RefCounted, width: int, height: int, biome: int) -> void:
	for x in range(width):
		for y in range(height):
			grid.place_tile(Vector2i(x, y), biome)

func test_1000_tile_scan_stays_under_budget_and_emits_dual_trigger_same_pass() -> void:
	var scheduler := PatternScanScheduler.new()
	add_child(scheduler)

	var matcher := PatternMatcher.new()
	matcher.set_patterns([
		_make_cluster_pattern("disc_cluster_10", BiomeType.Value.FOREST, 10),
		_make_cluster_pattern("disc_cluster_25", BiomeType.Value.FOREST, 25),
	])
	scheduler.set_matcher_for_testing(matcher)

	var grid := GridMapScript.new()
	_populate_rect(grid, 40, 25, BiomeType.Value.FOREST)
	scheduler.set_grid_provider(func() -> RefCounted:
		return grid
	)

	var events: Array[String] = []
	var discovered_ids: Array[String] = []

	scheduler.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		events.append("d:%s" % discovery_id)
		discovered_ids.append(discovery_id)
	)
	scheduler.scan_completed.connect(func(_scan_id: int, _duration_ms: float) -> void:
		events.append("completed")
	)

	scheduler.enqueue_scan(Vector2i(39, 24))
	await get_tree().process_frame

	assert_eq(discovered_ids, ["disc_cluster_10", "disc_cluster_25"], "Dual triggers must be emitted in deterministic ID order")
	assert_eq(events.size(), 3, "Two discoveries and one completion event are expected")
	assert_eq(events[2], "completed", "Both discovery signals should emit during the scan pass before completion")
	assert_lt(scheduler.get_last_scan_duration_ms(), 16.0, "1,000-tile scan should stay under 16ms budget")
