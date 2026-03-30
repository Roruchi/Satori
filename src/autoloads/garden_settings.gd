class_name GardenSettingsNode
extends Node

signal growth_speed_multiplier_changed(multiplier: float)

var growth_speed_multiplier: float = 1.0

func _ready() -> void:
	var seed_growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if seed_growth_service != null and seed_growth_service.has_method("set_growth_speed_multiplier"):
		seed_growth_service.set_growth_speed_multiplier(growth_speed_multiplier)
	growth_speed_multiplier_changed.emit(growth_speed_multiplier)

func set_growth_speed_multiplier(multiplier: float) -> void:
	var clamped_multiplier: float = clampf(multiplier, 1.0, 16.0)
	if is_equal_approx(growth_speed_multiplier, clamped_multiplier):
		return
	growth_speed_multiplier = clamped_multiplier
	var seed_growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if seed_growth_service != null and seed_growth_service.has_method("set_growth_speed_multiplier"):
		seed_growth_service.set_growth_speed_multiplier(growth_speed_multiplier)
	growth_speed_multiplier_changed.emit(growth_speed_multiplier)
