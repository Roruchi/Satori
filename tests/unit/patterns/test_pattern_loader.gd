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

func test_pattern_definition_supports_progression_metadata_fields() -> void:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_meta"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 3
	pattern.tier = 3
	pattern.cap_increase = 1000
	pattern.is_unique = true
	pattern.housing_capacity = 4
	pattern.effect_type = "pagoda_passive"
	pattern.effect_params = {"passive_per_minute": 5}
	assert_eq(pattern.tier, 3)
	assert_eq(pattern.cap_increase, 1000)
	assert_true(pattern.is_unique)
	assert_eq(pattern.housing_capacity, 4)
	assert_eq(pattern.effect_type, "pagoda_passive")
	assert_eq(int(pattern.effect_params.get("passive_per_minute", 0)), 5)

func test_discovery_catalog_exposes_cap_and_unique_metadata() -> void:
	var data := DiscoveryCatalogData.new()
	var found_unique: bool = false
	var found_tier2: bool = false
	for entry: Dictionary in data.get_tier2_entries():
		var tier: int = int(entry.get("tier", 0))
		var cap: int = int(entry.get("cap_increase", 0))
		if tier == 2:
			found_tier2 = true
			assert_eq(cap, 250)
		if bool(entry.get("is_unique", false)):
			found_unique = true
			assert_eq(cap, 1000)
	assert_true(found_unique, "Expected at least one unique monument entry")
	assert_true(found_tier2, "Expected at least one tier2 structure entry")

func test_unique_monument_guard_blocks_duplicate_emission() -> void:
	var matcher := PatternMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_great_torii"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.CLOUD_RIDGE]
	pattern.size_threshold = 4
	var grid := preload("res://src/grid/GridMap.gd").new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.CLOUD_RIDGE)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.CLOUD_RIDGE)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.CLOUD_RIDGE)
	grid.place_tile(Vector2i(-1, 1), BiomeType.Value.CLOUD_RIDGE)
	matcher.set_patterns([pattern])

	var satori_service: SatoriServiceNode = SatoriServiceNode.new()
	satori_service.name = "SatoriService"
	get_tree().root.add_child(satori_service)
	satori_service.set_structures_for_testing([{"discovery_id": "disc_great_torii", "is_unique": true}])

	var blocked_count: int = 0
	matcher.discovery_blocked.connect(func(_id: String, _coords: Array[Vector2i], _reason: String) -> void:
		blocked_count += 1
	)
	matcher.scan_and_emit(grid)
	assert_eq(blocked_count, 1, "Duplicate unique monument should be blocked by matcher guard")
	satori_service.queue_free()
