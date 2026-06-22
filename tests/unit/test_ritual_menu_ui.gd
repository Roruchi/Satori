extends GutTest

func test_ritual_panel_scene_uses_three_slots_and_ritual_copy() -> void:
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	assert_not_null(panel.get_node_or_null("VBox/Grid/Slot0"))
	assert_not_null(panel.get_node_or_null("VBox/Grid/Slot1"))
	assert_not_null(panel.get_node_or_null("VBox/Grid/Slot2"))
	assert_null(panel.get_node_or_null("VBox/Grid/Slot3"))
	assert_null(panel.get_node_or_null("VBox/Grid/Slot8"))
	assert_not_null(panel.get_node_or_null("VBox/Materials/LivingWoodButton"))
	assert_not_null(panel.get_node_or_null("VBox/ChoicePrompt"))

	var slots_label: Label = panel.get_node("VBox/Slots") as Label
	assert_eq(slots_label.text, "Ritual slots: 0/3")
	var slot0: Button = panel.get_node("VBox/Grid/Slot0") as Button
	assert_eq(slot0.text, "Slot 1\nTap to choose")
	var confirm_button: Button = panel.get_node("VBox/Actions/ConfirmButton") as Button
	assert_eq(confirm_button.text, "Perform Ritual")

	remove_child(panel)
	panel.free()

func test_ritual_slot_first_selection_fills_selected_slot() -> void:
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	panel.call("_on_slot_pressed", 1)
	panel.call("_on_input_tapped", "essence:fire")

	var keys: Array = panel.get("_slot_keys")
	assert_eq(keys[0], "")
	assert_eq(keys[1], "essence:fire")
	assert_eq(keys[2], "")
	var slot1: Button = panel.get_node("VBox/Grid/Slot1") as Button
	assert_eq(slot1.text, "Slot 2\nFire")
	var choice_prompt: Label = panel.get_node("VBox/ChoicePrompt") as Label
	assert_eq(choice_prompt.text, "Slot 3 selected: choose essence or material")

	remove_child(panel)
	panel.free()

func test_ritual_slot_first_selection_rejects_duplicate_inputs() -> void:
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	panel.call("_on_slot_pressed", 0)
	panel.call("_on_input_tapped", "essence:fire")
	panel.call("_on_slot_pressed", 1)
	panel.call("_on_input_tapped", "essence:fire")

	var keys: Array = panel.get("_slot_keys")
	assert_eq(keys[0], "essence:fire")
	assert_eq(keys[1], "")
	var feedback: Label = panel.get_node("VBox/Feedback") as Label
	assert_eq(feedback.text, "Each slot must be unique.")

	remove_child(panel)
	panel.free()

func test_hud_separates_placeables_essence_and_materials() -> void:
	var scene: PackedScene = load("res://scenes/UI/HUD.tscn") as PackedScene
	assert_not_null(scene)
	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	var pouch_label: Label = hud.get_node("Root/TopBar/InventoryStack/SeedPouchDisplay") as Label
	var material_label: Label = hud.get_node("Root/TopBar/InventoryStack/MaterialMeterLabel") as Label
	var essence_title: Label = hud.get_node("Root/TopBar/ElementMeterRow/EssenceTitle") as Label
	var debug_label: Label = hud.get_node("Root/DebugInfoLabel") as Label
	assert_true(pouch_label.text.begins_with("Placeables:"))
	assert_eq(material_label.text, "Materials: Living Wood x3")
	assert_eq(essence_title.text, "Essence:")
	assert_gt(debug_label.offset_top, 88.0)

	remove_child(hud)
	hud.free()

func test_ritual_tab_lays_out_panel_without_screen_resize() -> void:
	var scene: PackedScene = load("res://scenes/UI/HUD.tscn") as PackedScene
	assert_not_null(scene)
	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	hud.call("_set_mode", 1)
	await get_tree().process_frame

	var panel: Control = hud.get_node("Root/Panels/SeedAlchemyPanel") as Control
	assert_true(panel.visible)
	assert_true(panel.size.x >= 460.0)
	assert_true(panel.size.y >= 392.0)
	assert_true(panel.position.x >= 0.0)
	assert_true(panel.position.y >= 0.0)

	remove_child(hud)
	hud.free()
