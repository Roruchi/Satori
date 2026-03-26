extends GutTest

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
	assert_eq(growth_service.get_pouch().capacity, 4)
	assert_eq(growth_service.get_tracker().capacity, track_before)
	service.queue_free()
	growth_service.queue_free()
	settings.queue_free()
