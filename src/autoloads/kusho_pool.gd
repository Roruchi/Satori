class_name KushoPool
extends RefCounted

const GodaiElement = preload("res://src/seeds/GodaiElement.gd")
const CAPACITY_PER_ELEMENT: int = 5

var _charges: Dictionary = {
	GodaiElement.Value.CHI: 0,
	GodaiElement.Value.SUI: 0,
	GodaiElement.Value.KA: 0,
	GodaiElement.Value.FU: 0,
	GodaiElement.Value.KU: 0,
}

func set_charge(element: int, charge: int) -> void:
	_charges[element] = clampi(charge, 0, CAPACITY_PER_ELEMENT)

func get_charge(element: int) -> int:
	return int(_charges.get(element, 0))

func consume(element: int, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	var current: int = get_charge(element)
	if current < amount:
		return false
	_charges[element] = current - amount
	return true

func add_charge(element: int, amount: int = 1) -> int:
	if amount <= 0:
		return 0
	var current: int = get_charge(element)
	var space: int = CAPACITY_PER_ELEMENT - current
	if space <= 0:
		return amount
	var accepted: int = mini(space, amount)
	_charges[element] = current + accepted
	return amount - accepted

func is_low(element: int) -> bool:
	return get_charge(element) == 1

func is_depleted(element: int) -> bool:
	return get_charge(element) == 0

func are_all_depleted() -> bool:
	for element: int in _charges.keys():
		if int(_charges[element]) > 0:
			return false
	return true
