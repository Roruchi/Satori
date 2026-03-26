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
