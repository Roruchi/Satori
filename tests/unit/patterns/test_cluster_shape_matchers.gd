extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func test_cluster_pattern_triggers_when_threshold_is_met() -> void:
	var matcher := PatternMatcher.new()
	var cluster := PatternDefinition.new()
	cluster.discovery_id = "disc_cluster"
	cluster.pattern_type = PatternDefinition.PatternType.CLUSTER
	cluster.required_biomes = [BiomeType.Value.FOREST]
	cluster.size_threshold = 3
	matcher.set_patterns([cluster])

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_cluster"])

func test_shape_pattern_triggers_for_hex_offsets() -> void:
	var matcher := PatternMatcher.new()
	var shape := PatternDefinition.new()
	shape.discovery_id = "disc_shape"
	shape.pattern_type = PatternDefinition.PatternType.SHAPE
	# Hex-valid offsets: (0,0) anchor, (1,0) E neighbor, (0,1) SE neighbor
	shape.shape_recipe = [
		{"offset": Vector2i(0, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(1, 0), "biome": BiomeType.Value.WATER},
		{"offset": Vector2i(0, 1), "biome": BiomeType.Value.STONE},
	]
	matcher.set_patterns([shape])

	var grid := GridMapScript.new()
	# Place tiles at anchor (5, 3) and its hex neighbors (6,3) and (5,4)
	grid.place_tile(Vector2i(5, 3), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(6, 3), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(5, 4), BiomeType.Value.STONE)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_shape"])


func test_shape_pattern_triggers_for_rotated_hex_offsets() -> void:
	var matcher := PatternMatcher.new()
	var shape := PatternDefinition.new()
	shape.discovery_id = "disc_shape_rotated"
	shape.pattern_type = PatternDefinition.PatternType.SHAPE
	shape.shape_recipe = [
		{"offset": Vector2i(0, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(1, 0), "biome": BiomeType.Value.WATER},
		{"offset": Vector2i(0, 1), "biome": BiomeType.Value.STONE},
	]
	matcher.set_patterns([shape])

	var grid := GridMapScript.new()
	# 60-degree clockwise rotation of the recipe around the anchor.
	grid.place_tile(Vector2i(5, 3), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(5, 4), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(4, 4), BiomeType.Value.STONE)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_shape_rotated"])
