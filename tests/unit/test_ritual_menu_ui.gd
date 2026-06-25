extends GutTest

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")

class DiscoveryStub:
	extends Node
	var discovered_ids: Array[StringName] = []
	func get_discovered_ids() -> Array[StringName]:
		return discovered_ids

func _add_root_singleton(p_name: String, node: Node) -> void:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % p_name)
	if existing != null:
		root.remove_child(existing)
		existing.free()
	node.name = p_name
	root.add_child(node)

func _setup_context() -> Dictionary:
	var discovery: DiscoveryStub = DiscoveryStub.new()
	_add_root_singleton("DiscoveryPersistence", discovery)

	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()

	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	_add_root_singleton("SeedAlchemyService", alchemy)
	alchemy._ready()

	return {"growth": growth, "alchemy": alchemy, "discovery": discovery}

func _cleanup_context(ctx: Dictionary) -> void:
	for key: String in ["growth", "alchemy", "discovery"]:
		var node_variant: Variant = ctx.get(key, null)
		if node_variant is Node:
			var node: Node = node_variant as Node
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()

func test_ritual_panel_scene_uses_three_slots_and_ritual_copy() -> void:
	var ctx: Dictionary = _setup_context()
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
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_essence/Grid/Input_essence_earth"))
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_essence/Grid/Input_essence_wind"))
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_material/Grid/Input_material_living_wood"))
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_material/Grid/Input_material_reed_fiber"))
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_material/Grid/Input_material_spirit_stone"))
	assert_not_null(panel.get_node_or_null("VBox/PickerScroll/PickerSections/Section_material/Grid/Input_material_ember_clay"))
	assert_not_null(panel.get_node_or_null("VBox/ChoicePrompt"))

	var slots_label: Label = panel.get_node("VBox/Slots") as Label
	assert_eq(slots_label.text, "Ritual slots: 0/3")
	var slot0: Button = panel.get_node("VBox/Grid/Slot0") as Button
	var slot0_title: Label = slot0.get_node("Contents/Labels/Title") as Label
	var slot0_detail: Label = slot0.get_node("Contents/Labels/Detail") as Label
	assert_eq(slot0.text, "")
	assert_eq(slot0_title.text, "Slot 1")
	assert_eq(slot0_detail.text, "Choose input")
	var wind_button: Button = panel.get_node("VBox/PickerScroll/PickerSections/Section_essence/Grid/Input_essence_wind") as Button
	var wind_icon: TextureRect = wind_button.get_node("Contents/Icon") as TextureRect
	var wind_title: Label = wind_button.get_node("Contents/Labels/Title") as Label
	var wind_detail: Label = wind_button.get_node("Contents/Labels/Detail") as Label
	assert_eq(wind_button.text, "")
	assert_eq(wind_title.text, "Fu")
	assert_eq(wind_detail.text, "Wind Essence 3/3")
	assert_not_null(wind_icon.texture)
	assert_true(wind_icon.texture is AtlasTexture)
	assert_eq((wind_icon.texture as AtlasTexture).atlas.resource_path, "res://assets/ritual/ritual_input_icon_spritesheet.png")
	var confirm_button: Button = panel.get_node("VBox/Actions/ConfirmButton") as Button
	assert_eq(confirm_button.text, "Perform Ritual")

	remove_child(panel)
	panel.free()
	_cleanup_context(ctx)

func test_ritual_slot_first_selection_fills_selected_slot() -> void:
	var ctx: Dictionary = _setup_context()
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
	var slot1_icon: TextureRect = slot1.get_node("Contents/Icon") as TextureRect
	var slot1_detail: Label = slot1.get_node("Contents/Labels/Detail") as Label
	assert_eq(slot1.text, "")
	assert_true(slot1_icon.visible)
	assert_eq(slot1_detail.text, "Ka")
	var choice_prompt: Label = panel.get_node("VBox/ChoicePrompt") as Label
	assert_eq(choice_prompt.text, "Slot 3 selected: choose godai essence or material")

	remove_child(panel)
	panel.free()
	_cleanup_context(ctx)

func test_ritual_panel_previews_single_wind_as_meadow_seed() -> void:
	var ctx: Dictionary = _setup_context()
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	panel.call("_on_slot_pressed", 0)
	panel.call("_on_input_tapped", "essence:wind")

	var keys: Array = panel.get("_slot_keys")
	assert_eq(keys[0], "essence:wind")
	var slot0: Button = panel.get_node("VBox/Grid/Slot0") as Button
	var preview: Label = panel.get_node("VBox/Preview") as Label
	var feedback: Label = panel.get_node("VBox/Feedback") as Label
	var slot0_icon: TextureRect = slot0.get_node("Contents/Icon") as TextureRect
	var slot0_detail: Label = slot0.get_node("Contents/Labels/Detail") as Label
	assert_eq(slot0.text, "")
	assert_true(slot0_icon.visible)
	assert_eq(slot0_detail.text, "Fu")
	assert_eq(preview.text, "Preview: Meadow Seed")
	assert_eq(feedback.text, "Confirm to shape Meadow Seed.")

	remove_child(panel)
	panel.free()
	_cleanup_context(ctx)

