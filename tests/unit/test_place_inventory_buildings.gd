extends GutTest

const TileSelectorHexScript = preload("res://src/ui/tile_selector_hex.gd")

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

	assert_eq(selected_buildings, [&"building_house"])
	remove_child(selector)
	selector.free()
	if growth.get_parent() != null:
		growth.get_parent().remove_child(growth)
	growth.free()
