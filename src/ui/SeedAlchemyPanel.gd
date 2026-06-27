class_name SeedAlchemyPanel
extends PanelContainer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const RitualAttemptResultScript = preload("res://src/seeds/RitualAttemptResult.gd")
const _RITUAL_ICON_TEXTURE: Texture2D = preload("res://assets/ritual/ritual_input_icon_spritesheet.png")

const SLOT_COUNT: int = 3
const EMPTY_KEY: String = ""
const RITUAL_ICON_CELL_SIZE: float = 32.0
const INPUT_BUTTON_FULL_SIZE: Vector2 = Vector2(138.0, 68.0)
const INPUT_BUTTON_COMPACT_SIZE: Vector2 = Vector2(104.0, 56.0)
const INPUT_BUTTON_NARROW_SIZE: Vector2 = Vector2(86.0, 54.0)
const SLOT_BUTTON_FULL_SIZE: Vector2 = Vector2(116.0, 78.0)
const SLOT_BUTTON_COMPACT_SIZE: Vector2 = Vector2(92.0, 64.0)
const SLOT_BUTTON_NARROW_SIZE: Vector2 = Vector2(80.0, 62.0)
const COMPACT_WIDTH: float = 460.0
const NARROW_WIDTH: float = 340.0

const _INPUT_COLORS: Dictionary = {
	"essence:earth": Color(0.62, 0.62, 0.62),
	"essence:water": Color(0.129, 0.588, 0.953),
	"essence:fire": Color(0.922, 0.42, 0.18),
	"essence:wind": Color(0.298, 0.686, 0.314),
	"essence:ku": Color(0.55, 0.42, 0.78),
	"material:living_wood": Color(0.56, 0.42, 0.25),
	"material:reed_fiber": Color(0.42, 0.70, 0.66),
	"material:spirit_stone": Color(0.54, 0.58, 0.66),
	"material:ember_clay": Color(0.76, 0.35, 0.20),
}

const _INPUT_LABELS: Dictionary = {
	"essence:earth": "Chi",
	"essence:water": "Sui",
	"essence:fire": "Ka",
	"essence:wind": "Fu",
	"essence:ku": "Ku",
	"material:living_wood": "Living Wood",
	"material:reed_fiber": "Reed Fiber",
	"material:spirit_stone": "Spirit Stone",
	"material:ember_clay": "Ember Clay",
}

const _INPUT_SUBLABELS: Dictionary = {
	"essence:earth": "Earth Essence",
	"essence:water": "Water Essence",
	"essence:fire": "Fire Essence",
	"essence:wind": "Wind Essence",
	"essence:ku": "Void Essence",
}

const _INPUT_SHORT_LABELS: Dictionary = {
	"essence:earth": "Chi",
	"essence:water": "Sui",
	"essence:fire": "Ka",
	"essence:wind": "Fu",
	"essence:ku": "Ku",
	"material:living_wood": "Wood",
	"material:reed_fiber": "Reed",
	"material:spirit_stone": "Stone",
	"material:ember_clay": "Clay",
}

const _RITUAL_ICON_INDEX: Dictionary = {
	"essence:earth": 0,
	"essence:water": 1,
	"essence:fire": 2,
	"essence:wind": 3,
	"essence:ku": 4,
	"material:living_wood": 5,
	"material:reed_fiber": 6,
	"material:spirit_stone": 7,
	"material:ember_clay": 8,
}

const _SECTION_TITLES: Dictionary = {
	&"essence": "Godai Essence",
	&"material": "Materials",
	&"component": "Components",
	&"spirit": "Spirit Assistants",
}

const _BIOME_SEED_NAMES: Dictionary = {
	BiomeTypeScript.Value.STONE: "Stone Seed",
	BiomeTypeScript.Value.RIVER: "River Seed",
	BiomeTypeScript.Value.EMBER_FIELD: "Hearth Seed",
	BiomeTypeScript.Value.MEADOW: "Meadow Seed",
	BiomeTypeScript.Value.WETLANDS: "Wetlands Seed",
	BiomeTypeScript.Value.BADLANDS: "Badlands Seed",
	BiomeTypeScript.Value.WHISTLING_CANYONS: "Whistling Canyons Seed",
	BiomeTypeScript.Value.PRISMATIC_TERRACES: "Prismatic Terraces Seed",
	BiomeTypeScript.Value.FROSTLANDS: "Frostlands Seed",
	BiomeTypeScript.Value.THE_ASHFALL: "Sungrass Seed",
	BiomeTypeScript.Value.SACRED_STONE: "Sacred Stone Seed",
	BiomeTypeScript.Value.MOONLIT_POOL: "Moonlit Pool Seed",
	BiomeTypeScript.Value.EMBER_SHRINE: "Ember Shrine Seed",
	BiomeTypeScript.Value.CLOUD_RIDGE: "Cloud Ridge Seed",
	BiomeTypeScript.Value.KU: "Ku Seed",
}

