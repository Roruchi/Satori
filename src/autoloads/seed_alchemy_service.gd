class_name SeedAlchemyServiceNode
extends Node

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SeedRecipeRegistryScript = preload("res://src/seeds/SeedRecipeRegistry.gd")
const SeedCraftAttemptResultScript = preload("res://src/seeds/SeedCraftAttemptResult.gd")
const SeedCraftGridNormalizerScript = preload("res://src/seeds/SeedCraftGridNormalizer.gd")
const RitualAttemptResultScript = preload("res://src/seeds/RitualAttemptResult.gd")
const RitualRecipeCatalogScript = preload("res://src/seeds/RitualRecipeCatalog.gd")
const SatoriIds = preload("res://src/satori/SatoriIds.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const INVALID_ELEMENT: int = -1
const INPUT_KIND_ESSENCE: StringName = &"essence"
const INPUT_KIND_MATERIAL: StringName = &"material"
const STARTING_LIVING_WOOD: int = 0
const DEFAULT_MATERIAL_CAPACITY: int = 99
const MATERIAL_DISPLAY_ORDER: Array[StringName] = [&"living_wood", &"reed_fiber", &"spirit_stone", &"ember_clay"]

signal element_unlocked(element_id: int)
signal recipe_discovered(recipe_id: StringName)
signal seed_added_to_pouch(recipe: SeedRecipe)
signal shrine_charge_ready(coord: Vector2i, element_id: int)
signal shrine_charge_collected(coord: Vector2i, element_id: int, amount: int)
signal element_charge_changed(element_id: int, charge: int)
signal craft_attempt_resolved(outcome: StringName, feedback_key: StringName, guidance: String, consumed_slot_indices: Array[int])
signal ritual_attempt_resolved(outcome: StringName, feedback_key: StringName, guidance: String, ritual_id: StringName, result_kind: StringName, result_id: StringName)
signal material_count_changed(material_id: StringName, count: int)

var _registry
var _kusho_pool: KushoPool = KushoPoolScript.new()
var _grid_normalizer = SeedCraftGridNormalizerScript.new()
var _ritual_catalog = null
var _building_discovered: Dictionary = {}
var _material_counts: Dictionary = {}
var _is_initialized: bool = false
var _unlocked_elements: Array[int] = [
	GodaiElementScript.Value.CHI,
	GodaiElementScript.Value.SUI,
	GodaiElementScript.Value.KA,
	GodaiElementScript.Value.FU,
]
var _discovered: Dictionary = {}
var _pending_shrine_charges: Dictionary = {}

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	_registry = SeedRecipeRegistryScript.new()
	_ritual_catalog = RitualRecipeCatalogScript.new()
	for material_id: StringName in MATERIAL_DISPLAY_ORDER:
		_material_counts[material_id] = 0
	_material_counts[&"living_wood"] = STARTING_LIVING_WOOD
	for element: int in _unlocked_elements:
		_kusho_pool.set_charge(element, KushoPoolScript.CAPACITY_PER_ELEMENT)
	_kusho_pool.set_charge(GodaiElementScript.Value.KU, 0)

func is_element_unlocked(element: int) -> bool:
	return _unlocked_elements.has(element)

func is_ku_unlocked() -> bool:
	return is_element_unlocked(GodaiElementScript.Value.KU)

func unlock_element(element: int) -> void:
	if _unlocked_elements.has(element):
		return
	_unlocked_elements.append(element)
	element_unlocked.emit(element)
	if element == GodaiElementScript.Value.KU:
		# Ku should start at full charge immediately on unlock.
		_kusho_pool.set_charge(GodaiElementScript.Value.KU, KushoPoolScript.CAPACITY_PER_ELEMENT)
		element_charge_changed.emit(GodaiElementScript.Value.KU, _kusho_pool.get_charge(GodaiElementScript.Value.KU))
		_register_discovery(SatoriIds.KU_GUIDANCE_ENTRY_ID, false)

func lookup_recipe(elements: Array[int]) -> SeedRecipe:
	for element: int in elements:
		if not is_element_unlocked(element):
			return null
	return _registry.lookup(elements)

func craft_seed(elements: Array[int]) -> bool:
	var slots: Array[int] = []
	for i: int in range(9):
		slots.append(SeedCraftGridNormalizerScript.EMPTY_SLOT)
	for i: int in range(mini(elements.size(), slots.size())):
		slots[i] = elements[i]
	var result = attempt_seed_craft_from_grid(slots)
	return result.is_success()

func get_ritual_input_definitions() -> Array[Dictionary]:
	var inputs: Array[Dictionary] = []
	inputs.append(_essence_input(&"earth", GodaiElementScript.Value.CHI, "Earth Essence"))
	inputs.append(_essence_input(&"water", GodaiElementScript.Value.SUI, "Water Essence"))
	inputs.append(_essence_input(&"fire", GodaiElementScript.Value.KA, "Fire Essence"))
	inputs.append(_essence_input(&"wind", GodaiElementScript.Value.FU, "Wind Essence"))
	inputs.append(_essence_input(&"ku", GodaiElementScript.Value.KU, "Ku Essence"))
	for material_id: StringName in _ritual_material_input_ids():
		inputs.append({
			"kind": INPUT_KIND_MATERIAL,
			"id": material_id,
			"key": "material:%s" % str(material_id),
			"display_name": _material_display_name(material_id),
			"available_count": get_material_count(material_id),
			"available_for_selection": get_material_count(material_id) > 0,
			"unlocked": true,
		})
	return inputs

func get_material_count(material_id: StringName) -> int:
	return int(_material_counts.get(material_id, 0))

func get_material_display_order() -> Array[StringName]:
	return MATERIAL_DISPLAY_ORDER.duplicate()

func get_material_capacity(material_id: StringName) -> int:
	return DEFAULT_MATERIAL_CAPACITY + _material_capacity_bonus(material_id)

func try_add_material(material_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	var current: int = get_material_count(material_id)
	var capacity: int = get_material_capacity(material_id)
	if current + amount > capacity:
		return false
	_material_counts[material_id] = current + amount
	material_count_changed.emit(material_id, get_material_count(material_id))
	return true

func add_material_for_testing(material_id: StringName, amount: int) -> void:
	if amount == 0:
		return
	var current: int = int(_material_counts.get(material_id, 0))
	_material_counts[material_id] = maxi(0, current + amount)
	material_count_changed.emit(material_id, get_material_count(material_id))

func preview_ritual(slot_keys: Array[String]) -> RitualAttemptResultScript:
	return _resolve_ritual(slot_keys, false)

func attempt_ritual(slot_keys: Array[String]) -> RitualAttemptResultScript:
	var result: RitualAttemptResultScript = _resolve_ritual(slot_keys, true)
	ritual_attempt_resolved.emit(
		result.outcome,
		result.feedback_key,
		result.guidance,
		result.ritual_id,
		result.result_kind,
		result.result_id
	)
	return result

func resolve_form_placement(type_key: StringName, target_biome: int) -> StringName:
	if _ritual_catalog == null or not _ritual_catalog.is_placeable_form(type_key):
		return type_key
	return _ritual_catalog.resolve_form_placement(type_key, target_biome)

func is_placeable_form(type_key: StringName) -> bool:
	return _ritual_catalog != null and _ritual_catalog.is_placeable_form(type_key)

func get_form_display_name(type_key: StringName) -> String:
	if _ritual_catalog == null:
		return ""
	var entry = _ritual_catalog.get_form_entry(type_key)
	if entry == null:
		return ""
	return entry.friendly_name

func preview_phase1_seed_recipe_from_grid(slot_tokens: Array[int]) -> SeedRecipe:
	var normalized: Dictionary = _grid_normalizer.normalize_slots(slot_tokens)
	var occupied_count: int = int(normalized.get("occupied_count", 0))
	if occupied_count < 1 or occupied_count > 2:
		return null
	var normalized_variant: Variant = normalized.get("normalized_tokens", [])
	if not (normalized_variant is Array):
		return null
	var normalized_tokens: Array[int] = []
	for token_variant: Variant in normalized_variant:
		normalized_tokens.append(int(token_variant))
	return _registry.lookup_phase1_seed(normalized_tokens)

func attempt_seed_craft_from_grid(slot_tokens: Array[int]):
	var normalized: Dictionary = _grid_normalizer.normalize_slots(slot_tokens)
	var occupied_count: int = int(normalized.get("occupied_count", 0))
	if occupied_count == 0:
		return _emit_attempt_result(SeedCraftAttemptResultScript.empty_input())
	if occupied_count > 2:
		return _emit_attempt_result(SeedCraftAttemptResultScript.no_matching_seed_recipe())

	var normalized_variant: Variant = normalized.get("normalized_tokens", [])
	if not (normalized_variant is Array):
		return _emit_attempt_result(SeedCraftAttemptResultScript.no_matching_seed_recipe())
	var normalized_tokens: Array[int] = []
	for token_variant: Variant in normalized_variant:
		normalized_tokens.append(int(token_variant))

	var recipe: SeedRecipe = _registry.lookup_phase1_seed(normalized_tokens)
	if recipe == null:
		return _emit_attempt_result(SeedCraftAttemptResultScript.no_matching_seed_recipe())
	if _recipe_has_locked_elements(recipe):
		return _emit_attempt_result(SeedCraftAttemptResultScript.locked_element(recipe))
	if not can_afford_mix(recipe.elements):
		return _emit_attempt_result(SeedCraftAttemptResultScript.no_matching_seed_recipe())

	var pouch: SeedPouch = get_pouch()
	if pouch == null or pouch.is_full():
		return _emit_attempt_result(SeedCraftAttemptResultScript.inventory_full(recipe))
	if not pouch.add(recipe):
		return _emit_attempt_result(SeedCraftAttemptResultScript.inventory_full(recipe))
	_notify_pouch_updated()

	_consume_mix_elements(recipe.elements)
	var consumed_slots: Array[int] = _resolve_consumed_slots(slot_tokens, recipe.elements)
	if not _discovered.has(recipe.recipe_id):
		_register_discovery(recipe.recipe_id, true)
	seed_added_to_pouch.emit(recipe)
	return _emit_attempt_result(SeedCraftAttemptResultScript.success(recipe, consumed_slots))

func _resolve_ritual(slot_keys: Array[String], confirm: bool) -> RitualAttemptResultScript:
	var keys: Array[String] = _filled_ritual_keys(slot_keys)
	if keys.is_empty():
		return RitualAttemptResultScript.empty_input()
	if keys.size() > 3:
		return RitualAttemptResultScript.no_match()
	if _has_duplicate_strings(keys):
		return RitualAttemptResultScript.duplicate_input()
	var input_defs: Dictionary = _ritual_input_defs_by_key()
	var has_essence: bool = false
	for key: String in keys:
		var def_variant: Variant = input_defs.get(key, null)
		if not (def_variant is Dictionary):
			return RitualAttemptResultScript.locked_input(key)
		var input_def: Dictionary = def_variant as Dictionary
		if not bool(input_def.get("unlocked", false)):
			return RitualAttemptResultScript.locked_input(key)
		if StringName(str(input_def.get("kind", &""))) == INPUT_KIND_ESSENCE:
			has_essence = true
		var available_count: int = int(input_def.get("available_count", 0))
		if available_count <= 0:
			return RitualAttemptResultScript.locked_input(key)
	if not has_essence:
		return RitualAttemptResultScript.missing_essence()

	var normalized_keys: Array[String] = keys.duplicate()
	normalized_keys.sort()
	var form_result: RitualAttemptResultScript = _resolve_form_ritual(normalized_keys, confirm)
	if form_result != null:
		return form_result
	return _resolve_seed_ritual(normalized_keys, confirm)

func _resolve_seed_ritual(normalized_keys: Array[String], confirm: bool) -> RitualAttemptResultScript:
	var elements: Array[int] = []
	for key: String in normalized_keys:
		if not key.begins_with("essence:"):
			return RitualAttemptResultScript.no_match()
		var element: int = _element_for_essence_key(key)
		if element == INVALID_ELEMENT:
			return RitualAttemptResultScript.no_match()
		elements.append(element)
	if elements.size() < 1 or elements.size() > 2:
		return RitualAttemptResultScript.no_match()
	if _ritual_catalog == null:
		return RitualAttemptResultScript.no_match()
	var entry = _ritual_catalog.lookup_seed(normalized_keys)
	if entry == null:
		return RitualAttemptResultScript.no_match()
	var recipe: SeedRecipe = _registry.lookup_phase1_seed(entry.required_elements)
	if recipe == null:
		return RitualAttemptResultScript.no_match()
	if recipe.recipe_id != entry.result_id:
		return RitualAttemptResultScript.no_match()
	if _recipe_has_locked_elements(recipe):
		return RitualAttemptResultScript.locked_input(_key_for_element(recipe.elements[0]))
	if not can_afford_mix(recipe.elements):
		var no_energy: RitualAttemptResultScript = RitualAttemptResultScript.no_match()
		no_energy.guidance = "Gather more essence before shaping this seed."
		return no_energy
	if not confirm:
		return RitualAttemptResultScript.success(entry.ritual_id, entry.result_kind, entry.result_id, entry.input_keys, entry.discovery_id)
	var pouch: SeedPouch = get_pouch()
	if pouch == null or pouch.is_full():
		return RitualAttemptResultScript.inventory_full(&"seed", recipe.recipe_id)
	if not pouch.add(recipe):
		return RitualAttemptResultScript.inventory_full(&"seed", recipe.recipe_id)
	_notify_pouch_updated()
	_consume_mix_elements(recipe.elements)
	if entry.discovery_id != &"" and not _discovered.has(entry.discovery_id):
		_register_discovery(entry.discovery_id, true)
	seed_added_to_pouch.emit(recipe)
	return RitualAttemptResultScript.success(entry.ritual_id, entry.result_kind, entry.result_id, entry.input_keys, entry.discovery_id)

func _resolve_form_ritual(normalized_keys: Array[String], confirm: bool) -> RitualAttemptResultScript:
	if _ritual_catalog == null:
		return null
	var entry = _ritual_catalog.lookup_form(normalized_keys)
	if entry == null:
		return null
	var required_elements: Array[int] = []
	for element: int in entry.required_elements:
		required_elements.append(element)
	if not can_afford_mix(required_elements):
		var no_energy: RitualAttemptResultScript = RitualAttemptResultScript.no_match()
		no_energy.guidance = "Gather more essence before shaping this form."
		return no_energy
	for material_variant: Variant in entry.required_material_counts.keys():
		var material_id: StringName = StringName(str(material_variant))
		var required_count: int = int(entry.required_material_counts.get(material_variant, 0))
		if get_material_count(material_id) < required_count:
			return RitualAttemptResultScript.locked_input("material:%s" % str(material_id))
	if not confirm:
		return RitualAttemptResultScript.success(entry.ritual_id, entry.result_kind, entry.result_id, entry.input_keys, entry.discovery_id)
	var pouch: SeedPouch = get_pouch()
	if pouch == null or not pouch.add_building(entry.result_id):
		return RitualAttemptResultScript.inventory_full(entry.result_kind, entry.result_id)
	_notify_pouch_updated()
	_consume_mix_elements(required_elements)
	for material_variant_confirm: Variant in entry.required_material_counts.keys():
		var consumed_material_id: StringName = StringName(str(material_variant_confirm))
		var consumed_count: int = int(entry.required_material_counts.get(material_variant_confirm, 0))
		_material_counts[consumed_material_id] = maxi(0, get_material_count(consumed_material_id) - consumed_count)
		material_count_changed.emit(consumed_material_id, get_material_count(consumed_material_id))
	if entry.discovery_id != &"" and not _building_discovered.has(entry.discovery_id):
		_building_discovered[entry.discovery_id] = true
		_register_discovery(entry.discovery_id, true)
		_record_persistent_discovery(entry.discovery_id, entry.friendly_name, entry.codex_hint)
	return RitualAttemptResultScript.success(entry.ritual_id, entry.result_kind, entry.result_id, entry.input_keys, entry.discovery_id)

func get_element_charge(element: int) -> int:
	return _kusho_pool.get_charge(element)

func can_afford_mix(elements: Array[int]) -> bool:
	var required_counts: Dictionary = {}
	for element: int in elements:
		required_counts[element] = int(required_counts.get(element, 0)) + 1
	for element_variant: Variant in required_counts.keys():
		var element: int = int(element_variant)
		if _kusho_pool.get_charge(element) < int(required_counts[element_variant]):
			return false
	return true

func spend_for_biome_placement(biome: int) -> bool:
	var element: int = _element_for_biome_placement(biome)
	if element == INVALID_ELEMENT:
		return false
	if not _kusho_pool.consume(element, 1):
		return false
	element_charge_changed.emit(element, _kusho_pool.get_charge(element))
	return true

func spend_for_recipe_placement(recipe: SeedRecipe) -> bool:
	if recipe == null:
		return false
	var spent_elements: Array[int] = []
	for element: int in recipe.elements:
		if not is_element_unlocked(element):
			_refund_elements(spent_elements)
			return false
		if not _kusho_pool.consume(element, 1):
			_refund_elements(spent_elements)
			return false
		spent_elements.append(element)
		element_charge_changed.emit(element, _kusho_pool.get_charge(element))
	return true

func refund_for_biome_placement(biome: int) -> void:
	var element: int = _element_for_biome_placement(biome)
	if element == INVALID_ELEMENT:
		return
	_kusho_pool.add_charge(element, 1)
	element_charge_changed.emit(element, _kusho_pool.get_charge(element))

func refund_for_recipe_placement(recipe: SeedRecipe) -> void:
	if recipe == null:
		return
	_refund_elements(recipe.elements)

func set_element_charge_for_testing(element: int, charge: int) -> void:
	if _kusho_pool.has_method("set_charge_for_testing"):
		_kusho_pool.set_charge_for_testing(element, charge)
	else:
		_kusho_pool.set_charge(element, charge)
	element_charge_changed.emit(element, _kusho_pool.get_charge(element))

func store_shrine_charge(coord: Vector2i, element: int, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if element < GodaiElementScript.Value.CHI or element > GodaiElementScript.Value.KU:
		return false
	var coord_key: String = _coord_key(coord)
	var counts_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	var counts: Dictionary = {}
	if counts_variant is Dictionary:
		counts = (counts_variant as Dictionary).duplicate()
	var current_amount: int = int(counts.get(element, 0))
	var next_amount: int = mini(KushoPoolScript.CAPACITY_PER_ELEMENT, current_amount + amount)
	if next_amount <= current_amount:
		return false
	counts[element] = next_amount
	_pending_shrine_charges[coord_key] = counts
	shrine_charge_ready.emit(coord, element)
	return true

func collect_shrine_charge(coord: Vector2i) -> bool:
	var coord_key: String = _coord_key(coord)
	var counts_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	if not (counts_variant is Dictionary):
		return false
	var counts: Dictionary = counts_variant as Dictionary
	var had_any: bool = false
	for key_variant: Variant in counts.keys():
		var element: int = int(key_variant)
		var amount: int = int(counts.get(key_variant, 0))
		if element == INVALID_ELEMENT or amount <= 0:
			continue
		had_any = true
		var overflow: int = _kusho_pool.add_charge(element, amount)
		var collected: int = amount - overflow
		if collected > 0:
			element_charge_changed.emit(element, _kusho_pool.get_charge(element))
			shrine_charge_collected.emit(coord, element, collected)
	if not had_any:
		return false
	# A collect action consumes the pending shrine gift, even if the pool is full.
	_pending_shrine_charges.erase(coord_key)
	return true

func has_shrine_charge(coord: Vector2i) -> bool:
	var coord_key: String = _coord_key(coord)
	if not _pending_shrine_charges.has(coord_key):
		return false
	var counts_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	if not (counts_variant is Dictionary):
		return false
	return not (counts_variant as Dictionary).is_empty()

func get_shrine_charge_counts(coord: Vector2i) -> Dictionary:
	var coord_key: String = _coord_key(coord)
	var counts_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	if counts_variant is Dictionary:
		return (counts_variant as Dictionary).duplicate(true)
	return {}

func _coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func _essence_input(id: StringName, element: int, display_name: String) -> Dictionary:
	var unlocked: bool = is_element_unlocked(element)
	var charge: int = _kusho_pool.get_charge(element) if unlocked else 0
	return {
		"kind": INPUT_KIND_ESSENCE,
		"id": id,
		"key": _key_for_element(element),
		"element": element,
		"display_name": display_name,
		"available_count": charge,
		"available_for_selection": unlocked and charge > 0,
		"unlocked": unlocked,
	}

func _ritual_material_input_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	if _ritual_catalog != null:
		for material_id: StringName in _ritual_catalog.get_required_material_ids():
			seen[material_id] = true
			ids.append(material_id)
	for material_id_ordered: StringName in MATERIAL_DISPLAY_ORDER:
		if seen.has(material_id_ordered):
			continue
		seen[material_id_ordered] = true
		ids.append(material_id_ordered)
	return ids

func _material_display_name(material_id: StringName) -> String:
	match material_id:
		&"living_wood":
			return "Living Wood"
		&"reed_fiber":
			return "Reed Fiber"
		&"spirit_stone":
			return "Spirit Stone"
		&"ember_clay":
			return "Ember Clay"
		_:
			return str(material_id).replace("_", " ").capitalize()

func _ritual_input_defs_by_key() -> Dictionary:
	var defs: Dictionary = {}
	for input_def: Dictionary in get_ritual_input_definitions():
		defs[str(input_def.get("key", ""))] = input_def
	return defs

func _material_capacity_bonus(material_id: StringName) -> int:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("get_material_capacity_bonus"):
		return 0
	return int(game_state.get_material_capacity_bonus(material_id))

func _filled_ritual_keys(slot_keys: Array[String]) -> Array[String]:
	var keys: Array[String] = []
	for key: String in slot_keys:
		if key.strip_edges().is_empty():
			continue
		keys.append(key)
	return keys

func _has_duplicate_strings(values: Array[String]) -> bool:
	var seen: Dictionary = {}
	for value: String in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false

func _key_for_element(element: int) -> String:
	match element:
		GodaiElementScript.Value.CHI:
			return "essence:earth"
		GodaiElementScript.Value.SUI:
			return "essence:water"
		GodaiElementScript.Value.KA:
			return "essence:fire"
		GodaiElementScript.Value.FU:
			return "essence:wind"
		GodaiElementScript.Value.KU:
			return "essence:ku"
		_:
			return ""

func _element_for_essence_key(key: String) -> int:
	match key:
		"essence:earth":
			return GodaiElementScript.Value.CHI
		"essence:water":
			return GodaiElementScript.Value.SUI
		"essence:fire":
			return GodaiElementScript.Value.KA
		"essence:wind":
			return GodaiElementScript.Value.FU
		"essence:ku":
			return GodaiElementScript.Value.KU
		_:
			return INVALID_ELEMENT

func _keys_for_elements(elements: Array[int]) -> Array[String]:
	var keys: Array[String] = []
	for element: int in elements:
		keys.append(_key_for_element(element))
	keys.sort()
	return keys

func _ritual_id_for_seed(recipe: SeedRecipe) -> StringName:
	if recipe == null:
		return &""
	return StringName("ritual_%s" % str(recipe.recipe_id).replace("recipe_", ""))

func _consume_mix_elements(elements: Array[int]) -> void:
	for element: int in elements:
		if _kusho_pool.consume(element, 1):
			element_charge_changed.emit(element, _kusho_pool.get_charge(element))

func _refund_mix_elements(elements: Array[int]) -> void:
	_refund_elements(elements)

func _refund_elements(elements: Array[int]) -> void:
	for element: int in elements:
		_kusho_pool.add_charge(element, 1)
		element_charge_changed.emit(element, _kusho_pool.get_charge(element))

func _recipe_has_locked_elements(recipe: SeedRecipe) -> bool:
	if recipe == null:
		return true
	for element: int in recipe.elements:
		if not is_element_unlocked(element):
			return true
	return false

func _resolve_consumed_slots(slot_tokens: Array[int], recipe_elements: Array[int]) -> Array[int]:
	var remaining: Dictionary = {}
	for element: int in recipe_elements:
		remaining[element] = int(remaining.get(element, 0)) + 1
	var consumed: Array[int] = []
	for slot_index: int in range(slot_tokens.size()):
		var token: int = slot_tokens[slot_index]
		if token == SeedCraftGridNormalizerScript.EMPTY_SLOT:
			continue
		var count: int = int(remaining.get(token, 0))
		if count <= 0:
			continue
		consumed.append(slot_index)
		remaining[token] = count - 1
	consumed.sort()
	return consumed

func _emit_attempt_result(result):
	craft_attempt_resolved.emit(result.outcome, result.feedback_key, result.guidance, result.consumed_slot_indices)
	return result

func _element_for_biome_placement(biome: int) -> int:
	match biome:
		BiomeTypeScript.Value.STONE:
			return GodaiElementScript.Value.CHI
		BiomeTypeScript.Value.RIVER:
			return GodaiElementScript.Value.SUI
		BiomeTypeScript.Value.EMBER_FIELD:
			return GodaiElementScript.Value.KA
		BiomeTypeScript.Value.MEADOW:
			return GodaiElementScript.Value.FU
		BiomeTypeScript.Value.KU:
			return GodaiElementScript.Value.KU
		_:
			return INVALID_ELEMENT

func _register_discovery(entry_id: StringName, emit_recipe_signal: bool) -> void:
	_discovered[entry_id] = true
	if emit_recipe_signal:
		recipe_discovered.emit(entry_id)
	_mark_codex_discovered(entry_id)

func _mark_codex_discovered(entry_id: StringName) -> void:
	var codex_service: Node = get_node_or_null("/root/CodexService")
	if codex_service != null and codex_service.has_method("mark_discovered"):
		codex_service.mark_discovered(entry_id)

func _record_persistent_discovery(entry_id: StringName, display_name: String = "", flavor_text: String = "") -> void:
	if entry_id == &"":
		return
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence == null or not persistence.has_method("record_discovery"):
		return
	var safe_display_name: String = display_name if not display_name.is_empty() else str(entry_id)
	var payload: DiscoveryPayload = DiscoveryPayload.create(str(entry_id), [], {
		"display_name": safe_display_name,
		"flavor_text": flavor_text,
		"audio_key": "",
	})
	persistence.record_discovery(payload)

func get_pouch() -> SeedPouch:
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_pouch"):
		return null
	return growth_service.get_pouch()

func get_registry():
	return _registry

func _notify_pouch_updated() -> void:
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_method("notify_pouch_updated"):
		growth_service.notify_pouch_updated()
