class_name TitleScreen
extends Node2D

const GARDEN_SCENE = preload("res://scenes/Garden.tscn")
const AlphaWebPlaytestProbeScript = preload("res://src/testing/alpha_web_playtest_probe.gd")

const BG_TOP := Color(0.07, 0.11, 0.12, 1.0)
const BG_BOTTOM := Color(0.14, 0.11, 0.07, 1.0)
const MIST_COLOR := Color(0.60, 0.76, 0.70, 0.12)
const HEX_FILL := Color(0.52, 0.70, 0.50, 0.07)
const HEX_LINE := Color(0.86, 0.72, 0.40, 0.18)
const CARD_BG := Color(0.09, 0.13, 0.12, 0.82)
const CARD_BORDER := Color(0.74, 0.58, 0.30, 0.90)
const TEXT_TITLE := Color(0.96, 0.90, 0.72, 1.0)
const TEXT_SUBTITLE := Color(0.78, 0.86, 0.78, 0.86)
const TEXT_WARNING := Color(0.96, 0.68, 0.48, 1.0)
const BTN_BG := Color(0.16, 0.26, 0.22, 0.92)
const BTN_BORDER := Color(0.65, 0.52, 0.29, 0.92)
const BTN_HOVER_BG := Color(0.92, 0.82, 0.55, 1.0)
const BTN_TEXT := Color(0.91, 0.88, 0.76, 0.98)
const BTN_HOVER_TEXT := Color(0.08, 0.13, 0.11, 1.0)

const HEX_RADIUS: float = 52.0
const HEX_COUNT: int = 34

var _anim_time: float = 0.0
var _bg_hexes: Array[Vector2] = []
var _bg_phases: Array[float] = []

@onready var _settings_overlay: SettingsMenu = $SettingsOverlay
@onready var _center: MarginContainer = $UILayer/Root/Center
@onready var _content: VBoxContainer = $UILayer/Root/Center/Content
@onready var _card: PanelContainer = $UILayer/Root/Center/Content/Card
@onready var _vbox: VBoxContainer = $UILayer/Root/Center/Content/Card/VBox
@onready var _title_lbl: Label = $UILayer/Root/Center/Content/Card/VBox/TitleLabel
@onready var _subtitle_lbl: Label = $UILayer/Root/Center/Content/Card/VBox/SubtitleLabel
@onready var _status_lbl: Label = $UILayer/Root/Center/Content/Card/VBox/StatusLabel
@onready var _play_btn: Button = $UILayer/Root/Center/Content/Card/VBox/PlayButton
@onready var _settings_btn: Button = $UILayer/Root/Center/Content/Card/VBox/SettingsButton
@onready var _quit_btn: Button = $UILayer/Root/Center/Content/Card/VBox/QuitButton

func _ready() -> void:
	_init_bg_data()
	_style_ui()
	_play_btn.pressed.connect(_on_play)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_maybe_start_alpha_web_playtest_probe()

func _init_bg_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var vp: Vector2 = get_viewport_rect().size
	for _i in HEX_COUNT:
		_bg_hexes.append(Vector2(rng.randf_range(-40.0, vp.x + 40.0), rng.randf_range(-40.0, vp.y + 40.0)))
		_bg_phases.append(rng.randf_range(0.0, TAU))

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), BG_BOTTOM)
	for y: int in 18:
		var t: float = float(y) / 17.0
		var band := Rect2(0.0, vp.y * t, vp.x, vp.y / 17.0 + 1.0)
		draw_rect(band, BG_TOP.lerp(BG_BOTTOM, t))
	_draw_glow(vp)
	for i: int in _bg_hexes.size():
		var pulse: float = (sin(_anim_time * 0.25 + _bg_phases[i]) + 1.0) * 0.5
		var r: float = HEX_RADIUS * (0.75 + pulse * 0.35)
		_draw_hex(_bg_hexes[i], r, Color(HEX_FILL.r, HEX_FILL.g, HEX_FILL.b, HEX_FILL.a * (0.4 + pulse * 0.6)), false)
		_draw_hex(_bg_hexes[i], r, Color(HEX_LINE.r, HEX_LINE.g, HEX_LINE.b, HEX_LINE.a * pulse), true)
	_draw_mist(vp)

func _draw_glow(vp: Vector2) -> void:
	var center := Vector2(vp.x * 0.5, vp.y * 0.36)
	for i: int in 8:
		var alpha: float = 0.045 - float(i) * 0.004
		draw_circle(center, 90.0 + float(i) * 74.0, Color(0.76, 0.66, 0.35, alpha))

