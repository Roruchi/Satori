class_name SettingsMenu
extends CanvasLayer

const PANEL_BG := Color(0.16, 0.11, 0.07, 0.98)
const PANEL_BORDER := Color(0.60, 0.42, 0.21, 0.95)
const TEXT_LIGHT := Color(0.89, 0.84, 0.74, 0.96)
const TEXT_TITLE := Color(0.95, 0.89, 0.73, 1.0)
const BTN_BG := Color(0.63, 0.74, 0.45, 0.90)
const BTN_BORDER := Color(0.45, 0.58, 0.28, 1.0)
const BTN_HOVER := Color(0.73, 0.84, 0.55, 1.0)
const BTN_TEXT := Color(0.19, 0.13, 0.08, 1.0)

@onready var _panel: PanelContainer = $Root/Center/Panel
@onready var _vbox: VBoxContainer = $Root/Center/Panel/VBox
@onready var _title_lbl: Label = $Root/Center/Panel/VBox/TitleLabel
@onready var _volume_slider: HSlider = $Root/Center/Panel/VBox/VolumeRow/VolumeSlider
@onready var _mute_check: CheckButton = $Root/Center/Panel/VBox/MuteRow/MuteCheck
@onready var _growth_check: CheckButton = $Root/Center/Panel/VBox/GrowthRow/GrowthCheck
@onready var _close_btn: Button = $Root/Center/Panel/VBox/CloseButton

func _ready() -> void:
	_style_ui()
	_sync_from_settings()
	_volume_slider.value_changed.connect(_on_volume_changed)
	_mute_check.toggled.connect(_on_mute_toggled)
	_growth_check.toggled.connect(_on_growth_toggled)
	_close_btn.pressed.connect(_on_close)

func _sync_from_settings() -> void:
	var se: Node = get_node_or_null("/root/SoundscapeEngine")
	if se != null:
		if se.has_method("get_master_volume"):
			_volume_slider.value = se.get_master_volume()
		if se.has_method("is_muted"):
			_mute_check.button_pressed = se.is_muted()
	var gs: Node = get_node_or_null("/root/GardenSettings")
	if gs != null:
		var speed_mult: Variant = gs.get("growth_speed_multiplier")
		if speed_mult is float:
			_growth_check.button_pressed = float(speed_mult) > 1.0
		elif speed_mult is int:
			_growth_check.button_pressed = int(speed_mult) > 1

func show_menu() -> void:
	_sync_from_settings()
	_growth_check.text = "Growth Speedup (x8)"
	visible = true

func _on_volume_changed(value: float) -> void:
	var se: Node = get_node_or_null("/root/SoundscapeEngine")
	if se != null and se.has_method("set_master_volume"):
		se.set_master_volume(value)

func _on_mute_toggled(pressed: bool) -> void:
	var se: Node = get_node_or_null("/root/SoundscapeEngine")
	if se != null and se.has_method("set_mute"):
		se.set_mute(pressed)

func _on_growth_toggled(pressed: bool) -> void:
	var gs: Node = get_node_or_null("/root/GardenSettings")
	if gs != null and gs.has_method("set_growth_speed_multiplier"):
		gs.set_growth_speed_multiplier(8.0 if pressed else 1.0)

func _on_close() -> void:
	visible = false

func _style_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG
	panel_style.border_color = PANEL_BORDER
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_bottom = 24.0
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	panel_style.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", panel_style)

	_title_lbl.add_theme_font_size_override("font_size", 22)
	_title_lbl.add_theme_color_override("font_color", TEXT_TITLE)

	_vbox.add_theme_constant_override("separation", 12)

	for child: Node in _vbox.get_children():
		if child is HBoxContainer:
			for row_child: Node in child.get_children():
				if row_child is Label:
					(row_child as Label).add_theme_color_override("font_color", TEXT_LIGHT)
					(row_child as Label).add_theme_font_size_override("font_size", 15)

	_style_close_button(_close_btn)

func _style_close_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 16)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = BTN_BG
	normal_style.border_color = BTN_BORDER
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.content_margin_left = 16.0
	normal_style.content_margin_right = 16.0
	btn.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = BTN_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", BTN_TEXT)
	btn.add_theme_color_override("font_pressed_color", BTN_TEXT)
