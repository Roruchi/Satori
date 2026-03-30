## CraftingService — autoload singleton for the 3×3 crafting pipeline.
## No class_name to avoid autoload/class_name collision.
extends Node

const _RecipeRegistryScript = preload("res://src/crafting/RecipeRegistry.gd")
const _PlayerInventoryScript = preload("res://src/crafting/PlayerInventory.gd")
const _InventoryItemScript = preload("res://src/crafting/InventoryItem.gd")
const _BuildModeScript = preload("res://src/crafting/BuildMode.gd")
const _RecipeDefinitionScript = preload("res://src/crafting/RecipeDefinition.gd")

signal inventory_changed()
signal build_mode_entered(recipe: RecipeDefinition)
signal build_mode_exited()
signal structure_placed(record: PlacementRecord)

var registry: RecipeRegistry
var inventory: PlayerInventory
var active_build_mode: BuildMode = null

var _deferred_spirit_events: Array[Callable] = []

func _ready() -> void:
	registry = _RecipeRegistryScript.new()
	inventory = _PlayerInventoryScript.new()
	inventory.item_added.connect(_on_item_added)
	inventory.item_removed.connect(_on_item_removed)

func _on_item_added(_item: InventoryItem) -> void:
	inventory_changed.emit()

func _on_item_removed(_recipe_id: String) -> void:
	inventory_changed.emit()

## Craft a recipe: create an InventoryItem and add it to inventory.
func craft(recipe: RecipeDefinition) -> void:
	var item: InventoryItem = _InventoryItemScript.new()
	item.recipe_id = recipe.recipe_id
	item.item_type = recipe.output_type
	item.quantity = 1
	item.output_id = recipe.output_id
	inventory.add_item(item)

## Enter ghost-placement build mode for a crafted structure item.
func enter_build_mode(recipe_id: String) -> void:
	if active_build_mode != null:
		return
	var recipe: RecipeDefinition = registry.get_by_id(recipe_id)
	if recipe == null:
		return
	if recipe.output_type != _RecipeDefinitionScript.OutputType.STRUCTURE:
		return
	active_build_mode = _BuildModeScript.new(recipe, GameState.grid)
	active_build_mode.placement_confirmed.connect(_on_placement_confirmed)
	active_build_mode.placement_cancelled.connect(_on_placement_cancelled)
	build_mode_entered.emit(recipe)

func _on_placement_confirmed(record: PlacementRecord) -> void:
	inventory.consume(record.recipe_id)
	GameState.confirm_placement(record)
	structure_placed.emit(record)
	active_build_mode = null
	build_mode_exited.emit()
	_flush_deferred_spirit_events()

func _on_placement_cancelled(_recipe_id: String) -> void:
	active_build_mode = null
	build_mode_exited.emit()
	_flush_deferred_spirit_events()

## If not in build mode, call fn immediately; otherwise enqueue for after placement.
func defer_spirit_event(fn: Callable) -> void:
	if active_build_mode == null:
		fn.call()
	else:
		_deferred_spirit_events.append(fn)

func _flush_deferred_spirit_events() -> void:
	var events: Array[Callable] = _deferred_spirit_events.duplicate()
	_deferred_spirit_events.clear()
	for fn: Callable in events:
		fn.call()