func test_ritual_panel_updates_reed_fiber_material_button() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.add_material_for_testing(&"reed_fiber", 1)
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	var reed_button: Button = panel.get_node("VBox/PickerScroll/PickerSections/Section_material/Grid/Input_material_reed_fiber") as Button
	var reed_title: Label = reed_button.get_node("Contents/Labels/Title") as Label
	var reed_detail: Label = reed_button.get_node("Contents/Labels/Detail") as Label
	var reed_input_icon: TextureRect = reed_button.get_node("Contents/Icon") as TextureRect
	assert_eq(reed_button.text, "")
	assert_eq(reed_title.text, "Reed Fiber")
	assert_eq(reed_detail.text, "x1")
	assert_false(reed_button.disabled)
	assert_not_null(reed_input_icon.texture)
	assert_true(reed_input_icon.texture is AtlasTexture)

	remove_child(panel)
	panel.free()
	_cleanup_context(ctx)

func test_ritual_panel_blocks_depleted_essence_for_single_seed() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	alchemy.set_element_charge_for_testing(GodaiElementScript.Value.FU, 0)
	var scene: PackedScene = load("res://scenes/UI/SeedAlchemyPanel.tscn") as PackedScene
	assert_not_null(scene)
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame

	var wind_button: Button = panel.get_node("VBox/PickerScroll/PickerSections/Section_essence/Grid/Input_essence_wind") as Button
	var wind_title: Label = wind_button.get_node("Contents/Labels/Title") as Label
	var wind_detail: Label = wind_button.get_node("Contents/Labels/Detail") as Label
	assert_eq(wind_title.text, "Fu")
	assert_eq(wind_detail.text, "Wind Essence 0/3")
	assert_true(wind_button.disabled)
	panel.call("_on_input_tapped", "essence:wind")
	var slot0: Button = panel.get_node("VBox/Grid/Slot0") as Button
	var slot0_detail: Label = slot0.get_node("Contents/Labels/Detail") as Label
	assert_eq(slot0.text, "")
	assert_eq(slot0_detail.text, "Choose input")
	var preview: Label = panel.get_node("VBox/Preview") as Label
	assert_eq(preview.text, "Preview: --")

	remove_child(panel)
	panel.free()
	_cleanup_context(ctx)

func test_ritual_slot_first_selection_rejects_duplicate_inputs() -> void:
	var ctx: Dictionary = _setup_context()
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
	_cleanup_context(ctx)

func test_hud_separates_placeables_essence_and_materials() -> void:
	var ctx: Dictionary = _setup_context()
	var alchemy: SeedAlchemyServiceNode = ctx["alchemy"]
	var scene: PackedScene = load("res://scenes/UI/HUD.tscn") as PackedScene
	assert_not_null(scene)
	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	var pouch_label: Label = hud.get_node("Root/TopBar/InventoryStack/SeedPouchDisplay") as Label
	var material_label: Label = hud.get_node("Root/TopBar/InventoryStack/MaterialMeterLabel") as Label
	var material_slot_row: HBoxContainer = hud.get_node("Root/TopBar/InventoryStack/MaterialSlotRow") as HBoxContainer
	var essence_title: Label = hud.get_node("Root/TopBar/ElementMeterRow/EssenceTitle") as Label
	var debug_label: Label = hud.get_node("Root/DebugInfoLabel") as Label
	assert_true(pouch_label.text.begins_with("Placeables:"))
	assert_eq(material_label.text, "Materials:")
	assert_not_null(material_slot_row.get_node_or_null("MaterialSlot_reed_fiber"))
	var reed_count_label: Label = material_slot_row.get_node("MaterialSlot_reed_fiber/Contents/CountLabel") as Label
	var reed_icon: TextureRect = material_slot_row.get_node("MaterialSlot_reed_fiber/Contents/Icon") as TextureRect
	var reed_icon_fallback: Label = material_slot_row.get_node("MaterialSlot_reed_fiber/Contents/IconFallback") as Label
	var ember_count_label: Label = material_slot_row.get_node("MaterialSlot_ember_clay/Contents/CountLabel") as Label
	var ember_icon_fallback: Label = material_slot_row.get_node("MaterialSlot_ember_clay/Contents/IconFallback") as Label
	assert_eq(reed_count_label.text, "0")
	assert_true(reed_icon.texture is AtlasTexture)
	assert_eq((reed_icon.texture as AtlasTexture).atlas.resource_path, "res://assets/ritual/ritual_input_icon_spritesheet.png")
	assert_eq(reed_icon_fallback.text, "RF")
	assert_eq(ember_count_label.text, "0")
	assert_eq(ember_icon_fallback.text, "EC")
	assert_eq(essence_title.text, "Essence:")
	assert_gt(debug_label.offset_top, 88.0)

	alchemy.add_material_for_testing(&"reed_fiber", 2)
	alchemy.add_material_for_testing(&"spirit_stone", 1)
	await get_tree().process_frame
	assert_eq(material_label.text, "Materials:")
	assert_eq(reed_count_label.text, "2")
	assert_eq(ember_count_label.text, "0")

	remove_child(hud)
	hud.free()
	_cleanup_context(ctx)

func test_ritual_tab_lays_out_panel_without_screen_resize() -> void:
	var ctx: Dictionary = _setup_context()
	var scene: PackedScene = load("res://scenes/UI/HUD.tscn") as PackedScene
	assert_not_null(scene)
	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	hud.call("_set_mode", 1)
	await get_tree().process_frame

	var panel: Control = hud.get_node("Root/Panels/SeedAlchemyPanel") as Control
	assert_true(panel.visible)
	assert_true(panel.size.x >= 360.0)
	assert_true(panel.size.y >= 260.0)
	assert_true(panel.position.x >= 0.0)
	assert_true(panel.position.y >= 0.0)

	remove_child(hud)
	hud.free()
	_cleanup_context(ctx)
