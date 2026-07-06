class_name HUDController
extends CanvasLayer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")
const _RITUAL_ICON_TEXTURE: Texture2D = preload("res://assets/ritual/ritual_input_icon_spritesheet.png")
const MIX_PANEL_GAP: float = 16.0
const MIX_PANEL_MIN_WIDTH: float = 440.0
const MIX_PANEL_MAX_WIDTH: float = 480.0
const MIX_PANEL_PREFERRED_HEIGHT: float = 520.0
const MIX_PANEL_SCREEN_MARGIN: float = 12.0
const MIX_PANEL_TOP_GAP: float = 12.0
const CODEX_PANEL_MARGIN_X: float = 28.0
const CODEX_PANEL_TOP_MARGIN: float = 72.0
const CODEX_PANEL_BOTTOM_GAP: float = 18.0
const RITUAL_ICON_CELL_SIZE: float = 32.0
const MATERIAL_SLOT_ICON_SIZE: float = 16.0
const MATERIAL_SLOT_MIN_SIZE: Vector2 = Vector2(56.0, 24.0)
const PLACE_SLOT_ICON_SIZE: float = 22.0
const PLACE_SLOT_MIN_SIZE: Vector2 = Vector2(62.0, 28.0)
const _MATERIAL_ICON_INDEX: Dictionary = {
	&"living_wood": 5,
	&"reed_fiber": 6,
	&"spirit_stone": 7,
	&"ember_clay": 8,
}
const _MATERIAL_SHORT_LABELS: Dictionary = {
	&"living_wood": "LW",
	&"reed_fiber": "RF",
	&"spirit_stone": "SS",
	&"ember_clay": "EC",
}
const MODE_TAB_TITLES: Array[String] = ["Place", "Ritual", "Codex"]
const MODE_TAB_ICON_INDICES: Array[int] = [5, 4, 0]
const MODE_TAB_TINTS: Array[Color] = [
	Color(0.63, 0.74, 0.45),
	Color(0.83, 0.62, 0.33),
	Color(0.58, 0.50, 0.32),
]
const MODE_TAB_ACTIVE_BG := Color(0.90, 0.84, 0.66, 0.96)
const MODE_TAB_INACTIVE_BG := Color(0.30, 0.24, 0.18, 0.82)
const MODE_TAB_ACTIVE_BORDER := Color(0.59, 0.43, 0.23, 0.92)
const MODE_TAB_INACTIVE_BORDER := Color(0.28, 0.23, 0.20, 0.84)
const MODE_TAB_TEXT := Color(0.19, 0.13, 0.08, 1.0)
const MODE_TAB_TEXT_MUTED := Color(0.82, 0.78, 0.70, 0.92)
const MODE_TRAY_BG := Color(0.10, 0.08, 0.07, 0.72)
const MODE_TRAY_BORDER := Color(0.50, 0.37, 0.22, 0.72)
const MODE_TAB_ANIMATION_TIME := 0.18
const MODE_TAB_INDICATOR_INSET_X := 6.0
const MODE_TAB_INDICATOR_INSET_Y := 6.0
const MODE_TAB_HEIGHT: float = 48.0
const TOP_CHIP_BG := Color(0.05, 0.04, 0.07, 0.68)
const TOP_CHIP_BORDER := Color(0.42, 0.36, 0.52, 0.62)
const TOP_TEXT := Color(0.92, 0.90, 0.84, 0.96)
const TOP_TEXT_MUTED := Color(0.74, 0.77, 0.82, 0.88)
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
	CODEX,
}

