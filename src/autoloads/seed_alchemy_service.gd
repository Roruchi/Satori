class_name SeedAlchemyServiceNode
extends Node

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SeedRecipeRegistryScript = preload("res://src/seeds/SeedRecipeRegistry.gd")
const SatoriIds = preload("res://src/satori/SatoriIds.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const INVALID_ELEMENT: int = -1

signal element_unlocked(element_id: int)
signal recipe_discovered(recipe_id: StringName)
signal seed_added_to_pouch(recipe: SeedRecipe)
signal shrine_charge_ready(coord: Vector2i, element_id: int)
signal shrine_charge_collected(coord: Vector2i, element_id: int, amount: int)

var _registry: SeedRecipeRegistry
var _kusho_pool: KushoPool = KushoPoolScript.new()
var _unlocked_elements: Array[int] = [
	GodaiElementScript.Value.CHI,
	GodaiElementScript.Value.SUI,
	GodaiElementScript.Value.KA,
	GodaiElementScript.Value.FU,
]
var _discovered: Dictionary = {}
var _pending_shrine_charges: Dictionary = {}

func _ready() -> void:
	_registry = SeedRecipeRegistryScript.new()
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
		_register_discovery(SatoriIds.KU_GUIDANCE_ENTRY_ID, false)

func lookup_recipe(elements: Array[int]) -> SeedRecipe:
	for element: int in elements:
		if not is_element_unlocked(element):
			return null
	return _registry.lookup(elements)

func craft_seed(elements: Array[int]) -> bool:
	var recipe: SeedRecipe = lookup_recipe(elements)
	if recipe == null:
		return false
	if not can_afford_mix(elements):
		return false
	var pouch: SeedPouch = get_pouch()
	if pouch == null or pouch.is_full():
		return false
	_consume_mix_elements(elements)
	if not pouch.add(recipe):
		_refund_mix_elements(elements)
		return false
	if not _discovered.has(recipe.recipe_id):
		_register_discovery(recipe.recipe_id, true)
	seed_added_to_pouch.emit(recipe)
	return true

func get_element_charge(element: int) -> int:
	return _kusho_pool.get_charge(element)

func can_afford_mix(elements: Array[int]) -> bool:
	for element: int in elements:
		if _kusho_pool.get_charge(element) < 1:
			return false
	return true

func spend_for_biome_placement(biome: int) -> bool:
	var element: int = _element_for_biome_placement(biome)
	if element == INVALID_ELEMENT:
		return false
	return _kusho_pool.consume(element, 1)

func refund_for_biome_placement(biome: int) -> void:
	var element: int = _element_for_biome_placement(biome)
	if element == INVALID_ELEMENT:
		return
	_kusho_pool.add_charge(element, 1)

func set_element_charge_for_testing(element: int, charge: int) -> void:
	_kusho_pool.set_charge(element, charge)

func store_shrine_charge(coord: Vector2i, element: int, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if element < GodaiElementScript.Value.CHI or element > GodaiElementScript.Value.KU:
		return false
	var coord_key: String = _coord_key(coord)
	var entry_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	var entry: Dictionary = {}
	if entry_variant is Dictionary:
		entry = entry_variant as Dictionary
	var stored_element: int = int(entry.get("element", element))
	if not entry.is_empty() and stored_element != element:
		return false
	var current_amount: int = int(entry.get("amount", 0))
	var next_amount: int = mini(KushoPoolScript.CAPACITY_PER_ELEMENT, current_amount + amount)
	if next_amount <= current_amount:
		return false
	_pending_shrine_charges[coord_key] = {"element": element, "amount": next_amount}
	shrine_charge_ready.emit(coord, element)
	return true

func collect_shrine_charge(coord: Vector2i) -> bool:
	var coord_key: String = _coord_key(coord)
	var entry_variant: Variant = _pending_shrine_charges.get(coord_key, null)
	if not (entry_variant is Dictionary):
		return false
	var entry: Dictionary = entry_variant as Dictionary
	var element: int = int(entry.get("element", INVALID_ELEMENT))
	var amount: int = int(entry.get("amount", 0))
	if element == INVALID_ELEMENT or amount <= 0:
		return false
	var overflow: int = _kusho_pool.add_charge(element, amount)
	var collected: int = amount - overflow
	if collected <= 0:
		return false
	if overflow > 0:
		_pending_shrine_charges[coord_key] = {"element": element, "amount": overflow}
	else:
		_pending_shrine_charges.erase(coord_key)
	shrine_charge_collected.emit(coord, element, collected)
	return true

func has_shrine_charge(coord: Vector2i) -> bool:
	var coord_key: String = _coord_key(coord)
	return _pending_shrine_charges.has(coord_key)

func _coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func _consume_mix_elements(elements: Array[int]) -> void:
	for element: int in elements:
		_kusho_pool.consume(element, 1)

func _refund_mix_elements(elements: Array[int]) -> void:
	for element: int in elements:
		_kusho_pool.add_charge(element, 1)

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

func get_pouch() -> SeedPouch:
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_pouch"):
		return null
	return growth_service.get_pouch()

func get_registry() -> SeedRecipeRegistry:
	return _registry
