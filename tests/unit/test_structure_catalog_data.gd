extends GutTest

const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")

func test_structure_catalog_exposes_recipe_effects_for_forms() -> void:
	var catalog: RefCounted = StructureCatalogDataScript.new()

	var root_network: Dictionary = catalog.get_entry("form_root_network")
	assert_true(_has_effect(root_network, "material_spawn_speed"), "Root Network should expose its material speed effect")

	var wind_chime: Dictionary = catalog.get_entry("form_wind_chime")
	assert_true(_has_effect(wind_chime, "auto_harvest"), "Wind Chime should expose its auto-harvest effect")

	var kiln_heart: Dictionary = catalog.get_entry("form_kiln_heart")
	assert_true(_has_effect(kiln_heart, "material_spawn_speed"), "Kiln Heart should expose its fire-material speed effect")

	var dew_bowl: Dictionary = catalog.get_entry("form_dew_bowl")
	assert_true(_has_effect(dew_bowl, "storage_cap"), "Dew Bowl should expose its essence cap effect")

	var tiny_shrine: Dictionary = catalog.get_entry("form_tiny_shrine")
	assert_true(_has_effect(tiny_shrine, "essence_generator"), "Tiny Shrine should expose its essence generator effect")

	var meadow_dwelling: Dictionary = catalog.get_entry("building_meadow_dwelling")
	assert_true(_has_effect(meadow_dwelling, "dwelling"), "Meadow Dwelling should expose its housing effect")

	var stone_hollow: Dictionary = catalog.get_entry("building_stone_hollow")
	assert_true(_has_effect(stone_hollow, "dwelling"), "Stone Hollow should expose its housing effect")

	var wind_hollow: Dictionary = catalog.get_entry("building_wind_hollow")
	assert_true(_has_effect(wind_hollow, "dwelling"), "Wind Hollow should expose its housing effect")

	var reed_nest: Dictionary = catalog.get_entry("building_reed_nest")
	assert_true(_has_effect(reed_nest, "dwelling"), "Reed Nest should expose its water housing effect")

	var fox_den: Dictionary = catalog.get_entry("building_fox_den")
	assert_true(_has_effect(fox_den, "dwelling"), "Fox Den should expose its housing effect")
	assert_true(_has_effect(fox_den, "satori_rate_bonus"), "Fox Den should expose its upgraded Satori rate effect")


func test_structure_catalog_entries_have_loadable_assets() -> void:
	var catalog: RefCounted = StructureCatalogDataScript.new()
	for entry: Dictionary in catalog.get_all_entries():
		var structure_id: String = str(entry.get("structure_id", ""))
		var asset_path: String = str(entry.get("asset_path", ""))
		var sprite_frames_path: String = str(entry.get("sprite_frames_path", ""))
		assert_false(asset_path.is_empty(), "%s should have a frame asset path" % structure_id)
		assert_true(FileAccess.file_exists(asset_path), "%s frame PNG should exist" % structure_id)
		assert_true(FileAccess.file_exists(sprite_frames_path), "%s should have sprite_frames.tres metadata" % structure_id)
		var texture: Texture2D = _load_texture_resource(asset_path)
		assert_not_null(texture, "%s frame PNG should load as a Texture2D" % structure_id)