@onready var _plant_button: Button = $Root/BottomBar/PlantButton
@onready var _mix_button: Button = $Root/BottomBar/MixButton
@onready var _codex_button: Button = $Root/BottomBar/CodexButton
@onready var _root: Control = $Root
@onready var _top_bar: HBoxContainer = $Root/TopBar
@onready var _bottom_bar: HBoxContainer = $Root/BottomBar
@onready var _bottom_tray: Panel = $Root/BottomTray
@onready var _active_tab_indicator: ColorRect = $Root/BottomTray/ActiveTabIndicator
@onready var _mix_panel: SeedAlchemyPanel = $Root/Panels/SeedAlchemyPanel
@onready var _codex_panel: CodexPanel = $Root/Panels/CodexPanel
@onready var _instant_badge: Label = $Root/TopBar/InstantModeBadge
@onready var _inventory_stack: VBoxContainer = $Root/TopBar/InventoryStack
@onready var _pouch_display: SeedPouchDisplay = $Root/TopBar/InventoryStack/SeedPouchDisplay
@onready var _material_meter_label: Label = $Root/TopBar/InventoryStack/MaterialMeterLabel
@onready var _element_meter_row: HBoxContainer = $Root/TopBar/ElementMeterRow
@onready var _chi_meter_label: Label = $Root/TopBar/ElementMeterRow/ChiMeterLabel
@onready var _sui_meter_label: Label = $Root/TopBar/ElementMeterRow/SuiMeterLabel
@onready var _ka_meter_label: Label = $Root/TopBar/ElementMeterRow/KaMeterLabel
@onready var _fu_meter_label: Label = $Root/TopBar/ElementMeterRow/FuMeterLabel
@onready var _ku_meter_label: Label = $Root/TopBar/ElementMeterRow/KuMeterLabel
@onready var _settings_button: Button = $Root/TopBar/SettingsButton
@onready var _settings_menu: SettingsMenu = $SettingsMenu
@onready var _satori_label: Label = $Root/TopBar/StatusStack/SatoriLabel
@onready var _era_label: Label = $Root/TopBar/StatusStack/EraLabel
@onready var _debug_info_label: Label = $Root/DebugInfoLabel

var _mode: int = Mode.PLANT
var _tile_selector_hex: Node2D = null
var _mode_tabs_initialized: bool = false
var _building_confirm_panel: PanelContainer = null
var _debug_update_elapsed: float = 0.0
var _node_count_update_elapsed: float = 999.0
var _last_node_count: int = 0
var _last_scan_ms: float = 0.0
var _max_scan_ms: float = 0.0
var _scan_count: int = 0
var _material_slot_row: HBoxContainer = null
var _material_slot_count_labels: Dictionary = {}
var _place_slot_row: HBoxContainer = null
var _structure_catalog: RefCounted = StructureCatalogDataScript.new()
var _place_icon_cache: Dictionary = {}

signal building_placement_started(type_key: StringName)
signal building_placement_confirm_requested()
signal building_placement_cancel_requested()
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
	_style_top_hud()
	_root.resized.connect(_layout_mix_panel)
	_root.resized.connect(_layout_codex_panel)
	_root.resized.connect(_layout_mode_tab_indicator)
	call_deferred("_layout_mix_panel")
	call_deferred("_layout_codex_panel")
	call_deferred("_layout_mode_tab_indicator")
	_plant_button.pressed.connect(func() -> void: _set_mode(Mode.PLANT))
	_mix_button.pressed.connect(func() -> void: _set_mode(Mode.MIX))
	_codex_button.pressed.connect(func() -> void: _set_mode(Mode.CODEX))
	_settings_button.pressed.connect(_on_settings_pressed)
	_tile_selector_hex = get_node_or_null("../TileSelector/TileSelectorHex")
	if _tile_selector_hex != null and _tile_selector_hex.has_signal("building_selected"):
		_tile_selector_hex.connect("building_selected", _on_building_item_selected)
	if _tile_selector_hex != null and _tile_selector_hex.has_signal("selection_cleared"):
		_tile_selector_hex.connect("selection_cleared", _on_place_selection_cleared)
	if _pouch_display != null and _pouch_display.has_signal("building_item_selected"):
		_pouch_display.building_item_selected.connect(_on_building_item_selected)
	_init_place_inventory_slots()
	_init_material_slots()
	_style_top_hud()
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_speed_multiplier_changed"):
		settings.growth_speed_multiplier_changed.connect(_on_growth_speed_multiplier_changed)
		_on_growth_speed_multiplier_changed(float(settings.get("growth_speed_multiplier")))
	else:
		push_warning("HUDController could not connect to GardenSettings.growth_speed_multiplier_changed")
		_on_growth_speed_multiplier_changed(1.0)
	if settings != null and settings.has_signal("debug_info_enabled_changed"):
		settings.debug_info_enabled_changed.connect(_on_debug_info_enabled_changed)
		var debug_enabled: Variant = settings.get("debug_info_enabled")
		_on_debug_info_enabled_changed(debug_enabled is bool and bool(debug_enabled))
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
		if alchemy_service.has_signal("ritual_attempt_resolved"):
			alchemy_service.ritual_attempt_resolved.connect(func(_outcome: StringName, _feedback_key: StringName, _guidance: String, _ritual_id: StringName, _result_kind: StringName, _result_id: StringName) -> void: _refresh_material_meter())
		if alchemy_service.has_signal("material_count_changed"):
			alchemy_service.material_count_changed.connect(func(_material_id: StringName, _count: int) -> void: _refresh_material_meter())
		if alchemy_service.has_signal("seed_added_to_pouch"):
			alchemy_service.seed_added_to_pouch.connect(func(_recipe: SeedRecipe) -> void: _refresh_place_inventory_slots())
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_signal("pouch_updated"):
		growth_service.pouch_updated.connect(_refresh_place_inventory_slots)
	_refresh_element_meters()
	_refresh_material_meter()
	_refresh_place_inventory_slots()
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("scan_metrics_updated"):
		scan_service.scan_metrics_updated.connect(_on_scan_metrics_updated)
	_init_world_popover()

