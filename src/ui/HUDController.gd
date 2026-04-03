class_name HUDController
extends CanvasLayer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const _KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const MIX_PANEL_GAP: float = 16.0
const MIX_PANEL_MIN_WIDTH: float = 460.0
const MIX_PANEL_SCREEN_MARGIN: float = 16.0
const CODEX_PANEL_MARGIN_X: float = 28.0
const CODEX_PANEL_TOP_MARGIN: float = 72.0
const CODEX_PANEL_BOTTOM_GAP: float = 18.0
const MODE_TAB_GLYPHS: Array[String] = ["⬢", "✦", "⌘", "✋", "☷"]
const MODE_TAB_TITLES: Array[String] = ["Plant", "Craft", "Build", "Interact", "Codex"]
const MODE_TAB_TINTS: Array[Color] = [
	Color(0.63, 0.74, 0.45),
	Color(0.83, 0.62, 0.33),
	Color(0.72, 0.62, 0.84),
	Color(0.71, 0.80, 0.90),
	Color(0.58, 0.50, 0.32),
]
const MODE_TAB_ACTIVE_BG := Color(0.95, 0.89, 0.73, 1.0)
const MODE_TAB_INACTIVE_BG := Color(0.58, 0.48, 0.34, 0.94)
const MODE_TAB_ACTIVE_BORDER := Color(0.61, 0.44, 0.22, 1.0)
const MODE_TAB_INACTIVE_BORDER := Color(0.34, 0.24, 0.14, 0.90)
const MODE_TAB_TEXT := Color(0.19, 0.13, 0.08, 1.0)
const MODE_TAB_TEXT_MUTED := Color(0.89, 0.84, 0.74, 0.96)
const MODE_TRAY_BG := Color(0.26, 0.18, 0.11, 0.92)
const MODE_TRAY_BORDER := Color(0.60, 0.42, 0.21, 0.95)
const MODE_TAB_ANIMATION_TIME := 0.18
const MODE_TAB_INDICATOR_INSET_X := 10.0
const MODE_TAB_INDICATOR_INSET_Y := 8.0
const _ELEMENT_METER_LABELS: Dictionary = {
	GodaiElementScript.Value.CHI: "Chi",
	GodaiElementScript.Value.SUI: "Sui",
	GodaiElementScript.Value.KA: "Ka",
	GodaiElementScript.Value.FU: "Fu",
	GodaiElementScript.Value.KU: "Ku",
}

enum Mode {
	PLANT,
	MIX,
	BUILD,
	INTERACT,
	CODEX,
}

@onready var _plant_button: Button = $Root/BottomBar/PlantButton
@onready var _mix_button: Button = $Root/BottomBar/MixButton
@onready var _build_button: Button = $Root/BottomBar/BuildButton
@onready var _interact_button: Button = $Root/BottomBar/InteractButton
@onready var _codex_button: Button = $Root/BottomBar/CodexButton
@onready var _root: Control = $Root
@onready var _bottom_bar: HBoxContainer = $Root/BottomBar
@onready var _bottom_tray: Panel = $Root/BottomTray
@onready var _active_tab_indicator: ColorRect = $Root/BottomTray/ActiveTabIndicator
@onready var _mix_panel: SeedAlchemyPanel = $Root/Panels/SeedAlchemyPanel
@onready var _codex_panel: CodexPanel = $Root/Panels/CodexPanel
@onready var _instant_badge: Label = $Root/TopBar/InstantModeBadge
@onready var _pouch_display: SeedPouchDisplay = $Root/TopBar/SeedPouchDisplay
@onready var _element_meter_row: HBoxContainer = $Root/TopBar/ElementMeterRow
@onready var _chi_meter_label: Label = $Root/TopBar/ElementMeterRow/ChiMeterLabel
@onready var _sui_meter_label: Label = $Root/TopBar/ElementMeterRow/SuiMeterLabel
@onready var _ka_meter_label: Label = $Root/TopBar/ElementMeterRow/KaMeterLabel
@onready var _fu_meter_label: Label = $Root/TopBar/ElementMeterRow/FuMeterLabel
@onready var _ku_meter_label: Label = $Root/TopBar/ElementMeterRow/KuMeterLabel
@onready var _settings_button: Button = $Root/TopBar/SettingsButton
@onready var _settings_menu: SettingsMenu = $SettingsMenu
@onready var _satori_label: Label = $Root/TopBar/SatoriLabel
@onready var _era_label: Label = $Root/TopBar/EraLabel

