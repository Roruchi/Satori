class_name HUDController
extends CanvasLayer

const GrowthMode = preload("res://src/seeds/GrowthMode.gd")

enum Mode {
	PLANT,
	MIX,
	CODEX,
}

@onready var _plant_button: Button = $Root/BottomBar/PlantButton
@onready var _mix_button: Button = $Root/BottomBar/MixButton
@onready var _codex_button: Button = $Root/BottomBar/CodexButton
@onready var _mix_panel: SeedAlchemyPanel = $Root/Panels/SeedAlchemyPanel
@onready var _codex_panel: CodexPanel = $Root/Panels/CodexPanel
@onready var _instant_badge: Label = $Root/TopBar/InstantModeBadge
@onready var _pouch_display: SeedPouchDisplay = $Root/TopBar/SeedPouchDisplay

var _mode: int = Mode.PLANT

func _ready() -> void:
	_plant_button.pressed.connect(func() -> void: _set_mode(Mode.PLANT))
	_mix_button.pressed.connect(func() -> void: _set_mode(Mode.MIX))
	_codex_button.pressed.connect(func() -> void: _set_mode(Mode.CODEX))
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_mode_changed"):
		settings.growth_mode_changed.connect(_on_growth_mode_changed)
		var current_mode_variant: Variant = settings.get("growth_mode")
		if current_mode_variant is int:
			_on_growth_mode_changed(int(current_mode_variant))
		else:
			_on_growth_mode_changed(GrowthMode.Value.REAL_TIME)
	else:
		push_warning("HUDController could not connect to GardenSettings.growth_mode_changed")
		_on_growth_mode_changed(GrowthMode.Value.REAL_TIME)
	_set_mode(Mode.PLANT)

func _on_growth_mode_changed(mode: int) -> void:
	_instant_badge.visible = mode == GrowthMode.Value.INSTANT

func _set_mode(next_mode: int) -> void:
	_mode = next_mode
	_mix_panel.visible = _mode == Mode.MIX
	_codex_panel.visible = _mode == Mode.CODEX
	_pouch_display.visible = _mode == Mode.PLANT
	_plant_button.modulate = Color.WHITE if _mode == Mode.PLANT else Color(0.75, 0.75, 0.75)
	_mix_button.modulate = Color.WHITE if _mode == Mode.MIX else Color(0.75, 0.75, 0.75)
	_codex_button.modulate = Color.WHITE if _mode == Mode.CODEX else Color(0.75, 0.75, 0.75)

func is_plant_mode() -> bool:
	return _mode == Mode.PLANT