const _FEEDBACK_MESSAGES: Dictionary = {
	RitualAttemptResultScript.FEEDBACK_SUCCESS: "Ritual shaped a placeable.",
	RitualAttemptResultScript.FEEDBACK_EMPTY_INPUT: "Choose ritual inputs.",
	RitualAttemptResultScript.FEEDBACK_DUPLICATE_INPUT: "Each slot must be unique.",
	RitualAttemptResultScript.FEEDBACK_MISSING_ESSENCE: "Add an essence to give the ritual intent.",
	RitualAttemptResultScript.FEEDBACK_LOCKED_INPUT: "That input is not available yet.",
	RitualAttemptResultScript.FEEDBACK_NO_MATCH: "No known form responds to those inputs.",
	RitualAttemptResultScript.FEEDBACK_INVENTORY_FULL: "Place inventory is full.",
	RitualAttemptResultScript.FEEDBACK_CONTEXT_BLOCKED: "That form needs a valid place.",
}

@onready var _preview_label: Label = $VBox/Preview
@onready var _vbox: VBoxContainer = $VBox
@onready var _pouch_status_label: Label = $VBox/PouchStatus
@onready var _feedback_label: Label = $VBox/Feedback
@onready var _slots_label: Label = $VBox/Slots
@onready var _choice_prompt_label: Label = $VBox/ChoicePrompt
@onready var _slot_grid: GridContainer = $VBox/Grid
@onready var _picker_scroll: ScrollContainer = $VBox/PickerScroll
@onready var _picker_sections: VBoxContainer = $VBox/PickerScroll/PickerSections
@onready var _slot_buttons: Array[Button] = [
	$VBox/Grid/Slot0,
	$VBox/Grid/Slot1,
	$VBox/Grid/Slot2,
]
@onready var _confirm_button: Button = $VBox/Actions/ConfirmButton
@onready var _clear_button: Button = $VBox/Actions/ClearButton

var _slot_keys: Array[String] = []
var _selected_slot_index: int = 0
var _last_feedback: String = ""
var _input_buttons_by_key: Dictionary = {}
var _section_grids_by_kind: Dictionary = {}
var _section_nodes_by_kind: Dictionary = {}
var _input_icon_cache: Dictionary = {}
var _compact_layout: bool = true
var _narrow_layout: bool = false

func _ready() -> void:
	for _i: int in range(SLOT_COUNT):
		_slot_keys.append(EMPTY_KEY)
	for i: int in range(_slot_buttons.size()):
		var button: Button = _slot_buttons[i]
		button.pressed.connect(func() -> void: _on_slot_pressed(i))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_signal("element_unlocked"):
		alchemy.element_unlocked.connect(func(_element_id: int) -> void: _update_ui())
	if alchemy != null and alchemy.has_signal("element_charge_changed"):
		alchemy.element_charge_changed.connect(func(_element_id: int, _charge: int) -> void: _update_ui())
	if alchemy != null and alchemy.has_signal("seed_added_to_pouch"):
		alchemy.seed_added_to_pouch.connect(_on_seed_added_to_pouch)
	if alchemy != null and alchemy.has_signal("ritual_attempt_resolved"):
		alchemy.ritual_attempt_resolved.connect(func(_outcome: StringName, _feedback_key: StringName, _guidance: String, _ritual_id: StringName, _result_kind: StringName, _result_id: StringName) -> void: _update_ui())
	if alchemy != null and alchemy.has_signal("material_count_changed"):
		alchemy.material_count_changed.connect(func(_material_id: StringName, _count: int) -> void: _update_ui())
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_signal("pouch_updated"):
		growth.pouch_updated.connect(_on_pouch_updated)
	_apply_panel_style()
	_apply_responsive_layout()
	_update_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()

