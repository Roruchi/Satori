class_name BuildingInventoryEntry
extends RefCounted

const STACK_CAP: int = 99
const ENTRY_KIND: StringName = &"building_item"

var type_key: StringName = &""
var count: int = 1

static func create(key: StringName, initial_count: int = 1) -> BuildingInventoryEntry:
	var entry: BuildingInventoryEntry = new()
	entry.type_key = key
	entry.count = clampi(initial_count, 1, STACK_CAP)
	return entry

func can_add(amount: int = 1) -> bool:
	return count + amount <= STACK_CAP

func add(amount: int = 1) -> int:
	var space: int = STACK_CAP - count
	var to_add: int = mini(space, amount)
	count += to_add
	return amount - to_add

func consume(amount: int = 1) -> bool:
	if count < amount:
		return false
	count -= amount
	return true
