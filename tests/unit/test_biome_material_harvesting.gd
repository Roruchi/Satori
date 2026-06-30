extends GutTest

const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const RitualAttemptResultScript = preload("res://src/seeds/RitualAttemptResult.gd")
const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")
const HexUtilsScript = preload("res://src/grid/hex_utils.gd")

class DiscoveryStub:
	extends Node
	var discovered_ids: Array[StringName] = []
	func get_discovered_ids() -> Array[StringName]:
		return discovered_ids

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

	var discovery: DiscoveryStub = DiscoveryStub.new()
	_add_root_singleton("DiscoveryPersistence", discovery)

	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	_add_root_singleton("SeedAlchemyService", alchemy)
	alchemy._ready()

	return {"game_state": game_state, "growth": growth, "alchemy": alchemy, "discovery": discovery}

func _cleanup_context(ctx: Dictionary) -> void:
	for key: String in ["growth", "alchemy", "discovery"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			var node: Node = node_variant as Node
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()

func _spawn_materials(game_state: Node, delta_seconds: float) -> Array:
	var spawned_variant: Variant = game_state.evaluate_material_spawns(delta_seconds)
	if spawned_variant is Array:
		return spawned_variant as Array
	return []

func _mature_materials(game_state: Node, delta_seconds: float = 60.0) -> void:
	game_state.evaluate_material_spawns(delta_seconds)

func _complete_structure(game_state: Node, coord: Vector2i, biome: int, structure_id: String) -> GardenTile:
	game_state.place_tile_from_seed(coord, biome)
	var tile: GardenTile = game_state.grid.get_tile(coord)
	assert_not_null(tile)
	tile.metadata["is_building_complete"] = true
	tile.metadata["structure_discovery_id"] = structure_id
	return tile

func test_meadow_tile_does_not_spawn_living_wood_immediately() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	var node: Dictionary = game_state.get_material_node_at(coord)
	assert_true(node.is_empty())
	_cleanup_context(ctx)

func test_single_meadow_tile_spawns_living_wood_after_full_interval() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 99.0).size(), 0)
	assert_eq(_spawn_materials(game_state, 1.0).size(), 1)
	var node: Dictionary = game_state.get_material_node_at(coord)
	assert_false(node.is_empty())
	assert_eq(StringName(str(node.get("material_id", &""))), &"living_wood")
	assert_eq(StringName(str(node.get("state", &""))), &"growing")
	assert_eq(int(node.get("growth_stage", -1)), 0)
	assert_eq(int(node.get("amount", 0)), 1)
	assert_false(game_state.has_ready_material_at(coord))
	assert_eq(StringName(str(game_state.harvest_material_at(coord).get("outcome", &""))), &"not_ready")
	_mature_materials(game_state)
	node = game_state.get_material_node_at(coord)
	assert_eq(StringName(str(node.get("state", &""))), &"ready")
	assert_eq(int(node.get("growth_stage", -1)), 3)
	_cleanup_context(ctx)

func test_ten_meadow_cluster_spawns_one_living_wood_after_ten_seconds() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	for index: int in range(10):
		game_state.place_tile_from_seed(Vector2i(index + 1, 0), BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 9.0).size(), 0)
	var spawned: Array = _spawn_materials(game_state, 1.0)
	assert_eq(spawned.size(), 1)
	var ready_count: int = 0
	for index: int in range(10):
		if game_state.has_ready_material_at(Vector2i(index + 1, 0)):
			ready_count += 1
	assert_eq(ready_count, 0)
	_mature_materials(game_state)
	ready_count = 0
	for index: int in range(10):
		if game_state.has_ready_material_at(Vector2i(index + 1, 0)):
			ready_count += 1
	assert_eq(ready_count, 1)
	_cleanup_context(ctx)

func test_full_meadow_cluster_does_not_spawn_extra_materials() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 0)
	_mature_materials(game_state)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 0)
	assert_true(game_state.has_ready_material_at(coord))
	_cleanup_context(ctx)

func test_material_spawn_skips_structure_tiles() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var structure_coord: Vector2i = Vector2i(1, 0)
	var spawn_coord: Vector2i = Vector2i(2, 0)
	game_state.place_tile_from_seed(structure_coord, BiomeTypeScript.Value.MEADOW)
	game_state.place_tile_from_seed(spawn_coord, BiomeTypeScript.Value.MEADOW)
	var structure_tile: GardenTile = game_state.grid.get_tile(structure_coord)
	assert_not_null(structure_tile)
	structure_tile.metadata["is_building_complete"] = true
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	assert_false(game_state.has_ready_material_at(structure_coord))
	_mature_materials(game_state)
	assert_true(game_state.has_ready_material_at(spawn_coord))
	_cleanup_context(ctx)

