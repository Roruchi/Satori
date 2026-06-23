class_name SeedAlchemyPanel
extends PanelContainer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const RitualAttemptResultScript = preload("res://src/seeds/RitualAttemptResult.gd")

const SLOT_COUNT: int = 3
const EMPTY_KEY: String = ""

const _INPUT_COLORS: Dictionary = {
	"essence:earth": Color(0.62, 0.62, 0.62),
	"essence:water": Color(0.129, 0.588, 0.953),
	"essence:fire": Color(0.922, 0.42, 0.18),
	"essence:wind": Color(0.298, 0.686, 0.314),
	"essence:ku": Color(0.55, 0.42, 0.78),
	"material:living_wood": Color(0.56, 0.42, 0.25),
	"material:reed_fiber": Color(0.42, 0.70, 0.66),
	"material:spirit_stone": Color(0.54, 0.58, 0.66),
}

const _INPUT_LABELS: Dictionary = {
	"essence:earth": "Earth Essence",
	"essence:water": "Water Essence",
	"essence:fire": "Fire Essence",
	"essence:wind": "Wind Essence",
	"essence:ku": "Ku Essence",
	"material:living_wood": "Living Wood",
	"material:reed_fiber": "Reed Fiber",
	"material:spirit_stone": "Spirit Stone",
}

const _INPUT_SHORT_LABELS: Dictionary = {
	"essence:earth": "Earth",
	"essence:water": "Water",
	"essence:fire": "Fire",
	"essence:wind": "Wind",
	"essence:ku": "Ku",
	"material:living_wood": "Wood",
	"material:reed_fiber": "Reed",
	"material:spirit_stone": "Stone",
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
@onready var _pouch_status_label: Label = $VBox/PouchStatus
@onready var _feedback_label: Label = $VBox/Feedback
@onready var _slots_label: Label = $VBox/Slots
@onready var _choice_prompt_label: Label = $VBox/ChoicePrompt
@onready var _slot_buttons: Array[Button] = [
	$VBox/Grid/Slot0,
	$VBox/Grid/Slot1,
	$VBox/Grid/Slot2,
]
@onready var _confirm_button: Button = $VBox/Actions/ConfirmButton
@onready var _clear_button: Button = $VBox/Actions/ClearButton
@onready var _earth_button: Button = $VBox/Elements/EarthButton
@onready var _water_button: Button = $VBox/Elements/WaterButton
@onready var _fire_button: Button = $VBox/Elements/FireButton
@onready var _wind_button: Button = $VBox/Elements/WindButton
@onready var _ku_button: Button = $VBox/Elements/KuButton
@onready var _living_wood_button: Button = $VBox/Materials/LivingWoodButton
@onready var _reed_fiber_button: Button = $VBox/Materials/ReedFiberButton
@onready var _spirit_stone_button: Button = $VBox/Materials/SpiritStoneButton

var _slot_keys: Array[String] = []
var _selected_slot_index: int = 0
var _last_feedback: String = ""

func _ready() -> void:
	for _i: int in range(SLOT_COUNT):
		_slot_keys.append(EMPTY_KEY)
	for i: int in range(_slot_buttons.size()):
		var button: Button = _slot_buttons[i]
		button.pressed.connect(func() -> void: _on_slot_pressed(i))
	_earth_button.pressed.connect(func() -> void: _on_input_tapped("essence:earth"))
	_water_button.pressed.connect(func() -> void: _on_input_tapped("essence:water"))
	_fire_button.pressed.connect(func() -> void: _on_input_tapped("essence:fire"))
	_wind_button.pressed.connect(func() -> void: _on_input_tapped("essence:wind"))
	_ku_button.pressed.connect(func() -> void: _on_input_tapped("essence:ku"))
	_living_wood_button.pressed.connect(func() -> void: _on_input_tapped("material:living_wood"))
	_reed_fiber_button.pressed.connect(func() -> void: _on_input_tapped("material:reed_fiber"))
	_spirit_stone_button.pressed.connect(func() -> void: _on_input_tapped("material:spirit_stone"))
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
	_update_ui()

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
		_pouch_status_label.text = "Placeables: 0/0 | Empty"
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
	var buttons_by_key: Dictionary = {
		"essence:earth": _earth_button,
		"essence:water": _water_button,
		"essence:fire": _fire_button,
		"essence:wind": _wind_button,
		"essence:ku": _ku_button,
		"material:living_wood": _living_wood_button,
		"material:reed_fiber": _reed_fiber_button,
		"material:spirit_stone": _spirit_stone_button,
	}
	for key_variant: Variant in buttons_by_key.keys():
		var key: String = str(key_variant)
		var btn: Button = buttons_by_key[key] as Button
		if btn == null:
			continue
		var definition: Dictionary = _definition_for_key(key)
		var available: int = int(definition.get("available_count", 0))
		var unlocked: bool = bool(definition.get("unlocked", false))
		btn.disabled = not bool(definition.get("available_for_selection", false))
		btn.text = _format_input_button_text(key, available, unlocked)
		_style_input_button(btn, key, _selected_slot_key() == key)

func _update_slot_button(slot_index: int) -> void:
	var key: String = _slot_keys[slot_index]
	var btn: Button = _slot_buttons[slot_index]
	btn.custom_minimum_size = Vector2(104.0, 68.0)
	btn.clip_text = true
	var selected: bool = slot_index == _selected_slot_index
	if key.is_empty():
		btn.text = "Slot %d\nTap to choose" % (slot_index + 1)
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
	btn.text = "Slot %d\n%s" % [slot_index + 1, str(_INPUT_SHORT_LABELS.get(key, "?"))]

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

func _format_input_button_text(key: String, available: int, unlocked: bool) -> String:
	var base: String = str(_INPUT_LABELS.get(key, "?"))
	if not unlocked:
		return "%s\nLocked" % base
	if key.begins_with("essence:"):
		return "%s\n%d/%d" % [base, available, KushoPoolScript.CAPACITY_PER_ELEMENT]
	return "%s\nx%d" % [base, available]

func _definition_for_key(input_key: String) -> Dictionary:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("get_ritual_input_definitions"):
		return {}
	var definitions_variant: Variant = alchemy.get_ritual_input_definitions()
	if not (definitions_variant is Array):
		return {}
	var definitions: Array = definitions_variant as Array
	for definition_variant: Variant in definitions:
		if not (definition_variant is Dictionary):
			continue
		var definition: Dictionary = definition_variant as Dictionary
		if str(definition.get("key", "")) == input_key:
			return definition
	return {}

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
		return "Slot %d selected: choose essence or material" % slot_number
	return "Slot %d selected: replace %s" % [slot_number, str(_INPUT_LABELS.get(selected_key, "?"))]

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
		return "Placeables: 0/0 | Empty"
	if pouch.size() == 0:
		return "Placeables: 0/%d | Empty" % pouch.capacity
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
	var prefix: String = "Placeables: %d/%d" % [pouch.size(), pouch.capacity]
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
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
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
