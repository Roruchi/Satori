extends GutTest

const RitualRecipeCatalogScript = preload("res://src/seeds/RitualRecipeCatalog.gd")
const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")

const PRIMARY_FORM_IDS: Array[StringName] = [
	&"form_warm_hollow",
	&"form_fox_den",
	&"form_dew_bowl",
	&"form_wind_chime",
]
const PRIMARY_BUILDING_IDS: Array[String] = [
	"building_meadow_dwelling",
	"building_fox_den",
	"building_dew_bowl",
	"building_wind_chime",
]
const PRIMARY_SPIRIT_IDS: Array[String] = [
	"spirit_red_fox",
	"spirit_mist_stag",
	"spirit_suijin",
]
const PRIMARY_SEED_RESULT_IDS: Array[StringName] = [
	&"recipe_fu",
	&"recipe_ku",
	&"recipe_chi_ku",
]
const PRIMARY_RELEASE_UI_FILES: Array[String] = [
	"res://scenes/TitleScreen.tscn",
	"res://scenes/UI/HUD.tscn",
	"res://scenes/UI/SettingsMenu.tscn",
	"res://src/ui/HUDController.gd",
	"res://src/ui/SeedAlchemyPanel.gd",
	"res://src/seeds/RitualAttemptResult.gd",
]
const BROKEN_LOOKING_COPY: Array[String] = [
	"placeholder",
	"todo",
	"fixme",
	"coming soon",
	"not implemented",
	"tbd",
	"wip",
	"lorem",
	"missing texture",
	"unknown helper",
]


func test_primary_alpha_structure_chain_has_rituals_assets_and_effects() -> void:
	var ritual_catalog: RitualRecipeCatalog = RitualRecipeCatalogScript.new()
	var structure_catalog: StructureCatalogData = StructureCatalogDataScript.new()

	for form_id: StringName in PRIMARY_FORM_IDS:
		var form_entry: RitualRecipeCatalog.RitualEntry = ritual_catalog.get_form_entry(form_id)
		assert_not_null(form_entry, "%s should have a ritual form entry" % str(form_id))
		assert_false(form_entry.input_keys.is_empty(), "%s should list ritual inputs" % str(form_id))
		assert_false(str(form_entry.discovery_id).is_empty(), "%s should expose a Codex discovery id" % str(form_id))

	for building_id: String in PRIMARY_BUILDING_IDS:
		var structure_entry: Dictionary = structure_catalog.get_entry(building_id)
		assert_false(structure_entry.is_empty(), "%s should be in StructureCatalogData" % building_id)
		assert_false(str(structure_entry.get("asset_path", "")).is_empty(), "%s should expose an asset path" % building_id)
		assert_true(FileAccess.file_exists(str(structure_entry.get("asset_path", ""))), "%s asset should exist" % building_id)
		assert_true(_effects_are_present(structure_entry), "%s should expose runtime effects" % building_id)

	var fox_den: Dictionary = structure_catalog.get_entry("building_fox_den")
	assert_true(_has_effect(fox_den, "dwelling"), "Fox Den should remain a dwelling")
	assert_true(_has_effect(fox_den, "satori_rate_bonus"), "Fox Den should keep Red Fox Satori bonus wiring")
	assert_true(str(fox_den.get("description", "")).contains("doubles Red Fox Satori generation"))


func test_primary_alpha_spirits_are_cataloged_and_have_assets() -> void:
	var catalog_data: SpiritCatalogData = SpiritCatalogData.new()
	var entries_by_id: Dictionary = {}
	for entry: Dictionary in catalog_data.get_entries():
		entries_by_id[str(entry.get("spirit_id", ""))] = entry

	for spirit_id: String in PRIMARY_SPIRIT_IDS:
		assert_true(entries_by_id.has(spirit_id), "%s should be cataloged" % spirit_id)
		var frame_path: String = "res://assets/spirits/%s/frames/idle/down/frame_0000.png" % spirit_id
		var sprite_frames_path: String = "res://assets/spirits/%s/sprite_frames.tres" % spirit_id
		assert_true(FileAccess.file_exists(frame_path), "%s idle frame should exist" % spirit_id)
		assert_true(FileAccess.file_exists(sprite_frames_path), "%s sprite frames should exist" % spirit_id)


func test_primary_alpha_seed_results_remain_available() -> void:
	var ritual_catalog: RitualRecipeCatalog = RitualRecipeCatalogScript.new()
	var seen: Dictionary = {}
	for entry: RitualRecipeCatalog.RitualEntry in ritual_catalog.get_seed_entries():
		seen[entry.result_id] = true
	for result_id: StringName in PRIMARY_SEED_RESULT_IDS:
		assert_true(seen.has(result_id), "%s should remain a seed ritual result" % str(result_id))


func test_codex_registers_primary_alpha_content_entries() -> void:
	var codex: CodexServiceNode = CodexServiceNode.new()
	add_child(codex)
	codex._ready()

	for entry_id: StringName in [&"spirit_red_fox", &"spirit_mist_stag", &"spirit_suijin", &"disc_warm_hollow", &"disc_fox_den", &"disc_dew_bowl", &"disc_wind_chime"]:
		assert_true(codex.is_entry_hinted(entry_id), "%s should be hinted in Codex before discovery" % str(entry_id))

	codex.queue_free()


