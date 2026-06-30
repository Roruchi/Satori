extends GutTest

const TileSelectorHexScript = preload("res://src/ui/tile_selector_hex.gd")
const SeedPouchDisplayScript = preload("res://src/ui/SeedPouchDisplay.gd")
const SeedAlchemyPanelScript = preload("res://src/ui/SeedAlchemyPanel.gd")
const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")

func _add_root_singleton(p_name: String, node: Node) -> void:
	var root: Node = get_tree().root
	var existing: Node = root.get_node_or_null("/root/%s" % p_name)
	if existing != null:
		root.remove_child(existing)
		existing.free()
	node.name = p_name
	root.add_child(node)

func test_building_items_show_in_place_selector_and_emit_selection() -> void:
	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()
	assert_true(growth.get_pouch().add_building(&"building_house", 2))

	var selector: Node2D = Node2D.new()
	selector.set_script(TileSelectorHexScript)
	add_child(selector)
	await get_tree().process_frame
	selector.call("_refresh_from_pouch", false)

	var labels: Array = selector.get("_seed_labels")
	assert_eq(labels.size(), 1)
	assert_eq(labels[0], "House x2")

	var selected_buildings: Array[StringName] = []
	selector.connect("building_selected", func(type_key: StringName) -> void:
		selected_buildings.append(type_key)
	)
	var centers: Array = selector.get("_centers")
	assert_gt(centers.size(), 0)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.position = centers[0]
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	selector.call("_input", click)
	selector.call("_input", click)

	assert_eq(selected_buildings, [&"building_house"])
	remove_child(selector)
	selector.free()
	if growth.get_parent() != null:
		growth.get_parent().remove_child(growth)
	growth.free()

func test_building_place_selector_resolves_structure_sprites() -> void:
	var selector: Node2D = Node2D.new()
	selector.set_script(TileSelectorHexScript)
	add_child(selector)
	await get_tree().process_frame

	var catalog: RefCounted = StructureCatalogDataScript.new()
	for entry: Dictionary in catalog.get_all_entries():
		var structure_id: String = str(entry.get("structure_id", ""))
		if not (structure_id.begins_with("form_") or structure_id.begins_with("building_")):
			continue
		var texture: Texture2D = selector.call("_building_texture_for_key", StringName(structure_id)) as Texture2D
		assert_not_null(texture, "%s should resolve to a structure sprite texture" % structure_id)

	remove_child(selector)
	selector.free()

func test_clicking_selected_place_item_clears_selection() -> void:
	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()
	assert_true(growth.get_pouch().add_building(&"building_house", 2))

	var selector: Node2D = Node2D.new()
	selector.set_script(TileSelectorHexScript)
	add_child(selector)
	await get_tree().process_frame
	selector.call("_refresh_from_pouch", false)

	var selected_buildings: Array[StringName] = []
	var selected_biomes: Array[int] = []
	var cleared_events: Array[bool] = []
	selector.connect("building_selected", func(type_key: StringName) -> void:
		selected_buildings.append(type_key)
	)
	selector.connect("biome_selected", func(biome: int) -> void:
		selected_biomes.append(biome)
	)
	selector.connect("selection_cleared", func() -> void:
		cleared_events.append(true)
	)

	var centers: Array = selector.get("_centers")
	assert_gt(centers.size(), 0)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.position = centers[0]
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	selector.call("_input", click)

	assert_eq(selected_buildings, [])
	assert_eq(selected_biomes, [BiomeType.Value.NONE])
	assert_eq(cleared_events.size(), 1)
	assert_false(bool(selector.call("has_active_selection")))

	remove_child(selector)
	selector.free()
	if growth.get_parent() != null:
		growth.get_parent().remove_child(growth)
	growth.free()

func test_building_items_show_in_pouch_status() -> void:
	var growth: SeedGrowthServiceNode = SeedGrowthServiceNode.new()
	_add_root_singleton("SeedGrowthService", growth)
	growth._ready()
	assert_true(growth.get_pouch().add_building(&"building_house", 2))

	var display: Label = Label.new()
	display.set_script(SeedPouchDisplayScript)
	add_child(display)
	await get_tree().process_frame
	display.call("_refresh")

	assert_eq(display.text, "1/8 | House x2")
	remove_child(display)
	display.free()
	if growth.get_parent() != null:
		growth.get_parent().remove_child(growth)
	growth.free()

func test_building_items_show_in_craft_panel_pouch_status() -> void:
	var pouch: SeedPouch = SeedPouch.new()
	assert_true(pouch.add_building(&"building_house", 2))

	var panel: PanelContainer = PanelContainer.new()
	panel.set_script(SeedAlchemyPanelScript)
	assert_eq(panel.call("_format_place_inventory_status", pouch), "1/8 | House x2")
	panel.free()
