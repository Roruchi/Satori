class_name SeedAlchemyPanel
extends PanelContainer

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const RECIPE_DISPLAY_NAMES: Dictionary = {
	&"recipe_chi": "Stone Seed",
	&"recipe_sui": "River Seed",
	&"recipe_ka": "Ember Seed",
	&"recipe_fu": "Meadow Seed",
	&"recipe_chi_sui": "Clay Seed",
	&"recipe_chi_ka": "Desert Seed",
	&"recipe_chi_fu": "Dune Seed",
	&"recipe_sui_ka": "Hot Spring Seed",
	&"recipe_sui_fu": "Bog Seed",
	&"recipe_ka_fu": "Cinder Heath Seed",
}

@onready var _preview_label: Label = $VBox/Preview
@onready var _slots_label: Label = $VBox/Slots
@onready var _confirm_button: Button = $VBox/Actions/ConfirmButton
@onready var _clear_button: Button = $VBox/Actions/ClearButton
@onready var _chi_button: Button = $VBox/Elements/ChiButton
@onready var _sui_button: Button = $VBox/Elements/SuiButton
@onready var _ka_button: Button = $VBox/Elements/KaButton
@onready var _fu_button: Button = $VBox/Elements/FuButton
@onready var _ku_button: Button = $VBox/Elements/KuButton

var _selected: Array[int] = []

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
	_update_ui()

func _on_element_unlocked(_element_id: int) -> void:
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
	var selected_labels: Array[String] = []
	for value: int in _selected:
		selected_labels.append(str(GodaiElementScript.DISPLAY_NAMES.get(value, "?")))
	_slots_label.text = "Slots: %s" % [", ".join(selected_labels)]
	var recipe: SeedRecipe = alchemy.lookup_recipe(_selected)
	if recipe == null:
		_preview_label.text = "unknown combination"
	else:
		_preview_label.text = str(RECIPE_DISPLAY_NAMES.get(recipe.recipe_id, recipe.recipe_id))
	var pouch: SeedPouch = alchemy.get_pouch()
	var pouch_full: bool = pouch != null and pouch.is_full()
	_confirm_button.disabled = recipe == null or pouch_full

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
