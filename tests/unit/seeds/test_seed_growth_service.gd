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
	assert_eq(seed_before.growth_duration, 10.0)
	service.set_mode(GrowthMode.Value.INSTANT)
	var seed_after: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_after.state, SeedState.Value.READY)
	service.set_mode(GrowthMode.Value.REAL_TIME)
	var seed_after_back_to_rt: SeedInstance = service.get_tracker().get_at(Vector2i(1, 0))
	assert_eq(seed_after_back_to_rt.state, SeedState.Value.READY)
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
