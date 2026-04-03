extends GutTest

const PlacementControllerScript = preload("res://src/grid/PlacementController.gd")

class DiscoveryPersistenceStub:
	extends Node
	var discovered_ids: Array[String] = []
	func get_discovered_ids() -> Array[String]:
		return discovered_ids

func test_build_mode_places_pending_block_without_starting_countdown() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	game_state.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.STONE, true)
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(1, 0))
	assert_true(bool(tile.metadata.get("is_build_block", false)))
	assert_eq(bool(tile.metadata.get("build_countdown_started", true)), false)
	_cleanup_build_test_context(ctx)

func test_build_mode_does_not_create_build_tile_on_empty_coord() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	assert_false(game_state.grid.has_tile(Vector2i(4, 0)))
	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)
	assert_false(controller._toggle_build_block(Vector2i(4, 0)))
	assert_false(game_state.grid.has_tile(Vector2i(4, 0)))
	controller.queue_free()
	_cleanup_build_test_context(ctx)

func _add_root_singleton(name: String, node: Node) -> void:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % name)
	if existing != null:
		existing.queue_free()
	node.name = name
	root.add_child(node)

func _setup_build_test_context() -> Dictionary:
	var game_state: Node = Node.new()
	game_state.set_script(load("res://src/autoloads/GameState.gd"))
	_add_root_singleton("GameState", game_state)
	game_state._ready()

	var discovery: DiscoveryPersistenceStub = DiscoveryPersistenceStub.new()
	_add_root_singleton("DiscoveryPersistence", discovery)

	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	_add_root_singleton("SeedAlchemyService", alchemy)
	alchemy._ready()

	var base_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.CHI])
	assert_not_null(base_recipe)
	assert_true(growth.get_pouch().add(base_recipe, 1))

	return {
		"game_state": game_state,
		"discovery": discovery,
		"growth": growth,
		"alchemy": alchemy,
	}