var _mode: int = Mode.PLANT
var _tile_selector_hex: Node2D = null
var _mode_tabs_initialized: bool = false
var _world_popover_panel: PanelContainer = null
var _world_popover_label: Label = null

func _ready() -> void:
	_mix_panel.anchor_left = 0.0
	_mix_panel.anchor_top = 0.0
	_mix_panel.anchor_right = 0.0
	_mix_panel.anchor_bottom = 0.0
	_codex_panel.anchor_left = 0.0
	_codex_panel.anchor_top = 0.0
	_codex_panel.anchor_right = 0.0
	_codex_panel.anchor_bottom = 0.0
	_style_mode_tabs()
	_root.resized.connect(_layout_mix_panel)
	_root.resized.connect(_layout_codex_panel)
	_root.resized.connect(_layout_mode_tab_indicator)
	call_deferred("_layout_mix_panel")
	call_deferred("_layout_codex_panel")
	call_deferred("_layout_mode_tab_indicator")
	_plant_button.pressed.connect(func() -> void: _set_mode(Mode.PLANT))
	_mix_button.pressed.connect(func() -> void: _set_mode(Mode.MIX))
	_build_button.pressed.connect(func() -> void: _set_mode(Mode.BUILD))
	_interact_button.pressed.connect(func() -> void: _set_mode(Mode.INTERACT))
	_codex_button.pressed.connect(func() -> void: _set_mode(Mode.CODEX))
	_settings_button.pressed.connect(_on_settings_pressed)
	_tile_selector_hex = get_node_or_null("../TileSelector/TileSelectorHex")
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_speed_multiplier_changed"):
		settings.growth_speed_multiplier_changed.connect(_on_growth_speed_multiplier_changed)
		_on_growth_speed_multiplier_changed(float(settings.get("growth_speed_multiplier")))
	else:
		push_warning("HUDController could not connect to GardenSettings.growth_speed_multiplier_changed")
		_on_growth_speed_multiplier_changed(1.0)
	_set_mode(Mode.PLANT)
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if satori_service != null:
		if satori_service.has_signal("satori_changed"):
			satori_service.satori_changed.connect(_on_satori_changed)
		if satori_service.has_signal("era_changed"):
			satori_service.era_changed.connect(_on_era_changed)
		if satori_service.has_method("get_current_satori") and satori_service.has_method("get_current_cap"):
			_on_satori_changed(int(satori_service.get_current_satori()), int(satori_service.get_current_cap()))
		if satori_service.has_method("get_current_era"):
			_on_era_changed(satori_service.get_current_era())
	var alchemy_service: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy_service != null:
		if alchemy_service.has_signal("element_charge_changed"):
			alchemy_service.element_charge_changed.connect(_on_element_charge_changed)
		if alchemy_service.has_signal("element_unlocked"):
			alchemy_service.element_unlocked.connect(func(_element_id: int) -> void: _refresh_element_meters())
		if alchemy_service.has_signal("shrine_charge_collected"):
			alchemy_service.shrine_charge_collected.connect(func(_coord: Vector2i, _element_id: int, _amount: int) -> void: _refresh_element_meters())
	_refresh_element_meters()
	_init_world_popover()