func _process(delta: float) -> void:
	if _debug_info_label == null or not _debug_info_label.visible:
		return
	_debug_update_elapsed += delta
	if _debug_update_elapsed < 0.25:
		return
	_debug_update_elapsed = 0.0
	_refresh_debug_info(delta)

func _layout_mix_panel() -> void:
	var root_size: Vector2 = _root.size
	if root_size.x <= 0.0 or root_size.y <= 0.0:
		root_size = get_viewport().get_visible_rect().size
	if root_size.x <= 0.0 or root_size.y <= 0.0:
		call_deferred("_layout_mix_panel")
		return
	var bottom_y: float = _bottom_bar.position.y
	if bottom_y <= 0.0:
		bottom_y = root_size.y - 76.0
	var top_y: float = MIX_PANEL_SCREEN_MARGIN
	if _top_bar != null:
		top_y = maxf(MIX_PANEL_SCREEN_MARGIN, _top_bar.position.y + _top_bar.size.y + MIX_PANEL_TOP_GAP)
	var min_size: Vector2 = _mix_panel.get_combined_minimum_size()
	var available_width: float = maxf(300.0, root_size.x - (MIX_PANEL_SCREEN_MARGIN * 2.0))
	var available_height: float = maxf(260.0, bottom_y - MIX_PANEL_GAP - top_y)
	var desired_width: float = minf(MIX_PANEL_MAX_WIDTH, maxf(min_size.x, MIX_PANEL_MIN_WIDTH))
	var desired_height: float = maxf(maxf(min_size.y, _mix_panel.custom_minimum_size.y), minf(MIX_PANEL_PREFERRED_HEIGHT, available_height))
	var panel_width: float = minf(desired_width, available_width)
	var panel_height: float = minf(desired_height, available_height)
	var panel_x: float = (root_size.x - panel_width) * 0.5
	var panel_y: float = bottom_y - panel_height - MIX_PANEL_GAP
	var max_panel_x: float = root_size.x - panel_width - MIX_PANEL_SCREEN_MARGIN
	var max_panel_y: float = root_size.y - panel_height - MIX_PANEL_SCREEN_MARGIN
	if max_panel_x < MIX_PANEL_SCREEN_MARGIN:
		panel_x = maxf(0.0, panel_x)
	else:
		panel_x = clampf(panel_x, MIX_PANEL_SCREEN_MARGIN, max_panel_x)
	if max_panel_y < top_y:
		panel_y = maxf(0.0, panel_y)
	else:
		panel_y = clampf(panel_y, top_y, max_panel_y)
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

func _on_debug_info_enabled_changed(enabled: bool) -> void:
	if _debug_info_label == null:
		return
	_debug_info_label.visible = enabled
	_debug_update_elapsed = 0.0
	if enabled:
		_refresh_debug_info(0.0)

