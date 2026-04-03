class_name SeedAlchemyPanel
extends PanelContainer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")
const SeedCraftGridNormalizerScript = preload("res://src/seeds/SeedCraftGridNormalizer.gd")
const SeedCraftAttemptResultScript = preload("res://src/seeds/SeedCraftAttemptResult.gd")
const BuildingCraftAttemptResultScript = preload("res://src/seeds/BuildingCraftAttemptResult.gd")

const _ELEMENT_COLORS: Dictionary = {
	0: Color(0.62, 0.62, 0.62),      # CHI stone-grey
	1: Color(0.129, 0.588, 0.953),   # SUI river-blue
	2: Color(0.922, 0.42, 0.18),     # KA  ember-orange
	3: Color(0.298, 0.686, 0.314),   # FU  meadow-green
	4: Color(0.55, 0.42, 0.78),      # KU  void-purple
}

const _ELEMENT_BUTTON_TEXT: Dictionary = {
	GodaiElementScript.Value.CHI: "Chi / Stone",
	GodaiElementScript.Value.SUI: "Sui / River",
	GodaiElementScript.Value.KA: "Ka / Ember",
	GodaiElementScript.Value.FU: "Fu / Meadow",
	GodaiElementScript.Value.KU: "Ku / Void",
}

const _BIOME_SEED_NAMES: Dictionary = {
	BiomeTypeScript.Value.STONE: "Stone Seed",
	BiomeTypeScript.Value.RIVER: "River Seed",
	BiomeTypeScript.Value.EMBER_FIELD: "Ember Seed",
	BiomeTypeScript.Value.MEADOW: "Meadow Seed",
	BiomeTypeScript.Value.WETLANDS: "Wetlands Seed",
	BiomeTypeScript.Value.BADLANDS: "Badlands Seed",
	BiomeTypeScript.Value.WHISTLING_CANYONS: "Whistling Canyons Seed",
	BiomeTypeScript.Value.PRISMATIC_TERRACES: "Prismatic Terraces Seed",
	BiomeTypeScript.Value.FROSTLANDS: "Frostlands Seed",
	BiomeTypeScript.Value.THE_ASHFALL: "Ashfall Seed",
	BiomeTypeScript.Value.SACRED_STONE: "Sacred Stone Seed",
	BiomeTypeScript.Value.MOONLIT_POOL: "Moonlit Pool Seed",
	BiomeTypeScript.Value.EMBER_SHRINE: "Ember Shrine Seed",
	BiomeTypeScript.Value.CLOUD_RIDGE: "Cloud Ridge Seed",
	BiomeTypeScript.Value.KU: "Ku Seed",
}

const _FEEDBACK_MESSAGES: Dictionary = {
	SeedCraftAttemptResultScript.FEEDBACK_SUCCESS: "Seed added to plant inventory.",
	SeedCraftAttemptResultScript.FEEDBACK_EMPTY_INPUT: "Craft grid is empty.",
	SeedCraftAttemptResultScript.FEEDBACK_NO_MATCH: "No matching seed recipe.",
	SeedCraftAttemptResultScript.FEEDBACK_LOCKED_KU: "Ku is locked for this recipe.",
	SeedCraftAttemptResultScript.FEEDBACK_INVENTORY_FULL: "Plant inventory is full.",
	BuildingCraftAttemptResultScript.FEEDBACK_SUCCESS: "Building added to inventory.",
	BuildingCraftAttemptResultScript.FEEDBACK_NO_MATCH: "No matching building recipe.",
	BuildingCraftAttemptResultScript.FEEDBACK_INVENTORY_FULL: "Building inventory is full.",
}

