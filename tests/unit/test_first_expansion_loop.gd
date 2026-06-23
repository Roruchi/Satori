extends GutTest

const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")

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
		(spirit_service as Node).queue_free()
	for key: String in ["growth", "alchemy", "discovery", "spirit_persistence"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			var node: Node = node_variant as Node
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()


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
	controller.queue_free()


func _count_active_spirits(spirit_service: SpiritService, spirit_id: String) -> int:
	var count: int = 0
	for key_variant: Variant in spirit_service._active_instances.keys():
		var instance: SpiritInstance = spirit_service._active_instances.get(key_variant, null)
		if instance != null and instance.spirit_id == spirit_id:
			count += 1
	return count


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


func test_rain_kami_path_opens_after_reed_nest_on_second_island() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var discovery: DiscoveryPersistenceStub = ctx["discovery"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var spirit_service: SpiritService = ctx["spirit_service"]

	game_state.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.KU)
	var rain_coords: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 1)]
	for coord: Vector2i in rain_coords:
		game_state.place_tile_from_seed(coord, BiomeType.Value.RIVER)

	var second_island_id: String = str(game_state.grid.get_island_id(Vector2i(2, 0)))
	assert_false(second_island_id.is_empty())
	assert_false(second_island_id == str(game_state.grid.get_island_id(Vector2i.ZERO)))

	var spawned: Array[Dictionary] = game_state.evaluate_material_spawns(100.0)
	assert_true(spawned.size() > 0)
	var reed_coord: Vector2i = Vector2i.ZERO
	for node: Dictionary in spawned:
		if StringName(str(node.get("material_id", &""))) == &"reed_fiber":
			var coord_variant: Variant = node.get("coord", Vector2i.ZERO)
			if coord_variant is Vector2i:
				reed_coord = coord_variant as Vector2i
			break
	assert_false(reed_coord == Vector2i.ZERO)
	var harvest_result: Dictionary = game_state.harvest_material_at(reed_coord)
	assert_eq(StringName(str(harvest_result.get("outcome", &""))), &"success")
	assert_eq(alchemy.get_material_count(&"reed_fiber"), 1)

	var reed_result: RitualAttemptResult = alchemy.attempt_ritual(["material:reed_fiber", "essence:water"])
	assert_true(reed_result.is_success())
	assert_eq(reed_result.result_id, &"form_reed_nest")
	assert_true(discovery.discovered_ids.has("disc_reed_nest"))

	_place_form_on_tile(growth, &"form_reed_nest", Vector2i(2, 0))
	var reed_nest_tile: GardenTile = game_state.grid.get_tile(Vector2i(2, 0))
	assert_eq(str(reed_nest_tile.metadata.get("structure_discovery_id", "")), "building_reed_nest")

	spirit_service._current_era = SatoriIds.ERA_AWAKENING
	spirit_service._on_tile_placed(Vector2i(2, 1), game_state.grid.get_tile(Vector2i(2, 1)))
	assert_true(spirit_service._is_spirit_active_anywhere("spirit_suijin"))
	assert_eq(_count_active_spirits(spirit_service, "spirit_suijin"), 1)

	_cleanup_context(ctx)
