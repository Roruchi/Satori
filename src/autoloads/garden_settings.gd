class_name GardenSettingsNode
extends Node

const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")

signal growth_mode_changed(mode: int)

var growth_mode: int = GrowthModeScript.Value.INSTANT

func _ready() -> void:
	var seed_growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if seed_growth_service != null and seed_growth_service.has_method("set_mode"):
		seed_growth_service.set_mode(growth_mode)
	growth_mode_changed.emit(growth_mode)

func set_growth_mode(mode: int) -> void:
	if growth_mode == mode:
		return
	growth_mode = mode
	var seed_growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if seed_growth_service != null and seed_growth_service.has_method("set_mode"):
		seed_growth_service.set_mode(mode)
	growth_mode_changed.emit(mode)