func _apply_panel_style() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.11, 0.92)
	bg.border_color = Color(0.36, 0.32, 0.54, 0.78)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	bg.content_margin_left = 12.0
	bg.content_margin_right = 12.0
	bg.content_margin_top = 10.0
	bg.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", bg)
	_preview_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.78))
	_preview_label.add_theme_font_size_override("font_size", 18)
	_pouch_status_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.92))
	_feedback_label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.78))
	_slots_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.90))
	_choice_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.91, 0.78))
	_choice_prompt_label.add_theme_font_size_override("font_size", 14)

func _on_seed_added_to_pouch(recipe: SeedRecipe) -> void:
	if recipe != null:
		_last_feedback = "Shaped %s." % _recipe_display_name(recipe)
	_update_ui()

func _on_pouch_updated() -> void:
	_update_ui()

func _on_input_tapped(input_key: String) -> void:
	_ensure_selected_slot()
	var definition: Dictionary = _definition_for_key(input_key)
	if definition.is_empty():
		return
	if not bool(definition.get("available_for_selection", false)):
		_last_feedback = _feedback_text_for_key(RitualAttemptResultScript.FEEDBACK_LOCKED_INPUT)
		_update_ui()
		return
	if _slot_contains_key_elsewhere(input_key, _selected_slot_index):
		_last_feedback = _feedback_text_for_key(RitualAttemptResultScript.FEEDBACK_DUPLICATE_INPUT)
		_shake_button(_slot_buttons[_selected_slot_index])
	else:
		_slot_keys[_selected_slot_index] = input_key
		_last_feedback = ""
		_advance_selected_slot()
	_update_ui()

func _on_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_keys.size():
		return
	_selected_slot_index = slot_index
	_last_feedback = ""
	_update_ui()

func _on_confirm_pressed() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("attempt_ritual"):
		return
	var result_variant: Variant = alchemy.attempt_ritual(_slot_keys)
	if not (result_variant is RitualAttemptResultScript):
		return
	var result: RitualAttemptResultScript = result_variant as RitualAttemptResultScript
	if result.is_success():
		_clear_consumed_keys(result.consumed_input_keys)
		_selected_slot_index = 0
	_last_feedback = _feedback_text_for_result(result)
	_update_ui()

func _on_clear_pressed() -> void:
	for i: int in range(_slot_keys.size()):
		_slot_keys[i] = EMPTY_KEY
	_selected_slot_index = 0
	_last_feedback = ""
	_update_ui()

func _update_ui() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	_ensure_selected_slot()
	_refresh_input_controls()
	_apply_responsive_layout()
	_update_input_buttons()
	var occupied_count: int = _count_occupied_slots()
	_slots_label.text = "Ritual slots: %d/%d" % [occupied_count, SLOT_COUNT]
	_choice_prompt_label.text = _format_choice_prompt()
	for i: int in range(_slot_buttons.size()):
		_update_slot_button(i)
	var preview_result: RitualAttemptResultScript = RitualAttemptResultScript.empty_input()
	if alchemy != null and alchemy.has_method("preview_ritual"):
		var preview_variant: Variant = alchemy.preview_ritual(_slot_keys)
		if preview_variant is RitualAttemptResultScript:
			preview_result = preview_variant as RitualAttemptResultScript
	if preview_result.is_success():
		_preview_label.text = "Preview: %s" % _result_display_name(preview_result)
	else:
		_preview_label.text = "Preview: --"
	var pouch: SeedPouch = null
	if alchemy != null and alchemy.has_method("get_pouch"):
		var pouch_variant: Variant = alchemy.get_pouch()
		if pouch_variant is SeedPouch:
			pouch = pouch_variant as SeedPouch
	if pouch == null:
		_pouch_status_label.text = "0/0 | Empty"
	else:
		_pouch_status_label.text = _format_place_inventory_status(pouch)
	if not _last_feedback.is_empty():
		_feedback_label.text = _last_feedback
	elif alchemy == null:
		_feedback_label.text = "Ritual service unavailable."
	elif occupied_count == 0:
		_feedback_label.text = "Tap a slot, then choose an essence or material."
	elif preview_result.is_success():
		_feedback_label.text = "Confirm to shape %s." % _result_display_name(preview_result)
	else:
		_feedback_label.text = _feedback_text_for_result(preview_result)
	_confirm_button.disabled = occupied_count == 0