@onready var _preview_label: Label = $VBox/Preview
@onready var _pouch_status_label: Label = $VBox/PouchStatus
@onready var _feedback_label: Label = $VBox/Feedback
@onready var _slots_label: Label = $VBox/Slots
@onready var _slot_buttons: Array[Button] = [
	$VBox/Grid/Slot0,
	$VBox/Grid/Slot1,
	$VBox/Grid/Slot2,
	$VBox/Grid/Slot3,
	$VBox/Grid/Slot4,
	$VBox/Grid/Slot5,
	$VBox/Grid/Slot6,
	$VBox/Grid/Slot7,
	$VBox/Grid/Slot8,
]
@onready var _confirm_button: Button = $VBox/Actions/ConfirmButton
@onready var _clear_button: Button = $VBox/Actions/ClearButton
@onready var _chi_button: Button = $VBox/Elements/ChiButton
@onready var _sui_button: Button = $VBox/Elements/SuiButton
@onready var _ka_button: Button = $VBox/Elements/KaButton
@onready var _fu_button: Button = $VBox/Elements/FuButton
@onready var _ku_button: Button = $VBox/Elements/KuButton

var _slot_tokens: Array[int] = []
var _active_element: int = SeedCraftGridNormalizerScript.EMPTY_SLOT
var _last_feedback: String = ""

func _ready() -> void:
	for _i: int in range(9):
		_slot_tokens.append(SeedCraftGridNormalizerScript.EMPTY_SLOT)
	for i: int in range(_slot_buttons.size()):
		var button: Button = _slot_buttons[i]
		button.pressed.connect(func() -> void: _on_slot_pressed(i))
	_chi_button.pressed.connect(func() -> void: _on_element_tapped(GodaiElementScript.Value.CHI))
	_sui_button.pressed.connect(func() -> void: _on_element_tapped(GodaiElementScript.Value.SUI))
	_ka_button.pressed.connect(func() -> void: _on_element_tapped(GodaiElementScript.Value.KA))
	_fu_button.pressed.connect(func() -> void: _on_element_tapped(GodaiElementScript.Value.FU))
	_ku_button.pressed.connect(func() -> void: _on_element_tapped(GodaiElementScript.Value.KU))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_signal("element_unlocked"):
		alchemy.element_unlocked.connect(_on_element_unlocked)
	if alchemy != null and alchemy.has_signal("element_charge_changed"):
		alchemy.element_charge_changed.connect(_on_element_charge_changed)
	if alchemy != null and alchemy.has_signal("seed_added_to_pouch"):
		alchemy.seed_added_to_pouch.connect(_on_seed_added_to_pouch)
	if alchemy != null and alchemy.has_signal("building_craft_resolved"):
		alchemy.building_craft_resolved.connect(_on_building_craft_resolved)
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_signal("pouch_updated"):
		growth.pouch_updated.connect(_on_pouch_updated)
	_apply_element_button_labels()
	_apply_panel_style()
	_apply_button_styles()
	_update_ui()

func _apply_element_button_labels() -> void:
	var btn_map: Dictionary = {
		GodaiElementScript.Value.CHI: _chi_button,
		GodaiElementScript.Value.SUI: _sui_button,
		GodaiElementScript.Value.KA: _ka_button,
		GodaiElementScript.Value.FU: _fu_button,
		GodaiElementScript.Value.KU: _ku_button,
	}
	for element: int in btn_map:
		var btn: Button = btn_map[element] as Button
		if btn != null:
			btn.text = str(_ELEMENT_BUTTON_TEXT.get(element, "?"))

func _apply_panel_style() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.11, 0.90)
	bg.border_color = Color(0.30, 0.26, 0.50, 0.75)
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
	_preview_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.80))
	_pouch_status_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.92))
	_feedback_label.add_theme_color_override("font_color", Color(0.86, 0.95, 0.78))

func _apply_button_styles() -> void:
	var buttons: Array[Button] = [_chi_button, _sui_button, _ka_button, _fu_button, _ku_button]
	var elements: Array[int] = [
		GodaiElementScript.Value.CHI,
		GodaiElementScript.Value.SUI,
		GodaiElementScript.Value.KA,
		GodaiElementScript.Value.FU,
		GodaiElementScript.Value.KU,
	]
	for i: int in range(buttons.size()):
		_style_element_button(buttons[i], elements[i], _active_element == elements[i])

