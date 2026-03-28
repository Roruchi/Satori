extends GutTest
const GridMapScript = preload("res://src/grid/GridMap.gd")

func test_ku_deity_spirit_marks_spawn_tile_as_buildable_shrine() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", GridMapScript.new())
	root.add_child(game_state)

	var grid: RefCounted = game_state.get("grid")
	var spawn_coord: Vector2i = Vector2i(2, 0)
	grid.place_tile(spawn_coord, BiomeType.Value.SACRED_STONE)

	var service: SpiritService = SpiritService.new()
	service.name = "SpiritService"
	add_child(service)
	service._catalog = SpiritCatalog.new()
	service._catalog.load_from_data(SpiritCatalogData.new())
	service._riddle_evaluator = SpiritRiddleEvaluator.new()
	service._sky_whale_evaluator = SkyWhaleEvaluator.new()
	service._spawner = SpiritSpawner.new()

	service._summon_spirit("spirit_oyamatsumi", [spawn_coord], "")

	var tile: GardenTile = grid.get_tile(spawn_coord)
	assert_not_null(tile)
	assert_true(bool(tile.metadata.get("shrine_buildable", false)))
	assert_eq(bool(tile.metadata.get("shrine_built", false)), false)
	assert_eq(str(tile.metadata.get("shrine_spirit_id", "")), "spirit_oyamatsumi")
	service.queue_free()
	game_state.queue_free()


func test_store_and_collect_shrine_charge_transfers_to_kusho_pool() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()
	alchemy.set_element_charge_for_testing(GodaiElement.Value.CHI, 0)
	var coord: Vector2i = Vector2i(4, -1)
	assert_true(alchemy.store_shrine_charge(coord, GodaiElement.Value.CHI, 1))
	assert_true(alchemy.has_shrine_charge(coord))
	assert_true(alchemy.collect_shrine_charge(coord))
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.CHI), 1)
	assert_false(alchemy.has_shrine_charge(coord))
	alchemy.queue_free()


func test_store_and_collect_shrine_charge_supports_multi_element_gifts() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()
	alchemy.set_element_charge_for_testing(GodaiElement.Value.CHI, 0)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.FU, 0)
	var coord: Vector2i = Vector2i(5, -2)
	assert_true(alchemy.store_shrine_charge(coord, GodaiElement.Value.CHI, 1))
	assert_true(alchemy.store_shrine_charge(coord, GodaiElement.Value.FU, 1))
	assert_true(alchemy.collect_shrine_charge(coord))
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.CHI), 1)
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.FU), 1)
	assert_false(alchemy.has_shrine_charge(coord))
	alchemy.queue_free()


func test_spirit_service_maps_fu_spirit_to_fu_and_fu_chi_spirit_to_both() -> void:
	var service: SpiritService = SpiritService.new()
	add_child(service)
	var fu_only_entry: Dictionary = {"preferred_biomes": [BiomeType.Value.MEADOW]}
	var fu_and_chi_entry: Dictionary = {"preferred_biomes": [BiomeType.Value.WHISTLING_CANYONS]}
	var fu_only: Array[int] = service._elements_for_spirit_charge(fu_only_entry)
	var fu_and_chi: Array[int] = service._elements_for_spirit_charge(fu_and_chi_entry)
	assert_eq(fu_only, [GodaiElement.Value.FU], "Fu spirit should map to Fu gift charge")
	assert_true(fu_and_chi.has(GodaiElement.Value.FU), "Fu+Chi spirit should include Fu gift charge")
	assert_true(fu_and_chi.has(GodaiElement.Value.CHI), "Fu+Chi spirit should include Chi gift charge")
	assert_eq(fu_and_chi.size(), 2, "Fu+Chi spirit should map to exactly two unique gift charges")
	service.queue_free()
