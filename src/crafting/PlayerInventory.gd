class_name PlayerInventory
extends RefCounted

signal item_added(item: InventoryItem)
signal item_removed(recipe_id: String)

var _items: Dictionary = {}

func add_item(item: InventoryItem) -> void:
	if _items.has(item.recipe_id):
		var existing: InventoryItem = _items[item.recipe_id] as InventoryItem
		existing.quantity += item.quantity
	else:
		var clone := InventoryItem.new()
		clone.recipe_id = item.recipe_id
		clone.item_type = item.item_type
		clone.quantity = item.quantity
		clone.output_id = item.output_id
		_items[item.recipe_id] = clone
	item_added.emit(_items[item.recipe_id] as InventoryItem)

func consume(recipe_id: String) -> bool:
	if not _items.has(recipe_id):
		return false
	var item: InventoryItem = _items[recipe_id] as InventoryItem
	item.quantity -= 1
	if item.quantity <= 0:
		_items.erase(recipe_id)
	item_removed.emit(recipe_id)
	return true

func has_item(recipe_id: String) -> bool:
	return _items.has(recipe_id)

func get_items() -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for v: Variant in _items.values():
		result.append(v as InventoryItem)
	return result

func serialize() -> Array:
	var data: Array = []
	for v: Variant in _items.values():
		var item: InventoryItem = v as InventoryItem
		data.append({
			"recipe_id": item.recipe_id,
			"item_type": item.item_type,
			"quantity": item.quantity,
			"output_id": item.output_id,
		})
	return data

static func deserialize(data: Array) -> PlayerInventory:
	var inv := PlayerInventory.new()
	for entry: Variant in data:
		var d: Dictionary = entry as Dictionary
		var item := InventoryItem.new()
		item.recipe_id = str(d.get("recipe_id", ""))
		item.item_type = int(d.get("item_type", 0))
		item.quantity = int(d.get("quantity", 1))
		item.output_id = str(d.get("output_id", ""))
		if item.recipe_id != "" and item.quantity > 0:
			inv._items[item.recipe_id] = item
	return inv