func _style_element_button(btn: Button, element: int, selected: bool) -> void:
	var col: Color = Color(_ELEMENT_COLORS.get(element, Color.WHITE))
	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	var hover_style := StyleBoxFlat.new()
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	if selected:
		normal_style.bg_color = col.darkened(0.10)
		normal_style.border_color = Color.WHITE
		normal_style.border_width_left = 3
		normal_style.border_width_right = 3
		normal_style.border_width_top = 3
		normal_style.border_width_bottom = 3
	else:
		normal_style.bg_color = col.darkened(0.55)
		normal_style.border_color = col.darkened(0.20)
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
	hover_style.bg_color = col.darkened(0.30)
	hover_style.border_color = col
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.82, 0.82, 0.82))
	btn.add_theme_font_size_override("font_size", 13)

func _on_element_unlocked(_element_id: int) -> void:
	_update_ui()

func _on_seed_added_to_pouch(recipe: SeedRecipe) -> void:
	if recipe != null:
		_last_feedback = "Added %s to pouch" % _recipe_display_name(recipe)
	_update_ui()

func _on_element_charge_changed(_element_id: int, _charge: int) -> void:
	_update_ui()

func _on_pouch_updated() -> void:
	_last_feedback = ""
	_update_ui()

func _on_element_tapped(element_id: int) -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null:
		return
	if not alchemy.is_element_unlocked(element_id):
		return
	if _active_element == element_id:
		_active_element = SeedCraftGridNormalizerScript.EMPTY_SLOT
	else:
		_active_element = element_id
	_update_ui()

func _on_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_tokens.size():
		return
	if _active_element == SeedCraftGridNormalizerScript.EMPTY_SLOT:
		if _slot_tokens[slot_index] != SeedCraftGridNormalizerScript.EMPTY_SLOT:
			_slot_tokens[slot_index] = SeedCraftGridNormalizerScript.EMPTY_SLOT
	else:
		if _slot_tokens[slot_index] == _active_element:
			_slot_tokens[slot_index] = SeedCraftGridNormalizerScript.EMPTY_SLOT
		else:
			_slot_tokens[slot_index] = _active_element
	_update_ui()

func _on_confirm_pressed() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null:
		return
	var occupied_count: int = _count_occupied_slots()
	if occupied_count >= 3 and alchemy.has_method("attempt_building_craft_from_grid"):
		var building_result: BuildingCraftAttemptResult = alchemy.attempt_building_craft_from_grid(_slot_tokens)
		if building_result.is_success():
			for slot_index: int in building_result.consumed_slot_indices:
				if slot_index >= 0 and slot_index < _slot_tokens.size():
					_slot_tokens[slot_index] = SeedCraftGridNormalizerScript.EMPTY_SLOT
			_last_feedback = _feedback_text_for_key(BuildingCraftAttemptResultScript.FEEDBACK_SUCCESS)
		else:
			_last_feedback = _feedback_text_for_key(building_result.feedback_key)
		_update_ui()
		return
	var result: SeedCraftAttemptResult = alchemy.attempt_seed_craft_from_grid(_slot_tokens)
	if result.is_success():
		for slot_index: int in result.consumed_slot_indices:
			if slot_index >= 0 and slot_index < _slot_tokens.size():
				_slot_tokens[slot_index] = SeedCraftGridNormalizerScript.EMPTY_SLOT
	_last_feedback = _feedback_text_for_result(result)
	_update_ui()

func _on_clear_pressed() -> void:
	for i: int in range(_slot_tokens.size()):
		_slot_tokens[i] = SeedCraftGridNormalizerScript.EMPTY_SLOT
	_active_element = SeedCraftGridNormalizerScript.EMPTY_SLOT
	_update_ui()