func _draw_mist(vp: Vector2) -> void:
	for i: int in 5:
		var y: float = vp.y * (0.24 + float(i) * 0.13)
		var offset: float = sin(_anim_time * 0.13 + float(i)) * 34.0
		var from := Vector2(-120.0 + offset, y)
		var to := Vector2(vp.x + 120.0 + offset, y + sin(float(i)) * 24.0)
		draw_line(from, to, MIST_COLOR, 18.0 + float(i) * 3.0, true)

func _draw_hex(center: Vector2, radius: float, color: Color, outline: bool) -> void:
	var pts := PackedVector2Array()
	for i: int in 6:
		var angle: float = deg_to_rad(-90.0 + 60.0 * float(i))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	if outline:
		for i: int in 6:
			draw_line(pts[i], pts[(i + 1) % 6], color, 1.5, true)
	else:
		draw_colored_polygon(pts, color)

func _on_play() -> void:
	var save_service: Node = get_node_or_null("/root/SaveGameService")
	if save_service != null and save_service.has_method("start_session"):
		if not bool(save_service.start_session()):
			_show_save_status(save_service)
			return
	get_tree().change_scene_to_packed(GARDEN_SCENE)

func _on_settings() -> void:
	_settings_overlay.show_menu()

func _on_quit() -> void:
	get_tree().quit()

func _style_ui() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = CARD_BG
	card_style.border_color = CARD_BORDER
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left = 32.0
	card_style.content_margin_top = 26.0
	card_style.content_margin_right = 32.0
	card_style.content_margin_bottom = 28.0
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
	card_style.shadow_size = 18
	_card.add_theme_stylebox_override("panel", card_style)

	_title_lbl.visible = true
	_title_lbl.add_theme_font_size_override("font_size", 46)
	_title_lbl.add_theme_color_override("font_color", TEXT_TITLE)

	_subtitle_lbl.add_theme_font_size_override("font_size", 15)
	_subtitle_lbl.add_theme_color_override("font_color", TEXT_SUBTITLE)
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", TEXT_WARNING)

	_vbox.add_theme_constant_override("separation", 11)

	for child: Node in _vbox.get_children():
		if child is Button:
			_style_button(child as Button)

func _style_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override("font_size", 17)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = BTN_BG
	normal_style.border_color = BTN_BORDER
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 7
	normal_style.corner_radius_top_right = 7
	normal_style.corner_radius_bottom_left = 7
	normal_style.corner_radius_bottom_right = 7
	normal_style.content_margin_left = 16.0
	normal_style.content_margin_right = 16.0
	btn.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = BTN_HOVER_BG
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", BTN_HOVER_TEXT)
	btn.add_theme_color_override("font_pressed_color", BTN_HOVER_TEXT)
	btn.add_theme_color_override("font_focus_color", BTN_TEXT)

func _layout_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var margin_x: int = int(clampf(vp.x * 0.055, 18.0, 56.0))
	var margin_y: int = int(clampf(vp.y * 0.045, 16.0, 44.0))
	_center.add_theme_constant_override("margin_left", margin_x)
	_center.add_theme_constant_override("margin_right", margin_x)
	_center.add_theme_constant_override("margin_top", margin_y)
	_center.add_theme_constant_override("margin_bottom", margin_y)

	_card.custom_minimum_size = Vector2(clampf(vp.x * 0.35, 330.0, 470.0), 0.0)
	_content.add_theme_constant_override("separation", int(clampf(vp.y * 0.018, 10.0, 18.0)))

func _show_save_status(save_service: Node) -> void:
	var message: String = "The garden save could not be loaded safely."
	if save_service != null and save_service.has_method("get_last_failure_message"):
		var message_variant: Variant = save_service.get_last_failure_message()
		var service_message: String = str(message_variant)
		if not service_message.is_empty():
			message = service_message
	_status_lbl.text = message
	_status_lbl.visible = true

func _maybe_start_alpha_web_playtest_probe() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	var requested_variant: Variant = bridge.call("eval", "Boolean(window.__SATORI_ALPHA_WEB_PLAYTEST__)", true)
	if not bool(requested_variant):
		return
	var probe: Node = AlphaWebPlaytestProbeScript.new()
	add_child(probe)
	probe.call_deferred("run")
