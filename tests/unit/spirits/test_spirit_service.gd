## Test Suite: SpiritService
##
## GUT unit tests for SpiritService discovery routing, summoning logic,
## and interaction with SpiritWanderBounds / SpiritInstance.
## Run via tests/gut_runner.tscn

extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

# Ku-focused SpiritService coverage

class GameStateStub:
	extends Node
	var grid: RefCounted

class SatoriStub:
	extends Node
	var value: int = 0

	func get_satori_for_island(_island_id: String) -> int:
		return value

	func get_current_satori() -> int:
		return value

class CodexStub:
	extends Node
	var discovered: Array[StringName] = []

	func mark_discovered(entry_id: StringName) -> void:
		if discovered.has(entry_id):
			return
		discovered.append(entry_id)


func _make_grid() -> RefCounted:
	return GridMapScript.new()


func _make_game_state() -> Node:
	var game_state: Node = get_tree().root.get_node_or_null("/root/GameState")
	if game_state == null:
		var stub: GameStateStub = GameStateStub.new()
		stub.name = "GameState"
		game_state = stub
		get_tree().root.add_child(game_state)
	game_state.set("grid", _make_grid())
	return game_state


func _replace_root_node(p_name: String, node: Node) -> Node:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % p_name)
	if existing != null:
		root.remove_child(existing)
	node.name = p_name
	root.add_child(node)
	return existing


func _restore_root_node(p_name: String, replacement: Node, original: Node) -> void:
	var root: Node = get_tree().root
	if replacement != null:
		if replacement.get_parent() != null:
			replacement.get_parent().remove_child(replacement)
		replacement.free()
	if original != null:
		original.name = p_name
		root.add_child(original)


func _active_instance_for(svc: SpiritService, spirit_id: String) -> SpiritInstance:
	for key_variant: Variant in svc._active_instances.keys():
		var instance: SpiritInstance = svc._active_instances.get(key_variant, null)
		if instance != null and instance.spirit_id == spirit_id:
			return instance
	return null


func _active_instance_count_for(svc: SpiritService, spirit_id: String) -> int:
	var count: int = 0
	for key_variant: Variant in svc._active_instances.keys():
		var instance: SpiritInstance = svc._active_instances.get(key_variant, null)
		if instance != null and instance.spirit_id == spirit_id:
			count += 1
	return count


func _place_calm_water_island(grid: RefCounted, anchor_x: int, include_sacred: bool = true) -> Vector2i:
	for i: int in range(10):
		grid.place_tile(Vector2i(anchor_x + i, 0), BiomeType.Value.RIVER)
	var sacred_coord: Vector2i = Vector2i(anchor_x + 10, 0)
	if include_sacred:
		grid.place_tile(sacred_coord, BiomeType.Value.SACRED_STONE)
	return sacred_coord


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
	assert_not_null(_active_instance_for(svc, "spirit_red_fox"),
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
	var inst: SpiritInstance = _active_instance_for(svc, "spirit_emerald_snake")
	assert_not_null(inst, "Instance should exist after summoning")
	assert_eq(inst.spawn_coord, Vector2i(1, 1),
		"Spawn coord should be centroid of triggering coords")
	svc.queue_free()


func test_summoned_instance_wander_bounds_contains_spawn_coord() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	svc._on_discovery_triggered("spirit_red_fox", coords)
	var inst: SpiritInstance = _active_instance_for(svc, "spirit_red_fox")
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
	svc._current_era = SatoriIds.ERA_AWAKENING
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

func test_stillness_spirit_pacing_allows_small_unhoused_buffer() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.MEADOW)
	var island_id: String = str(grid.get_island_id(Vector2i.ZERO))

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_STILLNESS
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i.ZERO, Rect2i())
	fox.island_id = island_id
	var hare: SpiritInstance = SpiritInstance.create("spirit_hare", Vector2i.ZERO, Rect2i())
	hare.island_id = island_id
	svc._active_instances[svc._spirit_key("spirit_red_fox", island_id)] = fox
	svc._active_instances[svc._spirit_key("spirit_hare", island_id)] = hare

	assert_false(svc._can_spawn_under_era_pacing("spirit_tree_frog", island_id), "Stillness should pause a third spirit on an island with no houses")

	var house: GardenTile = grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)
	house.metadata["is_building_complete"] = true
	svc.mark_housing_dirty()
	assert_true(svc._can_spawn_under_era_pacing("spirit_tree_frog", island_id), "One completed house should make room for the third Stillness spirit")
	svc.queue_free()

