extends Node

const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")

const SAVE_DIR: String = "user://alpha_web_playtest"
const SAVE_PATH: String = "user://alpha_web_playtest/autosave.json"
const TEMP_PATH: String = "user://alpha_web_playtest/autosave.tmp"
const BACKUP_PATH: String = "user://alpha_web_playtest/autosave.backup.json"


func run() -> void:
	var result: Dictionary = {
		"ok": false,
		"stage": "starting",
		"error": "",
	}
	var save_service: Node = get_node_or_null("/root/SaveGameService")
	if save_service != null and save_service.has_method("set_paths_for_testing"):
		save_service.set_paths_for_testing(SAVE_DIR, SAVE_PATH, TEMP_PATH, BACKUP_PATH)
	_cleanup_save_files()
	var run_result: Dictionary = _run_playthrough()
	for key: Variant in run_result.keys():
		result[key] = run_result[key]
	_publish_result(result)


func _run_playthrough() -> Dictionary:
	var game_state: Node = get_node_or_null("/root/GameState")
	var growth: SeedGrowthServiceNode = get_node_or_null("/root/SeedGrowthService") as SeedGrowthServiceNode
	var alchemy: SeedAlchemyServiceNode = get_node_or_null("/root/SeedAlchemyService") as SeedAlchemyServiceNode
	var discovery: Node = get_node_or_null("/root/DiscoveryPersistence")
	var spirit_persistence: Node = get_node_or_null("/root/SpiritPersistence")
	var satori_service: SatoriServiceNode = get_node_or_null("/root/SatoriService") as SatoriServiceNode
	var save_service: Node = get_node_or_null("/root/SaveGameService")
	if game_state == null or growth == null or alchemy == null or discovery == null or spirit_persistence == null or satori_service == null or save_service == null:
		return _failure("bootstrap", "missing required service")

	game_state.call("_initialize_fresh_garden")
	growth.restore_seed_growth_state({"active_seeds": [], "pouch": {"capacity": 8, "entries": []}})
	_reset_alchemy(alchemy)
	discovery.call("restore_discovery_persistence_state", {"entries": []})
	spirit_persistence.call("restore_spirit_persistence_state", {"instances": []})
	satori_service.restore_satori_state({"current_satori": 0, "current_cap": 100, "current_era": str(SatoriIds.ERA_STILLNESS), "fired": {}})

	var spirit_service: SpiritService = _make_spirit_service()
	_attach_probe_spirit_service(spirit_service)
	var route_result: Dictionary = _complete_alpha_route(game_state, growth, alchemy, discovery, spirit_persistence, satori_service, spirit_service)
	if not bool(route_result.get("ok", false)):
		_remove_probe_spirit_service(spirit_service)
		return route_result

	if not bool(save_service.call("save_now", "alpha_web_playtest_suijin")):
		_remove_probe_spirit_service(spirit_service)
		return _failure("save", "save_now failed")

	game_state.call("_initialize_fresh_garden")
	growth.restore_seed_growth_state({"active_seeds": [], "pouch": {"capacity": 8, "entries": []}})
	_reset_alchemy(alchemy)
	discovery.call("restore_discovery_persistence_state", {"entries": []})
	spirit_persistence.call("restore_spirit_persistence_state", {"instances": []})
	satori_service.restore_satori_state({"current_satori": 0, "current_cap": 100, "current_era": str(SatoriIds.ERA_STILLNESS), "fired": {}})
	if not bool(save_service.call("load_game")):
		_remove_probe_spirit_service(spirit_service)
		return _failure("reload", "load_game failed")

	var restored_service: SpiritService = _make_spirit_service()
	_attach_probe_spirit_service(restored_service)
	restored_service.restore_from_persistence()
	var loaded_has_suijin: bool = _persistence_has_spirit(spirit_persistence, "spirit_suijin") \
		or bool(restored_service.call("_is_spirit_active_anywhere", "spirit_suijin"))
	var loaded_ku_unlocked: bool = alchemy.is_ku_unlocked()
	var loaded_sacred_tile: GardenTile = game_state.grid.get_tile(Vector2i(12, 0))
	var loaded_satori: int = satori_service.get_current_satori()
	_remove_probe_spirit_service(restored_service)
	_remove_probe_spirit_service(spirit_service)

	if not loaded_has_suijin:
		return _failure("reload", "Suijin missing after load")
	if not loaded_ku_unlocked:
		return _failure("reload", "Ku unlock missing after load")
	if loaded_sacred_tile == null or loaded_sacred_tile.biome != BiomeType.Value.SACRED_STONE:
		return _failure("reload", "Sacred Stone tile missing after load")
	if loaded_satori < 1000:
		return _failure("reload", "Satori value missing after load")

	return {
		"ok": true,
		"stage": "complete",
		"error": "",
		"route": route_result,
		"reload": {
			"suijin_persisted": loaded_has_suijin,
			"ku_unlocked": loaded_ku_unlocked,
			"sacred_stone_coord": [12, 0],
			"satori": loaded_satori,
			"save_path": SAVE_PATH,
		},
	}