func _layout_mix_panel() -> void:
	var min_size: Vector2 = _mix_panel.get_combined_minimum_size()
	var panel_width: float = max(min_size.x, MIX_PANEL_MIN_WIDTH)
	var panel_height: float = min_size.y
	var panel_x: float = (_root.size.x - panel_width) * 0.5
	var panel_y: float = _bottom_bar.position.y - panel_height - MIX_PANEL_GAP
	panel_x = clamp(panel_x, MIX_PANEL_SCREEN_MARGIN, _root.size.x - panel_width - MIX_PANEL_SCREEN_MARGIN)
	panel_y = clamp(panel_y, MIX_PANEL_SCREEN_MARGIN, _root.size.y - panel_height - MIX_PANEL_SCREEN_MARGIN)
	_mix_panel.position = Vector2(panel_x, panel_y)
	_mix_panel.size = Vector2(panel_width, panel_height)

func _layout_codex_panel() -> void:
	var panel_x: float = CODEX_PANEL_MARGIN_X
	var panel_y: float = CODEX_PANEL_TOP_MARGIN
	var panel_width: float = max(320.0, _root.size.x - (CODEX_PANEL_MARGIN_X * 2.0))
	var available_height: float = _bottom_bar.position.y - panel_y - CODEX_PANEL_BOTTOM_GAP
	var panel_height: float = max(260.0, available_height)
	_codex_panel.position = Vector2(panel_x, panel_y)
	_codex_panel.size = Vector2(panel_width, panel_height)

func _on_growth_speed_multiplier_changed(multiplier: float) -> void:
	var rounded: int = int(round(multiplier))
	if rounded <= 1:
		_instant_badge.visible = false
		return
	_instant_badge.visible = true
	_instant_badge.text = "x%d" % rounded

func _on_satori_changed(current: int, cap: int) -> void:
	_satori_label.text = "Satori: %d/%d" % [current, cap]

func _on_era_changed(new_era: StringName) -> void:
	_era_label.text = "Era: %s" % str(new_era).capitalize()

func _on_element_charge_changed(_element_id: int, _charge: int) -> void:
	_refresh_element_meters()

func _refresh_element_meters() -> void:
	var alchemy_service: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy_service == null:
		return
	var label_map: Dictionary = {
		GodaiElementScript.Value.CHI: _chi_meter_label,
		GodaiElementScript.Value.SUI: _sui_meter_label,
		GodaiElementScript.Value.KA: _ka_meter_label,
		GodaiElementScript.Value.FU: _fu_meter_label,
		GodaiElementScript.Value.KU: _ku_meter_label,
	}
	for element: int in label_map:
		var meter_label: Label = label_map[element] as Label
		if meter_label == null:
			continue
		var unlocked: bool = alchemy_service.has_method("is_element_unlocked") and alchemy_service.is_element_unlocked(element)
		var charge: int = 0
		if unlocked and alchemy_service.has_method("get_element_charge"):
			charge = int(alchemy_service.get_element_charge(element))
		meter_label.text = _format_element_meter_text(element, charge, unlocked)
	_element_meter_row.visible = true

func _format_element_meter_text(element: int, charge: int, unlocked: bool) -> String:
	var label: String = str(_ELEMENT_METER_LABELS.get(element, "?"))
	if not unlocked:
		return "%s: --" % label
	return "%s: %d/%d" % [label, charge, _KushoPoolScript.CAPACITY_PER_ELEMENT]

func _set_mode(next_mode: int) -> void:
	# Cancel any active crafting build mode when switching HUD tabs.
	var cs: Node = get_node_or_null("/root/CraftingService")
	if cs != null:
		var active_bm: Variant = cs.get("active_build_mode")
		if active_bm != null:
			active_bm.cancel()
	_mode = next_mode
	if _tile_selector_hex != null:
		var selector_active: bool = _mode == Mode.PLANT or _mode == Mode.BUILD
		_tile_selector_hex.visible = selector_active
		_tile_selector_hex.set_process_input(selector_active)
	_mix_panel.visible = _mode == Mode.MIX
	_codex_panel.visible = _mode == Mode.CODEX
	_pouch_display.visible = _mode != Mode.CODEX
	_apply_mode_tab_state(_plant_button, _mode == Mode.PLANT, 0)
	_apply_mode_tab_state(_mix_button, _mode == Mode.MIX, 1)
	_apply_mode_tab_state(_build_button, _mode == Mode.BUILD, 2)
	_apply_mode_tab_state(_interact_button, _mode == Mode.INTERACT, 3)
	_apply_mode_tab_state(_codex_button, _mode == Mode.CODEX, 4)
	call_deferred("_refresh_mode_tab_motion", _mode_tabs_initialized)
	_mode_tabs_initialized = true