func test_flow_spirit_pacing_is_open() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_FLOW
	for i: int in range(8):
		var instance: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(i, 0), Rect2i())
		instance.island_id = "island_a"
		svc._active_instances["island_a|spirit_%d" % i] = instance
	assert_true(svc._can_spawn_under_era_pacing("spirit_tree_frog", "island_a"), "Flow era should keep open spawn behavior")
	svc.queue_free()

func test_new_ku_deities_can_be_summoned_from_discoveries() -> void:
	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_FLOW
	var deity_ids: Array[String] = [
		"spirit_oyamatsumi",
		"spirit_kagutsuchi",
		"spirit_fujin",
	]
	for deity_id: String in deity_ids:
		var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(1, 1)]
		svc._on_discovery_triggered(deity_id, coords)
		assert_not_null(_active_instance_for(svc, deity_id), "Expected active instance for %s" % deity_id)
	svc.queue_free()

func test_suijin_requires_ten_water_tiles_chi_ku_and_satori_1000() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	for i: int in range(9):
		grid.place_tile(Vector2i(40 + i, 0), BiomeType.Value.RIVER)
	var sacred_coord: Vector2i = Vector2i(49, 0)
	grid.place_tile(sacred_coord, BiomeType.Value.SACRED_STONE)

	var satori_stub: SatoriStub = SatoriStub.new()
	satori_stub.value = 1000
	var original_satori: Node = _replace_root_node("SatoriService", satori_stub)

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_AWAKENING
	svc._on_discovery_triggered("spirit_suijin", [sacred_coord])
	assert_null(_active_instance_for(svc, "spirit_suijin"), "Suijin should wait for ten water tiles")

	grid.place_tile(Vector2i(50, 0), BiomeType.Value.RIVER)
	svc._on_discovery_triggered("spirit_suijin", [sacred_coord])
	assert_not_null(_active_instance_for(svc, "spirit_suijin"), "Suijin should arrive on a qualifying calm water island")

	svc.queue_free()
	_restore_root_node("SatoriService", satori_stub, original_satori)

func test_suijin_rejects_fire_based_tiles_on_candidate_island() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var sacred_coord: Vector2i = _place_calm_water_island(grid, 60)
	grid.place_tile(Vector2i(71, 0), BiomeType.Value.EMBER_FIELD)

	var satori_stub: SatoriStub = SatoriStub.new()
	satori_stub.value = 1000
	var original_satori: Node = _replace_root_node("SatoriService", satori_stub)

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_AWAKENING
	svc._on_discovery_triggered("spirit_suijin", [sacred_coord])
	assert_null(_active_instance_for(svc, "spirit_suijin"), "Any fire-based tile on the island should block Suijin")

	svc.queue_free()
	_restore_root_node("SatoriService", satori_stub, original_satori)

func test_suijin_invitation_is_island_local_duplicate_safe_and_marks_codex() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	_place_calm_water_island(grid, 80)
	var wrong_island_sacred: Vector2i = Vector2i(100, 0)
	grid.place_tile(wrong_island_sacred, BiomeType.Value.KU)
	grid.place_tile(Vector2i(101, 0), BiomeType.Value.SACRED_STONE)

	var satori_stub: SatoriStub = SatoriStub.new()
	satori_stub.value = 1000
	var original_satori: Node = _replace_root_node("SatoriService", satori_stub)
	var codex_stub: CodexStub = CodexStub.new()
	var original_codex: Node = _replace_root_node("CodexService", codex_stub)

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._current_era = SatoriIds.ERA_AWAKENING
	svc._on_discovery_triggered("spirit_suijin", [Vector2i(101, 0)])
	assert_null(_active_instance_for(svc, "spirit_suijin"), "Water on another island must not satisfy Suijin")

	var sacred_coord: Vector2i = Vector2i(90, 0)
	svc._on_discovery_triggered("spirit_suijin", [sacred_coord])
	svc._on_discovery_triggered("spirit_suijin", [sacred_coord])
	assert_eq(_active_instance_count_for(svc, "spirit_suijin"), 1, "Repeated scans should not duplicate Suijin")
	assert_true(codex_stub.discovered.has(&"spirit_suijin"), "Suijin arrival should mark the Codex entry")

	svc.queue_free()
	_restore_root_node("CodexService", codex_stub, original_codex)
	_restore_root_node("SatoriService", satori_stub, original_satori)