func _cleanup_build_test_context(ctx: Dictionary) -> void:
	for key: String in ["game_state", "discovery", "growth", "alchemy"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			(node_variant as Node).queue_free()

func test_build_confirm_starts_countdown_and_disables_cancel() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	game_state.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.STONE, true)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(1, 0)))
	var tile_first: GardenTile = game_state.grid.get_tile(Vector2i(1, 0))
	assert_true(bool(tile_first.metadata.get("is_build_block", false)))
	assert_true(bool(tile_first.metadata.get("build_countdown_started", false)))
	assert_true(tile_first.metadata.has("build_started_at"))

	# Permanence rule: cannot toggle off after countdown has started.
	assert_false(controller._toggle_build_block(Vector2i(1, 0)))
	assert_false(controller._cancel_pending_build_block(Vector2i(1, 0)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_build_cancel_only_allowed_before_confirm() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	game_state.place_tile_from_seed(Vector2i(2, 0), BiomeType.Value.STONE, true)
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(2, 0))
	tile.metadata["build_countdown_started"] = false
	tile.metadata.erase("build_started_at")
	tile.metadata.erase("build_duration")

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._cancel_pending_build_block(Vector2i(2, 0)))
	assert_false(bool(tile.metadata.get("is_build_block", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_completed_house_is_not_removed_by_build_toggle() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	game_state.place_tile_from_seed(Vector2i(2, 0), BiomeType.Value.STONE, true)
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(2, 0))
	tile.metadata["is_building_complete"] = true
	tile.metadata["is_build_block"] = true

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_false(controller._toggle_build_block(Vector2i(2, 0)))
	assert_true(bool(tile.metadata.get("is_building_complete", false)))
	assert_true(bool(tile.metadata.get("is_build_block", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_completed_house_cannot_be_restarted_as_new_build_block() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	game_state.place_tile_from_seed(Vector2i(3, 0), BiomeType.Value.STONE, false)
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(3, 0))
	tile.metadata["is_building_complete"] = true
	tile.metadata["is_build_block"] = false

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_false(controller._toggle_build_block(Vector2i(3, 0)))
	assert_true(bool(tile.metadata.get("is_building_complete", false)))
	assert_false(bool(tile.metadata.get("is_build_block", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_ku_build_block_on_stone_marks_pending_origin_shrine() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var ku_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.KU])
	assert_not_null(ku_recipe)
	assert_true(growth.get_pouch().add(ku_recipe, 1))
	game_state.place_tile_from_seed(Vector2i(6, 0), BiomeType.Value.STONE, false)
	game_state.selected_biome = BiomeType.Value.KU

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(6, 0)))
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(6, 0))
	assert_true(bool(tile.metadata.get("is_build_block", false)))
	assert_true(bool(tile.metadata.get("pending_origin_shrine", false)))
	assert_eq(int(tile.metadata.get("build_recipe_biome", -1)), BiomeType.Value.MEADOW)

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_ku_build_block_on_non_stone_tile_does_not_mark_pending_origin_shrine() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var ku_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.KU])
	assert_not_null(ku_recipe)
	assert_true(growth.get_pouch().add(ku_recipe, 1))
	# Origin shrine must be placed on Stone only.
	game_state.place_tile_from_seed(Vector2i(6, 1), BiomeType.Value.RIVER, false)
	game_state.selected_biome = BiomeType.Value.KU

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_false(controller._toggle_build_block(Vector2i(6, 1)))
	var tile: GardenTile = game_state.grid.get_tile(Vector2i(6, 1))
	assert_false(bool(tile.metadata.get("is_build_block", false)))
	assert_false(bool(tile.metadata.get("pending_origin_shrine", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_origin_shrine_build_is_limited_to_one_per_island() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var ku_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.KU])
	assert_not_null(ku_recipe)
	assert_true(growth.get_pouch().add(ku_recipe, 2))

	# Separate island with two connected stone tiles.
	game_state.place_tile_from_seed(Vector2i(10, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(11, 0), BiomeType.Value.STONE, false)
	var first_tile: GardenTile = game_state.grid.get_tile(Vector2i(10, 0))
	first_tile.metadata["is_origin_shrine"] = true
	game_state.selected_biome = BiomeType.Value.KU

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_false(controller._toggle_build_block(Vector2i(11, 0)))
	var second_tile: GardenTile = game_state.grid.get_tile(Vector2i(11, 0))
	assert_false(bool(second_tile.metadata.get("is_build_block", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_build_project_requires_adjacency_for_new_pending_blocks() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var base_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.CHI])
	assert_not_null(base_recipe)
	assert_true(growth.get_pouch().add(base_recipe, 3))
	game_state.selected_biome = BiomeType.Value.STONE
	game_state.place_tile_from_seed(Vector2i(20, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(21, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(24, 0), BiomeType.Value.STONE, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(20, 0)))
	assert_true(controller._toggle_build_block(Vector2i(21, 0)))
	assert_false(controller._toggle_build_block(Vector2i(24, 0)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_confirming_multi_tile_non_recipe_project_is_blocked() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var base_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.FU])
	assert_not_null(base_recipe)
	assert_true(growth.get_pouch().add(base_recipe, 3))
	game_state.selected_biome = BiomeType.Value.MEADOW
	game_state.place_tile_from_seed(Vector2i(30, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(31, 0), BiomeType.Value.STONE, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(30, 0)))
	assert_false(controller._toggle_build_block(Vector2i(31, 0)))
	assert_true(controller._toggle_build_block(Vector2i(30, 0)))

	var first_tile: GardenTile = game_state.grid.get_tile(Vector2i(30, 0))
	var second_tile: GardenTile = game_state.grid.get_tile(Vector2i(31, 0))
	assert_true(bool(first_tile.metadata.get("build_countdown_started", false)))
	assert_false(bool(second_tile.metadata.get("build_countdown_started", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_invalid_recipe_confirm_flashes_and_does_not_start_countdown() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var fu_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.FU])
	assert_not_null(fu_recipe)
	assert_true(growth.get_pouch().add(fu_recipe, 4))
	game_state.selected_biome = BiomeType.Value.MEADOW
	for coord: Vector2i in [Vector2i(40, 0), Vector2i(41, 0), Vector2i(40, 1), Vector2i(41, 1)]:
		game_state.place_tile_from_seed(coord, BiomeType.Value.WETLANDS, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(40, 0)))
	assert_true(controller._toggle_build_block(Vector2i(41, 0)))
	assert_true(controller._toggle_build_block(Vector2i(40, 1)))
	assert_true(controller._toggle_build_block(Vector2i(41, 1)))

	var sample_tile: GardenTile = game_state.grid.get_tile(Vector2i(40, 0))
	assert_false(bool(sample_tile.metadata.get("project_recipe_valid", false)))
	assert_false(controller._toggle_build_block(Vector2i(40, 0)))
	assert_true(sample_tile.metadata.has("project_invalid_flash_started_at"))
	assert_false(bool(sample_tile.metadata.get("build_countdown_started", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_valid_recipe_project_turns_green_and_confirms() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var discovery: DiscoveryPersistenceStub = ctx["discovery"]
	discovery.discovered_ids = ["disc_lotus_pagoda"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var fu_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.FU])
	assert_not_null(fu_recipe)
	assert_true(growth.get_pouch().add(fu_recipe, 4))
	game_state.selected_biome = BiomeType.Value.MEADOW
	for coord: Vector2i in [Vector2i(50, 0), Vector2i(51, 0), Vector2i(50, 1), Vector2i(51, 1)]:
		game_state.place_tile_from_seed(coord, BiomeType.Value.WETLANDS, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(50, 0)))
	assert_true(controller._toggle_build_block(Vector2i(51, 0)))
	assert_true(controller._toggle_build_block(Vector2i(50, 1)))
	assert_true(controller._toggle_build_block(Vector2i(51, 1)))

	var sample_tile: GardenTile = game_state.grid.get_tile(Vector2i(50, 0))
	assert_true(bool(sample_tile.metadata.get("project_recipe_valid", false)))
	assert_true(controller._toggle_build_block(Vector2i(50, 0)))
	assert_true(bool(sample_tile.metadata.get("build_countdown_started", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_rotatable_u_recipe_project_turns_valid_and_confirms_wayfarer_torii() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var chi_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.CHI])
	assert_not_null(chi_recipe)
	assert_true(growth.get_pouch().add(chi_recipe, 3))
	# Selected Stone is the ritual selector; target biome can be non-Ku (here: River).
	game_state.selected_biome = BiomeType.Value.STONE
	for coord: Vector2i in [Vector2i(80, 0), Vector2i(81, 0), Vector2i(80, 1)]:
		game_state.place_tile_from_seed(coord, BiomeType.Value.RIVER, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(80, 0)))
	assert_true(controller._toggle_build_block(Vector2i(81, 0)))
	assert_true(controller._toggle_build_block(Vector2i(80, 1)))

	var sample_tile: GardenTile = game_state.grid.get_tile(Vector2i(80, 0))
	assert_true(bool(sample_tile.metadata.get("project_recipe_valid", false)))
	assert_true(controller._toggle_build_block(Vector2i(80, 0)))
	assert_true(bool(sample_tile.metadata.get("build_countdown_started", false)))

	var has_wayfarer_anchor: bool = false
	for coord: Vector2i in [Vector2i(80, 0), Vector2i(81, 0), Vector2i(80, 1)]:
		var tile: GardenTile = game_state.grid.get_tile(coord)
		if tile != null and str(tile.metadata.get("pending_structure_id", "")) == "disc_wayfarer_torii":
			has_wayfarer_anchor = true
			break
	assert_true(has_wayfarer_anchor)

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_can_start_new_project_while_previous_project_counts_down() -> void:
	var ctx: Dictionary = _setup_build_test_context()
	var game_state: Node = ctx["game_state"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var base_recipe: SeedRecipe = alchemy.lookup_recipe([GodaiElement.Value.CHI])
	assert_not_null(base_recipe)
	assert_true(growth.get_pouch().add(base_recipe, 4))
	game_state.selected_biome = BiomeType.Value.STONE

	game_state.place_tile_from_seed(Vector2i(60, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(61, 0), BiomeType.Value.STONE, false)
	game_state.place_tile_from_seed(Vector2i(70, 0), BiomeType.Value.STONE, false)

	var controller: Node2D = Node2D.new()
	controller.set_script(PlacementControllerScript)
	add_child(controller)

	assert_true(controller._toggle_build_block(Vector2i(60, 0)))
	assert_true(controller._toggle_build_block(Vector2i(61, 0)))
	assert_true(controller._toggle_build_block(Vector2i(60, 0)))

	var first_project_tile: GardenTile = game_state.grid.get_tile(Vector2i(60, 0))
	assert_true(bool(first_project_tile.metadata.get("build_countdown_started", false)))

	assert_true(controller._toggle_build_block(Vector2i(70, 0)))
	var second_project_tile: GardenTile = game_state.grid.get_tile(Vector2i(70, 0))
	assert_true(bool(second_project_tile.metadata.get("is_build_block", false)))
	assert_false(bool(second_project_tile.metadata.get("build_countdown_started", false)))

	controller.queue_free()
	_cleanup_build_test_context(ctx)

func test_normal_tile_placement_does_not_require_confirm() -> void:
var ctx: Dictionary = _setup_build_test_context()
var game_state: Node = ctx["game_state"]
var controller: Node2D = Node2D.new()
controller.set_script(PlacementControllerScript)
add_child(controller)

game_state.selected_biome = BiomeType.Value.STONE
game_state.place_tile_from_seed(Vector2i(90, 0), BiomeType.Value.STONE, false)
assert_true(game_state.grid.has_tile(Vector2i(90, 0)), "Normal tile placement should succeed without confirm")

controller.queue_free()
_cleanup_build_test_context(ctx)

func test_building_placement_session_confirm_consumes_inventory_item() -> void:
var ctx: Dictionary = _setup_build_test_context()
var game_state: Node = ctx["game_state"]
var growth: SeedGrowthServiceNode = ctx["growth"]
var pouch: SeedPouch = growth.get_pouch()
game_state.place_tile_from_seed(Vector2i(95, 0), BiomeType.Value.STONE, false)
assert_true(pouch.add_building(&"building_house", 2))

var controller: Node2D = Node2D.new()
controller.set_script(PlacementControllerScript)
add_child(controller)

controller.start_building_placement(&"building_house")
var session = controller.get_active_building_session()
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
_cleanup_build_test_context(ctx)

func test_building_placement_session_cancel_preserves_inventory() -> void:
var ctx: Dictionary = _setup_build_test_context()
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
_cleanup_build_test_context(ctx)
