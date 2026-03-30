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
signal element_charge_changed(element_id: int, charge: int)

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

## Origin Shrine grants a random element every SHRINE_GRANT_INTERVAL seconds.
const SHRINE_GRANT_INTERVAL: float = 300.0  # 5 minutes
var _shrine_grant_accumulator: float = 0.0

## Coord of the Origin Shrine tile (always at map origin).
const ORIGIN_SHRINE_COORD: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	_registry = SeedRecipeRegistryScript.new()
	for element: int in _unlocked_elements:
		_kusho_pool.set_charge(element, KushoPoolScript.CAPACITY_PER_ELEMENT)
	_kusho_pool.set_charge(GodaiElementScript.Value.KU, 0)

func _process(delta: float) -> void:
	_shrine_grant_accumulator += delta
	if _shrine_grant_accumulator >= SHRINE_GRANT_INTERVAL:
		_shrine_grant_accumulator -= SHRINE_GRANT_INTERVAL
		_grant_origin_shrine_element()

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

## Grant a random elemental charge to the Origin Shrine every SHRINE_GRANT_INTERVAL.
## Picks from the four basic elements (not KU) so the player is never fully stuck.
func _grant_origin_shrine_element() -> void:
	var basic_elements: Array[int] = [
		GodaiElementScript.Value.CHI,
		GodaiElementScript.Value.SUI,
		GodaiElementScript.Value.KA,
		GodaiElementScript.Value.FU,
	]
	var element: int = basic_elements[randi() % basic_elements.size()]
	store_shrine_charge(ORIGIN_SHRINE_COORD, element, 1)