func _refresh_debug_info(delta: float) -> void:
	if _debug_info_label == null:
		return
	var frame_ms: float = 0.0 if is_zero_approx(delta) else delta * 1000.0
	_node_count_update_elapsed += 0.25
	if _last_node_count <= 0 or _node_count_update_elapsed >= 1.0:
		_last_node_count = _count_nodes(get_tree().root)
		_node_count_update_elapsed = 0.0
	var spirit_service: Node = _resolve_spirit_service()
	var spirit_count: int = 0
	var housing_count: int = 0
	var pending_builds: int = 0
	if spirit_service != null:
		if spirit_service.has_method("active_count"):
			spirit_count = int(spirit_service.active_count())
		if spirit_service.has_method("get_housing_recompute_count"):
			housing_count = int(spirit_service.get_housing_recompute_count())
		if spirit_service.has_method("get_pending_building_count"):
			pending_builds = int(spirit_service.get_pending_building_count())
	_debug_info_label.text = "FPS %d | %.1f ms | Nodes %d\nScan %.1f/%.1f ms #%d | Spirits %d | Housing %d | Builds %d" % [
		Engine.get_frames_per_second(),
		frame_ms,
		_last_node_count,
		_last_scan_ms,
		_max_scan_ms,
		_scan_count,
		spirit_count,
		housing_count,
		pending_builds,
	]

func _count_nodes(root_node: Node) -> int:
	if root_node == null:
		return 0
	var total: int = 1
	for child: Node in root_node.get_children():
		total += _count_nodes(child)
	return total

func _on_scan_metrics_updated(last_duration_ms: float, _average_duration_ms: float, max_duration_ms: float, scan_count: int) -> void:
	_last_scan_ms = last_duration_ms
	_max_scan_ms = max_duration_ms
	_scan_count = scan_count

func _resolve_spirit_service() -> Node:
	var direct: Node = get_node_or_null("/root/SpiritService")
	if direct != null:
		return direct
	var garden_path: Node = get_node_or_null("/root/Garden/SpiritService")
	if garden_path != null:
		return garden_path
	var voxel_path: Node = get_node_or_null("/root/VoxelGarden/SpiritService")
	if voxel_path != null:
		return voxel_path
	var local_path: Node = get_node_or_null("../SpiritService")
	if local_path != null:
		return local_path
	return null

func _on_satori_changed(current: int, cap: int) -> void:
	_satori_label.text = "%d/%d" % [current, cap]

func _on_era_changed(new_era: StringName) -> void:
	_era_label.text = str(new_era).capitalize()

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
		return "%s --" % label
	return "%s %d/3" % [label, charge]

func _refresh_material_meter() -> void:
	if _material_meter_label == null:
		return
	var alchemy_service: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy_service == null or not alchemy_service.has_method("get_material_count"):
		_material_meter_label.text = "Mat --"
		return
	var material_ids: Array[StringName] = [&"living_wood", &"reed_fiber", &"spirit_stone", &"ember_clay"]
	if alchemy_service.has_method("get_material_display_order"):
		var ordered_variant: Variant = alchemy_service.get_material_display_order()
		if ordered_variant is Array:
			material_ids.clear()
			for id_variant: Variant in ordered_variant:
				material_ids.append(StringName(str(id_variant)))
	_ensure_material_slots(material_ids)
	for material_id: StringName in material_ids:
		var count: int = int(alchemy_service.get_material_count(material_id))
		var label_variant: Variant = _material_slot_count_labels.get(material_id, null)
		if label_variant is Label:
			var slot_label: Label = label_variant as Label
			slot_label.text = str(count)
	_material_meter_label.text = "Mat"

func _init_material_slots() -> void:
	var row_variant: Variant = get_node_or_null("Root/TopBar/InventoryStack/MaterialSlotRow")
	if row_variant is HBoxContainer:
		_material_slot_row = row_variant as HBoxContainer
	else:
		_material_slot_row = HBoxContainer.new()
		_material_slot_row.name = "MaterialSlotRow"
		_material_slot_row.add_theme_constant_override("separation", 4)
		_inventory_stack.add_child(_material_slot_row)
	_material_slot_row.visible = true
	_ensure_material_slots([&"living_wood", &"reed_fiber", &"spirit_stone", &"ember_clay"])

func _init_place_inventory_slots() -> void:
	var row_variant: Variant = get_node_or_null("Root/TopBar/InventoryStack/PlaceSlotRow")
	if row_variant is HBoxContainer:
		_place_slot_row = row_variant as HBoxContainer
	else:
		_place_slot_row = HBoxContainer.new()
		_place_slot_row.name = "PlaceSlotRow"
		_place_slot_row.add_theme_constant_override("separation", 4)
		_inventory_stack.add_child(_place_slot_row)
	_place_slot_row.visible = true