func test_housing_snapshot_reports_housed_and_unhoused_counts() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var house_a: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.MEADOW)
	house_a.metadata["is_building_complete"] = true
	var house_b: GardenTile = grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)
	house_b.metadata["is_building_complete"] = true
	var svc: SpiritService = _make_service()
	add_child(svc)
	var island_id: String = str(grid.get_island_id(Vector2i.ZERO))
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i.ZERO, Rect2i())
	fox.island_id = island_id
	var stag: SpiritInstance = SpiritInstance.create("spirit_mist_stag", Vector2i(1, 0), Rect2i())
	stag.island_id = island_id
	var hare: SpiritInstance = SpiritInstance.create("spirit_hare", Vector2i(2, 0), Rect2i())
	hare.island_id = island_id
	svc._active_instances[svc._spirit_key("spirit_red_fox", island_id)] = fox
	svc._active_instances[svc._spirit_key("spirit_mist_stag", island_id)] = stag
	svc._active_instances[svc._spirit_key("spirit_hare", island_id)] = hare
	var snapshot: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot.get("housed_count", -1)), 2)
	assert_eq(int(snapshot.get("unhoused_count", -1)), 1)
	svc.queue_free()

func test_housing_assignment_is_cached_until_marked_dirty() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var house: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.MEADOW)
	house.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var island_id: String = str(grid.get_island_id(Vector2i(1, 0)))
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 0), Rect2i())
	fox.island_id = island_id
	svc._active_instances[svc._spirit_key("spirit_red_fox", island_id)] = fox

	assert_true(svc.is_spirit_housed("spirit_red_fox", island_id))
	var recomputes_after_first_lookup: int = svc.get_housing_recompute_count()
	assert_true(svc.is_spirit_housed("spirit_red_fox", island_id))
	svc.get_housing_snapshot()
	assert_eq(svc.get_housing_recompute_count(), recomputes_after_first_lookup)

	svc.mark_housing_dirty()
	svc.get_housing_snapshot()
	assert_eq(svc.get_housing_recompute_count(), recomputes_after_first_lookup + 1)
	svc.queue_free()

func test_has_housed_spirit_matches_island_scoped_assignments() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var house: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.MEADOW)
	house.metadata["is_building_complete"] = true
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var island_id: String = str(grid.get_island_id(Vector2i(1, 0)))
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 0), Rect2i())
	fox.island_id = island_id
	svc._active_instances[svc._spirit_key("spirit_red_fox", island_id)] = fox

	assert_true(svc.has_housed_spirit("spirit_red_fox"))
	assert_false(svc.has_housed_spirit("spirit_hare"))
	svc.queue_free()

