extends GutTest

func test_registry_prevents_duplicate_discovery_id_across_repeated_scans() -> void:
	var registry := DiscoveryRegistry.new()
	var matcher := PatternMatcher.new()
	matcher.set_discovery_registry(registry)

	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_once"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 2
	matcher.set_patterns([pattern])

	var grid_script := preload("res://src/grid/GridMap.gd")
	var grid := grid_script.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)

	var first_pass: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		first_pass.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(first_pass, ["disc_once"], "First qualifying scan should emit once")

	var second_pass: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		second_pass.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(second_pass, [], "Discovery should not emit again after registry contains the ID")
	assert_true(registry.has_discovery("disc_once"), "Discovery ID should be persisted in registry")