func test_primary_alpha_route_guidance_is_practical() -> void:
	var codex: CodexServiceNode = CodexServiceNode.new()
	add_child(codex)
	codex._ready()

	var expected_terms: Dictionary = {
		&"recipe_fu": ["Meadow", "Living Wood", "Red Fox"],
		&"ku_unlock_guidance": ["Mist Stag", "Kū Seed", "Void"],
		&"recipe_ku": ["Void", "split islands", "calm-water"],
		&"recipe_chi_ku": ["Sacred Stone", "calm water island", "Suijin"],
		&"spirit_suijin": ["ten water tiles", "no fire", "Satori 1000"],
		&"biome_ku": ["Void", "separating islands", "calm-water"],
		&"biome_sacred_stone": ["Sacred Stone", "ten water tiles", "Suijin"],
	}
	for entry_id: StringName in expected_terms.keys():
		var entry: CodexEntry = _find_codex_entry(codex, entry_id)
		assert_not_null(entry, "%s should be registered in Codex" % str(entry_id))
		var combined_text: String = "%s %s" % [entry.hint_text, entry.full_description]
		for term_variant: Variant in expected_terms[entry_id]:
			var term: String = str(term_variant)
			assert_true(combined_text.contains(term), "%s should mention '%s'" % [str(entry_id), term])

	codex.queue_free()


func test_settings_menu_displays_alpha_build_version() -> void:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	var semver_alpha_with_build: RegEx = RegEx.create_from_string("^0\\.[0-9]+\\.[0-9]+-alpha\\+[A-Za-z0-9][A-Za-z0-9.-]*$")
	assert_not_null(semver_alpha_with_build.search(version), "Project version should be 0.x.y-alpha+build")

	var scene: PackedScene = load("res://scenes/UI/SettingsMenu.tscn") as PackedScene
	assert_not_null(scene)
	var menu: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(menu)
	await get_tree().process_frame

	var version_label: Label = menu.get_node("Root/Center/Panel/VBox/VersionLabel") as Label
	assert_eq(version_label.text, "Version %s" % version)

	remove_child(menu)
	menu.free()


func test_discovery_stingers_are_deferred_until_final_assets_exist() -> void:
	assert_true(DiscoveryAudioPlayer.AUDIO_MAP.is_empty(), "Discovery stingers should be deferred, not mapped to absent placeholder files")


func test_normal_ui_copy_does_not_expose_broken_alpha_gaps() -> void:
	for file_path: String in PRIMARY_RELEASE_UI_FILES:
		var text: String = FileAccess.get_file_as_string(file_path)
		assert_false(text.is_empty(), "%s should be readable" % file_path)
		var lower_text: String = text.to_lower()
		for broken_copy: String in BROKEN_LOOKING_COPY:
			assert_false(lower_text.contains(broken_copy), "%s should not expose '%s' on normal alpha UI" % [file_path, broken_copy])

	var seed_panel_text: String = FileAccess.get_file_as_string("res://src/ui/SeedAlchemyPanel.gd")
	var ritual_result_text: String = FileAccess.get_file_as_string("res://src/seeds/RitualAttemptResult.gd")
	assert_true(seed_panel_text.contains("is not available yet."), "Locked ritual inputs should explain gated content clearly")
	assert_true(ritual_result_text.contains("do not yet shape a known form"), "Unknown ritual mixes should read as undiscovered, not broken")


func test_primary_alpha_assets_are_real_files_not_placeholder_paths() -> void:
	var structure_catalog: StructureCatalogData = StructureCatalogDataScript.new()
	for building_id: String in PRIMARY_BUILDING_IDS:
		var structure_entry: Dictionary = structure_catalog.get_entry(building_id)
		var asset_path: String = str(structure_entry.get("asset_path", ""))
		assert_false(asset_path.to_lower().contains("placeholder"), "%s should not use a placeholder asset path" % building_id)
		assert_false(asset_path.to_lower().contains("stub"), "%s should not use a stub asset path" % building_id)
		_assert_asset_file_is_final_enough(asset_path, "%s structure asset" % building_id)

	for spirit_id: String in PRIMARY_SPIRIT_IDS:
		var frame_path: String = "res://assets/spirits/%s/frames/idle/down/frame_0000.png" % spirit_id
		var sprite_frames_path: String = "res://assets/spirits/%s/sprite_frames.tres" % spirit_id
		_assert_asset_file_is_final_enough(frame_path, "%s idle frame" % spirit_id)
		_assert_asset_file_is_final_enough(sprite_frames_path, "%s sprite frames" % spirit_id)


func _effects_are_present(entry: Dictionary) -> bool:
	var effects_variant: Variant = entry.get("effects", [])
	return effects_variant is Array and not (effects_variant as Array).is_empty()


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


func _find_codex_entry(codex: CodexServiceNode, entry_id: StringName) -> CodexEntry:
	for category: int in [CodexEntry.Category.SEED, CodexEntry.Category.BIOME, CodexEntry.Category.SPIRIT, CodexEntry.Category.STRUCTURE]:
		for entry: CodexEntry in codex.get_entries_by_category(category):
			if entry.entry_id == entry_id:
				return entry
	return null


func _assert_asset_file_is_final_enough(file_path: String, context: String) -> void:
	assert_false(file_path.is_empty(), "%s should have an asset path" % context)
	assert_true(FileAccess.file_exists(file_path), "%s should exist at %s" % [context, file_path])
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	assert_not_null(file, "%s should be readable" % context)
	if file == null:
		return
	assert_gt(file.get_length(), 100, "%s should not be an empty placeholder file" % context)
	file.close()