func test_ritual_discovery_aliases_have_structure_assets() -> void:
	var catalog: RefCounted = StructureCatalogDataScript.new()

	var warm_hollow: Dictionary = catalog.get_entry("disc_warm_hollow")
	assert_true(str(warm_hollow.get("asset_path", "")).ends_with("/warm_hollow/frames/idle/down/frame_0000.png"))
	assert_true(FileAccess.file_exists(str(warm_hollow.get("asset_path", ""))))

	var meadow_hollow: Dictionary = catalog.get_entry("disc_meadow_hollow")
	assert_true(str(meadow_hollow.get("asset_path", "")).ends_with("/meadow_hollow/frames/idle/down/frame_0000.png"))
	assert_true(FileAccess.file_exists(str(meadow_hollow.get("asset_path", ""))))

	var stone_hollow: Dictionary = catalog.get_entry("disc_stone_hollow")
	assert_true(str(stone_hollow.get("asset_path", "")).ends_with("/stone_hollow/frames/idle/down/frame_0000.png"))
	assert_true(FileAccess.file_exists(str(stone_hollow.get("asset_path", ""))))

	var wind_chime: Dictionary = catalog.get_entry("disc_wind_chime")
	assert_true(str(wind_chime.get("asset_path", "")).ends_with("/wind_chime/frames/idle/down/frame_0000.png"))
	assert_true(FileAccess.file_exists(str(wind_chime.get("asset_path", ""))))

func test_building_hover_lines_stay_short_and_scannable() -> void:
	var catalog: RefCounted = StructureCatalogDataScript.new()

	var meadow_lines: Array[String] = catalog.get_hover_lines("building_meadow_dwelling")
	assert_true(_has_line_containing(meadow_lines, "Meadow dwelling"))
	assert_true(_has_line_containing(meadow_lines, "Meadow Hollow"))

	var water_lines: Array[String] = catalog.get_hover_lines("building_reed_nest")
	assert_true(_has_line_containing(water_lines, "Water dwelling"))
	assert_true(_has_line_containing(water_lines, "Reed Nest"))

	var wind_lines: Array[String] = catalog.get_hover_lines("building_wind_hollow")
	assert_true(_has_line_containing(wind_lines, "Wind dwelling"))
	assert_true(_has_line_containing(wind_lines, "Warm Hollow"))

	var stone_lines: Array[String] = catalog.get_hover_lines("building_stone_hollow")
	assert_true(_has_line_containing(stone_lines, "Stone dwelling"))
	assert_true(_has_line_containing(stone_lines, "Stone Hollow"))

	var fire_lines: Array[String] = catalog.get_hover_lines("building_scorched_hollow")
	assert_true(_has_line_containing(fire_lines, "Fire dwelling"))
	assert_true(_has_line_containing(fire_lines, "Scorched Hollow"))
	for lines: Array[String] in [meadow_lines, water_lines, wind_lines, stone_lines, fire_lines]:
		assert_lte(lines.size(), 2)
		for line: String in lines:
			assert_lte(line.length(), 32)
			assert_false(line.contains("then place"))
			assert_false(line.begins_with("Effect:"))


func test_satori_service_structure_definitions_include_effects_and_assets() -> void:
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)

	var lantern: Dictionary = service.get_structure_definition("disc_misogi_spring_shrine")
	assert_eq(str(lantern.get("effect_type", "")), "guidance_lantern")
	assert_eq(int((lantern.get("effect_params", {}) as Dictionary).get("pacified_max", 0)), 3)
	assert_true(_has_effect(lantern, "guidance_lantern"))
	assert_false(str(lantern.get("asset_path", "")).is_empty())

	var pagoda: Dictionary = service.get_structure_definition("disc_pagoda_of_the_five")
	assert_true(_has_effect(pagoda, "pagoda_passive"))
	assert_true(_has_effect(pagoda, "housing"))
	assert_false(str(pagoda.get("sprite_frames_path", "")).is_empty())

	service.queue_free()


func _has_effect(entry: Dictionary, effect_type: String) -> bool:
	var effects_variant: Variant = entry.get("effects", [])
	if not (effects_variant is Array):
		return false
	for effect_variant: Variant in effects_variant as Array:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant as Dictionary
		if str(effect.get("type", "")) == effect_type:
			return true
	return false

func _has_line_containing(lines: Array[String], needle: String) -> bool:
	for line: String in lines:
		if line.contains(needle):
			return true
	return false

func _load_texture_resource(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		var loaded_texture: Texture2D = ResourceLoader.load(path, "Texture2D") as Texture2D
		if loaded_texture != null:
			return loaded_texture
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null
