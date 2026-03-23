extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func _make_cluster_pattern(discovery_id: String, biome: int, threshold: int) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = discovery_id
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [biome]
	pattern.size_threshold = threshold
	return pattern

func _populate_line(grid: RefCounted, count: int, biome: int) -> void:
	for x in range(count):
		grid.place_tile(Vector2i(x, 0), biome)

func test_async_enqueue_processes_queue_in_order() -> void:
	var scheduler := PatternScanScheduler.new()
	add_child(scheduler)

	var matcher := PatternMatcher.new()
	matcher.set_patterns([
		_make_cluster_pattern("disc_line_10", BiomeType.Value.FOREST, 10),
	])
	scheduler.set_matcher_for_testing(matcher)

	var grid := GridMapScript.new()
	_populate_line(grid, 10, BiomeType.Value.FOREST)
	scheduler.set_grid_provider(func() -> RefCounted:
		return grid
	)

	var requested: Array[int] = []
	var completed: Array[int] = []
	var discoveries: Array[String] = []

	scheduler.scan_requested.connect(func(scan_id: int, _coord: Vector2i) -> void:
		requested.append(scan_id)
	)
	scheduler.scan_completed.connect(func(scan_id: int, _duration_ms: float) -> void:
		completed.append(scan_id)
	)
	scheduler.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		discoveries.append(discovery_id)
	)

	scheduler.enqueue_scan(Vector2i(9, 0))
	scheduler.enqueue_scan(Vector2i(8, 0))
	await get_tree().process_frame

	assert_eq(requested, [1, 2], "Queued scans should keep FIFO order")
	assert_eq(completed, [1, 2], "Both queued scans should complete in order")
	assert_eq(discoveries, ["disc_line_10"], "Duplicate suppression should emit discovery only once across queued scans")
	assert_eq(scheduler.get_queue_size(), 0, "Queue should be drained after scan loop")
	assert_false(scheduler._is_scanning, "Scheduler should exit scanning state when queue is empty")
