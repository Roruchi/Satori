## Test Suite: SpiritService
##
## GUT unit tests for SpiritService discovery routing, summoning logic,
## and interaction with SpiritWanderBounds / SpiritInstance.
## Run via tests/gut_runner.tscn

extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

# Ku-focused SpiritService coverage


func _make_grid() -> RefCounted:
	return GridMapScript.new()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_service() -> SpiritService:
	var svc := SpiritService.new()
	# Manually init catalog and evaluators without connecting autoloads
	svc._catalog = SpiritCatalog.new()
	svc._catalog.load_from_data(SpiritCatalogData.new())
	svc._riddle_evaluator = SpiritRiddleEvaluator.new()
	svc._sky_whale_evaluator = SkyWhaleEvaluator.new()
	svc._spawner = SpiritSpawner.new()
	return svc


# ---------------------------------------------------------------------------
# _on_discovery_triggered: ignores non-spirit_ prefixed IDs
# ---------------------------------------------------------------------------

func test_non_spirit_discovery_id_does_not_emit_signal() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	watch_signals(svc)
	svc._on_discovery_triggered("disc_deep_stand", [Vector2i(0, 0)])
	assert_signal_not_emitted(svc, "spirit_summoned",
		"Non-spirit_ discovery should not emit spirit_summoned")
	svc.queue_free()


func test_non_spirit_prefix_does_not_create_active_instance() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._on_discovery_triggered("disc_glade", [Vector2i(0, 0)])
	assert_false(svc._active_instances.has("disc_glade"),
		"Non-spirit_ ID should not be added to active_instances")
	svc.queue_free()


# ---------------------------------------------------------------------------
# _on_discovery_triggered: spirit_red_fox triggers spirit_summoned
# ---------------------------------------------------------------------------

func test_spirit_red_fox_discovery_emits_spirit_summoned() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	watch_signals(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	svc._on_discovery_triggered("spirit_red_fox", coords)
	assert_signal_emitted(svc, "spirit_summoned",
		"spirit_red_fox discovery should emit spirit_summoned")
	svc.queue_free()


func test_spirit_red_fox_discovery_creates_active_instance() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	svc._on_discovery_triggered("spirit_red_fox", coords)
	assert_true(svc._active_instances.has("spirit_red_fox"),
		"spirit_red_fox should be added to active_instances after discovery")
	svc.queue_free()


# ---------------------------------------------------------------------------
# _on_discovery_triggered: does not re-summon already-active spirit
# ---------------------------------------------------------------------------

func test_already_active_spirit_does_not_re_emit() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	svc._on_discovery_triggered("spirit_red_fox", coords)
	watch_signals(svc)
	svc._on_discovery_triggered("spirit_red_fox", coords)
	assert_signal_not_emitted(svc, "spirit_summoned",
		"Re-triggering already-summoned spirit should not emit spirit_summoned again")
	svc.queue_free()


# ---------------------------------------------------------------------------
# SpiritWanderBounds + centroid used correctly via SpiritInstance
# ---------------------------------------------------------------------------

func test_summoned_instance_spawn_coord_is_centroid_of_triggering_coords() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	# Use coords with known centroid: (0,0),(2,0),(0,2),(2,2) -> centroid (1,1)
	var coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(2, 2)
	]
	svc._on_discovery_triggered("spirit_emerald_snake", coords)
	var inst: SpiritInstance = svc._active_instances.get("spirit_emerald_snake")
	assert_not_null(inst, "Instance should exist after summoning")
	assert_eq(inst.spawn_coord, Vector2i(1, 1),
		"Spawn coord should be centroid of triggering coords")
	svc.queue_free()


func test_summoned_instance_wander_bounds_contains_spawn_coord() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	svc._on_discovery_triggered("spirit_red_fox", coords)
	var inst: SpiritInstance = svc._active_instances.get("spirit_red_fox")
	assert_not_null(inst, "Instance should exist")
	assert_true(inst.wander_bounds.has_point(inst.spawn_coord),
		"Wander bounds should contain the spawn coord")
	svc.queue_free()

