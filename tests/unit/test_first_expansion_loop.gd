extends GutTest

const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")
const SaveGameServiceScript = preload("res://src/autoloads/save_game_service.gd")
const TEST_SAVE_DIR: String = "user://test_first_session_saves"
const TEST_SAVE_PATH: String = "user://test_first_session_saves/autosave_test.json"
const TEST_TEMP_PATH: String = "user://test_first_session_saves/autosave_test.tmp"
const TEST_BACKUP_PATH: String = "user://test_first_session_saves/autosave_test.backup.json"

class DiscoveryPersistenceStub:
	extends Node
	signal discovery_recorded(discovery_id: String)
	var discovered_ids: Array[String] = []

	func get_discovered_ids() -> Array[String]:
		return discovered_ids.duplicate()

	func has_discovery(discovery_id: String) -> bool:
		return discovered_ids.has(discovery_id)

	func record_discovery(payload: DiscoveryPayload) -> void:
		var discovery_id: String = ""
		if payload != null:
			discovery_id = payload.discovery_id
		if discovery_id.is_empty() or discovered_ids.has(discovery_id):
			return
		discovered_ids.append(discovery_id)
		discovery_recorded.emit(discovery_id)

	func serialize_discovery_persistence_state() -> Dictionary:
		var entries: Array[Dictionary] = []
		for discovery_id: String in discovered_ids:
			entries.append({
				"discovery_id": discovery_id,
				"display_name": discovery_id,
				"trigger_timestamp": 0,
				"triggering_coords": [],
			})
		return {"entries": entries}

	func restore_discovery_persistence_state(data: Dictionary) -> bool:
		discovered_ids.clear()
		var entries_variant: Variant = data.get("entries", [])
		if not (entries_variant is Array):
			return false
		for entry_variant: Variant in entries_variant as Array:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant as Dictionary
			var discovery_id: String = str(entry.get("discovery_id", ""))
			if not discovery_id.is_empty() and not discovered_ids.has(discovery_id):
				discovered_ids.append(discovery_id)
		return true


class SpiritPersistenceStub:
	extends Node
	var instances: Array[Dictionary] = []

	func get_instances() -> Array[Dictionary]:
		return instances.duplicate(true)

	func get_summoned_ids() -> Array[String]:
		var ids: Array[String] = []
		for data: Dictionary in instances:
			var spirit_id: String = str(data.get("spirit_id", ""))
			if not spirit_id.is_empty() and not ids.has(spirit_id):
				ids.append(spirit_id)
		return ids

	func record_instance(instance: SpiritInstance) -> void:
		if instance == null:
			return
		instances.append(instance.serialize())

	func serialize_spirit_persistence_state() -> Dictionary:
		return {"instances": instances.duplicate(true)}

	func restore_spirit_persistence_state(data: Dictionary) -> bool:
		var raw_instances: Variant = data.get("instances", [])
		if not (raw_instances is Array):
			return false
		instances.clear()
		for raw_instance: Variant in raw_instances as Array:
			if raw_instance is Dictionary:
				instances.append((raw_instance as Dictionary).duplicate(true))
		return true


func _add_root_singleton(p_name: String, node: Node) -> void:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % p_name)
	if existing != null:
		root.remove_child(existing)
		existing.free()
	node.name = p_name
	root.add_child(node)


func _setup_context() -> Dictionary:
	var game_state: Node = get_tree().root.get_node_or_null("/root/GameState")
	if game_state == null:
		game_state = Node.new()
		game_state.set_script(load("res://src/autoloads/GameState.gd"))
		_add_root_singleton("GameState", game_state)
	game_state.set("_is_initialized", false)
	game_state._ready()

	var discovery: DiscoveryPersistenceStub = DiscoveryPersistenceStub.new()
	_add_root_singleton("DiscoveryPersistence", discovery)

	var spirit_persistence: SpiritPersistenceStub = SpiritPersistenceStub.new()
	_add_root_singleton("SpiritPersistence", spirit_persistence)

	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	_add_root_singleton("SeedAlchemyService", alchemy)
	alchemy._ready()

	var spirit_service: SpiritService = SpiritService.new()
	spirit_service._catalog = SpiritCatalog.new()
	spirit_service._catalog.load_from_data(SpiritCatalogData.new())
	spirit_service._riddle_evaluator = SpiritRiddleEvaluator.new()
	spirit_service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	spirit_service._spawner = SpiritSpawner.new()
	spirit_service._spirit_patterns = PatternLoader.new().load_patterns("res://src/biomes/patterns/spirits")
	add_child(spirit_service)

	return {
		"game_state": game_state,
		"discovery": discovery,
		"spirit_persistence": spirit_persistence,
		"growth": growth,
		"alchemy": alchemy,
		"spirit_service": spirit_service,
	}


