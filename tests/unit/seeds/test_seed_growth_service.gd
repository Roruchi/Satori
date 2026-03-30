extends GutTest

func test_try_plant_in_real_time_starts_growing_seed() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test"
	recipe.tier = 1
	recipe.produces_biome = BiomeType.Value.STONE
	assert_true(service.try_plant(Vector2i(1, 0), recipe))
	var seed: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_not_null(seed)
	assert_eq(seed.state, SeedState.Value.GROWING)
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

func test_growth_duration_defaults_to_real_time_seconds() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test"
	recipe.tier = 2
	recipe.produces_biome = BiomeType.Value.WETLANDS
	assert_true(service.try_plant(Vector2i(1, 0), recipe))
	var seed_before: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_before.state, SeedState.Value.GROWING)
	assert_eq(seed_before.growth_duration, 10.0)
	service.queue_free()

func test_growth_speed_multiplier_reduces_real_time_duration() -> void:
	var service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	add_child(service)
	service.set_growth_speed_multiplier(4.0)
	var recipe: SeedRecipe = SeedRecipe.new()
	recipe.recipe_id = &"test_speed"
	recipe.tier = 1
	recipe.produces_biome = BiomeType.Value.STONE
	assert_true(service.try_plant(Vector2i(3, 0), recipe))
	var seed: SeedInstance = service.get_tracker().get_at(Vector2i(3, 0))
	assert_not_null(seed)
	assert_eq(seed.state, SeedState.Value.GROWING)
	assert_eq(seed.growth_duration, 2.5)
	service.queue_free()

func test_ku_unlock_to_craft_flow_requires_mist_stag_gift() -> void:
	var root: Node = get_tree().root
	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
		await get_tree().process_frame
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()
	assert_eq(alchemy.is_ku_unlocked(), false, "Ku should start locked")
	assert_null(alchemy.lookup_recipe([GodaiElement.Value.CHI, GodaiElement.Value.KU]), "Ku recipe should not resolve while locked")
	SpiritGiftProcessor.process_gift(SpiritGiftType.Value.KU_UNLOCK, &"")
	assert_eq(alchemy.is_ku_unlocked(), true, "Ku should unlock after KU_UNLOCK gift")
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.KU), 3, "Ku should start with full 3/3 charges on unlock")
	var ku_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.CHI, GodaiElement.Value.KU])
	assert_not_null(ku_recipe, "Ku recipe should resolve after unlock")
	assert_eq(ku_recipe.produces_biome, BiomeType.Value.SACRED_STONE)
	alchemy.queue_free()

func test_repeated_ku_unlock_gift_is_idempotent() -> void:
	var root: Node = get_tree().root
	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
		await get_tree().process_frame
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()
	watch_signals(alchemy)
	SpiritGiftProcessor.process_gift(SpiritGiftType.Value.KU_UNLOCK, &"")
	assert_signal_emitted(alchemy, "element_unlocked")
	var first_count: int = get_signal_emit_count(alchemy, "element_unlocked")
	SpiritGiftProcessor.process_gift(SpiritGiftType.Value.KU_UNLOCK, &"")
	var second_count: int = get_signal_emit_count(alchemy, "element_unlocked")
	assert_eq(first_count, 1, "First Ku unlock should emit exactly once")
	assert_eq(second_count, 1, "Repeated Ku unlock should not emit again")
	alchemy.queue_free()
