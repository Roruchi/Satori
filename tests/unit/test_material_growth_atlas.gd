extends GutTest

const GardenViewScript = preload("res://src/grid/GardenView.gd")
const ATLAS_PATH: String = "res://assets/materials/material_growth_atlas.png"

func test_material_growth_atlas_asset_is_available_and_transparent() -> void:
	assert_true(FileAccess.file_exists(ATLAS_PATH))
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(ATLAS_PATH))
	assert_not_null(image)
	assert_eq(image.get_width(), 1254)
	assert_eq(image.get_height(), 1254)
	assert_eq(image.get_pixel(0, 0).a, 0.0)

func test_material_growth_atlas_regions_cover_all_material_stages() -> void:
	var view: Node2D = GardenViewScript.new()
	add_child(view)
	var material_ids: Array[StringName] = [&"living_wood", &"reed_fiber", &"spirit_stone", &"ember_clay"]
	for material_index: int in range(material_ids.size()):
		for stage: int in range(4):
			var region: Rect2 = view._material_atlas_region(material_ids[material_index], stage)
			assert_gt(region.size.x, 0.0)
			assert_gt(region.size.y, 0.0)
			assert_eq(region.position.x, region.size.x * float(stage))
			assert_eq(region.position.y, region.size.y * float(material_index))
	assert_eq(view._material_atlas_region(&"unknown", 0), Rect2())
	remove_child(view)
	view.free()