func _refresh_place_inventory_slots() -> void:
	if _place_slot_row == null:
		return
	for child: Node in _place_slot_row.get_children():
		child.queue_free()
	var pouch: SeedPouch = _resolve_place_inventory_pouch()
	if pouch == null:
		_place_slot_row.visible = false
		return
	var added_any: bool = false
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) != &"building_item":
			continue
		var entry: BuildingInventoryEntry = pouch.get_building_at(i)
		if entry == null or entry.count <= 0:
			continue
		_place_slot_row.add_child(_create_place_slot(entry))
		added_any = true
	_place_slot_row.visible = added_any


func _resolve_place_inventory_pouch() -> SeedPouch:
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_method("get_pouch"):
		var growth_pouch_variant: Variant = growth_service.get_pouch()
		if growth_pouch_variant is SeedPouch:
			return growth_pouch_variant as SeedPouch
	var alchemy_service: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy_service != null and alchemy_service.has_method("get_pouch"):
		var alchemy_pouch_variant: Variant = alchemy_service.get_pouch()
		if alchemy_pouch_variant is SeedPouch:
			return alchemy_pouch_variant as SeedPouch
	return null


func _create_place_slot(entry: BuildingInventoryEntry) -> PanelContainer:
	var slot: PanelContainer = PanelContainer.new()
	slot.name = "PlaceSlot_%s" % str(entry.type_key)
	slot.custom_minimum_size = PLACE_SLOT_MIN_SIZE
	slot.tooltip_text = _place_slot_tooltip(entry)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.10, 0.74)
	style.border_color = Color(0.48, 0.52, 0.40, 0.86)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 2.0
	slot.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Contents"
	row.add_theme_constant_override("separation", 4)
	slot.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(PLACE_SLOT_ICON_SIZE, PLACE_SLOT_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _place_icon_texture(entry.type_key)
	row.add_child(icon)
	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = str(entry.count)
	count_label.custom_minimum_size = Vector2(18.0, 20.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.78, 0.98))
	count_label.add_theme_font_size_override("font_size", 13)
	row.add_child(count_label)
	return slot


func _place_icon_texture(type_key: StringName) -> Texture2D:
	var cache_key: String = str(type_key)
	var cached_variant: Variant = _place_icon_cache.get(cache_key)
	if cached_variant is Texture2D:
		return cached_variant as Texture2D
	var asset_path: String = _structure_catalog.get_asset_path(cache_key)
	if asset_path.is_empty():
		_place_icon_cache[cache_key] = null
		return null
	var texture: Texture2D = _load_texture_resource(asset_path)
	_place_icon_cache[cache_key] = texture
	return texture


func _load_texture_resource(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		var loaded_texture: Texture2D = ResourceLoader.load(path, "Texture2D") as Texture2D
		if loaded_texture != null:
			return loaded_texture
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null


func _place_slot_tooltip(entry: BuildingInventoryEntry) -> String:
	return "%s x%d" % [_building_display_name(entry.type_key), entry.count]


func _building_display_name(type_key: StringName) -> String:
	var form_name: String = ""
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_method("get_form_display_name"):
		form_name = str(alchemy.get_form_display_name(type_key))
	if not form_name.is_empty():
		return form_name
	var raw: String = str(type_key)
	if raw.begins_with("building_"):
		raw = raw.substr("building_".length())
	if raw.begins_with("form_"):
		raw = raw.substr("form_".length())
	return raw.capitalize()


func _ensure_material_slots(material_ids: Array[StringName]) -> void:
	if _material_slot_row == null:
		return
	for material_id: StringName in material_ids:
		if _material_slot_count_labels.has(material_id):
			continue
		var slot: PanelContainer = _create_material_slot(material_id)
		_material_slot_row.add_child(slot)

func _create_material_slot(material_id: StringName) -> PanelContainer:
	var slot: PanelContainer = PanelContainer.new()
	slot.name = "MaterialSlot_%s" % str(material_id)
	slot.custom_minimum_size = MATERIAL_SLOT_MIN_SIZE
	slot.tooltip_text = _material_display_name(material_id)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.72)
	style.border_color = Color(0.52, 0.42, 0.28, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 2.0
	slot.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Contents"
	row.add_theme_constant_override("separation", 4)
	slot.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(MATERIAL_SLOT_ICON_SIZE, MATERIAL_SLOT_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _material_icon_texture(material_id)
	row.add_child(icon)
	var fallback_label: Label = Label.new()
	fallback_label.name = "IconFallback"
	fallback_label.text = _material_short_label(material_id)
	fallback_label.visible = icon.texture == null
	fallback_label.custom_minimum_size = Vector2(16.0, 18.0)
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.59, 0.98))
	fallback_label.add_theme_font_size_override("font_size", 9)
	row.add_child(fallback_label)
	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = "0"
	count_label.custom_minimum_size = Vector2(18.0, 18.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.78, 0.98))
	count_label.add_theme_font_size_override("font_size", 13)
	row.add_child(count_label)
	_material_slot_count_labels[material_id] = count_label
	return slot

