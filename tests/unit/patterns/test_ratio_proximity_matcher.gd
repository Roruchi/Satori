extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func test_ratio_proximity_pattern_triggers_for_required_neighbors() -> void:
	var matcher := PatternMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_ratio"
	pattern.pattern_type = PatternDefinition.PatternType.RATIO_PROXIMITY
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.neighbour_requirements = {
		"radius": 1,
		"biomes": {
			BiomeType.Value.WATER: 2,
			BiomeType.Value.STONE: 1,
		}
	}
	matcher.set_patterns([pattern])

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(-1, 0), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.STONE)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_ratio"])
