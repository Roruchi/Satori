extends GutTest

const BuildingPlacementSessionScript = preload("res://src/grid/BuildingPlacementSession.gd")
const BuildingFootprintScript = preload("res://src/grid/BuildingFootprint.gd")
const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")

class DiscoveryStub:
	extends Node
	func get_discovered_ids() -> Array[StringName]:
		return []

func _add_root_singleton(p_name: String, node: Node) -> void:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % p_name)
	if existing != null:
		existing.queue_free()
	node.name = p_name
	root.add_child(node)

func _setup_context() -> Dictionary:
	var game_state: Node = Node.new()
	game_state.set_script(load("res://src/autoloads/GameState.gd"))
	_add_root_singleton("GameState", game_state)
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
	for key: String in ["game_state", "growth", "alchemy", "discovery"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			(node_variant as Node).queue_free()

# --- Session lifecycle tests (T025, T026) ---

func test_session_starts_inactive() -> void:
	var session: BuildingPlacementSession = BuildingPlacementSessionScript.new()
	assert_false(session.active)
	assert_false(session.can_confirm())

func test_session_start_sets_active() -> void:
	var session: BuildingPlacementSession = BuildingPlacementSessionScript.new()
	session.start(&"building_house")
	assert_true(session.active)
	assert_eq(session.building_type_key, &"building_house")

func test_session_update_anchor_reflects_validity() -> void:
	var session: BuildingPlacementSession = BuildingPlacementSessionScript.new()
	session.start(&"building_house")
	var tiles: Array[Vector2i] = [Vector2i(1, 0)]
	session.update_anchor(Vector2i(1, 0), tiles, true, &"")
	assert_true(session.is_valid)
	assert_true(session.can_confirm())

func test_session_update_anchor_invalid() -> void:
	var session: BuildingPlacementSession = BuildingPlacementSessionScript.new()
	session.start(&"building_house")
	var tiles: Array[Vector2i] = [Vector2i(5, 5)]
	session.update_anchor(Vector2i(5, 5), tiles, false, &"not_on_tile")
	assert_false(session.is_valid)
	assert_false(session.can_confirm())
	assert_eq(session.invalid_reason, &"not_on_tile")

func test_session_cancel_clears_state() -> void:
	var session: BuildingPlacementSession = BuildingPlacementSessionScript.new()
	session.start(&"building_house")
	session.update_anchor(Vector2i(1, 0), [Vector2i(1, 0)], true, &"")
	session.cancel()
	assert_false(session.active)

# --- Footprint tests ---

func test_single_tile_footprint_returns_anchor() -> void:
	var fp: BuildingFootprint = BuildingFootprintScript.single_tile(&"fp_single")
	var tiles: Array[Vector2i] = fp.get_world_tiles(Vector2i(3, 2))
	assert_eq(tiles.size(), 1)
	assert_eq(tiles[0], Vector2i(3, 2))

func test_multi_tile_footprint_offsets() -> void:
	var offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	var fp: BuildingFootprint = BuildingFootprintScript.multi_tile(&"fp_l", offsets)
	var tiles: Array[Vector2i] = fp.get_world_tiles(Vector2i(2, 2))
	assert_eq(tiles.size(), 3)
	assert_true(tiles.has(Vector2i(2, 2)))
	assert_true(tiles.has(Vector2i(3, 2)))
	assert_true(tiles.has(Vector2i(2, 3)))

# --- Confirm consumes one inventory item (T037, T040) ---

func test_building_placement_session_confirm_consumes_inventory_item() -> void:
	var ctx: Dictionary = _setup_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var pouch: SeedPouch = growth.get_pouch()
	game_state.place_tile_from_seed(Vector2i(95, 0), BiomeType.Value.STONE, false)
	assert_true(pouch.add_building(&"building_house", 2))

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	controller.start_building_placement(&"building_house")
	var session: BuildingPlacementSession = controller.get_active_building_session()
	assert_not_null(session)
	session.update_anchor(Vector2i(95, 0), [Vector2i(95, 0)], true, &"")
	assert_true(controller.confirm_building_placement())
	assert_null(controller.get_active_building_session())
	var idx: int = pouch.find_building_index(&"building_house")
	if idx >= 0:
		var entry: BuildingInventoryEntry = pouch.get_building_at(idx)
		assert_not_null(entry)
		assert_eq(entry.count, 1)

	controller.queue_free()
	_cleanup_context(ctx)

# --- Cancel preserves inventory (T038, T041) ---

func test_building_placement_session_cancel_preserves_inventory() -> void:
	var ctx: Dictionary = _setup_context()
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var pouch: SeedPouch = growth.get_pouch()
	assert_true(pouch.add_building(&"building_house", 3))
	var initial_idx: int = pouch.find_building_index(&"building_house")
	var initial_entry: BuildingInventoryEntry = pouch.get_building_at(initial_idx)
	var initial_count: int = initial_entry.count if initial_entry != null else 0

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	controller.start_building_placement(&"building_house")
	controller.cancel_building_placement()
	assert_null(controller.get_active_building_session())

	var after_idx: int = pouch.find_building_index(&"building_house")
	var after_entry: BuildingInventoryEntry = pouch.get_building_at(after_idx)
	var after_count: int = after_entry.count if after_entry != null else 0
	assert_eq(after_count, initial_count, "Cancel must not consume inventory items")

	controller.queue_free()
	_cleanup_context(ctx)