func _update_input_buttons() -> void:
	for key_variant: Variant in _input_buttons_by_key.keys():
		var key: String = str(key_variant)
		var btn: Button = _input_buttons_by_key[key] as Button
		if btn == null:
			continue
		var definition: Dictionary = _definition_for_key(key)
		var available: int = int(definition.get("available_count", 0))
		var unlocked: bool = bool(definition.get("unlocked", false))
		btn.disabled = not bool(definition.get("available_for_selection", false))
		btn.text = ""
		btn.tooltip_text = _format_input_tooltip(key, definition, available, unlocked)
		_set_input_button_content(btn, key, definition, available, unlocked)
		_style_input_button(btn, key, _selected_slot_key() == key)

func _refresh_input_controls() -> void:
	var definitions: Array[Dictionary] = _get_input_definitions()
	var active_keys: Dictionary = {}
	for definition: Dictionary in definitions:
		var key: String = str(definition.get("key", ""))
		if key.is_empty():
			continue
		active_keys[key] = true
		var kind: StringName = StringName(str(definition.get("kind", &"material")))
		var grid: GridContainer = _ensure_section_grid(kind)
		if not _input_buttons_by_key.has(key):
			var btn: Button = _create_input_button(key)
			_input_buttons_by_key[key] = btn
			grid.add_child(btn)
	for key_variant: Variant in _input_buttons_by_key.keys().duplicate():
		var existing_key: String = str(key_variant)
		if active_keys.has(existing_key):
			continue
		var old_button: Button = _input_buttons_by_key[existing_key] as Button
		_input_buttons_by_key.erase(existing_key)
		if old_button != null:
			old_button.queue_free()

func _create_input_button(input_key: String) -> Button:
	var btn: Button = Button.new()
	btn.name = _node_name_for_input_key(input_key)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = _input_button_min_size()
	btn.clip_text = true
	btn.pressed.connect(func() -> void: _on_input_tapped(input_key))
	return btn

func _ensure_button_contents(btn: Button) -> Dictionary:
	var existing: Node = btn.get_node_or_null("Contents")
	if existing != null:
		return {
			"row": existing,
			"icon": existing.get_node("Icon"),
			"title": existing.get_node("Labels/Title"),
			"detail": existing.get_node("Labels/Detail"),
		}
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Contents"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8.0
	row.offset_top = 6.0
	row.offset_right = -8.0
	row.offset_bottom = -6.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(32.0, 32.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var labels: VBoxContainer = VBoxContainer.new()
	labels.name = "Labels"
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.add_theme_constant_override("separation", 0)
	row.add_child(labels)
	var title: Label = Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 14)
	labels.add_child(title)
	var detail: Label = Label.new()
	detail.name = "Detail"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.clip_text = true
	detail.add_theme_font_size_override("font_size", 12)
	labels.add_child(detail)
	btn.add_child(row)
	return {"row": row, "icon": icon, "title": title, "detail": detail}

func _set_input_button_content(btn: Button, key: String, definition: Dictionary, available: int, unlocked: bool) -> void:
	var parts: Dictionary = _ensure_button_contents(btn)
	_apply_button_content_metrics(parts)
	var icon: TextureRect = parts["icon"] as TextureRect
	var title: Label = parts["title"] as Label
	var detail: Label = parts["detail"] as Label
	if icon != null:
		icon.texture = _icon_texture_for_key(key)
		icon.modulate = Color.WHITE if unlocked else Color(0.45, 0.42, 0.50, 0.75)
	if title != null:
		title.text = _compact_display_label_for_key(key) if _compact_layout else _display_label_for_key(key, definition)
	if detail != null:
		if not unlocked:
			detail.text = "Locked"
		elif key.begins_with("essence:"):
			if _compact_layout:
				detail.text = "%d/%d" % [available, _capacity_for_definition(definition)]
			else:
				detail.text = "%s %d/%d" % [str(_INPUT_SUBLABELS.get(key, "Essence")), available, _capacity_for_definition(definition)]
		else:
			detail.text = "x%d" % available

func _ensure_section_grid(kind: StringName) -> GridContainer:
	var existing_variant: Variant = _section_grids_by_kind.get(kind, null)
	if existing_variant is GridContainer:
		return existing_variant as GridContainer
	var section: VBoxContainer = VBoxContainer.new()
	section.name = "Section_%s" % str(kind)
	section.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.name = "Title"
	title.text = _section_title(kind)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.66))
	title.add_theme_font_size_override("font_size", 13)
	var grid: GridContainer = GridContainer.new()
	grid.name = "Grid"
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	section.add_child(title)
	section.add_child(grid)
	_picker_sections.add_child(section)
	_section_nodes_by_kind[kind] = section
	_section_grids_by_kind[kind] = grid
	return grid

