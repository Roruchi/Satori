extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func _make_pattern(discovery_id: String, threshold: int) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = discovery_id
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = threshold
	return pattern

func test_distinct_discoveries_emit_once_each_in_same_scan_pass() -> void:
	var scheduler := PatternScanScheduler.new()
	add_child(scheduler)

	var matcher := PatternMatcher.new()
	matcher.set_patterns([
		_make_pattern("disc_alpha", 10),
		_make_pattern("disc_beta", 25),
	])
	scheduler.set_matcher_for_testing(matcher)

	var grid := GridMapScript.new()
	for x in range(30):
		grid.place_tile(Vector2i(x, 0), BiomeType.Value.FOREST)
	scheduler.set_grid_provider(func() -> RefCounted:
		return grid
	)

	var emitted: Array[String] = []
	scheduler.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)

	scheduler.enqueue_scan(Vector2i(29, 0))
	scheduler.enqueue_scan(Vector2i(28, 0))
	await get_tree().process_frame

	assert_eq(emitted, ["disc_alpha", "disc_beta"], "Distinct discovery IDs should emit once, then stay suppressed in queued follow-up scans")
