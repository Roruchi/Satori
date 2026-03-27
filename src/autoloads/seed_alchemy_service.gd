class_name SeedAlchemyServiceNode
extends Node

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SeedRecipeRegistryScript = preload("res://src/seeds/SeedRecipeRegistry.gd")
const SatoriIds = preload("res://src/satori/SatoriIds.gd")

signal element_unlocked(element_id: int)
signal recipe_discovered(recipe_id: StringName)
signal seed_added_to_pouch(recipe: SeedRecipe)

var _registry: SeedRecipeRegistry
var _unlocked_elements: Array[int] = [
	GodaiElementScript.Value.CHI,
	GodaiElementScript.Value.SUI,
	GodaiElementScript.Value.KA,
	GodaiElementScript.Value.FU,
]
var _discovered: Dictionary = {}

func _ready() -> void:
	_registry = SeedRecipeRegistryScript.new()

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
	var pouch: SeedPouch = get_pouch()
	if pouch == null or pouch.is_full():
		return false
	if not pouch.add(recipe):
		return false
	if not _discovered.has(recipe.recipe_id):
		_register_discovery(recipe.recipe_id, true)
	seed_added_to_pouch.emit(recipe)
	return true

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