func _apply_responsive_layout() -> void:
	var panel_width: float = size.x
	if panel_width <= 0.0:
		panel_width = custom_minimum_size.x
	_compact_layout = panel_width < COMPACT_WIDTH
	_narrow_layout = panel_width < NARROW_WIDTH
	if _vbox != null:
		_vbox.add_theme_constant_override("separation", 5 if _compact_layout else 8)
	if _slot_grid != null:
		_slot_grid.columns = SLOT_COUNT
		_slot_grid.add_theme_constant_override("h_separation", 5 if _narrow_layout else 8)
		_slot_grid.add_theme_constant_override("v_separation", 5 if _compact_layout else 8)
	for slot_button: Button in _slot_buttons:
		if slot_button != null:
			slot_button.custom_minimum_size = _slot_button_min_size()
	if _picker_scroll != null:
		_picker_scroll.custom_minimum_size = Vector2(0.0, 164.0 if _compact_layout else 190.0)
	var content_width: float = maxf(1.0, panel_width - 36.0)
	var button_size: Vector2 = _input_button_min_size()
	var gap: int = 5 if _compact_layout else 6
	for kind_variant: Variant in _section_grids_by_kind.keys():
		var kind: StringName = StringName(str(kind_variant))
		var grid: GridContainer = _section_grids_by_kind[kind] as GridContainer
		if grid == null:
			continue
		grid.add_theme_constant_override("h_separation", gap)
		grid.add_theme_constant_override("v_separation", gap)
		grid.columns = mini(3, maxi(1, int(floor((content_width + float(gap)) / (button_size.x + float(gap))))))
	var title_font_size: int = 12 if _compact_layout else 13
	for kind_node_variant: Variant in _section_nodes_by_kind.keys():
		var section_kind: StringName = StringName(str(kind_node_variant))
		var section: VBoxContainer = _section_nodes_by_kind[section_kind] as VBoxContainer
		if section == null:
			continue
		section.add_theme_constant_override("separation", 3 if _compact_layout else 4)
		var title: Label = section.get_node_or_null("Title") as Label
		if title != null:
			title.text = _section_title(section_kind)
			title.add_theme_font_size_override("font_size", title_font_size)
	for key_variant: Variant in _input_buttons_by_key.keys():
		var btn: Button = _input_buttons_by_key[key_variant] as Button
		if btn != null:
			btn.custom_minimum_size = button_size

func _section_title(kind: StringName) -> String:
	if _compact_layout:
		match kind:
			&"essence":
				return "Essence"
			&"material":
				return "Materials"
			&"component":
				return "Components"
			&"spirit":
				return "Assistants"
	return str(_SECTION_TITLES.get(kind, str(kind).replace("_", " ").capitalize()))

func _input_button_min_size() -> Vector2:
	if _narrow_layout:
		return INPUT_BUTTON_NARROW_SIZE
	if _compact_layout:
		return INPUT_BUTTON_COMPACT_SIZE
	return INPUT_BUTTON_FULL_SIZE

func _slot_button_min_size() -> Vector2:
	if _narrow_layout:
		return SLOT_BUTTON_NARROW_SIZE
	if _compact_layout:
		return SLOT_BUTTON_COMPACT_SIZE
	return SLOT_BUTTON_FULL_SIZE

func _apply_button_content_metrics(parts: Dictionary) -> void:
	var row: HBoxContainer = parts.get("row", null) as HBoxContainer
	var icon: TextureRect = parts.get("icon", null) as TextureRect
	var title: Label = parts.get("title", null) as Label
	var detail: Label = parts.get("detail", null) as Label
	var inset_x: float = 5.0 if _compact_layout else 8.0
	var inset_y: float = 4.0 if _compact_layout else 6.0
	if row != null:
		row.offset_left = inset_x
		row.offset_top = inset_y
		row.offset_right = -inset_x
		row.offset_bottom = -inset_y
		row.add_theme_constant_override("separation", 5 if _compact_layout else 8)
	if icon != null:
		var icon_size: float = 26.0 if _compact_layout else 32.0
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
	if title != null:
		title.add_theme_font_size_override("font_size", 13 if _compact_layout else 14)
	if detail != null:
		detail.add_theme_font_size_override("font_size", 11 if _compact_layout else 12)

