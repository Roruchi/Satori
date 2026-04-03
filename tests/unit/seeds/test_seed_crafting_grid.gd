extends GutTest

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const SeedCraftAttemptResultScript = preload("res://src/seeds/SeedCraftAttemptResult.gd")
const SeedCraftGridNormalizerScript = preload("res://src/seeds/SeedCraftGridNormalizer.gd")

func _ensure_services() -> Dictionary:
	var root: Node = get_tree().root
	var existing_growth: Node = root.get_node_or_null("/root/SeedGrowthService")
	if existing_growth != null:
		existing_growth.queue_free()
	await get_tree().process_frame
	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	growth.name = "SeedGrowthService"
	root.add_child(growth)
	growth._ready()

	var existing_alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
	if existing_alchemy != null:
		existing_alchemy.queue_free()
	await get_tree().process_frame
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	alchemy.name = "SeedAlchemyService"
	root.add_child(alchemy)
	alchemy._ready()

	for element: int in [
		GodaiElementScript.Value.CHI,
		GodaiElementScript.Value.SUI,
		GodaiElementScript.Value.KA,
		GodaiElementScript.Value.FU,
	]:
		alchemy.set_element_charge_for_testing(element, 50)

	return {
		"growth": growth,
		"alchemy": alchemy,
	}

func _cleanup_services(context: Dictionary) -> void:
	var growth_variant: Variant = context.get("growth", null)
	if growth_variant is Node:
		(growth_variant as Node).queue_free()
	var alchemy_variant: Variant = context.get("alchemy", null)
	if alchemy_variant is Node:
		(alchemy_variant as Node).queue_free()

func _grid_with(entries: Array) -> Array[int]:
	var grid: Array[int] = []
	for _i: int in range(9):
		grid.append(SeedCraftGridNormalizerScript.EMPTY_SLOT)
	for entry_variant: Variant in entries:
		if not (entry_variant is Array):
			continue
		var entry: Array = entry_variant as Array
		if entry.size() != 2:
			continue
		var slot_index: int = int(entry[0])
		var token: int = int(entry[1])
		if slot_index >= 0 and slot_index < grid.size():
			grid[slot_index] = token
	return grid

func _assert_successful_attempt(
	alchemy: SeedAlchemyServiceNode,
	grid_entries: Array,
	expected_biome: int,
	expected_consumed_slots: Array[int]
) -> void:
	var result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(_grid_with(grid_entries))
	assert_eq(result.outcome, SeedCraftAttemptResultScript.OUTCOME_SUCCESS)
	assert_eq(result.feedback_key, SeedCraftAttemptResultScript.FEEDBACK_SUCCESS)
	assert_eq(result.consumed_slot_indices, expected_consumed_slots)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_eq(pouch.size(), 1)
	var recipe: SeedRecipe = pouch.get_at(0)
	assert_not_null(recipe)
	assert_eq(recipe.produces_biome, expected_biome)
	pouch.seeds.clear()

func test_single_token_mappings_craft_to_expected_seed() -> void:
	var context: Dictionary = await _ensure_services()
	var alchemy: SeedAlchemyServiceNode = context.get("alchemy") as SeedAlchemyServiceNode
	alchemy.unlock_element(GodaiElementScript.Value.KU)
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.KU, 50)
	var cases: Array = [
		{"slot": 4, "token": GodaiElementScript.Value.CHI, "biome": BiomeTypeScript.Value.STONE},
		{"slot": 0, "token": GodaiElementScript.Value.SUI, "biome": BiomeTypeScript.Value.RIVER},
		{"slot": 8, "token": GodaiElementScript.Value.KA, "biome": BiomeTypeScript.Value.EMBER_FIELD},
		{"slot": 5, "token": GodaiElementScript.Value.FU, "biome": BiomeTypeScript.Value.MEADOW},
		{"slot": 2, "token": GodaiElementScript.Value.KU, "biome": BiomeTypeScript.Value.KU},
	]
	for case_variant: Variant in cases:
		var case: Dictionary = case_variant as Dictionary
		var slot: int = int(case.get("slot", 0))
		var token: int = int(case.get("token", GodaiElementScript.Value.CHI))
		var biome: int = int(case.get("biome", BiomeTypeScript.Value.NONE))
		_assert_successful_attempt(alchemy, [[slot, token]], biome, [slot])
	_cleanup_services(context)

