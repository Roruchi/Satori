extends GutTest

func _create_temp_pattern_dir() -> String:
	var base := "user://pattern_loader_tests"
	DirAccess.make_dir_recursive_absolute(base)
	return base

func _save_resource(path: String, resource: Resource) -> int:
	return ResourceSaver.save(resource, path)

func _create_valid_pattern(id: String) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = id
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 3
	return pattern

func test_loader_ingests_valid_patterns_and_skips_malformed_resources() -> void:
	var temp_dir := _create_temp_pattern_dir()
	var valid_path := "%s/valid_cluster.tres" % temp_dir
	var malformed_path := "%s/malformed_resource.tres" % temp_dir
	var invalid_path := "%s/invalid_pattern.tres" % temp_dir

	assert_eq(_save_resource(valid_path, _create_valid_pattern("disc_valid")), OK)
	assert_eq(_save_resource(malformed_path, Resource.new()), OK)
	assert_eq(_save_resource(invalid_path, PatternDefinition.new()), OK)

	var loader := PatternLoader.new()
	var patterns := loader.load_patterns(temp_dir)

	assert_eq(patterns.size(), 1, "Only one valid pattern definition should be loaded")
	assert_eq(patterns[0].discovery_id, "disc_valid")