func test_repeated_mist_stag_discovery_unlocks_ku_once() -> void:
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
	var svc: SpiritService = _make_service()
	add_child(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	svc._on_discovery_triggered("spirit_mist_stag", coords)
	svc._on_discovery_triggered("spirit_mist_stag", coords)
	assert_eq(alchemy.is_ku_unlocked(), true, "Mist Stag summon should unlock Ku")
	assert_eq(get_signal_emit_count(alchemy, "element_unlocked"), 1, "Repeated Mist Stag discovery should not re-unlock Ku")
	svc.queue_free()
	alchemy.queue_free()

func test_mist_stag_does_not_spawn_in_stillness_era() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_STILLNESS
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	svc._on_discovery_triggered("spirit_mist_stag", coords)
	assert_false(svc._is_spirit_active_anywhere("spirit_mist_stag"), "Mist Stag should not spawn during Stillness era")
	svc.queue_free()

func test_mist_stag_spawns_in_awakening_era() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_AWAKENING
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	svc._on_discovery_triggered("spirit_mist_stag", coords)
	assert_true(svc._is_spirit_active_anywhere("spirit_mist_stag"), "Mist Stag should spawn in Awakening era")
	svc.queue_free()

func test_new_ku_deities_can_be_summoned_from_discoveries() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var deity_ids: Array[String] = [
		"spirit_oyamatsumi",
		"spirit_suijin",
		"spirit_kagutsuchi",
		"spirit_fujin",
	]
	for deity_id: String in deity_ids:
		var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(1, 1)]
		svc._on_discovery_triggered(deity_id, coords)
		assert_true(svc._active_instances.has(deity_id), "Expected active instance for %s" % deity_id)
	svc.queue_free()

func test_housing_snapshot_reports_housed_and_unhoused_counts() -> void:
	var root: Node = get_tree().root
	var satori_service: SatoriServiceNode = SatoriServiceNode.new()
	satori_service.name = "SatoriService"
	root.add_child(satori_service)
	satori_service._structures = [
		{"discovery_id": "disc_deep_stand", "housing_capacity": 1},
		{"discovery_id": "disc_glade", "housing_capacity": 1},
	]
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._active_instances["spirit_red_fox"] = SpiritInstance.create("spirit_red_fox", Vector2i.ZERO, Rect2i())
	svc._active_instances["spirit_mist_stag"] = SpiritInstance.create("spirit_mist_stag", Vector2i(1, 0), Rect2i())
	svc._active_instances["spirit_hare"] = SpiritInstance.create("spirit_hare", Vector2i(2, 0), Rect2i())
	var snapshot: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot.get("housed_count", -1)), 2)
	assert_eq(int(snapshot.get("unhoused_count", -1)), 1)
	svc.queue_free()
	satori_service.queue_free()

func test_housing_does_not_use_houses_from_other_islands() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	# House exists on island A.
	var house_tile: GardenTile = grid.place_tile(Vector2i(0, 0), BiomeType.Value.MEADOW)
	house_tile.metadata["is_building_complete"] = true
	# KU separator and spirit on island B.
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.KU)
	grid.place_tile(Vector2i(3, 0), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(3, 0), Rect2i())
	fox.island_id = str(grid.get_island_id(Vector2i(3, 0)))
	svc._active_instances["island_%s|spirit_spirit_red_fox" % fox.island_id] = fox

	var snapshot: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot.get("housed_count", -1)), 0)
	assert_eq(int(snapshot.get("unhoused_count", -1)), 1)

	svc.queue_free()
	game_state.queue_free()

func test_housing_falls_back_to_any_house_on_same_island_when_preferred_missing() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	# Only a stone house exists on this island.
	var house_tile: GardenTile = grid.place_tile(Vector2i(0, 0), BiomeType.Value.STONE)
	house_tile.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 0), Rect2i())
	fox.island_id = str(grid.get_island_id(Vector2i(1, 0)))
	var fox_key: String = "island_%s|spirit_spirit_red_fox" % fox.island_id
	svc._active_instances[fox_key] = fox

	var snapshot: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot.get("housed_count", -1)), 1)
	assert_true(svc._house_binding_by_spirit.has(fox_key))

	svc.queue_free()
	game_state.queue_free()

func test_house_binding_remains_with_spirit_after_recompute() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var house_a: GardenTile = grid.place_tile(Vector2i(0, 0), BiomeType.Value.MEADOW)
	house_a.metadata["is_building_complete"] = true
	var house_b: GardenTile = grid.place_tile(Vector2i(1, 0), BiomeType.Value.STONE)
	house_b.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(0, 1), Rect2i())
	fox.island_id = str(grid.get_island_id(Vector2i(0, 1)))
	var fox_key: String = "island_%s|spirit_spirit_red_fox" % fox.island_id
	svc._active_instances[fox_key] = fox

	svc.get_housing_snapshot()
	var initial_binding: String = str(svc._house_binding_by_spirit.get(fox_key, ""))
	assert_false(initial_binding.is_empty())

	var hare: SpiritInstance = SpiritInstance.create("spirit_hare", Vector2i(0, 1), Rect2i())
	hare.island_id = fox.island_id
	var hare_key: String = "island_%s|spirit_spirit_hare" % hare.island_id
	svc._active_instances[hare_key] = hare

	svc.get_housing_snapshot()
	assert_eq(str(svc._house_binding_by_spirit.get(fox_key, "")), initial_binding)

	svc.queue_free()
	game_state.queue_free()

