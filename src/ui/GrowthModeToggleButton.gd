class_name GrowthModeToggleButton
extends Button

const SPEED_STEPS: Array[float] = [1.0, 4.0, 8.0]

func _ready() -> void:
	pressed.connect(_on_pressed)
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_speed_multiplier_changed"):
		settings.growth_speed_multiplier_changed.connect(_update_display)
		_update_display(float(settings.get("growth_speed_multiplier")))
	else:
		_update_display(1.0)

func _on_pressed() -> void:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings == null or not settings.has_method("set_growth_speed_multiplier"):
		return
	var current_multiplier: float = float(settings.get("growth_speed_multiplier"))
	var next_multiplier: float = SPEED_STEPS[0]
	for i: int in range(SPEED_STEPS.size()):
		if is_equal_approx(current_multiplier, SPEED_STEPS[i]):
			next_multiplier = SPEED_STEPS[(i + 1) % SPEED_STEPS.size()]
			break
	settings.set_growth_speed_multiplier(next_multiplier)

func _update_display(multiplier: float) -> void:
	var rounded: int = int(round(multiplier))
	text = "x%d" % max(1, rounded)
	tooltip_text = "Growth speed x%d" % max(1, rounded)