func _cleanup_context(ctx: Dictionary) -> void:
	var spirit_service: Variant = ctx.get("spirit_service", null)
	if spirit_service is Node:
		var service_node: Node = spirit_service as Node
		if service_node.get_parent() != null:
			service_node.get_parent().remove_child(service_node)
		service_node.free()
	for key: String in ["growth", "alchemy", "discovery", "spirit_persistence"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			var node: Node = node_variant as Node
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_cleanup_test_save_files()


func _plant_and_bloom_now(growth: SeedGrowthServiceNode, recipe: SeedRecipe, coord: Vector2i) -> void:
	assert_not_null(recipe)
	assert_true(growth.try_plant(coord, recipe))
	var seed: SeedInstance = growth.get_tracker().get_at(coord)
	assert_not_null(seed)
	seed.planted_at -= seed.growth_duration
	assert_true(growth.try_bloom(coord))


func _recipe_from_pouch(growth: SeedGrowthServiceNode, recipe_id: StringName) -> SeedRecipe:
	var pouch: SeedPouch = growth.get_pouch()
	assert_not_null(pouch)
	var index: int = pouch.find_index_by_recipe_id(recipe_id)
	assert_true(index >= 0, "Expected pouch to contain %s" % str(recipe_id))
	return pouch.get_at(index)


func _place_form_on_tile(growth: SeedGrowthServiceNode, type_key: StringName, coord: Vector2i) -> void:
	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)
	controller.start_building_placement(type_key)
	var session: BuildingPlacementSession = controller.get_active_building_session()
	assert_not_null(session)
	session.update_anchor(coord, [coord], true, &"")
	assert_true(controller.confirm_building_placement())
	assert_eq(growth.get_pouch().find_building_index(type_key), -1)
	remove_child(controller)
	controller.free()


func _count_active_spirits(spirit_service: SpiritService, spirit_id: String) -> int:
	var count: int = 0
	for key_variant: Variant in spirit_service._active_instances.keys():
		var instance: SpiritInstance = spirit_service._active_instances.get(key_variant, null)
		if instance != null and instance.spirit_id == spirit_id:
			count += 1
	return count


func test_first_session_housed_red_fox_survives_save_load() -> void:
	_cleanup_test_save_files()
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var spirit_service: SpiritService = ctx["spirit_service"]

	var meadow_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:wind"])
	assert_true(meadow_result.is_success())
	assert_eq(meadow_result.result_id, &"recipe_fu")
	var meadow_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_fu")
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(1, 0))

	assert_eq(game_state.evaluate_material_spawns(100.0).size(), 1)
	game_state.evaluate_material_spawns(60.0)
	var harvest_result: Dictionary = game_state.harvest_material_at(Vector2i(1, 0))
	assert_eq(StringName(str(harvest_result.get("outcome", &""))), &"success")
	assert_eq(alchemy.get_material_count(&"living_wood"), 1)
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(2, 0))
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(1, 1))

	var hollow_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_true(hollow_result.is_success())
	assert_eq(hollow_result.result_id, &"form_warm_hollow")
	_place_form_on_tile(growth, &"form_warm_hollow", Vector2i(1, 0))
	spirit_service._on_tile_placed(Vector2i(1, 1), game_state.grid.get_tile(Vector2i(1, 1)))
	var island_id: String = str(game_state.grid.get_island_id(Vector2i(1, 0)))
	assert_true(spirit_service.is_spirit_housed("spirit_red_fox", island_id))

	var service: Node = SaveGameServiceScript.new()
	add_child(service)
	service.set_paths_for_testing(TEST_SAVE_DIR, TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH)
	assert_true(service.save_now("first_session_roundtrip"))

	game_state._initialize_fresh_garden()
	growth.restore_seed_growth_state({"active_seeds": [], "pouch": {"capacity": 8, "entries": []}})
	alchemy.restore_seed_alchemy_state({})
	var spirit_persistence: SpiritPersistenceStub = ctx["spirit_persistence"]
	assert_true(spirit_persistence.restore_spirit_persistence_state({"instances": []}))
	assert_true(service.load_game())

	var restored_tile: GardenTile = game_state.grid.get_tile(Vector2i(1, 0))
	assert_not_null(restored_tile)
	assert_eq(str(restored_tile.metadata.get("structure_discovery_id", "")), "building_meadow_dwelling")
	assert_eq(alchemy.get_material_count(&"living_wood"), 0)
	assert_eq(growth.get_pouch().find_building_index(&"form_warm_hollow"), -1)

	var restored_service: SpiritService = SpiritService.new()
	restored_service._catalog = SpiritCatalog.new()
	restored_service._catalog.load_from_data(SpiritCatalogData.new())
	restored_service._riddle_evaluator = SpiritRiddleEvaluator.new()
	restored_service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	restored_service._spawner = SpiritSpawner.new()
	restored_service._spirit_patterns = PatternLoader.new().load_patterns("res://src/biomes/patterns/spirits")
	add_child(restored_service)
	restored_service.restore_from_persistence()
	assert_true(restored_service.is_spirit_housed("spirit_red_fox", island_id))

	remove_child(restored_service)
	restored_service.free()
	remove_child(service)
	service.free()
	_cleanup_context(ctx)