func test_housing_does_not_use_houses_from_other_islands() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_housing_falls_back_to_any_house_on_same_island_when_preferred_missing() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_house_binding_remains_with_spirit_after_recompute() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_red_fox_rebinds_to_fox_den_upgrade() -> void:
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var meadow_house_coord: Vector2i = Vector2i(20, 0)
	var meadow_house: GardenTile = grid.place_tile(meadow_house_coord, BiomeType.Value.MEADOW)
	meadow_house.metadata["is_building_complete"] = true
	meadow_house.metadata["structure_discovery_id"] = "building_meadow_dwelling"
	grid.place_tile(Vector2i(20, 1), BiomeType.Value.MEADOW)

	var svc: SpiritService = _make_service()
	add_child(svc)
	var island_id: String = str(grid.get_island_id(Vector2i(20, 1)))
	var fox: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(20, 1), Rect2i())
	fox.island_id = island_id
	var fox_key: String = "island_%s|spirit_spirit_red_fox" % island_id
	svc._active_instances[fox_key] = fox

	svc.get_housing_snapshot()
	assert_eq(str(svc._house_binding_by_spirit.get(fox_key, "")), "20,0")

	var fox_den_coord: Vector2i = Vector2i(21, 0)
	var fox_den: GardenTile = grid.place_tile(fox_den_coord, BiomeType.Value.MEADOW)
	fox_den.metadata["is_building_complete"] = true
	fox_den.metadata["structure_discovery_id"] = "building_fox_den"
	svc.mark_housing_dirty()
	var snapshot: Dictionary = svc.get_housing_snapshot()

	assert_eq(str(svc._house_binding_by_spirit.get(fox_key, "")), "21,0")
	assert_eq(int(snapshot.get("housed_count", -1)), 1)
	assert_eq(int(snapshot.get("upgraded_housed_count", -1)), 1)
	assert_eq(str(svc.get_house_owner_at_coord(fox_den_coord).get("spirit_id", "")), "spirit_red_fox")

	svc.queue_free()

func test_get_house_owner_at_coord_returns_bound_spirit() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var tile: GardenTile = grid.place_tile(Vector2i(3, 0), BiomeType.Value.STONE)
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_countdown_started"] = true
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

func test_finalize_pending_buildings_completes_multiple_elapsed_countdowns() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_tile_placed_spawns_same_spirit_on_two_ku_separated_islands() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_tile_placed_does_not_respawn_same_spirit_when_island_id_changes() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_island_id_drift_rekeys_spirit_without_losing_house_binding() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

	var snapshot_after: Dictionary = svc.get_housing_snapshot()
	assert_eq(int(snapshot_after.get("housed_count", -1)), 1)
	assert_true(svc._house_binding_by_spirit.has(after_key), "Expected house binding to rekey with spirit")
	assert_true(svc.is_spirit_housed("spirit_red_fox", after_island_id), "Red fox should remain housed after island expansion")

	svc.queue_free()

func test_finalize_pending_buildings_converts_pending_origin_shrine_metadata() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_finalize_pending_buildings_converts_pending_structure_metadata() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
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

func test_finalize_pending_torii_project_marks_all_tiles_as_structure_not_houses() -> void:
	var root: Node = get_tree().root
	var game_state: Node = _make_game_state()
	var grid: RefCounted = game_state.get("grid")
	var coords: Array[Vector2i] = [Vector2i(30, 0), Vector2i(31, 0), Vector2i(30, 1)]
	for i: int in range(coords.size()):
		var tile: GardenTile = grid.place_tile(coords[i], BiomeType.Value.RIVER)
		tile.metadata["is_build_block"] = true
		tile.metadata["is_building_complete"] = false
		tile.metadata["build_countdown_started"] = true
		tile.metadata["build_started_at"] = Time.get_unix_time_from_system() - 20.0
		tile.metadata["build_duration"] = 1.0
		tile.metadata["pending_structure_id"] = "disc_wayfarer_torii"
		tile.metadata["pending_structure_anchor"] = i == 0
		tile.locked = true

	var svc: SpiritService = _make_service()
	add_child(svc)
	svc._finalize_pending_buildings()

	var anchor_count: int = 0
	var footprint_count: int = 0
	for coord: Vector2i in coords:
		var tile: GardenTile = grid.get_tile(coord)
		assert_true(bool(tile.metadata.get("shrine_built", false)))
		assert_false(bool(tile.metadata.get("is_building_complete", true)))
		assert_false(tile.locked)
		if str(tile.metadata.get("structure_discovery_id", "")) == "disc_wayfarer_torii":
			footprint_count += 1
		if str(tile.metadata.get("build_discovery_id", "")) == "disc_wayfarer_torii":
			anchor_count += 1
	assert_eq(anchor_count, 1, "Exactly one anchor tile should carry build_discovery_id for multi-tile structure")
	assert_eq(footprint_count, 3, "All Torii project tiles should be marked as structure footprint")

	svc.queue_free()
