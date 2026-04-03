extends GutTest

const SeedAlchemyServiceScript = preload("res://src/autoloads/seed_alchemy_service.gd")
const BuildingRecipeCatalogScript = preload("res://src/seeds/BuildingRecipeCatalog.gd")
const BuildingInventoryEntryScript = preload("res://src/seeds/BuildingInventoryEntry.gd")
const SeedCraftGridNormalizerScript = preload("res://src/seeds/SeedCraftGridNormalizer.gd")

class DiscoveryStub:
	extends Node
	var discovered_ids: Array[StringName] = []
	func get_discovered_ids() -> Array[StringName]:
		return discovered_ids

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

func _make_slots(tokens: Array[int]) -> Array[int]:
	var slots: Array[int] = []
	for _i: int in range(9):
		slots.append(SeedCraftGridNormalizerScript.EMPTY_SLOT)
	for i: int in range(mini(tokens.size(), 9)):
		slots[i] = tokens[i]
	return slots

# --- T012: Valid pattern matching ---

func test_three_chi_matches_building_house() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var slots: Array[int] = _make_slots([GodaiElement.Value.CHI, GodaiElement.Value.CHI, GodaiElement.Value.CHI])
	var result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_true(result.is_success(), "3x CHI should match building_house recipe")
	assert_eq(result.building_type_key, &"building_house")
	_cleanup_context(ctx)

func test_two_chi_does_not_match_building_recipe() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var slots: Array[int] = _make_slots([GodaiElement.Value.CHI, GodaiElement.Value.CHI])
	var result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_false(result.is_success(), "2x CHI should not match any building recipe (need 3+)")
	assert_eq(result.outcome, BuildingCraftAttemptResult.OUTCOME_NO_MATCH)
	_cleanup_context(ctx)

func test_empty_grid_returns_no_match() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var slots: Array[int] = _make_slots([])
	var result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_false(result.is_success())
	assert_eq(result.outcome, BuildingCraftAttemptResult.OUTCOME_NO_MATCH)
	_cleanup_context(ctx)

# --- T014: Discovery recorded on success only ---

func test_first_successful_craft_sets_first_discovery_flag() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var slots: Array[int] = _make_slots([GodaiElement.Value.CHI, GodaiElement.Value.CHI, GodaiElement.Value.CHI])
	var result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_true(result.is_success())
	assert_true(result.is_first_discovery, "First craft should set is_first_discovery=true")
	_cleanup_context(ctx)

func test_second_successful_craft_does_not_set_first_discovery_flag() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var slots: Array[int] = _make_slots([GodaiElement.Value.CHI, GodaiElement.Value.CHI, GodaiElement.Value.CHI])
	alchemy.attempt_building_craft_from_grid(slots)
	var result2: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_true(result2.is_success())
	assert_false(result2.is_first_discovery, "Second craft of same type should not be first_discovery")
	_cleanup_context(ctx)

# --- T015: Full inventory failure is non-destructive ---

func test_full_inventory_returns_inventory_full_with_no_consumption() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var growth: SeedGrowthServiceNode = ctx["growth"]
	var pouch: SeedPouch = growth.get_pouch()
	# Fill 8 slots with different building types.
	var keys: Array[StringName] = [&"type_a", &"type_b", &"type_c", &"type_d", &"type_e", &"type_f", &"type_g", &"type_h"]
	for k: StringName in keys:
		assert_true(pouch.add_building(k, 1))
	assert_true(pouch.is_full())
	var slots: Array[int] = _make_slots([GodaiElement.Value.CHI, GodaiElement.Value.CHI, GodaiElement.Value.CHI])
	var result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(slots)
	assert_false(result.is_success())
	assert_eq(result.outcome, BuildingCraftAttemptResult.OUTCOME_INVENTORY_FULL)
	assert_true(pouch.is_full(), "Inventory should still be full after failed craft")
	_cleanup_context(ctx)

# --- T016: Stacking at 99-cap with rollover ---

func test_same_type_stacks_up_to_99() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	assert_true(pouch.add_building(&"building_house", 50))
	assert_true(pouch.add_building(&"building_house", 49))
	var idx: int = pouch.find_building_index(&"building_house")
	var entry: BuildingInventoryEntry = pouch.get_building_at(idx)
	assert_not_null(entry)
	assert_eq(entry.count, 99)
	assert_eq(pouch.size(), 1)

func test_rollover_creates_new_slot_when_stack_full() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	assert_true(pouch.add_building(&"building_house", 99))
	assert_true(pouch.add_building(&"building_house", 1))
	assert_eq(pouch.size(), 2)
	var idx2: int = -1
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var e: BuildingInventoryEntry = pouch.get_building_at(i)
			if e != null and e.type_key == &"building_house" and e.count == 1:
				idx2 = i
				break
	assert_true(idx2 >= 0, "Rollover slot with count=1 should exist")

func test_full_inventory_hard_fail_when_all_slots_taken() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	var keys: Array[StringName] = [&"a", &"b", &"c", &"d", &"e", &"f", &"g", &"h"]
	for k: StringName in keys:
		assert_true(pouch.add_building(k, 99))
	assert_true(pouch.is_full())
	assert_false(pouch.add_building(&"a", 1), "Should fail — all slots full at 99 cap")

# --- T017: Consume building at ---

func test_consume_building_at_decrements_count() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	pouch.add_building(&"building_house", 3)
	var idx: int = pouch.find_building_index(&"building_house")
	assert_true(pouch.consume_building_at(idx, 1))
	var entry: BuildingInventoryEntry = pouch.get_building_at(idx)
	assert_not_null(entry)
	assert_eq(entry.count, 2)

func test_consume_building_at_removes_entry_when_zero() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	pouch.add_building(&"building_house", 1)
	var idx: int = pouch.find_building_index(&"building_house")
	assert_true(pouch.consume_building_at(idx, 1))
	assert_eq(pouch.find_building_index(&"building_house"), -1)

# --- T018: Preview recipe ---

func test_preview_returns_entry_for_valid_pattern() -> void:
	var catalog: BuildingRecipeCatalog = BuildingRecipeCatalog.new()
	var entry = catalog.lookup([0, 0, 0])
	assert_not_null(entry)
	assert_eq(entry.building_type_key, &"building_house")

func test_preview_returns_null_for_invalid_pattern() -> void:
	var catalog: BuildingRecipeCatalog = BuildingRecipeCatalog.new()
	var entry = catalog.lookup([0, 1, 2, 3])
	assert_null(entry)