func test_first_island_fun_loop_survives_save_load() -> void:
	_cleanup_test_save_files()
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var discovery: DiscoveryPersistenceStub = ctx["discovery"]
	var spirit_persistence: SpiritPersistenceStub = ctx["spirit_persistence"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var spirit_service: SpiritService = ctx["spirit_service"]
	var satori_service: SatoriServiceNode = get_tree().root.get_node_or_null("/root/SatoriService") as SatoriServiceNode
	assert_not_null(satori_service)
	var original_satori: Dictionary = satori_service.serialize_satori_state()

	var meadow_coords: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 0),
	]
	for coord: Vector2i in meadow_coords:
		game_state.place_tile_from_seed(coord, BiomeType.Value.MEADOW)

	var pouch: SeedPouch = growth.get_pouch()
	assert_true(pouch.add_building(&"form_warm_hollow", 1))
	assert_true(pouch.add_building(&"form_fox_den", 1))
	assert_true(pouch.add_building(&"form_dew_bowl", 1))
	assert_true(pouch.add_building(&"form_wind_chime", 1))
	for discovery_id: String in ["disc_warm_hollow", "disc_fox_den", "disc_dew_bowl", "disc_wind_chime"]:
		discovery.record_discovery(DiscoveryPayload.create(discovery_id, [], {"display_name": discovery_id}))

	_place_form_on_tile(growth, &"form_warm_hollow", Vector2i(1, 0))
	var island_id: String = str(game_state.grid.get_island_id(Vector2i(1, 0)))
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 1), Rect2i())
	fox.island_id = island_id
	spirit_service._active_instances[spirit_service._spirit_key("spirit_red_fox", island_id)] = fox
	spirit_persistence.record_instance(fox)
	assert_true(spirit_service.is_spirit_housed("spirit_red_fox", island_id))

	_place_form_on_tile(growth, &"form_fox_den", Vector2i(2, 0))
	spirit_service.mark_housing_dirty()
	var fox_den_owner: Dictionary = spirit_service.get_house_owner_at_coord(Vector2i(2, 0))
	assert_eq(str(fox_den_owner.get("spirit_id", "")), "spirit_red_fox")

	_place_form_on_tile(growth, &"form_dew_bowl", Vector2i(2, 1))
	_place_form_on_tile(growth, &"form_wind_chime", Vector2i(3, 0))
	satori_service.set_satori_for_testing(140)
	var satori_tick: Dictionary = satori_service.process_minute_tick({
		"housed_count": 1,
		"unhoused_count": 0,
		"upgraded_housed_count": 1,
		"housed_by_island": {island_id: 1},
		"upgraded_housed_by_island": {island_id: 1},
	})
	assert_eq(int(satori_tick.get("applied_delta", 0)), 2)

	var service: Node = SaveGameServiceScript.new()
	add_child(service)
	service.set_paths_for_testing(TEST_SAVE_DIR, TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH)
	assert_true(service.save_now("first_island_fun_loop"))

	game_state._initialize_fresh_garden()
	growth.restore_seed_growth_state({"active_seeds": [], "pouch": {"capacity": 8, "entries": []}})
	discovery.restore_discovery_persistence_state({"entries": []})
	spirit_persistence.restore_spirit_persistence_state({"instances": []})
	satori_service.set_satori_for_testing(0)
	assert_true(service.load_game())

	var restored_fox_den: GardenTile = game_state.grid.get_tile(Vector2i(2, 0))
	var restored_dew_bowl: GardenTile = game_state.grid.get_tile(Vector2i(2, 1))
	var restored_wind_chime: GardenTile = game_state.grid.get_tile(Vector2i(3, 0))
	assert_not_null(restored_fox_den)
	assert_not_null(restored_dew_bowl)
	assert_not_null(restored_wind_chime)
	assert_eq(str(restored_fox_den.metadata.get("structure_discovery_id", "")), "building_fox_den")
	assert_eq(str(restored_dew_bowl.metadata.get("structure_discovery_id", "")), "building_dew_bowl")
	assert_eq(str(restored_wind_chime.metadata.get("structure_discovery_id", "")), "building_wind_chime")
	assert_true(discovery.discovered_ids.has("disc_fox_den"))
	assert_true(discovery.discovered_ids.has("disc_dew_bowl"))
	assert_true(discovery.discovered_ids.has("disc_wind_chime"))
	assert_eq(satori_service.get_current_satori(), int(satori_tick.get("new_satori", 0)))

	var restored_service: SpiritService = SpiritService.new()
	restored_service._catalog = SpiritCatalog.new()
	restored_service._catalog.load_from_data(SpiritCatalogData.new())
	restored_service._riddle_evaluator = SpiritRiddleEvaluator.new()
	restored_service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	restored_service._spawner = SpiritSpawner.new()
	restored_service._spirit_patterns = PatternLoader.new().load_patterns("res://src/biomes/patterns/spirits")
	add_child(restored_service)
	restored_service.restore_from_persistence()
	assert_true(restored_service.is_spirit_housed("spirit_red_fox", island_id))
	assert_eq(str(restored_service.get_house_owner_at_coord(Vector2i(2, 0)).get("spirit_id", "")), "spirit_red_fox")

	remove_child(restored_service)
	restored_service.free()
	remove_child(service)
	service.free()
	satori_service.restore_satori_state(original_satori)
	_cleanup_context(ctx)