func _material_icon_texture(material_id: StringName) -> Texture2D:
	if _RITUAL_ICON_TEXTURE == null or not _MATERIAL_ICON_INDEX.has(material_id):
		return null
	var icon_index: int = int(_MATERIAL_ICON_INDEX.get(material_id, 0))
	return _ritual_icon_region_texture(icon_index)

func _material_short_label(material_id: StringName) -> String:
	return str(_MATERIAL_SHORT_LABELS.get(material_id, str(material_id).substr(0, 2).to_upper()))

func _material_display_name(material_id: StringName) -> String:
	match material_id:
		&"living_wood":
			return "Living Wood"
		&"reed_fiber":
			return "Reed Fiber"
		&"spirit_stone":
			return "Spirit Stone"
		&"ember_clay":
			return "Ember Clay"
		_:
			return str(material_id).replace("_", " ").capitalize()

func _set_mode(next_mode: int) -> void:
	_mode = next_mode
	if _tile_selector_hex != null:
		var selector_active: bool = _mode == Mode.PLANT
		_tile_selector_hex.visible = selector_active
		_tile_selector_hex.set_process_input(selector_active)
	_mix_panel.visible = _mode == Mode.MIX
	_codex_panel.visible = _mode == Mode.CODEX
	_pouch_display.visible = _mode != Mode.CODEX
	if _mode == Mode.MIX:
		_layout_mix_panel()
		call_deferred("_layout_mix_panel")
	_apply_mode_tab_state(_plant_button, _mode == Mode.PLANT, 0)
	_apply_mode_tab_state(_mix_button, _mode == Mode.MIX, 1)
	_apply_mode_tab_state(_codex_button, _mode == Mode.CODEX, 2)
	call_deferred("_refresh_mode_tab_motion", _mode_tabs_initialized)
	_mode_tabs_initialized = true

func is_plant_mode() -> bool:
	return _mode == Mode.PLANT

func _on_building_item_selected(type_key: StringName) -> void:
	_set_mode(Mode.PLANT)
	var placement_controller: Node = get_node_or_null("../PlacementController")
	if placement_controller != null and placement_controller.has_method("start_building_placement"):
		placement_controller.start_building_placement(type_key)

func is_build_mode() -> bool:
	# Build mode has been retired. Returns false for backward compatibility with
	# callers (PlacementController, GardenView) that still check this method.
	return false

func is_interact_mode() -> bool:
	return _mode == Mode.PLANT and not is_place_selection_active()

func is_place_selection_active() -> bool:
	if _tile_selector_hex != null and _tile_selector_hex.has_method("has_active_selection"):
		return bool(_tile_selector_hex.call("has_active_selection"))
	return int(GameState.selected_biome) != BiomeType.Value.NONE

func _on_place_selection_cleared() -> void:
	var placement_controller: Node = get_node_or_null("../PlacementController")
	if placement_controller != null and placement_controller.has_method("cancel_building_placement"):
		placement_controller.cancel_building_placement()

func show_world_popover(screen_anchor: Vector2, lines: Array[String]) -> void:
	if _world_popover_panel == null or _world_popover_label == null:
		return
	if lines.is_empty():
		hide_world_popover()
		return
	var joined: String = "\n".join(lines)
	_world_popover_label.text = joined
	_world_popover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	var max_width: float = 0.0
	for line: String in lines:
		var line_width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		max_width = maxf(max_width, line_width)
	var line_height: float = 17.0
	var padding: Vector2 = Vector2(10.0, 8.0)
	var available_width: float = 320.0
	if _root != null:
		available_width = minf(320.0, maxf(160.0, _root.size.x - 24.0))
	var content_width: float = clampf(max_width, 120.0, available_width - padding.x * 2.0)
	var visual_lines: int = 0
	for line: String in lines:
		var line_width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		visual_lines += maxi(1, int(ceil(line_width / maxf(1.0, content_width))))
	var box_size: Vector2 = Vector2(content_width + padding.x * 2.0, line_height * float(visual_lines) + padding.y * 2.0)
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
	_world_popover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

