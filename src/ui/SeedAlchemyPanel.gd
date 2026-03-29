class_name SeedAlchemyPanel
extends PanelContainer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const KushoPoolScript = preload("res://src/autoloads/kusho_pool.gd")

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

@onready var _preview_label: Label = $VBox/Preview
@onready var _pouch_status_label: Label = $VBox/PouchStatus
@onready var _feedback_label: Label = $VBox/Feedback
@onready var _slots_label: Label = $VBox/Slots
@onready var _confirm_button: Button = $VBox/Actions/ConfirmButton
@onready var _clear_button: Button = $VBox/Actions/ClearButton
@onready var _chi_button: Button = $VBox/Elements/ChiButton
@onready var _sui_button: Button = $VBox/Elements/SuiButton
@onready var _ka_button: Button = $VBox/Elements/KaButton
@onready var _fu_button: Button = $VBox/Elements/FuButton
@onready var _ku_button: Button = $VBox/Elements/KuButton

var _selected: Array[int] = []
var _last_feedback: String = ""

func _ready() -> void:
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
		_style_element_button(buttons[i], elements[i], false)

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
	if _selected.has(element_id):
		_shake_button_for_element(element_id)
		return
	if _selected.size() >= 2:
		_shake_button_for_element(element_id)
		return
	_selected.append(element_id)
	_update_ui()

func _on_confirm_pressed() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null:
		return
	if alchemy.craft_seed(_selected):
		_selected.clear()
	_update_ui()

func _on_clear_pressed() -> void:
	_selected.clear()
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
		_style_element_button(btn, element, _selected.has(element))
	if _selected.is_empty():
		_slots_label.text = "Select 1 or 2 elements"
	else:
		var labels: Array[String] = []
		for value: int in _selected:
			labels.append(str(GodaiElementScript.DISPLAY_NAMES.get(value, "?")))
		_slots_label.text = " + ".join(labels)
	var recipe: SeedRecipe = alchemy.lookup_recipe(_selected)
	var can_afford_selected: bool = _selected.is_empty() or alchemy.can_afford_mix(_selected)
	if recipe == null:
		_preview_label.text = "\u2192  \u2026"
	else:
		_preview_label.text = "\u2192  %s" % _recipe_display_name(recipe)
	var pouch: SeedPouch = alchemy.get_pouch()
	var pouch_full: bool = pouch != null and pouch.is_full()
	if pouch == null:
		_pouch_status_label.text = "Pouch: 0/0 slots | 0 uses"
	else:
		_pouch_status_label.text = "Pouch: %d/%d slots | %d uses" % [pouch.size(), pouch.capacity, pouch.total_uses()]
	if pouch_full:
		_feedback_label.text = "Pouch full"
	elif not can_afford_selected and not _selected.is_empty():
		_feedback_label.text = "Insufficient essence"
	elif not _last_feedback.is_empty():
		_feedback_label.text = _last_feedback
	elif recipe != null:
		_feedback_label.text = "Confirm to craft"
	elif _selected.size() == 2:
		_feedback_label.text = "No stable resonance for that pairing"
	elif _selected.size() == 1:
		_feedback_label.text = "Select one more element"
	else:
		_feedback_label.text = ""
	_confirm_button.disabled = recipe == null or pouch_full or not can_afford_selected

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