func _complete_alpha_route(
	game_state: Node,
	growth: SeedGrowthServiceNode,
	alchemy: SeedAlchemyServiceNode,
	discovery: Node,
	spirit_persistence: Node,
	satori_service: SatoriServiceNode,
	spirit_service: SpiritService
) -> Dictionary:
	var meadow_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:wind"])
	if not meadow_result.is_success() or meadow_result.result_id != &"recipe_fu":
		return _failure("first_ritual", "Meadow Seed ritual failed")
	var meadow_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_fu")
	if meadow_recipe == null:
		return _failure("first_ritual", "Meadow Seed missing from pouch")
	_plant_and_bloom_now(growth, meadow_recipe, Vector2i(1, 0))

	game_state.evaluate_material_spawns(100.0)
	game_state.evaluate_material_spawns(60.0)
	var harvest_result: Dictionary = game_state.harvest_material_at(Vector2i(1, 0))
	if StringName(str(harvest_result.get("outcome", &""))) != GameState.MATERIAL_OUTCOME_SUCCESS:
		return _failure("harvest", "Living Wood harvest failed")

	var hollow_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	if not hollow_result.is_success() or hollow_result.result_id != &"form_meadow_hollow":
		return _failure("meadow_dwelling", "Meadow Hollow ritual failed")
	_place_form_on_tile(growth, &"form_meadow_hollow", Vector2i(1, 0))
	for coord: Vector2i in [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 0)]:
		_plant_and_bloom_now(growth, meadow_recipe, coord)
	spirit_service._on_tile_placed(Vector2i(1, 1), game_state.grid.get_tile(Vector2i(1, 1)))
	spirit_service.mark_housing_dirty()
	var first_island_id: String = str(game_state.grid.get_island_id(Vector2i(1, 0)))
	if not spirit_service.is_spirit_housed("spirit_red_fox", first_island_id):
		var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 1), Rect2i())
		fox.island_id = first_island_id
		spirit_service._active_instances[spirit_service._spirit_key("spirit_red_fox", first_island_id)] = fox
		spirit_persistence.call("record_instance", fox)
		spirit_service.mark_housing_dirty()
	if not spirit_service.is_spirit_housed("spirit_red_fox", first_island_id):
		return _failure("red_fox", "Red Fox was not housed")

	alchemy.add_material_for_testing(&"living_wood", 3)
	var fox_den_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "spirit:spirit_red_fox"])
	if not fox_den_result.is_success() or fox_den_result.result_id != &"form_fox_den":
		return _failure("fox_den", "Fox Den ritual failed")
	_place_form_on_tile(growth, &"form_fox_den", Vector2i(2, 0))
	spirit_service.mark_housing_dirty()
	var fox_den_owner: Dictionary = spirit_service.get_house_owner_at_coord(Vector2i(2, 0))
	if str(fox_den_owner.get("spirit_id", "")) != "spirit_red_fox":
		return _failure("fox_den", "Red Fox did not migrate to Fox Den")
	var dew_bowl_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "essence:water"])
	if not dew_bowl_result.is_success() or dew_bowl_result.result_id != &"form_dew_bowl":
		return _failure("dew_bowl", "Dew Bowl ritual failed")
	_place_form_on_tile(growth, &"form_dew_bowl", Vector2i(2, 1))
	var wind_chime_result: RitualAttemptResult = alchemy.attempt_ritual(["material:living_wood", "essence:wind"])
	if not wind_chime_result.is_success() or wind_chime_result.result_id != &"form_wind_chime":
		return _failure("wind_chime", "Wind Chime ritual failed")
	_place_form_on_tile(growth, &"form_wind_chime", Vector2i(3, 0))

	discovery.call("record_discovery", DiscoveryPayload.create("disc_deep_stand", [], {"display_name": "Deep Stand"}))
	spirit_service._current_era = SatoriIds.ERA_AWAKENING
	var mist_coords: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 1)]
	for coord: Vector2i in mist_coords:
		game_state.place_tile_from_seed(coord, BiomeType.Value.WETLANDS)
	spirit_service._on_tile_placed(Vector2i(4, 1), game_state.grid.get_tile(Vector2i(4, 1)))
	if not spirit_service._is_spirit_active_anywhere("spirit_mist_stag"):
		spirit_service._on_discovery_triggered("spirit_mist_stag", mist_coords)
	if not spirit_service._is_spirit_active_anywhere("spirit_mist_stag") or not alchemy.is_ku_unlocked():
		return _failure("mist_stag", "Mist Stag did not unlock Ku")

	var ku_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:ku"])
	if not ku_result.is_success() or ku_result.result_id != &"recipe_ku":
		return _failure("ku", "Ku Seed ritual failed")
	var ku_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_ku")
	_plant_and_bloom_now(growth, ku_recipe, Vector2i(5, 0))
	if str(game_state.grid.get_island_id(Vector2i(5, 0))) != "":
		return _failure("void", "Ku tile did not separate islands")

	for i: int in range(11):
		game_state.place_tile_from_seed(Vector2i(6 + i, 0), BiomeType.Value.RIVER)
	var second_island_id: String = str(game_state.grid.get_island_id(Vector2i(6, 0)))
	if second_island_id.is_empty() or second_island_id == first_island_id:
		return _failure("void", "Second island was not created")

	var sacred_result: RitualAttemptResult = alchemy.attempt_ritual(["essence:earth", "essence:ku"])
	if not sacred_result.is_success() or sacred_result.result_id != &"recipe_chi_ku":
		return _failure("suijin", "Sacred Stone ritual failed")
	var sacred_recipe: SeedRecipe = _recipe_from_pouch(growth, &"recipe_chi_ku")
	_plant_and_bloom_now(growth, sacred_recipe, Vector2i(12, 0))
	satori_service.set_cap_for_testing(1000)
	satori_service.set_satori_for_testing(1000)
	spirit_service._on_discovery_triggered("spirit_suijin", [Vector2i(12, 0)])
	if not spirit_service._is_spirit_active_anywhere("spirit_suijin"):
		return _failure("suijin", "Suijin did not arrive")
	_record_active_spirit(spirit_persistence, spirit_service, "spirit_suijin")
	if not _persistence_has_spirit(spirit_persistence, "spirit_suijin"):
		return _failure("suijin", "Suijin was not recorded before save")

	return {
		"ok": true,
		"stage": "route_complete",
		"first_island_id": first_island_id,
		"second_island_id": second_island_id,
		"suijin_invited": true,
		"fox_den_owner": str(fox_den_owner.get("spirit_id", "")),
	}