func _style_top_hud() -> void:
	_top_bar.add_theme_constant_override("separation", 8)
	_inventory_stack.add_theme_constant_override("separation", 2)
	_inventory_stack.custom_minimum_size = Vector2(244.0, 50.0)
	_element_meter_row.add_theme_constant_override("separation", 4)
	_style_chip_label(_pouch_display, TOP_TEXT, 12, Vector2(8.0, 3.0), HORIZONTAL_ALIGNMENT_LEFT)
	_style_plain_label(_material_meter_label, TOP_TEXT_MUTED, 11)
	var essence_title: Label = _element_meter_row.get_node("EssenceTitle") as Label
	if essence_title != null:
		essence_title.text = "Ess"
	_style_plain_label(essence_title, TOP_TEXT_MUTED, 11)
	for meter_label: Label in [_chi_meter_label, _sui_meter_label, _ka_meter_label, _fu_meter_label, _ku_meter_label]:
		_style_chip_label(meter_label, TOP_TEXT, 12, Vector2(7.0, 3.0), HORIZONTAL_ALIGNMENT_CENTER)
	_style_plain_label(_satori_label, TOP_TEXT, 13)
	_style_plain_label(_era_label, TOP_TEXT_MUTED, 12)
	_style_top_button(_settings_button, _ritual_icon_texture_by_index(8), "Settings")
	if _instant_badge != null:
		_style_chip_label(_instant_badge, Color(1.0, 0.91, 0.66, 0.98), 12, Vector2(8.0, 3.0), HORIZONTAL_ALIGNMENT_CENTER)

func _style_plain_label(label: Label, color: Color, font_size: int) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

func _style_chip_label(label: Label, color: Color, font_size: int, padding: Vector2, alignment: HorizontalAlignment) -> void:
	if label == null:
		return
	_style_plain_label(label, color, font_size)
	label.horizontal_alignment = alignment
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = TOP_CHIP_BG
	style.border_color = TOP_CHIP_BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	label.add_theme_stylebox_override("normal", style)

func _style_top_button(button: Button, icon_texture: Texture2D, tooltip: String) -> void:
	if button == null:
		return
	button.text = ""
	button.tooltip_text = tooltip
	button.icon = icon_texture
	button.expand_icon = false
	button.custom_minimum_size = Vector2(42.0, 36.0)
	button.add_theme_font_size_override("font_size", 12)
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = TOP_CHIP_BG
	normal_style.border_color = TOP_CHIP_BORDER
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = TOP_CHIP_BG.lightened(0.10)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_color_override("icon_normal_color", TOP_TEXT)
	button.add_theme_color_override("icon_hover_color", Color.WHITE)

func _style_mode_tabs() -> void:
	var tray_style: StyleBoxFlat = StyleBoxFlat.new()
	tray_style.bg_color = MODE_TRAY_BG
	tray_style.border_color = MODE_TRAY_BORDER
	tray_style.border_width_left = 2
	tray_style.border_width_top = 2
	tray_style.border_width_right = 2
	tray_style.border_width_bottom = 2
	tray_style.corner_radius_top_left = 12
	tray_style.corner_radius_top_right = 12
	tray_style.corner_radius_bottom_left = 12
	tray_style.corner_radius_bottom_right = 12
	tray_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	tray_style.shadow_size = 4
	_bottom_tray.add_theme_stylebox_override("panel", tray_style)
	var indicator_style: StyleBoxFlat = StyleBoxFlat.new()
	indicator_style.bg_color = Color(0.97, 0.92, 0.78, 0.22)
	indicator_style.border_color = MODE_TAB_ACTIVE_BORDER
	indicator_style.border_width_left = 2
	indicator_style.border_width_top = 2
	indicator_style.border_width_right = 2
	indicator_style.border_width_bottom = 2
	indicator_style.corner_radius_top_left = 8
	indicator_style.corner_radius_top_right = 8
	indicator_style.corner_radius_bottom_left = 8
	indicator_style.corner_radius_bottom_right = 8
	_active_tab_indicator.add_theme_stylebox_override("panel", indicator_style)
	_bottom_bar.add_theme_constant_override("separation", 8)
	for button_index: int in MODE_TAB_TITLES.size():
		var button: Button = [_plant_button, _mix_button, _codex_button][button_index]
		button.custom_minimum_size = Vector2(0, MODE_TAB_HEIGHT)
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 13)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = false
		button.scale = Vector2.ONE
		_apply_mode_tab_state(button, false, button_index)