func test_get_house_owner_at_coord_returns_bound_spirit() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var house_coord: Vector2i = Vector2i(12, 0)
	var house: GardenTile = grid.place_tile(house_coord, BiomeType.Value.MEADOW)
	house.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(12, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(12, 1), Rect2i())
	fox.island_id = str(grid.get_island_id(Vector2i(12, 1)))
	var fox_key: String = "island_%s|spirit_spirit_red_fox" % fox.island_id
	svc._active_instances[fox_key] = fox
	# Force assignment compute.
	svc.get_housing_snapshot()

	var owner: Dictionary = svc.get_house_owner_at_coord(house_coord)
	assert_eq(str(owner.get("spirit_id", "")), "spirit_red_fox")
	assert_false(str(owner.get("display_name", "")).is_empty())

	svc.queue_free()
	game_state.queue_free()

func test_era_drop_despawns_spirits_below_required_threshold() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var stag: SpiritInstance = SpiritInstance.create("spirit_mist_stag", Vector2i.ZERO, Rect2i())
	svc._active_instances["spirit_mist_stag"] = stag
	svc._on_era_changed(SatoriIds.ERA_STILLNESS)
	assert_false(svc._active_instances.has("spirit_mist_stag"), "Tier2 spirit should despawn in Stillness era")
	svc.queue_free()

func test_is_spirit_housed_reports_false_for_unhoused_spirit() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._active_instances["spirit_red_fox"] = SpiritInstance.create("spirit_red_fox", Vector2i.ZERO, Rect2i())
	assert_false(svc.is_spirit_housed("spirit_red_fox", ""))
	svc.queue_free()

func test_finalize_pending_buildings_clears_locked_state() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var tile: GardenTile = grid.place_tile(Vector2i(3, 0), BiomeType.Value.STONE)
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_started_at"] = Time.get_unix_time_from_system() - 20.0
	tile.metadata["build_duration"] = 1.0
	tile.locked = true

	var svc: SpiritService = _make_service()
	add_child(svc)
	var builder: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(3, 0), Rect2i())
	svc._active_instances["spirit_red_fox"] = builder
	svc._finalize_pending_buildings()

	assert_true(bool(tile.metadata.get("is_building_complete", false)))
	assert_false(tile.locked)

	svc.queue_free()
	game_state.queue_free()

func test_finalize_pending_buildings_completes_multiple_elapsed_countdowns() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var first_tile: GardenTile = grid.place_tile(Vector2i(4, 0), BiomeType.Value.STONE)
	var second_tile: GardenTile = grid.place_tile(Vector2i(5, 0), BiomeType.Value.RIVER)
	for tile: GardenTile in [first_tile, second_tile]:
		tile.metadata["is_build_block"] = true
		tile.metadata["is_building_complete"] = false
		tile.metadata["build_countdown_started"] = true
		tile.metadata["build_started_at"] = Time.get_unix_time_from_system() - 20.0
		tile.metadata["build_duration"] = 1.0
		tile.locked = true

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._finalize_pending_buildings()

	assert_true(bool(first_tile.metadata.get("is_building_complete", false)))
	assert_true(bool(second_tile.metadata.get("is_building_complete", false)))
	assert_false(bool(first_tile.metadata.get("is_build_block", true)))
	assert_false(bool(second_tile.metadata.get("is_build_block", true)))
	assert_false(first_tile.locked)
	assert_false(second_tile.locked)

	svc.queue_free()
	game_state.queue_free()

