extends GutTest

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const RitualAttemptResultScript = preload("res://src/seeds/RitualAttemptResult.gd")

class DiscoveryStub:
	extends Node
	var discovered_ids: Array[StringName] = []
	func get_discovered_ids() -> Array[StringName]:
		return discovered_ids
	func record_discovery(payload: DiscoveryPayload) -> void:
		if payload == null:
			return
		var discovery_id: StringName = StringName(payload.discovery_id)
		if discovery_id != &"" and not discovered_ids.has(discovery_id):
			discovered_ids.append(discovery_id)

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

func test_duplicate_ritual_inputs_are_rejected_without_consumption() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var before_fire: int = alchemy.get_element_charge(GodaiElementScript.Value.KA)
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["essence:fire", "essence:fire"])
	assert_eq(result.outcome, RitualAttemptResultScript.OUTCOME_DUPLICATE_INPUT)
	assert_eq(result.consumed_input_keys.size(), 0)
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.KA), before_fire)
	_cleanup_context(ctx)

func test_ritual_resolution_is_order_insensitive_for_seeds() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var first: RitualAttemptResultScript = alchemy.preview_ritual(["essence:wind", "essence:fire"])
	var second: RitualAttemptResultScript = alchemy.preview_ritual(["essence:fire", "essence:wind"])
	assert_true(first.is_success())
	assert_true(second.is_success())
	assert_eq(first.result_id, second.result_id)
	assert_eq(first.result_kind, &"seed")
	_cleanup_context(ctx)

func test_wind_essence_shapes_meadow_seed_through_ritual_path() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var before_wind: int = alchemy.get_element_charge(GodaiElementScript.Value.FU)
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["essence:wind"])
	assert_true(result.is_success())
	assert_eq(result.result_kind, &"seed")
	assert_eq(result.result_id, &"recipe_fu")
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.FU), before_wind - 1)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_true(pouch.find_index_by_biome(BiomeTypeScript.Value.MEADOW) >= 0)
	_cleanup_context(ctx)

func test_living_wood_and_fire_shape_warm_hollow() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.add_material_for_testing(&"living_wood", 1)
	var before_fire: int = alchemy.get_element_charge(GodaiElementScript.Value.KA)
	var before_wood: int = alchemy.get_material_count(&"living_wood")
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_true(result.is_success())
	assert_eq(result.result_kind, &"form")
	assert_eq(result.result_id, &"form_warm_hollow")
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.KA), before_fire - 1)
	assert_eq(alchemy.get_material_count(&"living_wood"), before_wood - 1)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_true(pouch.find_building_index(&"form_warm_hollow") >= 0)
	_cleanup_context(ctx)

func test_reed_fiber_and_water_shape_reed_nest_and_record_discovery() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var discovery: DiscoveryStub = ctx["discovery"]
	alchemy.add_material_for_testing(&"reed_fiber", 1)
	var before_water: int = alchemy.get_element_charge(GodaiElementScript.Value.SUI)
	var before_reed: int = alchemy.get_material_count(&"reed_fiber")
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["material:reed_fiber", "essence:water"])
	assert_true(result.is_success())
	assert_eq(result.result_kind, &"form")
	assert_eq(result.result_id, &"form_reed_nest")
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.SUI), before_water - 1)
	assert_eq(alchemy.get_material_count(&"reed_fiber"), before_reed - 1)
	assert_true(discovery.discovered_ids.has(&"disc_reed_nest"))
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_true(pouch.find_building_index(&"form_reed_nest") >= 0)
	_cleanup_context(ctx)

func test_spirit_stone_and_water_shape_stone_basin() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.add_material_for_testing(&"spirit_stone", 1)
	var before_water: int = alchemy.get_element_charge(GodaiElementScript.Value.SUI)
	var before_stone: int = alchemy.get_material_count(&"spirit_stone")
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["material:spirit_stone", "essence:water"])
	assert_true(result.is_success())
	assert_eq(result.result_kind, &"form")
	assert_eq(result.result_id, &"form_stone_basin")
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.SUI), before_water - 1)
	assert_eq(alchemy.get_material_count(&"spirit_stone"), before_stone - 1)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	assert_true(pouch.find_building_index(&"form_stone_basin") >= 0)
	_cleanup_context(ctx)

func test_ritual_without_essence_preserves_materials() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.add_material_for_testing(&"living_wood", 1)
	var before_wood: int = alchemy.get_material_count(&"living_wood")
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["material:living_wood"])
	assert_eq(result.outcome, RitualAttemptResultScript.OUTCOME_MISSING_ESSENCE)
	assert_eq(alchemy.get_material_count(&"living_wood"), before_wood)
	_cleanup_context(ctx)

func test_inventory_full_warm_hollow_attempt_is_non_destructive() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.add_material_for_testing(&"living_wood", 1)
	var pouch: SeedPouch = alchemy.get_pouch()
	assert_not_null(pouch)
	var filler_keys: Array[StringName] = [&"type_a", &"type_b", &"type_c", &"type_d", &"type_e", &"type_f", &"type_g", &"type_h"]
	for key: StringName in filler_keys:
		assert_true(pouch.add_building(key, 1))
	assert_true(pouch.is_full())
	var before_fire: int = alchemy.get_element_charge(GodaiElementScript.Value.KA)
	var before_wood: int = alchemy.get_material_count(&"living_wood")
	var result: RitualAttemptResultScript = alchemy.attempt_ritual(["material:living_wood", "essence:fire"])
	assert_eq(result.outcome, RitualAttemptResultScript.OUTCOME_INVENTORY_FULL)
	assert_eq(alchemy.get_element_charge(GodaiElementScript.Value.KA), before_fire)
	assert_eq(alchemy.get_material_count(&"living_wood"), before_wood)
	assert_eq(pouch.find_building_index(&"form_warm_hollow"), -1)
	_cleanup_context(ctx)