func test_material_nodes_spawn_for_water_stone_and_fire_families_after_interval() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var cases: Array[Dictionary] = [
		{"coord": Vector2i(1, 0), "biome": BiomeTypeScript.Value.RIVER, "material": &"reed_fiber", "visual": &"water_fish_reeds"},
		{"coord": Vector2i(0, 1), "biome": BiomeTypeScript.Value.STONE, "material": &"spirit_stone", "visual": &"spirit_stone_minerals"},
		{"coord": Vector2i(-1, 1), "biome": BiomeTypeScript.Value.EMBER_FIELD, "material": &"ember_clay", "visual": &"ember_clay_shards"},
	]
	for case: Dictionary in cases:
		var coord: Vector2i = case["coord"]
		game_state.place_tile_from_seed(coord, int(case["biome"]))
		assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
		var node: Dictionary = game_state.get_material_node_at(coord)
		assert_eq(StringName(str(node.get("material_id", &""))), StringName(str(case["material"])))
		assert_eq(StringName(str(node.get("visual_id", &""))), StringName(str(case["visual"])))
		assert_eq(StringName(str(node.get("state", &""))), &"growing")
		_mature_materials(game_state)
		node = game_state.get_material_node_at(coord)
		assert_eq(StringName(str(node.get("state", &""))), &"ready")
	_cleanup_context(ctx)

func test_harvesting_living_wood_adds_material_once() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	_mature_materials(game_state)
	var result: Dictionary = game_state.harvest_material_at(coord)
	assert_eq(StringName(str(result.get("outcome", &""))), &"success")
	assert_eq(alchemy.get_material_count(&"living_wood"), 1)
	var duplicate_result: Dictionary = game_state.harvest_material_at(coord)
	assert_eq(StringName(str(duplicate_result.get("outcome", &""))), &"missing_node")
	assert_eq(alchemy.get_material_count(&"living_wood"), 1)
	_cleanup_context(ctx)

func test_harvesting_non_wood_materials_updates_material_inventory() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.RIVER)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	_mature_materials(game_state)
	var result: Dictionary = game_state.harvest_material_at(coord)
	assert_eq(StringName(str(result.get("outcome", &""))), &"success")
	assert_eq(alchemy.get_material_count(&"reed_fiber"), 1)
	assert_eq(alchemy.get_material_count(&"living_wood"), 0)
	_cleanup_context(ctx)

func test_material_interaction_target_accepts_visible_reed_fronds() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.RIVER)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	_mature_materials(game_state)

	var controller: Node2D = PlacementControllerScript.new()
	add_child(controller)
	var reed_center: Vector2 = HexUtilsScript.axial_to_pixel(coord, 20.0)
	var visible_frond_point: Vector2 = reed_center + Vector2(0.0, -24.0)
	assert_ne(HexUtilsScript.pixel_to_axial(visible_frond_point, 20.0), coord)
	assert_eq(controller.call("_material_interaction_coord", visible_frond_point, true), coord)

	remove_child(controller)
	controller.free()
	_cleanup_context(ctx)

func test_inventory_full_harvest_preserves_ready_node() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	_mature_materials(game_state)
	alchemy.add_material_for_testing(&"living_wood", alchemy.get_material_capacity(&"living_wood"))
	var result: Dictionary = game_state.harvest_material_at(coord)
	assert_eq(StringName(str(result.get("outcome", &""))), &"inventory_full")
	var node: Dictionary = game_state.get_material_node_at(coord)
	assert_eq(StringName(str(node.get("state", &""))), &"ready")
	_cleanup_context(ctx)

func test_dew_bowl_increases_living_wood_material_capacity() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var coord: Vector2i = Vector2i(1, 0)
	_complete_structure(game_state, coord, BiomeTypeScript.Value.MEADOW, "building_dew_bowl")
	assert_eq(alchemy.get_material_capacity(&"living_wood"), 124)
	assert_eq(alchemy.get_material_capacity(&"reed_fiber"), 99)
	_cleanup_context(ctx)

func test_essence_capacity_structures_raise_matching_caps() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	_complete_structure(game_state, Vector2i(1, 0), BiomeTypeScript.Value.MEADOW, "building_dew_bowl")
	_complete_structure(game_state, Vector2i(0, 1), BiomeTypeScript.Value.RIVER, "building_reed_nest")
	_complete_structure(game_state, Vector2i(-1, 1), BiomeTypeScript.Value.STONE, "building_hearth_stone")

	assert_eq(alchemy.get_element_capacity(GodaiElementScript.Value.FU), KushoPoolScript.CAPACITY_PER_ELEMENT + 1)
	assert_eq(alchemy.get_element_capacity(GodaiElementScript.Value.SUI), KushoPoolScript.CAPACITY_PER_ELEMENT + 1)
	assert_eq(alchemy.get_element_capacity(GodaiElementScript.Value.KA), KushoPoolScript.CAPACITY_PER_ELEMENT + 1)
	assert_eq(alchemy.get_element_capacity(GodaiElementScript.Value.CHI), KushoPoolScript.CAPACITY_PER_ELEMENT)

	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.FU, KushoPoolScript.CAPACITY_PER_ELEMENT)
	assert_true(alchemy.store_shrine_charge(Vector2i.ZERO, GodaiElementScript.Value.FU, 1))
	assert_true(alchemy.collect_shrine_charge(Vector2i.ZERO))
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.FU), KushoPoolScript.CAPACITY_PER_ELEMENT + 1)
	_cleanup_context(ctx)

