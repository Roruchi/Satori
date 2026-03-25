extends GutTest

func test_try_plant_in_instant_mode_creates_ready_seed() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	service.set_mode(GrowthMode.Value.INSTANT)
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test"
	recipe.tier = 1
	recipe.produces_biome = BiomeType.Value.STONE
	assert_true(service.try_plant(Vector2i(1, 0), recipe))
	var seed: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_not_null(seed)
	assert_eq(seed.state, SeedState.Value.READY)
	service.queue_free()

func test_try_plant_fails_when_slots_full() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	service.get_tracker().capacity = 1
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test"
	recipe.tier = 1
	recipe.produces_biome = BiomeType.Value.STONE
	assert_true(service.try_plant(Vector2i(1, 0), recipe))
	assert_false(service.try_plant(Vector2i(2, 0), recipe))
	service.queue_free()

func test_set_mode_instant_promotes_growing_seeds() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	service.set_mode(GrowthMode.Value.REAL_TIME)
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test"
	recipe.tier = 2
	recipe.produces_biome = BiomeType.Value.CLAY
	assert_true(service.try_plant(Vector2i(1, 0), recipe))
	var seed_before: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_before.state, SeedState.Value.GROWING)
	service.set_mode(GrowthMode.Value.INSTANT)
	var seed_after: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_after.state, SeedState.Value.READY)
	service.set_mode(GrowthMode.Value.REAL_TIME)
	var seed_after_back_to_rt: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_after_back_to_rt.state, SeedState.Value.READY)
	service.queue_free()