func _node_name_for_input_key(input_key: String) -> String:
	return "Input_%s" % input_key.replace(":", "_").replace("-", "_").replace(" ", "_")

func _update_slot_button(slot_index: int) -> void:
	var key: String = _slot_keys[slot_index]
	var btn: Button = _slot_buttons[slot_index]
	btn.custom_minimum_size = _slot_button_min_size()
	btn.clip_text = true
	var selected: bool = slot_index == _selected_slot_index
	if key.is_empty():
		btn.text = ""
		_set_slot_button_content(btn, null, "Slot %d" % (slot_index + 1), "Choose input", false)
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.16, 0.14, 0.22) if selected else Color(0.12, 0.12, 0.16)
		empty_style.border_color = Color(0.86, 0.76, 0.48) if selected else Color(0.37, 0.36, 0.48)
		empty_style.border_width_left = 3 if selected else 1
		empty_style.border_width_right = empty_style.border_width_left
		empty_style.border_width_top = empty_style.border_width_left
		empty_style.border_width_bottom = empty_style.border_width_left
		empty_style.corner_radius_top_left = 6
		empty_style.corner_radius_top_right = 6
		empty_style.corner_radius_bottom_left = 6
		empty_style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
		btn.add_theme_font_size_override("font_size", 13)
		return
	var col: Color = Color(_INPUT_COLORS.get(key, Color(0.45, 0.45, 0.45)))
	btn.text = ""
	_set_slot_button_content(btn, _icon_texture_for_key(key), "Slot %d" % (slot_index + 1), _short_label_for_key(key), true)
	var filled_style := StyleBoxFlat.new()
	filled_style.bg_color = col.darkened(0.24 if selected else 0.34)
	filled_style.border_color = Color(0.96, 0.88, 0.58) if selected else col.lightened(0.12)
	filled_style.border_width_left = 3 if selected else 2
	filled_style.border_width_right = filled_style.border_width_left
	filled_style.border_width_top = filled_style.border_width_left
	filled_style.border_width_bottom = filled_style.border_width_left
	filled_style.corner_radius_top_left = 6
	filled_style.corner_radius_top_right = 6
	filled_style.corner_radius_bottom_left = 6
	filled_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", filled_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 15)

func _set_slot_button_content(btn: Button, texture: Texture2D, title_text: String, detail_text: String, show_icon: bool) -> void:
	var parts: Dictionary = _ensure_button_contents(btn)
	_apply_button_content_metrics(parts)
	var icon: TextureRect = parts["icon"] as TextureRect
	var title: Label = parts["title"] as Label
	var detail: Label = parts["detail"] as Label
	if icon != null:
		icon.visible = show_icon and texture != null
		icon.texture = texture
	if title != null:
		title.text = title_text
		title.add_theme_color_override("font_color", Color(0.90, 0.88, 0.98) if not show_icon else Color(1.0, 0.96, 0.78))
	if detail != null:
		detail.text = detail_text
		detail.add_theme_color_override("font_color", Color(0.78, 0.76, 0.86) if not show_icon else Color.WHITE)

func _style_input_button(btn: Button, key: String, selected: bool) -> void:
	var col: Color = Color(_INPUT_COLORS.get(key, Color.WHITE))
	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.bg_color = col.darkened(0.12 if selected else 0.56)
	normal_style.border_color = Color.WHITE if selected else col.darkened(0.20)
	normal_style.border_width_left = 3 if selected else 2
	normal_style.border_width_right = normal_style.border_width_left
	normal_style.border_width_top = normal_style.border_width_left
	normal_style.border_width_bottom = normal_style.border_width_left
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = col.darkened(0.30)
	hover_style.border_color = col.lightened(0.12)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	btn.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.86, 0.86, 0.86))
	btn.add_theme_font_size_override("font_size", 13)
	var parts: Dictionary = _ensure_button_contents(btn)
	var title: Label = parts["title"] as Label
	var detail: Label = parts["detail"] as Label
	if title != null:
		title.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.94, 0.92, 0.84))
	if detail != null:
		detail.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96) if selected else Color(0.78, 0.76, 0.72))

func _format_input_button_text(key: String, definition: Dictionary, available: int, unlocked: bool) -> String:
	var base: String = _display_label_for_key(key, definition)
	if not unlocked:
		return "%s\nLocked" % base
	if key.begins_with("essence:"):
		var sublabel: String = str(_INPUT_SUBLABELS.get(key, "Essence"))
		return "%s\n%s %d/%d" % [base, sublabel, available, _capacity_for_definition(definition)]
	return "%s\nx%d" % [base, available]