func is_plant_mode() -> bool:
	return _mode == Mode.PLANT

func is_build_mode() -> bool:
	return _mode == Mode.BUILD

func is_interact_mode() -> bool:
	return _mode == Mode.INTERACT

func show_world_popover(screen_anchor: Vector2, lines: Array[String]) -> void:
	if _world_popover_panel == null or _world_popover_label == null:
		return
	if lines.is_empty():
		hide_world_popover()
		return
	var joined: String = "\n".join(lines)
	_world_popover_label.text = joined
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	var max_width: float = 0.0
	for line: String in lines:
		var line_width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		max_width = maxf(max_width, line_width)
	var line_height: float = 17.0
	var padding: Vector2 = Vector2(10.0, 8.0)
	var box_size: Vector2 = Vector2(max_width + padding.x * 2.0, line_height * float(lines.size()) + padding.y * 2.0)
	var target_pos: Vector2 = screen_anchor + Vector2(18.0, -box_size.y - 16.0)
	if _root != null:
		target_pos.x = clampf(target_pos.x, 8.0, _root.size.x - box_size.x - 8.0)
		target_pos.y = clampf(target_pos.y, 8.0, _root.size.y - box_size.y - 8.0)
	_world_popover_panel.position = target_pos
	_world_popover_panel.custom_minimum_size = box_size
	_world_popover_panel.size = box_size
	_world_popover_label.position = padding
	_world_popover_label.size = Vector2(box_size.x - padding.x * 2.0, box_size.y - padding.y * 2.0)
	_world_popover_panel.visible = true

func hide_world_popover() -> void:
	if _world_popover_panel == null:
		return
	_world_popover_panel.visible = false

func _init_world_popover() -> void:
	if _root == null:
		return
	if _world_popover_panel != null:
		return
	_world_popover_panel = PanelContainer.new()
	_world_popover_panel.name = "WorldHoverPopover"
	_world_popover_panel.visible = false
	_world_popover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_popover_panel.z_index = 200
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.16, 0.90)
	panel_style.border_color = Color(0.55, 0.77, 1.0, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	_world_popover_panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_world_popover_panel)

	_world_popover_label = Label.new()
	_world_popover_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_world_popover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_world_popover_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_world_popover_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 0.98))
	_world_popover_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.70))
	_world_popover_label.add_theme_constant_override("shadow_offset_x", 1)
	_world_popover_label.add_theme_constant_override("shadow_offset_y", 1)
	_world_popover_panel.add_child(_world_popover_label)

func _on_settings_pressed() -> void:
	if _settings_menu != null:
		_settings_menu.show_menu()