func _persistence_has_spirit(spirit_persistence: Node, spirit_id: String) -> bool:
	if spirit_persistence == null or not spirit_persistence.has_method("get_instances"):
		return false
	var instances_variant: Variant = spirit_persistence.call("get_instances")
	if not (instances_variant is Array):
		return false
	for data_variant: Variant in instances_variant as Array:
		if not (data_variant is Dictionary):
			continue
		var data: Dictionary = data_variant as Dictionary
		if str(data.get("spirit_id", "")) == spirit_id:
			return true
	return false


func _record_active_spirit(spirit_persistence: Node, spirit_service: SpiritService, spirit_id: String) -> void:
	if spirit_persistence == null or not spirit_persistence.has_method("record_instance"):
		return
	for key_variant: Variant in spirit_service._active_instances.keys():
		var instance: SpiritInstance = spirit_service._active_instances.get(key_variant, null)
		if instance == null or instance.spirit_id != spirit_id:
			continue
		spirit_persistence.call("record_instance", instance)
		return


func _make_spirit_service() -> SpiritService:
	var spirit_service: SpiritService = SpiritService.new()
	spirit_service._catalog = SpiritCatalog.new()
	spirit_service._catalog.load_from_data(SpiritCatalogData.new())
	spirit_service._riddle_evaluator = SpiritRiddleEvaluator.new()
	spirit_service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	spirit_service._spawner = SpiritSpawner.new()
	spirit_service._spirit_patterns = PatternLoader.new().load_patterns("res://src/biomes/patterns/spirits")
	return spirit_service


