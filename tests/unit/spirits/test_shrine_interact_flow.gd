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

func test_get_shrine_charge_counts_returns_pending_amounts() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()
	var coord: Vector2i = Vector2i(7, -3)
	assert_true(alchemy.store_shrine_charge(coord, GodaiElement.Value.CHI, 1))
	assert_true(alchemy.store_shrine_charge(coord, GodaiElement.Value.FU, 2))
	var counts: Dictionary = alchemy.get_shrine_charge_counts(coord)
	assert_eq(int(counts.get(GodaiElement.Value.CHI, 0)), 1)
	assert_eq(int(counts.get(GodaiElement.Value.FU, 0)), 2)
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

func test_water_spirit_prefers_completed_water_house_for_charge_dropoff() -> void:
	var root: Node = get_tree().root
	var existing_game_state: Node = root.get_node_or_null("/root/GameState")
	if existing_game_state != null:
		existing_game_state.queue_free()
		await get_tree().process_frame
	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
		await get_tree().process_frame

	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", GridMapScript.new())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var origin_coord: Vector2i = Vector2i.ZERO
	var origin_tile: GardenTile = grid.place_tile(origin_coord, BiomeType.Value.STONE)
	origin_tile.metadata["is_origin_shrine"] = true

	var water_house_coord: Vector2i = Vector2i(1, 0)
	var water_house: GardenTile = grid.place_tile(water_house_coord, BiomeType.Value.RIVER)
	water_house.metadata["is_building_complete"] = true

	var spirit_coord: Vector2i = Vector2i(2, 0)
	var spirit_tile: GardenTile = grid.place_tile(spirit_coord, BiomeType.Value.RIVER)
	spirit_tile.metadata["spirit_id"] = "spirit_suijin"

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()

	SpiritGiftProcessor.process_gift(SpiritGiftType.Value.GODAI_CHARGE, &"spirit_suijin:1")

	assert_true(alchemy.has_shrine_charge(water_house_coord), "Water spirit essence should drop at completed water house")
	assert_false(alchemy.has_shrine_charge(origin_coord), "Water spirit essence should not fallback to origin shrine when a water house exists")

	alchemy.queue_free()
	game_state.queue_free()

func test_mist_stag_essence_drop_restores_only_ku_charge() -> void:
	var root: Node = get_tree().root
	var existing_game_state: Node = root.get_node_or_null("/root/GameState")
	if existing_game_state != null:
		existing_game_state.queue_free()
		await get_tree().process_frame
	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
		await get_tree().process_frame

	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", GridMapScript.new())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var origin_tile: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	origin_tile.metadata["is_origin_shrine"] = true
	var spirit_tile: GardenTile = grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)
	spirit_tile.metadata["spirit_id"] = "spirit_mist_stag"

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()
	alchemy.set_element_charge_for_testing(GodaiElement.Value.CHI, 0)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.SUI, 0)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.KA, 0)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.FU, 0)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.KU, 0)

	var svc: SpiritService = SpiritService.new()
	add_child(svc)
	svc._catalog = SpiritCatalog.new()
	svc._catalog.load_from_data(SpiritCatalogData.new())
	svc._spawner = SpiritSpawner.new()

	var entry: Dictionary = svc.get_catalog_entry("spirit_mist_stag")
	svc._maybe_queue_godai_charge_drop("spirit_mist_stag", entry)
	assert_true(alchemy.collect_shrine_charge(Vector2i.ZERO))
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.KU), 1)
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.CHI), 0)
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.SUI), 0)
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.KA), 0)
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.FU), 0)

	svc.queue_free()
	alchemy.queue_free()
	game_state.queue_free()

func test_godai_charge_prefers_origin_shrine_on_spirit_island() -> void:
	var root: Node = get_tree().root
	var existing_game_state: Node = root.get_node_or_null("/root/GameState")
	if existing_game_state != null:
		existing_game_state.queue_free()
		await get_tree().process_frame
	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
		await get_tree().process_frame

	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", GridMapScript.new())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")

	var origin_a: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	origin_a.metadata["is_origin_shrine"] = true
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.KU)
	var origin_b_coord: Vector2i = Vector2i(4, 0)
	var origin_b: GardenTile = grid.place_tile(origin_b_coord, BiomeType.Value.STONE)
	origin_b.metadata["is_origin_shrine"] = true
	var spirit_coord: Vector2i = Vector2i(5, 0)
	var spirit_tile: GardenTile = grid.place_tile(spirit_coord, BiomeType.Value.MEADOW)
	spirit_tile.metadata["spirit_id"] = "spirit_red_fox"

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()

	SpiritGiftProcessor.process_gift(SpiritGiftType.Value.GODAI_CHARGE, &"spirit_red_fox:0")

	assert_true(alchemy.has_shrine_charge(origin_b_coord), "Charge should drop at origin shrine on spirit island")
	assert_false(alchemy.has_shrine_charge(Vector2i.ZERO), "Charge should not drop at origin shrine on a different island")

	alchemy.queue_free()
	game_state.queue_free()

func test_unique_monument_attempt_is_blocked_when_already_built() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service.set_structures_for_testing([
		{"discovery_id": "disc_great_torii", "is_unique": true}
	])
	assert_false(service.can_build_structure("disc_great_torii"))
	assert_true(service.can_build_structure("disc_deep_stand"))
	service.queue_free()