func test_root_network_speeds_nearby_living_wood_spawn() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var root_coord: Vector2i = Vector2i(1, 0)
	var meadow_coord: Vector2i = Vector2i(2, 0)
	game_state.place_tile_from_seed(meadow_coord, BiomeTypeScript.Value.MEADOW)
	_complete_structure(game_state, root_coord, BiomeTypeScript.Value.MEADOW, "building_root_network")
	assert_eq(_spawn_materials(game_state, 49.0).size(), 0)
	assert_eq(_spawn_materials(game_state, 1.0).size(), 1)
	_mature_materials(game_state)
	assert_true(game_state.has_ready_material_at(meadow_coord))
	_cleanup_context(ctx)

func test_kiln_heart_speeds_nearby_ember_clay_spawn() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var kiln_coord: Vector2i = Vector2i(1, 0)
	var ember_coord: Vector2i = Vector2i(2, 0)
	game_state.place_tile_from_seed(ember_coord, BiomeTypeScript.Value.EMBER_FIELD)
	_complete_structure(game_state, kiln_coord, BiomeTypeScript.Value.EMBER_FIELD, "building_kiln_heart")
	assert_eq(_spawn_materials(game_state, 49.0).size(), 0)
	var spawned: Array = _spawn_materials(game_state, 1.0)
	assert_eq(spawned.size(), 1)
	_mature_materials(game_state)
	assert_true(game_state.has_ready_material_at(ember_coord))
	_cleanup_context(ctx)

func test_wind_chime_auto_harvests_nearby_living_wood() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var chime_coord: Vector2i = Vector2i(1, 0)
	var meadow_coord: Vector2i = Vector2i(2, 0)
	game_state.place_tile_from_seed(meadow_coord, BiomeTypeScript.Value.MEADOW)
	_complete_structure(game_state, chime_coord, BiomeTypeScript.Value.MEADOW, "building_wind_chime")
	var spawned: Array = _spawn_materials(game_state, 100.0)
	assert_eq(spawned.size(), 1)
	assert_false(bool((spawned[0] as Dictionary).get("auto_harvested", false)))
	_mature_materials(game_state)
	assert_false(game_state.has_ready_material_at(meadow_coord))
	assert_eq(alchemy.get_material_count(&"living_wood"), 1)
	_cleanup_context(ctx)

func test_tiny_shrine_generates_ku_shrine_charge() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var shrine_coord: Vector2i = Vector2i(1, 0)
	_complete_structure(game_state, shrine_coord, BiomeTypeScript.Value.MEADOW, "building_tiny_shrine")
	alchemy.unlock_element(GodaiElementScript.Value.KU)
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.KU, 0)

	var early_generated: Variant = game_state.evaluate_structure_essence_generators(119.0)
	assert_true(early_generated is Array)
	assert_eq((early_generated as Array).size(), 0)
	assert_false(alchemy.has_shrine_charge(shrine_coord))

	var generated_variant: Variant = game_state.evaluate_structure_essence_generators(1.0)
	assert_true(generated_variant is Array)
	var generated: Array = generated_variant as Array
	assert_eq(generated.size(), 1)
	assert_eq(StringName(str((generated[0] as Dictionary).get("structure_id", &""))), &"building_tiny_shrine")
	assert_true(alchemy.has_shrine_charge(shrine_coord))
	assert_true(alchemy.collect_shrine_charge(shrine_coord))
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.KU), 1)
	_cleanup_context(ctx)

func test_first_session_loop_reaches_warm_hollow_after_harvest() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var blocked: RitualAttemptResultScript = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_eq(blocked.outcome, RitualAttemptResultScript.OUTCOME_LOCKED_INPUT)
	var coord: Vector2i = Vector2i(1, 0)
	game_state.place_tile_from_seed(coord, BiomeTypeScript.Value.MEADOW)
	assert_eq(_spawn_materials(game_state, 100.0).size(), 1)
	_mature_materials(game_state)
	var harvest_result: Dictionary = game_state.harvest_material_at(coord)
	assert_eq(StringName(str(harvest_result.get("outcome", &""))), &"success")
	var shaped: RitualAttemptResultScript = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_true(shaped.is_success())
	assert_eq(shaped.result_id, &"form_meadow_hollow")
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_true(pouch.find_building_index(&"form_meadow_hollow") >= 0)
	_cleanup_context(ctx)
