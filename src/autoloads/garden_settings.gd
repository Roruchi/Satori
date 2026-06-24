class_name GardenSettingsNode
extends Node

signal growth_speed_multiplier_changed(multiplier: float)
signal debug_info_enabled_changed(enabled: bool)

var growth_speed_multiplier: float = 1.0
var debug_info_enabled: bool = false

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

func get_progression_speed_multiplier() -> float:
	return maxf(1.0, growth_speed_multiplier)

func scale_progress_delta(delta_seconds: float) -> float:
	return maxf(0.0, delta_seconds) * get_progression_speed_multiplier()

func scaled_progress_duration(duration_seconds: float) -> float:
	return maxf(0.1, maxf(0.0, duration_seconds) / get_progression_speed_multiplier())

func set_debug_info_enabled(enabled: bool) -> void:
	if debug_info_enabled == enabled:
		return
	debug_info_enabled = enabled
	debug_info_enabled_changed.emit(debug_info_enabled)