func _update_ui() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null:
		return
	_ku_button.disabled = not alchemy.is_element_unlocked(GodaiElementScript.Value.KU)
	var btn_map: Dictionary = {
		GodaiElementScript.Value.CHI: _chi_button,
		GodaiElementScript.Value.SUI: _sui_button,
		GodaiElementScript.Value.KA: _ka_button,
		GodaiElementScript.Value.FU: _fu_button,
		GodaiElementScript.Value.KU: _ku_button,
	}
	for element: int in btn_map:
		var btn: Button = btn_map[element] as Button
		var unlocked: bool = alchemy.is_element_unlocked(element)
		var charge: int = alchemy.get_element_charge(element) if unlocked else 0
		if btn != null:
			btn.disabled = not unlocked or charge <= 0
			btn.text = _format_element_button_text(element, charge, unlocked)
		_style_element_button(btn, element, _active_element == element)
	var occupied_count: int = _count_occupied_slots()
	_slots_label.text = "Occupied slots: %d/9" % occupied_count
	for i: int in range(_slot_buttons.size()):
		_update_slot_button(i)
	var recipe: SeedRecipe = alchemy.preview_phase1_seed_recipe_from_grid(_slot_tokens)
	if occupied_count >= 3 and alchemy.has_method("preview_building_recipe_from_grid"):
		var building_entry = alchemy.preview_building_recipe_from_grid(_slot_tokens)
		if building_entry != null:
			_preview_label.text = "Preview: Building (%s)" % str(building_entry.building_type_key).replace("building_", "").capitalize()
		elif recipe == null:
			_preview_label.text = "Preview: --"
		else:
			_preview_label.text = "Preview: %s" % _recipe_display_name(recipe)
	elif recipe == null:
		_preview_label.text = "Preview: --"
	else:
		_preview_label.text = "Preview: %s" % _recipe_display_name(recipe)
	var craft_elements: Array[int] = []
	for token: int in _slot_tokens:
		if token == SeedCraftGridNormalizerScript.EMPTY_SLOT:
			continue
		craft_elements.append(token)
	var can_afford_selected: bool = craft_elements.is_empty() or alchemy.can_afford_mix(craft_elements)
	var pouch: SeedPouch = alchemy.get_pouch()
	var pouch_full: bool = pouch != null and pouch.is_full()
	if pouch == null:
		_pouch_status_label.text = "Pouch: 0/0 slots | 0 uses"
	else:
		_pouch_status_label.text = "Pouch: %d/%d slots | %d uses" % [pouch.size(), pouch.capacity, pouch.total_uses()]
	if pouch_full:
		_feedback_label.text = _feedback_text_for_key(SeedCraftAttemptResultScript.FEEDBACK_INVENTORY_FULL)
	elif not can_afford_selected and occupied_count > 0:
		_feedback_label.text = "Insufficient essence"
	elif not _last_feedback.is_empty():
		_feedback_label.text = _last_feedback
	elif recipe != null and _recipe_has_locked_element(alchemy, recipe):
		_feedback_label.text = _feedback_text_for_key(SeedCraftAttemptResultScript.FEEDBACK_LOCKED_KU)
	elif recipe != null:
		_feedback_label.text = "Confirm to craft this seed"
	elif occupied_count == 0:
		_feedback_label.text = "Place 1 or 2 tokens in the grid"
	else:
		_feedback_label.text = _feedback_text_for_key(SeedCraftAttemptResultScript.FEEDBACK_NO_MATCH)
	_confirm_button.disabled = false

