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


func test_structure_catalog_entries_have_loadable_assets() -> void:
	var catalog: RefCounted = StructureCatalogDataScript.new()
	for entry: Dictionary in catalog.get_all_entries():
		var structure_id: String = str(entry.get("structure_id", ""))
		var asset_path: String = str(entry.get("asset_path", ""))
		var sprite_frames_path: String = str(entry.get("sprite_frames_path", ""))
		assert_false(asset_path.is_empty(), "%s should have a frame asset path" % structure_id)
		assert_true(FileAccess.file_exists(asset_path), "%s frame PNG should exist" % structure_id)
		assert_true(FileAccess.file_exists(sprite_frames_path), "%s should have sprite_frames.tres metadata" % structure_id)
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(asset_path))
		assert_not_null(image, "%s frame PNG should load as an Image" % structure_id)


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
