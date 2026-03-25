class_name GrowthModeToggleButton
extends Button

const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")

func _ready() -> void:
	pressed.connect(_on_pressed)
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_mode_changed"):
		settings.growth_mode_changed.connect(_update_display)
		_update_display(int(settings.get("growth_mode")))
	else:
		_update_display(GrowthModeScript.Value.REAL_TIME)

func _on_pressed() -> void:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings == null or not settings.has_method("set_growth_mode"):
		return
	var mode: int = int(settings.get("growth_mode"))
	var next_mode: int = GrowthModeScript.Value.INSTANT if mode == GrowthModeScript.Value.REAL_TIME else GrowthModeScript.Value.REAL_TIME
	settings.set_growth_mode(next_mode)

func _update_display(mode: int) -> void:
	if mode == GrowthModeScript.Value.INSTANT:
		text = "⚡"
		tooltip_text = "INSTANT"
	else:
		text = "RT"
		tooltip_text = "REAL_TIME"