func test_dual_token_mappings_are_position_insensitive_across_permutations() -> void:
	var context: Dictionary = await _ensure_services()
	var alchemy: SeedAlchemyServiceNode = context.get("alchemy") as SeedAlchemyServiceNode
	alchemy.unlock_element(GodaiElementScript.Value.KU)
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.KU, 50)
	var dual_cases: Array = [
		{"tokens": [0, 1], "biome": BiomeTypeScript.Value.WETLANDS},
		{"tokens": [0, 2], "biome": BiomeTypeScript.Value.BADLANDS},
		{"tokens": [0, 3], "biome": BiomeTypeScript.Value.WHISTLING_CANYONS},
		{"tokens": [0, 4], "biome": BiomeTypeScript.Value.SACRED_STONE},
		{"tokens": [1, 2], "biome": BiomeTypeScript.Value.PRISMATIC_TERRACES},
		{"tokens": [1, 3], "biome": BiomeTypeScript.Value.FROSTLANDS},
		{"tokens": [1, 4], "biome": BiomeTypeScript.Value.MOONLIT_POOL},
		{"tokens": [2, 3], "biome": BiomeTypeScript.Value.THE_ASHFALL},
		{"tokens": [2, 4], "biome": BiomeTypeScript.Value.EMBER_SHRINE},
		{"tokens": [3, 4], "biome": BiomeTypeScript.Value.CLOUD_RIDGE},
	]
	var arrangements: Array = [
		[0, 8],
		[3, 4],
		[7, 1],
	]
	for case_variant: Variant in dual_cases:
		var case: Dictionary = case_variant as Dictionary
		var tokens_variant: Variant = case.get("tokens", [])
		var tokens: Array = tokens_variant as Array
		var biome: int = int(case.get("biome", BiomeTypeScript.Value.NONE))
		for arrangement_variant: Variant in arrangements:
			var arrangement: Array = arrangement_variant as Array
			var slot_a: int = int(arrangement[0])
			var slot_b: int = int(arrangement[1])
			var token_a: int = int(tokens[0])
			var token_b: int = int(tokens[1])
			var expected_slots: Array[int] = [slot_a, slot_b]
			expected_slots.sort()
			_assert_successful_attempt(alchemy, [[slot_a, token_a], [slot_b, token_b]], biome, expected_slots)
	_cleanup_services(context)

func test_failure_outcomes_are_deterministic_and_non_destructive() -> void:
	var context: Dictionary = await _ensure_services()
	var alchemy: SeedAlchemyServiceNode = context.get("alchemy") as SeedAlchemyServiceNode
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.KU, 50)

	var empty_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(_grid_with([]))
	assert_eq(empty_result.outcome, SeedCraftAttemptResultScript.OUTCOME_EMPTY_INPUT)
	assert_eq(empty_result.feedback_key, SeedCraftAttemptResultScript.FEEDBACK_EMPTY_INPUT)
	assert_false(empty_result.guidance.is_empty())

	var invalid_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(
		_grid_with([[0, GodaiElementScript.Value.CHI], [1, GodaiElementScript.Value.CHI], [2, GodaiElementScript.Value.CHI]])
	)
	assert_eq(invalid_result.outcome, SeedCraftAttemptResultScript.OUTCOME_NO_MATCHING_SEED_RECIPE)
	assert_eq(invalid_result.feedback_key, SeedCraftAttemptResultScript.FEEDBACK_NO_MATCH)
	assert_false(invalid_result.guidance.is_empty())

	var locked_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(_grid_with([[6, GodaiElementScript.Value.KU]]))
	assert_eq(locked_result.outcome, SeedCraftAttemptResultScript.OUTCOME_LOCKED_ELEMENT)
	assert_eq(locked_result.feedback_key, SeedCraftAttemptResultScript.FEEDBACK_LOCKED_KU)
	assert_false(locked_result.guidance.is_empty())

	alchemy.unlock_element(GodaiElementScript.Value.KU)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	pouch.capacity = 0
	var full_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(_grid_with([[2, GodaiElementScript.Value.KU]]))
	assert_eq(full_result.outcome, SeedCraftAttemptResultScript.OUTCOME_INVENTORY_FULL)
	assert_eq(full_result.feedback_key, SeedCraftAttemptResultScript.FEEDBACK_INVENTORY_FULL)
	assert_false(full_result.guidance.is_empty())
	assert_eq(full_result.consumed_slot_indices.size(), 0)
	_cleanup_services(context)

func test_consumption_happens_only_on_success_and_emits_feedback_payload() -> void:
	var context: Dictionary = await _ensure_services()
	var alchemy: SeedAlchemyServiceNode = context.get("alchemy") as SeedAlchemyServiceNode
	alchemy.unlock_element(GodaiElementScript.Value.KU)
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.KU, 50)

	watch_signals(alchemy)
	var start_chi: int = alchemy.get_element_charge(GodaiElementScript.Value.CHI)
	var start_sui: int = alchemy.get_element_charge(GodaiElementScript.Value.SUI)
	var success_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(
		_grid_with([[0, GodaiElementScript.Value.CHI], [1, GodaiElementScript.Value.SUI]])
	)
	assert_true(success_result.is_success())
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.CHI), start_chi - 1)
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.SUI), start_sui - 1)
	assert_signal_emitted(alchemy, "craft_attempt_resolved")

	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	pouch.capacity = 0
	var before_ku: int = alchemy.get_element_charge(GodaiElementScript.Value.KU)
	var inventory_full_result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(
		_grid_with([[4, GodaiElementScript.Value.KU]])
	)
	assert_eq(inventory_full_result.outcome, SeedCraftAttemptResultScript.OUTCOME_INVENTORY_FULL)
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.KU), before_ku)
	_cleanup_services(context)
