extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func _create_temp_pattern_dir() -> String:
	var base := "user://pattern_addition_tests"
	DirAccess.make_dir_recursive_absolute(base)
	return base

func _create_shape_pattern() -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_new_shape"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 3
	return pattern

func test_new_pattern_resource_is_detected_without_engine_code_changes() -> void:
	var temp_dir := _create_temp_pattern_dir()
	var new_pattern_path := "%s/new_pattern.tres" % temp_dir
	assert_eq(ResourceSaver.save(_create_shape_pattern(), new_pattern_path), OK)

	var matcher := PatternMatcher.new()
	matcher.reload_patterns_from_dir(temp_dir)

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)

	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_new_shape"], "Matcher should detect newly added pattern resource with no code changes")