func _format_input_tooltip(key: String, definition: Dictionary, available: int, unlocked: bool) -> String:
	var label: String = _display_label_for_key(key, definition)
	var sublabel: String = str(_INPUT_SUBLABELS.get(key, str(definition.get("display_name", ""))))
	if not unlocked:
		return "%s is not available yet." % label
	if key.begins_with("essence:"):
		return "%s: %s, %d of %d essence ready." % [label, sublabel, available, _capacity_for_definition(definition)]
	return "%s: %d available." % [label, available]

func _capacity_for_definition(definition: Dictionary) -> int:
	return int(definition.get("capacity", KushoPoolScript.CAPACITY_PER_ELEMENT))

func _display_label_for_key(key: String, definition: Dictionary = {}) -> String:
	if _INPUT_LABELS.has(key):
		return str(_INPUT_LABELS[key])
	return str(definition.get("display_name", key.replace(":", " ").replace("_", " ").capitalize()))

func _compact_display_label_for_key(key: String) -> String:
	if key.begins_with("material:"):
		return _short_label_for_key(key)
	return str(_INPUT_LABELS.get(key, _short_label_for_key(key)))

func _short_label_for_key(key: String) -> String:
	return str(_INPUT_SHORT_LABELS.get(key, _display_label_for_key(key).substr(0, mini(6, _display_label_for_key(key).length()))))

func _definition_for_key(input_key: String) -> Dictionary:
	for definition: Dictionary in _get_input_definitions():
		if str(definition.get("key", "")) == input_key:
			return definition
	return {}

func _get_input_definitions() -> Array[Dictionary]:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("get_ritual_input_definitions"):
		return []
	var definitions_variant: Variant = alchemy.get_ritual_input_definitions()
	if not (definitions_variant is Array):
		return []
	var definitions: Array = definitions_variant as Array
	var typed_definitions: Array[Dictionary] = []
	for definition_variant: Variant in definitions:
		if not (definition_variant is Dictionary):
			continue
		var definition: Dictionary = definition_variant as Dictionary
		typed_definitions.append(definition)
	return typed_definitions

func _icon_texture_for_key(input_key: String) -> Texture2D:
	if _input_icon_cache.has(input_key):
		return _input_icon_cache[input_key] as Texture2D
	var texture: Texture2D = _ritual_icon_texture(input_key)
	if texture != null:
		_input_icon_cache[input_key] = texture
	return texture

func _ritual_icon_texture(input_key: String) -> Texture2D:
	if _RITUAL_ICON_TEXTURE == null or not _RITUAL_ICON_INDEX.has(input_key):
		return null
	var icon_index: int = int(_RITUAL_ICON_INDEX.get(input_key, 0))
	var column: int = icon_index % 3
	var row: int = floori(float(icon_index) / 3.0)
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = _RITUAL_ICON_TEXTURE
	atlas_texture.region = Rect2(
		Vector2(float(column) * RITUAL_ICON_CELL_SIZE, float(row) * RITUAL_ICON_CELL_SIZE),
		Vector2(RITUAL_ICON_CELL_SIZE, RITUAL_ICON_CELL_SIZE)
	)
	return atlas_texture

func _slot_contains_key_elsewhere(input_key: String, current_slot: int) -> bool:
	for i: int in range(_slot_keys.size()):
		if i == current_slot:
			continue
		if _slot_keys[i] == input_key:
			return true
	return false

func _clear_consumed_keys(consumed_keys: Array[String]) -> void:
	for consumed_key: String in consumed_keys:
		for i: int in range(_slot_keys.size()):
			if _slot_keys[i] == consumed_key:
				_slot_keys[i] = EMPTY_KEY
				break

func _selected_slot_key() -> String:
	if _selected_slot_index < 0 or _selected_slot_index >= _slot_keys.size():
		return EMPTY_KEY
	return _slot_keys[_selected_slot_index]

func _ensure_selected_slot() -> void:
	if _slot_keys.is_empty():
		_selected_slot_index = 0
		return
	_selected_slot_index = clampi(_selected_slot_index, 0, _slot_keys.size() - 1)

