extends GutTest

func test_registry_loads_tier1_and_tier2_recipes() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	assert_eq(registry.all_known_recipes().size(), 10)

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
