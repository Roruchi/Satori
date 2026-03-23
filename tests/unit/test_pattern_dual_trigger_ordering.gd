extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func test_dual_trigger_ordering_is_deterministic_by_discovery_id() -> void:
	var scheduler := PatternScanScheduler.new()
	add_child(scheduler)

	var cluster := PatternDefinition.new()
	cluster.discovery_id = "disc_b"
	cluster.pattern_type = PatternDefinition.PatternType.CLUSTER
	cluster.required_biomes = [BiomeType.Value.FOREST]
	cluster.size_threshold = 3

	var shape := PatternDefinition.new()
	shape.discovery_id = "disc_a"
	shape.pattern_type = PatternDefinition.PatternType.SHAPE
	shape.shape_recipe = [
		{"offset": Vector2i(0, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(1, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(2, 0), "biome": BiomeType.Value.FOREST},
	]

	var matcher := PatternMatcher.new()
	matcher.set_patterns([cluster, shape])
	scheduler.set_matcher_for_testing(matcher)

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)
	scheduler.set_grid_provider(func() -> RefCounted:
		return grid
	)

	var emitted: Array[String] = []
	scheduler.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)

	scheduler.enqueue_scan(Vector2i(2, 0))
	await get_tree().process_frame

	assert_eq(emitted, ["disc_a", "disc_b"], "Dual-trigger ordering must remain deterministic")
