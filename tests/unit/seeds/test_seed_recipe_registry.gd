extends GutTest

# Ku-focused recipe coverage

func test_registry_loads_tier1_and_tier2_recipes() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	assert_not_null(registry.lookup([GodaiElement.Value.CHI]), "Base Chi recipe should exist")
	assert_not_null(registry.lookup([GodaiElement.Value.SUI]), "Base Sui recipe should exist")
	assert_not_null(registry.lookup([GodaiElement.Value.KA]), "Base Ka recipe should exist")
	assert_not_null(registry.lookup([GodaiElement.Value.FU]), "Base Fu recipe should exist")
	assert_not_null(registry.lookup([GodaiElement.Value.CHI, GodaiElement.Value.KU]), "Ku pairing Chi+Ku should exist in registry")
	assert_not_null(registry.lookup([GodaiElement.Value.SUI, GodaiElement.Value.KU]), "Ku pairing Sui+Ku should exist in registry")
	assert_not_null(registry.lookup([GodaiElement.Value.KA, GodaiElement.Value.KU]), "Ku pairing Ka+Ku should exist in registry")
	assert_not_null(registry.lookup([GodaiElement.Value.FU, GodaiElement.Value.KU]), "Ku pairing Fu+Ku should exist in registry")

func test_lookup_is_order_independent_for_chi_sui() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var a: SeedRecipe = registry.lookup([0, 1])
	var b: SeedRecipe = registry.lookup([1, 0])
	assert_not_null(a)
	assert_not_null(b)
	assert_eq(a.produces_biome, BiomeType.Value.CLAY)
	assert_eq(b.produces_biome, BiomeType.Value.CLAY)

func test_unknown_combo_returns_null() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	assert_null(registry.lookup([0, 1, 2]))

func test_tier3_recipe_requires_unlock() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var tier3: SeedRecipe = SeedRecipe.new()
	tier3.recipe_id = &"recipe_chi_sui_ka"
	tier3.elements = [0, 1, 2]
	tier3.tier = 3
	tier3.produces_biome = BiomeType.Value.CLAY
	tier3.spirit_unlock_id = &"spirit_river_otter"
	registry.add_recipe_for_testing(tier3)
	assert_null(registry.lookup([0, 1, 2]))
	registry.unlock_recipe(&"recipe_chi_sui_ka")
	assert_not_null(registry.lookup([0, 1, 2]))

func test_ku_pairings_are_valid_and_order_independent_after_unlock() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()
	alchemy.unlock_element(GodaiElement.Value.KU)
	var expected: Dictionary = {
		"0_4": BiomeType.Value.SACRED_STONE,
		"1_4": BiomeType.Value.VEIL_MARSH,
		"2_4": BiomeType.Value.EMBER_SHRINE,
		"3_4": BiomeType.Value.CLOUD_RIDGE,
	}
	for key: String in expected.keys():
		var parts: PackedStringArray = key.split("_")
		var a: int = int(parts[0])
		var b: int = int(parts[1])
		var recipe_forward: SeedRecipe = alchemy.lookup_recipe([a, b])
		var recipe_reverse: SeedRecipe = alchemy.lookup_recipe([b, a])
		assert_not_null(recipe_forward, "Expected Ku recipe for %s" % key)
		assert_not_null(recipe_reverse, "Expected reverse Ku recipe for %s" % key)
		assert_eq(recipe_forward.produces_biome, expected[key], "Unexpected biome for %s" % key)
		assert_eq(recipe_reverse.produces_biome, expected[key], "Unexpected reverse biome for %s" % key)
	alchemy.queue_free()

func test_solo_ku_and_unknown_ku_combinations_return_null() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()
	alchemy.unlock_element(GodaiElement.Value.KU)
	assert_null(alchemy.lookup_recipe([GodaiElement.Value.KU]), "Solo Ku should remain invalid")
	assert_null(alchemy.lookup_recipe([GodaiElement.Value.KU, GodaiElement.Value.KU]), "Duplicate Ku should remain invalid")
	assert_null(alchemy.lookup_recipe([GodaiElement.Value.CHI, GodaiElement.Value.SUI, GodaiElement.Value.KU]), "Undefined 3-element Ku combo should remain invalid")
	alchemy.queue_free()

func test_existing_non_ku_pairing_compatibility_is_preserved() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var clay_recipe: SeedRecipe = registry.lookup([GodaiElement.Value.CHI, GodaiElement.Value.SUI])
	assert_not_null(clay_recipe, "Chi+Sui must stay craftable")
	assert_eq(clay_recipe.produces_biome, BiomeType.Value.CLAY, "Chi+Sui must still produce Clay")