func test_first_expansion_loop_reaches_second_island_without_spirit_assistants() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var discovery: DiscoveryPersistenceStub = ctx["discovery"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var spirit_service: SpiritService = ctx["spirit_service"]

	var meadow_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:wind"])
	assert_true(meadow_result.is_success())
	assert_eq(meadow_result.result_id, &"recipe_fu")
	var meadow_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_fu")
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(1, 0))

	assert_eq(game_state.evaluate_material_spawns(100.0).size(), 1)
	game_state.evaluate_material_spawns(60.0)
	var harvest_result: Dictionary = game_state.harvest_material_at(Vector2i(1, 0))
	assert_eq(StringName(str(harvest_result.get("outcome", &""))), &"success")
	assert_eq(alchemy.get_material_count(&"living_wood"), 1)

	var hollow_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_true(hollow_result.is_success())
	assert_eq(hollow_result.result_id, &"form_warm_hollow")
	_place_form_on_tile(growth, &"form_warm_hollow", Vector2i(1, 0))
	var dwelling_tile: GardenTile = game_state.grid.get_tile(Vector2i(1, 0))
	assert_eq(str(dwelling_tile.metadata.get("structure_discovery_id", "")), "building_meadow_dwelling")

	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(2, 0))
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(1, 1))
	spirit_service._on_tile_placed(Vector2i(1, 1), game_state.grid.get_tile(Vector2i(1, 1)))
	var first_island_id: String = str(game_state.grid.get_island_id(Vector2i(1, 0)))
	assert_true(spirit_service.is_spirit_housed("spirit_red_fox", first_island_id))

	discovery.discovered_ids.append("disc_deep_stand")
	spirit_service._current_era = SatoriIds.ERA_AWAKENING
	for coord: Vector2i in [Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 1)]:
		game_state.place_tile_from_seed(coord, BiomeType.Value.WETLANDS)
	spirit_service._on_tile_placed(Vector2i(4, 1), game_state.grid.get_tile(Vector2i(4, 1)))
	assert_true(spirit_service._is_spirit_active_anywhere("spirit_mist_stag"))
	assert_true(alchemy.is_ku_unlocked())

	var ku_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:ku"])
	assert_true(ku_result.is_success())
	assert_eq(ku_result.result_id, &"recipe_ku")
	var ku_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_ku")
	_plant_and_bloom_now(growth, ku_recipe, Vector2i(5, 0))
	assert_eq(game_state.grid.get_island_id(Vector2i(5, 0)), "")

	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(6, 0))
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(7, 0))
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(6, 1))
	var second_island_id: String = str(game_state.grid.get_island_id(Vector2i(6, 0)))
	assert_false(second_island_id.is_empty())
	assert_false(second_island_id == first_island_id)
	spirit_service._on_tile_placed(Vector2i(6, 1), game_state.grid.get_tile(Vector2i(6, 1)))
	assert_eq(_count_active_spirits(spirit_service, "spirit_red_fox"), 2)

	_cleanup_context(ctx)