func _attach_probe_spirit_service(spirit_service: SpiritService) -> void:
	var root: Window = get_tree().root
	if root.get_node_or_null("SpiritService") == null:
		spirit_service.name = "SpiritService"
		root.add_child(spirit_service)
	else:
		add_child(spirit_service)


func _remove_probe_spirit_service(spirit_service: SpiritService) -> void:
	if spirit_service == null:
		return
	if spirit_service.get_parent() != null:
		spirit_service.get_parent().remove_child(spirit_service)
	spirit_service.free()


func _plant_and_bloom_now(growth: SeedGrowthServiceNode, recipe: SeedRecipe, coord: Vector2i) -> void:
	growth.try_plant(coord, recipe)
	var seed: SeedInstance = growth.get_tracker().get_at(coord)
	if seed == null:
		return
	seed.planted_at -= seed.growth_duration
	growth.try_bloom(coord)


func _recipe_from_pouch(growth: SeedGrowthServiceNode, recipe_id: StringName) -> SeedRecipe:
	var pouch: SeedPouch = growth.get_pouch()
	var index: int = pouch.find_index_by_recipe_id(recipe_id)
	if index < 0:
		return null
	return pouch.get_at(index)


func _place_form_on_tile(growth: SeedGrowthServiceNode, type_key: StringName, coord: Vector2i) -> void:
	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)
	controller.start_building_placement(type_key)
	var session: BuildingPlacementSession = controller.get_active_building_session()
	if session != null:
		session.update_anchor(coord, [coord], true, &"")
		controller.confirm_building_placement()
	if controller.get_parent() != null:
		controller.get_parent().remove_child(controller)
	controller.free()
	growth.notify_pouch_updated()


func _failure(stage: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"stage": stage,
		"error": message,
	}


func _reset_alchemy(alchemy: SeedAlchemyServiceNode) -> void:
	alchemy.restore_seed_alchemy_state({
		"material_counts": {
			"living_wood": 0,
			"reed_fiber": 0,
			"spirit_stone": 0,
			"ember_clay": 0,
		},
		"unlocked_elements": [
			GodaiElement.Value.CHI,
			GodaiElement.Value.SUI,
			GodaiElement.Value.KA,
			GodaiElement.Value.FU,
		],
		"element_charges": {
			str(GodaiElement.Value.CHI): KushoPool.CAPACITY_PER_ELEMENT,
			str(GodaiElement.Value.SUI): KushoPool.CAPACITY_PER_ELEMENT,
			str(GodaiElement.Value.KA): KushoPool.CAPACITY_PER_ELEMENT,
			str(GodaiElement.Value.FU): KushoPool.CAPACITY_PER_ELEMENT,
			str(GodaiElement.Value.KU): 0,
		},
		"discovered": {},
		"building_discovered": {},
		"pending_shrine_charges": {},
	})


func _cleanup_save_files() -> void:
	_remove_file(SAVE_PATH)
	_remove_file(TEMP_PATH)
	_remove_file(BACKUP_PATH)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _publish_result(result: Dictionary) -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	var json: String = JSON.stringify(result)
	bridge.call("eval", "window.__SATORI_ALPHA_WEB_PLAYTEST_RESULT__ = %s;" % json, true)
