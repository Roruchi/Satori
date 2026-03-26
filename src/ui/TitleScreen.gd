class_name TitleScreen
extends Node2D

const GARDEN_SCENE = preload("res://scenes/Garden.tscn")

const BG_COLOR := Color(0.10, 0.07, 0.04, 1.0)
const HEX_FILL := Color(0.63, 0.74, 0.45, 0.06)
const HEX_LINE := Color(0.63, 0.74, 0.45, 0.14)
const CARD_BG := Color(0.16, 0.11, 0.07, 0.96)
const CARD_BORDER := Color(0.60, 0.42, 0.21, 0.95)
const TEXT_TITLE := Color(0.95, 0.89, 0.73, 1.0)
const TEXT_SUBTITLE := Color(0.70, 0.62, 0.50, 0.80)
const BTN_BG := Color(0.58, 0.48, 0.34, 0.94)
const BTN_BORDER := Color(0.61, 0.44, 0.22, 1.0)
const BTN_HOVER_BG := Color(0.95, 0.89, 0.73, 1.0)
const BTN_TEXT := Color(0.89, 0.84, 0.74, 0.96)
const BTN_HOVER_TEXT := Color(0.19, 0.13, 0.08, 1.0)

const HEX_RADIUS: float = 44.0
const HEX_COUNT: int = 28

var _anim_time: float = 0.0
var _bg_hexes: Array[Vector2] = []
var _bg_phases: Array[float] = []

@onready var _settings_overlay: SettingsMenu = $SettingsOverlay
@onready var _card: PanelContainer = $UILayer/Root/Center/Card
@onready var _vbox: VBoxContainer = $UILayer/Root/Center/Card/VBox
@onready var _title_lbl: Label = $UILayer/Root/Center/Card/VBox/TitleLabel
@onready var _subtitle_lbl: Label = $UILayer/Root/Center/Card/VBox/SubtitleLabel
@onready var _play_btn: Button = $UILayer/Root/Center/Card/VBox/PlayButton
@onready var _settings_btn: Button = $UILayer/Root/Center/Card/VBox/SettingsButton
@onready var _quit_btn: Button = $UILayer/Root/Center/Card/VBox/QuitButton

func _ready() -> void:
	_init_bg_data()
	_style_ui()
	_play_btn.pressed.connect(_on_play)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)

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
	draw_rect(Rect2(Vector2.ZERO, vp), BG_COLOR)
	for i: int in _bg_hexes.size():
		var pulse: float = (sin(_anim_time * 0.25 + _bg_phases[i]) + 1.0) * 0.5
		var r: float = HEX_RADIUS * (0.75 + pulse * 0.35)
		_draw_hex(_bg_hexes[i], r, Color(HEX_FILL.r, HEX_FILL.g, HEX_FILL.b, HEX_FILL.a * (0.4 + pulse * 0.6)), false)
		_draw_hex(_bg_hexes[i], r, Color(HEX_LINE.r, HEX_LINE.g, HEX_LINE.b, HEX_LINE.a * pulse), true)

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
	card_style.corner_radius_top_left = 18
	card_style.corner_radius_top_right = 18
	card_style.corner_radius_bottom_left = 18
	card_style.corner_radius_bottom_right = 18
	card_style.content_margin_left = 36.0
	card_style.content_margin_top = 32.0
	card_style.content_margin_right = 36.0
	card_style.content_margin_bottom = 32.0
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	card_style.shadow_size = 14
	_card.add_theme_stylebox_override("panel", card_style)

	_title_lbl.add_theme_font_size_override("font_size", 48)
	_title_lbl.add_theme_color_override("font_color", TEXT_TITLE)

	_subtitle_lbl.add_theme_font_size_override("font_size", 14)
	_subtitle_lbl.add_theme_color_override("font_color", TEXT_SUBTITLE)

	_vbox.add_theme_constant_override("separation", 10)

	for child: Node in _vbox.get_children():
		if child is Button:
			_style_button(child as Button)

func _style_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(0, 54)
	btn.add_theme_font_size_override("font_size", 17)
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
	hover_style.bg_color = BTN_HOVER_BG
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", BTN_HOVER_TEXT)
	btn.add_theme_color_override("font_pressed_color", BTN_HOVER_TEXT)
	btn.add_theme_color_override("font_focus_color", BTN_TEXT)