func _style_mode_tabs() -> void:
	var tray_style: StyleBoxFlat = StyleBoxFlat.new()
	tray_style.bg_color = MODE_TRAY_BG
	tray_style.border_color = MODE_TRAY_BORDER
	tray_style.border_width_left = 2
	tray_style.border_width_top = 2
	tray_style.border_width_right = 2
	tray_style.border_width_bottom = 2
	tray_style.corner_radius_top_left = 18
	tray_style.corner_radius_top_right = 18
	tray_style.corner_radius_bottom_left = 18
	tray_style.corner_radius_bottom_right = 18
	tray_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	tray_style.shadow_size = 6
	_bottom_tray.add_theme_stylebox_override("panel", tray_style)
	var indicator_style: StyleBoxFlat = StyleBoxFlat.new()
	indicator_style.bg_color = Color(0.97, 0.92, 0.78, 0.22)
	indicator_style.border_color = MODE_TAB_ACTIVE_BORDER
	indicator_style.border_width_left = 2
	indicator_style.border_width_top = 2
	indicator_style.border_width_right = 2
	indicator_style.border_width_bottom = 2
	indicator_style.corner_radius_top_left = 14
	indicator_style.corner_radius_top_right = 14
	indicator_style.corner_radius_bottom_left = 12
	indicator_style.corner_radius_bottom_right = 12
	_active_tab_indicator.add_theme_stylebox_override("panel", indicator_style)
	_bottom_bar.add_theme_constant_override("separation", 12)
	for button_index: int in 5:
		var button: Button = [_plant_button, _mix_button, _build_button, _interact_button, _codex_button][button_index]
		button.custom_minimum_size = Vector2(0, 72)
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 18)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.scale = Vector2.ONE
		_apply_mode_tab_state(button, false, button_index)

func _apply_mode_tab_state(button: Button, is_active: bool, index: int) -> void:
	button.text = "%s\n%s" % [MODE_TAB_GLYPHS[index], MODE_TAB_TITLES[index]]
	button.modulate = Color.WHITE
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = MODE_TAB_ACTIVE_BG if is_active else MODE_TAB_INACTIVE_BG
	normal_style.border_color = MODE_TAB_ACTIVE_BORDER if is_active else MODE_TAB_INACTIVE_BORDER
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 0 if is_active else 2
	normal_style.corner_radius_top_left = 16
	normal_style.corner_radius_top_right = 16
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.content_margin_left = 12
	normal_style.content_margin_top = 8
	normal_style.content_margin_right = 12
	normal_style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = MODE_TAB_ACTIVE_BG.lightened(0.04) if is_active else MODE_TAB_INACTIVE_BG.lightened(0.08)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_color_override("font_color", MODE_TAB_TEXT if is_active else MODE_TAB_TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", MODE_TAB_TEXT if is_active else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", MODE_TAB_TEXT)
	button.add_theme_color_override("font_focus_color", MODE_TAB_TEXT if is_active else Color.WHITE)
	button.add_theme_color_override("icon_normal_color", MODE_TAB_TINTS[index])
	button.add_theme_color_override("icon_hover_color", MODE_TAB_TINTS[index].lightened(0.1))
	button.add_theme_color_override("icon_pressed_color", MODE_TAB_TINTS[index])

func _refresh_mode_tab_motion(animated: bool) -> void:
	_layout_mode_tab_indicator(animated)
	for button_index: int in 5:
		var button: Button = [_plant_button, _mix_button, _build_button, _interact_button, _codex_button][button_index]
		var is_active: bool = button_index == _mode
		button.z_index = 2 if is_active else 1
		button.scale = Vector2.ONE

func _layout_mode_tab_indicator(animated: bool = false) -> void:
	var active_button: Button = [_plant_button, _mix_button, _build_button, _interact_button, _codex_button][_mode]
	var local_origin: Vector2 = active_button.global_position - _bottom_tray.global_position
	var indicator_position: Vector2 = Vector2(
		local_origin.x + MODE_TAB_INDICATOR_INSET_X,
		local_origin.y + MODE_TAB_INDICATOR_INSET_Y
	)
	var indicator_size: Vector2 = Vector2(
		active_button.size.x - (MODE_TAB_INDICATOR_INSET_X * 2.0),
		active_button.size.y - (MODE_TAB_INDICATOR_INSET_Y * 2.0)
	)
	if animated:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(_active_tab_indicator, "position", indicator_position, MODE_TAB_ANIMATION_TIME)
		tween.parallel().tween_property(_active_tab_indicator, "size", indicator_size, MODE_TAB_ANIMATION_TIME)
	else:
		_active_tab_indicator.position = indicator_position
		_active_tab_indicator.size = indicator_size