func _cleanup_test_save_files() -> void:
	_remove_file(TEST_SAVE_PATH)
	_remove_file(TEST_TEMP_PATH)
	_remove_file(TEST_BACKUP_PATH)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_alpha_endgame_spine_invites_suijin_and_survives_save_load() -> void:
	_cleanup_test_save_files()
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var spirit_persistence: SpiritPersistenceStub = ctx["spirit_persistence"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var spirit_service: SpiritService = ctx["spirit_service"]
	var satori_service: SatoriServiceNode = get_tree().root.get_node_or_null("/root/SatoriService") as SatoriServiceNode
	assert_not_null(satori_service)
	var original_satori: Dictionary = satori_service.serialize_satori_state()

	spirit_service._current_era = SatoriIds.ERA_AWAKENING
	var mist_coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	spirit_service._on_discovery_triggered("spirit_mist_stag", mist_coords)
	assert_true(spirit_service._is_spirit_active_anywhere("spirit_mist_stag"))
	assert_true(alchemy.is_ku_unlocked())

	var ku_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:ku"])
	assert_true(ku_result.is_success())
	assert_eq(ku_result.result_id, &"recipe_ku")
	var ku_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_ku")
	_plant_and_bloom_now(growth, ku_recipe, Vector2i(1, 0))
	assert_eq(game_state.grid.get_island_id(Vector2i(1, 0)), "")

	for i: int in range(10):
		var coord: Vector2i = Vector2i(2 + i, 0)
		game_state.place_tile_from_seed(coord, BiomeType.Value.RIVER)

	var second_island_id: String = str(game_state.grid.get_island_id(Vector2i(2, 0)))
	assert_false(second_island_id.is_empty())
	assert_false(second_island_id == str(game_state.grid.get_island_id(Vector2i.ZERO)))

	var sacred_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:earth", "essence:ku"])
	assert_true(sacred_result.is_success())
	assert_eq(sacred_result.result_id, &"recipe_chi_ku")
	var sacred_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_chi_ku")
	_plant_and_bloom_now(growth, sacred_recipe, Vector2i(12, 0))
	satori_service.set_cap_for_testing(1000)
	satori_service.set_satori_for_testing(1000)
	spirit_service._on_discovery_triggered("spirit_suijin", [Vector2i(12, 0)])
	assert_true(spirit_service._is_spirit_active_anywhere("spirit_suijin"))
	assert_eq(_count_active_spirits(spirit_service, "spirit_suijin"), 1)

	var service: Node = SaveGameServiceScript.new()
	add_child(service)
	service.set_paths_for_testing(TEST_SAVE_DIR, TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH)
	assert_true(service.save_now("alpha_endgame_spine"))

	game_state._initialize_fresh_garden()
	growth.restore_seed_growth_state({"active_seeds": [], "pouch": {"capacity": 8, "entries": []}})
	alchemy.restore_seed_alchemy_state({})
	spirit_persistence.restore_spirit_persistence_state({"instances": []})
	satori_service.set_satori_for_testing(0)
	assert_true(service.load_game())
	assert_true(alchemy.is_ku_unlocked())
	assert_eq(game_state.grid.get_island_id(Vector2i(1, 0)), "")
	assert_false(str(game_state.grid.get_island_id(Vector2i(2, 0))).is_empty())
	assert_eq(game_state.grid.get_tile(Vector2i(12, 0)).biome, BiomeType.Value.SACRED_STONE)
	assert_eq(satori_service.get_current_satori(), 1000)

	var restored_service: SpiritService = SpiritService.new()
	restored_service._catalog = SpiritCatalog.new()
	restored_service._catalog.load_from_data(SpiritCatalogData.new())
	restored_service._riddle_evaluator = SpiritRiddleEvaluator.new()
	restored_service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	restored_service._spawner = SpiritSpawner.new()
	add_child(restored_service)
	restored_service.restore_from_persistence()
	assert_true(restored_service._is_spirit_active_anywhere("spirit_suijin"))
	assert_eq(_count_active_spirits(restored_service, "spirit_suijin"), 1)

	remove_child(restored_service)
	restored_service.free()
	remove_child(service)
	service.free()
	satori_service.restore_satori_state(original_satori)
	_cleanup_context(ctx)
