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

func test_ku_mapping_cardinality_integrity() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var ku_recipe_ids: Array[StringName] = [&"recipe_chi_ku", &"recipe_sui_ku", &"recipe_ka_ku", &"recipe_fu_ku"]
	var expected_recipe_to_biome: Dictionary = {
		&"recipe_chi_ku": BiomeType.Value.SACRED_STONE,
		&"recipe_sui_ku": BiomeType.Value.VEIL_MARSH,
		&"recipe_ka_ku": BiomeType.Value.EMBER_SHRINE,
		&"recipe_fu_ku": BiomeType.Value.CLOUD_RIDGE,
	}
	for recipe_id: StringName in ku_recipe_ids:
		assert_true(registry.is_recipe_known(recipe_id), "Recipe should exist: %s" % String(recipe_id))
		var by_id: SeedRecipe = null
		for candidate: SeedRecipe in registry.all_known_recipes():
			if candidate.recipe_id == recipe_id:
				by_id = candidate
				break
		assert_not_null(by_id, "Expected recipe resource for %s" % String(recipe_id))
		assert_eq(by_id.produces_biome, expected_recipe_to_biome[recipe_id], "Recipe-to-biome mismatch for %s" % String(recipe_id))

	var spirit_catalog: SpiritCatalogData = SpiritCatalogData.new()
	var deity_spirits: Array[String] = ["spirit_oyamatsumi", "spirit_suijin", "spirit_kagutsuchi", "spirit_fujin"]
	var spirit_entries: Array[Dictionary] = spirit_catalog.get_entries()
	for spirit_id: String in deity_spirits:
		var found: bool = false
		for entry: Dictionary in spirit_entries:
			if str(entry.get("spirit_id", "")) == spirit_id:
				found = true
				break
		assert_true(found, "Deity spirit mapping missing: %s" % spirit_id)

	var discovery_data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	var ku_structures: Array[String] = [
		"disc_iwakura_sanctum",
		"disc_misogi_spring_shrine",
		"disc_eternal_kagura_hall",
		"disc_heavenwind_torii",
	]
	var tier2_entries: Array[Dictionary] = discovery_data.get_tier2_entries()
	for discovery_id: String in ku_structures:
		var found_discovery: bool = false
		for entry: Dictionary in tier2_entries:
			if str(entry.get("discovery_id", "")) == discovery_id:
				found_discovery = true
				break
		assert_true(found_discovery, "Ku structure mapping missing: %s" % discovery_id)