func _advance_selected_slot() -> void:
	for offset: int in range(1, _slot_keys.size() + 1):
		var next_index: int = (_selected_slot_index + offset) % _slot_keys.size()
		if _slot_keys[next_index].is_empty():
			_selected_slot_index = next_index
			return

func _format_choice_prompt() -> String:
	var slot_number: int = _selected_slot_index + 1
	var selected_key: String = _selected_slot_key()
	if selected_key.is_empty():
		return "Slot %d selected: choose godai essence or material" % slot_number
	return "Slot %d selected: replace %s" % [slot_number, _display_label_for_key(selected_key)]

func _count_occupied_slots() -> int:
	var count: int = 0
	for key: String in _slot_keys:
		if not key.is_empty():
			count += 1
	return count

func _feedback_text_for_result(result: RitualAttemptResultScript) -> String:
	if result == null:
		return _feedback_text_for_key(RitualAttemptResultScript.FEEDBACK_NO_MATCH)
	var base_text: String = _feedback_text_for_key(result.feedback_key)
	if result.guidance.is_empty():
		return base_text
	return "%s %s" % [base_text, result.guidance]

func _feedback_text_for_key(feedback_key: StringName) -> String:
	return str(_FEEDBACK_MESSAGES.get(feedback_key, "Ritual resolved."))

func _result_display_name(result: RitualAttemptResultScript) -> String:
	if result == null:
		return ""
	if result.result_kind == &"seed":
		return _recipe_display_name_by_id(result.result_id)
	var form_name: String = _form_display_name(result.result_id)
	if not form_name.is_empty():
		return form_name
	var raw: String = str(result.result_id)
	return raw.replace("form_", "").replace("building_", "").capitalize()

func _recipe_display_name_by_id(recipe_id: StringName) -> String:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("get_registry"):
		return str(recipe_id).replace("recipe_", "").capitalize()
	var registry: SeedRecipeRegistry = null
	var registry_variant: Variant = alchemy.get_registry()
	if registry_variant is SeedRecipeRegistry:
		registry = registry_variant as SeedRecipeRegistry
	if registry == null:
		return str(recipe_id).replace("recipe_", "").capitalize()
	for recipe: SeedRecipe in registry.all_known_recipes():
		if recipe != null and recipe.recipe_id == recipe_id:
			return _recipe_display_name(recipe)
	return str(recipe_id).replace("recipe_", "").capitalize()

func _recipe_display_name(recipe: SeedRecipe) -> String:
	if recipe == null:
		return ""
	return str(_BIOME_SEED_NAMES.get(recipe.produces_biome, recipe.recipe_id))

func _format_place_inventory_status(pouch: SeedPouch) -> String:
	if pouch == null:
		return "0/0 | Empty"
	if pouch.size() == 0:
		return "0/%d | Empty" % pouch.capacity
	var placeable_parts: Array[String] = []
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var entry: BuildingInventoryEntry = pouch.get_building_at(i)
			if entry != null:
				placeable_parts.append("%s x%d" % [_building_display_name(entry.type_key), entry.count])
		else:
			var recipe: SeedRecipe = pouch.get_at(i)
			var uses: int = pouch.get_uses_at(i)
			if recipe != null and uses > 0:
				placeable_parts.append("%s x%d" % [_recipe_display_name(recipe), uses])
	var prefix: String = "%d/%d" % [pouch.size(), pouch.capacity]
	if placeable_parts.is_empty():
		return "%s | Empty" % prefix
	return "%s | %s" % [prefix, ", ".join(placeable_parts)]

func _building_display_name(type_key: StringName) -> String:
	var form_name: String = _form_display_name(type_key)
	if not form_name.is_empty():
		return form_name
	var raw: String = str(type_key)
	if raw.begins_with("building_"):
		raw = raw.substr("building_".length())
	if raw.begins_with("form_"):
		raw = raw.substr("form_".length())
	return raw.capitalize()

func _form_display_name(type_key: StringName) -> String:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService") if is_inside_tree() else null
	if alchemy != null and alchemy.has_method("get_form_display_name"):
		return str(alchemy.get_form_display_name(type_key))
	return ""

func _shake_button(target: Button) -> void:
	if target == null:
		return
	var start_pos: Vector2 = target.position
	var tween: Tween = create_tween()
	tween.tween_property(target, "position", start_pos + Vector2(4.0, 0.0), 0.04)
	tween.tween_property(target, "position", start_pos + Vector2(-4.0, 0.0), 0.04)
	tween.tween_property(target, "position", start_pos, 0.04)