func _update_slot_button(slot_index: int) -> void:
	var token: int = _slot_tokens[slot_index]
	var btn: Button = _slot_buttons[slot_index]
	if token == SeedCraftGridNormalizerScript.EMPTY_SLOT:
		btn.text = "+"
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.12, 0.12, 0.16)
		empty_style.border_color = Color(0.35, 0.35, 0.45)
		empty_style.border_width_left = 1
		empty_style.border_width_right = 1
		empty_style.border_width_top = 1
		empty_style.border_width_bottom = 1
		empty_style.corner_radius_top_left = 6
		empty_style.corner_radius_top_right = 6
		empty_style.corner_radius_bottom_left = 6
		empty_style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
		return
	var filled_style := StyleBoxFlat.new()
	filled_style.bg_color = Color(_ELEMENT_COLORS.get(token, Color(0.45, 0.45, 0.45))).darkened(0.35)
	filled_style.border_color = Color(_ELEMENT_COLORS.get(token, Color(0.65, 0.65, 0.65)))
	filled_style.border_width_left = 2
	filled_style.border_width_right = 2
	filled_style.border_width_top = 2
	filled_style.border_width_bottom = 2
	filled_style.corner_radius_top_left = 6
	filled_style.corner_radius_top_right = 6
	filled_style.corner_radius_bottom_left = 6
	filled_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", filled_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.text = _slot_token_short_name(token)

func _slot_token_short_name(token: int) -> String:
	match token:
		GodaiElementScript.Value.CHI:
			return "CHI"
		GodaiElementScript.Value.SUI:
			return "SUI"
		GodaiElementScript.Value.KA:
			return "KA"
		GodaiElementScript.Value.FU:
			return "FU"
		GodaiElementScript.Value.KU:
			return "KU"
		_:
			return "?"

func _count_occupied_slots() -> int:
	var count: int = 0
	for token: int in _slot_tokens:
		if token != SeedCraftGridNormalizerScript.EMPTY_SLOT:
			count += 1
	return count

func _feedback_text_for_result(result: SeedCraftAttemptResult) -> String:
	var base_text: String = _feedback_text_for_key(result.feedback_key)
	if result.guidance.is_empty():
		return base_text
	return "%s %s" % [base_text, result.guidance]

func _feedback_text_for_key(feedback_key: StringName) -> String:
	return str(_FEEDBACK_MESSAGES.get(feedback_key, "Craft attempt processed."))

func _recipe_has_locked_element(alchemy: Node, recipe: SeedRecipe) -> bool:
	if alchemy == null or recipe == null:
		return false
	for element: int in recipe.elements:
		if not alchemy.is_element_unlocked(element):
			return true
	return false

func _format_element_button_text(element: int, charge: int, unlocked: bool) -> String:
	var base: String = str(_ELEMENT_BUTTON_TEXT.get(element, "?"))
	if not unlocked:
		return "%s\nLocked" % base
	return "%s\n%d/%d" % [base, charge, KushoPoolScript.CAPACITY_PER_ELEMENT]

func _shake_button_for_element(element_id: int) -> void:
	var target: Button = null
	match element_id:
		GodaiElementScript.Value.CHI:
			target = _chi_button
		GodaiElementScript.Value.SUI:
			target = _sui_button
		GodaiElementScript.Value.KA:
			target = _ka_button
		GodaiElementScript.Value.FU:
			target = _fu_button
		GodaiElementScript.Value.KU:
			target = _ku_button
	if target == null:
		return
	var start_pos: Vector2 = target.position
	var tween: Tween = create_tween()
	tween.tween_property(target, "position", start_pos + Vector2(4.0, 0.0), 0.04)
	tween.tween_property(target, "position", start_pos + Vector2(-4.0, 0.0), 0.04)
	tween.tween_property(target, "position", start_pos, 0.04)

func _recipe_display_name(recipe: SeedRecipe) -> String:
	if recipe == null:
		return ""
	return str(_BIOME_SEED_NAMES.get(recipe.produces_biome, recipe.recipe_id))

func _on_building_craft_resolved(_building_type_key: StringName, _outcome: StringName, feedback_key: StringName, _guidance: String, _consumed: Array[int], _first_disc: bool) -> void:
_last_feedback = _feedback_text_for_key(feedback_key)
_update_ui()