func test_tile_placed_spawns_same_spirit_on_two_ku_separated_islands() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")

	# Island A (red fox L-shape)
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.MEADOW)
	# KU divider and Island B (same shape)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.KU)
	grid.place_tile(Vector2i(4, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(5, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(4, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	var loader: PatternLoader = PatternLoader.new()
	svc._spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	add_child(svc)

	svc._on_tile_placed(Vector2i(0, 0), grid.get_tile(Vector2i(0, 0)))
	svc._on_tile_placed(Vector2i(4, 0), grid.get_tile(Vector2i(4, 0)))

	var red_fox_count: int = 0
	for key_variant: Variant in svc._active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = svc._active_instances.get(key, null)
		if instance != null and instance.spirit_id == "spirit_red_fox":
			red_fox_count += 1
	assert_eq(red_fox_count, 2, "Expected one red fox spirit per Ku-separated island")

	svc.queue_free()
	game_state.queue_free()

func test_tile_placed_does_not_respawn_same_spirit_when_island_id_changes() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")

	grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(1, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	var loader: PatternLoader = PatternLoader.new()
	svc._spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	add_child(svc)

	svc._on_tile_placed(Vector2i(1, 0), grid.get_tile(Vector2i(1, 0)))
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.MEADOW)
	svc._on_tile_placed(Vector2i(0, 0), grid.get_tile(Vector2i(0, 0)))

	var red_fox_count: int = 0
	for key_variant: Variant in svc._active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = svc._active_instances.get(key, null)
		if instance != null and instance.spirit_id == "spirit_red_fox":
			red_fox_count += 1
	assert_eq(red_fox_count, 1, "Expected only one red fox on same island even after island ID drift")

	svc.queue_free()
	game_state.queue_free()

func test_island_id_drift_rekeys_spirit_without_losing_house_binding() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")

	# Build a red-fox L-shape and mark one tile as a completed house.
	var house_coord: Vector2i = Vector2i(1, 0)
	var house_tile: GardenTile = grid.place_tile(house_coord, BiomeType.Value.MEADOW)
	house_tile.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.MEADOW)
	grid.place_tile(Vector2i(1, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	var loader: PatternLoader = PatternLoader.new()
	svc._spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	add_child(svc)

	svc._on_tile_placed(house_coord, grid.get_tile(house_coord))

	var before_key: String = ""
	for key_variant: Variant in svc._active_instances.keys():
		var key: String = str(key_variant)
		var inst: SpiritInstance = svc._active_instances.get(key, null)
		if inst != null and inst.spirit_id == "spirit_red_fox":
			before_key = key
			break
	assert_false(before_key.is_empty(), "Expected red fox instance before island expansion")
	assert_true(svc._active_wanderers.has(before_key), "Expected wanderer key before island expansion")

	var snapshot_before: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot_before.get("housed_count", -1)), 1)
	assert_true(svc._house_binding_by_spirit.has(before_key), "Expected house binding before island expansion")

	# Expanding left can change the canonical island ID for the existing component.
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.MEADOW)
	svc._on_tile_placed(Vector2i(0, 0), grid.get_tile(Vector2i(0, 0)))

	var fox_count: int = 0
	var after_key: String = ""
	var after_island_id: String = ""
	for key_variant: Variant in svc._active_instances.keys():
		var key: String = str(key_variant)
		var inst: SpiritInstance = svc._active_instances.get(key, null)
		if inst != null and inst.spirit_id == "spirit_red_fox":
			fox_count += 1
			after_key = key
			after_island_id = inst.island_id
	assert_eq(fox_count, 1, "Expected one red fox after island ID drift")
	assert_false(after_key.is_empty(), "Expected red fox key after island expansion")
	assert_true(svc._active_wanderers.has(after_key), "Expected wanderer to rekey with spirit")

	var snapshot_after: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot_after.get("housed_count", -1)), 1)
	assert_true(svc._house_binding_by_spirit.has(after_key), "Expected house binding to rekey with spirit")
	assert_true(svc.is_spirit_housed("spirit_red_fox", after_island_id), "Red fox should remain housed after island expansion")

	svc.queue_free()
	game_state.queue_free()

func test_finalize_pending_buildings_converts_pending_origin_shrine_metadata() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var tile: GardenTile = grid.place_tile(Vector2i(8, 0), BiomeType.Value.STONE)
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_countdown_started"] = true
	tile.metadata["build_started_at"] = Time.get_unix_time_from_system() - 20.0
	tile.metadata["build_duration"] = 1.0
	tile.metadata["pending_origin_shrine"] = true
	tile.locked = true

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._finalize_pending_buildings()

	assert_true(bool(tile.metadata.get("is_origin_shrine", false)))
	assert_true(bool(tile.metadata.get("shrine_built", false)))
	assert_eq(str(tile.metadata.get("build_discovery_id", "")), "disc_origin_shrine")
	assert_false(bool(tile.metadata.get("is_building_complete", true)))
	assert_false(tile.locked)

	svc.queue_free()
	game_state.queue_free()

func test_finalize_pending_buildings_converts_pending_structure_metadata() -> void:
	var root: Node = get_tree().root
	var game_state: Node = Node.new()
	game_state.name = "GameState"
	game_state.set("grid", _make_grid())
	root.add_child(game_state)
	var grid: RefCounted = game_state.get("grid")
	var tile: GardenTile = grid.place_tile(Vector2i(9, 0), BiomeType.Value.WETLANDS)
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_countdown_started"] = true
	tile.metadata["build_started_at"] = Time.get_unix_time_from_system() - 20.0
	tile.metadata["build_duration"] = 1.0
	tile.metadata["pending_structure_id"] = "disc_lotus_pagoda"
	tile.locked = true

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._finalize_pending_buildings()

	assert_true(bool(tile.metadata.get("shrine_built", false)))
	assert_eq(str(tile.metadata.get("build_discovery_id", "")), "disc_lotus_pagoda")
	assert_false(bool(tile.metadata.get("is_building_complete", true)))
	assert_false(tile.locked)

	svc.queue_free()
	game_state.queue_free()
