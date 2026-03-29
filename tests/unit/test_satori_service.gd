extends GutTest

const EXPECTED_DEBUG_POUCH_CAPACITY: int = 4

func test_satori_condition_evaluator_biome_present_true() -> void:
	var gs: Node = Node.new()
	gs.name = "GameState"
	gs.set_script(load("res://src/autoloads/GameState.gd"))
	add_child(gs)
	gs._ready()
	var ok: bool = SatoriConditionEvaluator.evaluate([
		{"type": "biome_present", "biome": BiomeType.Value.STONE}
	])
	assert_true(ok)
	gs.queue_free()

func test_trigger_debug_safe_call() -> void:
	var settings: GardenSettingsNode = GardenSettingsNode.new()
	settings.name = "GardenSettings"
	add_child(settings)
	settings.growth_mode = GrowthMode.Value.INSTANT
	var growth_service: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	growth_service.name = "SeedGrowthService"
	add_child(growth_service)
	var track_before: int = growth_service.get_tracker().capacity
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.trigger_debug()
	service._complete_sequence()
	assert_eq(growth_service.get_pouch().capacity, EXPECTED_DEBUG_POUCH_CAPACITY)
	assert_eq(growth_service.get_tracker().capacity, track_before)
	service.queue_free()
	growth_service.queue_free()
	settings.queue_free()

func test_minute_tick_delta_formula_applies_housed_minus_double_unhoused() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(100)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 6,
		"unhoused_count": 2,
		"housed_by_island": {}
	})
	assert_eq(int(result["base_delta"]), 2)
	assert_eq(int(result["new_satori"]), 102)
	service.queue_free()

func test_minute_tick_clamps_to_zero_on_underflow() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(3)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 0,
		"unhoused_count": 2,
		"housed_by_island": {}
	})
	assert_eq(int(result["new_satori"]), 0)
	service.queue_free()

func test_minute_tick_clamps_to_cap_on_overflow() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(248)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 10,
		"unhoused_count": 0,
		"housed_by_island": {}
	})
	assert_eq(int(result["new_satori"]), 250)
	service.queue_free()

func test_era_boundary_transitions_upward_and_downward() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_cap_for_testing(10000)

	service.set_satori_for_testing(499)
	assert_eq(service.get_current_era(), SatoriIds.ERA_STILLNESS)
	service.set_satori_for_testing(500)
	assert_eq(service.get_current_era(), SatoriIds.ERA_AWAKENING)
	service.set_satori_for_testing(1499)
	assert_eq(service.get_current_era(), SatoriIds.ERA_AWAKENING)
	service.set_satori_for_testing(1500)
	assert_eq(service.get_current_era(), SatoriIds.ERA_FLOW)
	service.set_satori_for_testing(4999)
	assert_eq(service.get_current_era(), SatoriIds.ERA_FLOW)
	service.set_satori_for_testing(5000)
	assert_eq(service.get_current_era(), SatoriIds.ERA_SATORI)

	service.set_satori_for_testing(4999)
	assert_eq(service.get_current_era(), SatoriIds.ERA_FLOW)
	service.set_satori_for_testing(1499)
	assert_eq(service.get_current_era(), SatoriIds.ERA_AWAKENING)
	service.set_satori_for_testing(499)
	assert_eq(service.get_current_era(), SatoriIds.ERA_STILLNESS)
	service.queue_free()

func test_spirit_tier_availability_predicates_follow_era_rules() -> void:
	assert_false(SatoriConditionEvaluator.is_tier2_allowed(SatoriIds.ERA_STILLNESS))
	assert_true(SatoriConditionEvaluator.is_tier2_allowed(SatoriIds.ERA_AWAKENING))
	assert_true(SatoriConditionEvaluator.is_tier2_allowed(SatoriIds.ERA_FLOW))
	assert_true(SatoriConditionEvaluator.is_tier2_allowed(SatoriIds.ERA_SATORI))

	assert_false(SatoriConditionEvaluator.is_tier3_allowed(SatoriIds.ERA_AWAKENING))
	assert_true(SatoriConditionEvaluator.is_tier3_allowed(SatoriIds.ERA_FLOW))
	assert_true(SatoriConditionEvaluator.is_tier3_allowed(SatoriIds.ERA_SATORI))

	assert_false(SatoriConditionEvaluator.is_tier4_allowed(SatoriIds.ERA_FLOW))
	assert_true(SatoriConditionEvaluator.is_tier4_allowed(SatoriIds.ERA_SATORI))

func test_structure_cap_metadata_maps_by_tier() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	for entry: Dictionary in data.get_tier1_entries():
		assert_eq(int(entry.get("cap_increase", 0)), 50)
	for entry2: Dictionary in data.get_tier2_entries():
		assert_eq(int(entry2.get("cap_increase", 0)), 250)
	for entry3: Dictionary in data.get_tier3_entries():
		assert_eq(int(entry3.get("cap_increase", 0)), 1000)

func test_tier_cap_contribution_values() -> void:
	assert_eq(SatoriIds.TIER1_CAP_INCREASE, 50)
	assert_eq(SatoriIds.TIER2_CAP_INCREASE, 250)
	assert_eq(SatoriIds.TIER3_CAP_INCREASE, 1000)

func test_guidance_lantern_reduces_unhoused_penalty_for_up_to_three() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_structures_for_testing([
		{"discovery_id": "disc_guidance_lantern", "island_id": "island_a"}
	])
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(100)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 0,
		"unhoused_count": 4,
		"housed_by_island": {}
	})
	# Base -8, pacify +3 => -5.
	assert_eq(int(result["applied_delta"]), -5)
	assert_eq(int(result["new_satori"]), 95)
	service.queue_free()

func test_pagoda_passive_adds_five_per_tick() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_structures_for_testing([
		{"discovery_id": "disc_pagoda_of_the_five", "island_id": "island_a"}
	])
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(10)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 0,
		"unhoused_count": 0,
		"housed_by_island": {}
	})
	assert_eq(int(result["applied_delta"]), 5)
	assert_eq(int(result["new_satori"]), 15)
	service.queue_free()

func test_void_mirror_multiplier_boosts_housed_on_same_island() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_structures_for_testing([
		{"discovery_id": "disc_void_mirror", "island_id": "island_a"}
	])
	service.set_cap_for_testing(250)
	service.set_satori_for_testing(50)
	var result: Dictionary = service.process_minute_tick({
		"housed_count": 4,
		"unhoused_count": 0,
		"housed_by_island": {"island_a": 4}
	})
	# Base +4, mirror bonus +2 (50% of 4).
	assert_eq(int(result["applied_delta"]), 6)
	assert_eq(int(result["new_satori"]), 56)
	service.queue_free()

func test_great_torii_burst_is_clamped_to_cap() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_cap_for_testing(600)
	service.set_satori_for_testing(200)
	service.apply_monument_on_build("disc_great_torii")
	assert_eq(service.get_current_satori(), 600)
	service.queue_free()