func _apply_mode_tab_state(button: Button, is_active: bool, index: int) -> void:
	button.text = MODE_TAB_TITLES[index]
	button.icon = _ritual_icon_texture_by_index(MODE_TAB_ICON_INDICES[index])
	button.modulate = Color.WHITE
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = MODE_TAB_ACTIVE_BG if is_active else MODE_TAB_INACTIVE_BG
	normal_style.border_color = MODE_TAB_ACTIVE_BORDER if is_active else MODE_TAB_INACTIVE_BORDER
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 0 if is_active else 2
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.content_margin_left = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_right = 8
	normal_style.content_margin_bottom = 6
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

func _ritual_icon_texture_by_index(icon_index: int) -> Texture2D:
	if _RITUAL_ICON_TEXTURE == null:
		return null
	return _ritual_icon_region_texture(icon_index)

func _ritual_icon_region_texture(icon_index: int) -> Texture2D:
	if _RITUAL_ICON_TEXTURE == null:
		return null
	var image: Image = _RITUAL_ICON_TEXTURE.get_image()
	if image == null:
		return null
	var column: int = icon_index % 3
	var row: int = floori(float(icon_index) / 3.0)
	var cell_size: int = int(RITUAL_ICON_CELL_SIZE)
	var region: Rect2i = Rect2i(
		Vector2i(column * cell_size, row * cell_size),
		Vector2i(cell_size, cell_size)
	)
	if region.position.x < 0 or region.position.y < 0 or region.end.x > image.get_width() or region.end.y > image.get_height():
		return null
	var icon_image: Image = image.get_region(region)
	return ImageTexture.create_from_image(icon_image)

func _refresh_mode_tab_motion(animated: bool) -> void:
	_layout_mode_tab_indicator(animated)
	for button_index: int in MODE_TAB_TITLES.size():
		var button: Button = [_plant_button, _mix_button, _codex_button][button_index]
		var is_active: bool = button_index == _mode
		button.z_index = 2 if is_active else 1
		button.scale = Vector2.ONE

func _layout_mode_tab_indicator(animated: bool = false) -> void:
	var active_button: Button = [_plant_button, _mix_button, _codex_button][_mode]
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

func start_building_placement(type_key: StringName) -> void:
	_init_building_confirm_panel()
	if _building_confirm_panel != null:
		_building_confirm_panel.visible = true
	building_placement_started.emit(type_key)

func stop_building_placement() -> void:
	if _building_confirm_panel != null:
		_building_confirm_panel.visible = false

func _init_building_confirm_panel() -> void:
	if _building_confirm_panel != null:
		return
	if _root == null:
		return
	_building_confirm_panel = PanelContainer.new()
	_building_confirm_panel.name = "BuildingPlacementPanel"
	_building_confirm_panel.visible = false
	_building_confirm_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_building_confirm_panel.z_index = 150
	var anchored: Control = _building_confirm_panel
	anchored.layout_mode = 1
	anchored.anchors_preset = Control.PRESET_CENTER_TOP
	anchored.offset_top = 8.0
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.16, 0.88)
	panel_style.border_color = Color(0.35, 0.75, 0.35, 0.90)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	_building_confirm_panel.add_theme_stylebox_override("panel", panel_style)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	_building_confirm_panel.add_child(hbox)
	var label: Label = Label.new()
	label.text = "Place building"
	label.add_theme_color_override("font_color", Color(0.90, 0.95, 0.90, 0.98))
	hbox.add_child(label)
	var confirm_btn: Button = Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.pressed.connect(func() -> void: building_placement_confirm_requested.emit())
	hbox.add_child(confirm_btn)
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func() -> void: building_placement_cancel_requested.emit())
	hbox.add_child(cancel_btn)
	_root.add_child(_building_confirm_panel)
