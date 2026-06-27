extends GutTest

const RitualRecipeCatalogScript = preload("res://src/seeds/RitualRecipeCatalog.gd")

func test_form_rituals_load_from_csv() -> void:
	var catalog = RitualRecipeCatalogScript.new()
	var entry = catalog.lookup_form(["material:living_wood", "essence:fire"])
	assert_not_null(entry)
	assert_eq(entry.ritual_id, &"ritual_warm_hollow")
	assert_eq(entry.result_kind, &"form")
	assert_eq(entry.result_id, &"form_warm_hollow")
	assert_eq(entry.discovery_id, &"disc_warm_hollow")
	assert_eq(entry.required_material_counts.get(&"living_wood", 0), 1)
	assert_true(entry.required_elements.has(GodaiElement.Value.KA))

	var fox_den_entry = catalog.lookup_form(["material:living_wood", "spirit:spirit_red_fox"])
	assert_not_null(fox_den_entry)
	assert_eq(fox_den_entry.ritual_id, &"ritual_fox_den")
	assert_eq(fox_den_entry.result_kind, &"form")
	assert_eq(fox_den_entry.result_id, &"form_fox_den")
	assert_eq(fox_den_entry.discovery_id, &"disc_fox_den")
	assert_eq(fox_den_entry.required_material_counts.get(&"living_wood", 0), 1)
	assert_false(fox_den_entry.required_elements.has(GodaiElement.Value.KA), "Red Fox should not be parsed as a generic Fire Essence component")

	var reed_entry = catalog.lookup_form(["material:reed_fiber", "essence:water"])
	assert_not_null(reed_entry)
	assert_eq(reed_entry.ritual_id, &"ritual_reed_nest")
	assert_eq(reed_entry.result_id, &"form_reed_nest")
	assert_eq(reed_entry.discovery_id, &"disc_reed_nest")
	assert_eq(reed_entry.required_material_counts.get(&"reed_fiber", 0), 1)
	assert_true(reed_entry.required_elements.has(GodaiElement.Value.SUI))

	var basin_entry = catalog.lookup_form(["material:spirit_stone", "essence:water"])
	assert_not_null(basin_entry)
	assert_eq(basin_entry.ritual_id, &"ritual_stone_basin")
	assert_eq(basin_entry.result_id, &"form_stone_basin")
	assert_eq(basin_entry.discovery_id, &"disc_stone_basin")
	assert_eq(basin_entry.required_material_counts.get(&"spirit_stone", 0), 1)
	assert_true(basin_entry.required_elements.has(GodaiElement.Value.SUI))

func test_tier1_material_family_form_rituals_are_complete() -> void:
	var catalog = RitualRecipeCatalogScript.new()
	var expected: Array[Dictionary] = [
		{"inputs": ["material:living_wood", "essence:fire"], "result": &"form_warm_hollow", "discovery": &"disc_warm_hollow"},
		{"inputs": ["material:living_wood", "spirit:spirit_red_fox"], "result": &"form_fox_den", "discovery": &"disc_fox_den"},
		{"inputs": ["material:living_wood", "essence:water"], "result": &"form_dew_bowl", "discovery": &"disc_dew_bowl"},
		{"inputs": ["material:living_wood", "essence:earth"], "result": &"form_root_network", "discovery": &"disc_root_network"},
		{"inputs": ["material:living_wood", "essence:wind"], "result": &"form_wind_chime", "discovery": &"disc_wind_chime"},
		{"inputs": ["material:living_wood", "essence:ku"], "result": &"form_tiny_shrine", "discovery": &"disc_tiny_shrine"},
		{"inputs": ["material:reed_fiber", "essence:fire"], "result": &"form_steam_weave", "discovery": &"disc_steam_weave"},
		{"inputs": ["material:reed_fiber", "essence:water"], "result": &"form_reed_nest", "discovery": &"disc_reed_nest"},
		{"inputs": ["material:reed_fiber", "essence:earth"], "result": &"form_reed_mat", "discovery": &"disc_reed_mat"},
		{"inputs": ["material:reed_fiber", "essence:wind"], "result": &"form_reed_flute", "discovery": &"disc_reed_flute"},
		{"inputs": ["material:reed_fiber", "essence:ku"], "result": &"form_dream_hammock", "discovery": &"disc_dream_hammock"},
		{"inputs": ["material:spirit_stone", "essence:fire"], "result": &"form_hearth_stone", "discovery": &"disc_hearth_stone"},
		{"inputs": ["material:spirit_stone", "essence:water"], "result": &"form_stone_basin", "discovery": &"disc_stone_basin"},
		{"inputs": ["material:spirit_stone", "essence:earth"], "result": &"form_foundation_marker", "discovery": &"disc_foundation_marker"},
		{"inputs": ["material:spirit_stone", "essence:wind"], "result": &"form_resonance_cairn", "discovery": &"disc_resonance_cairn"},
		{"inputs": ["material:spirit_stone", "essence:ku"], "result": &"form_rune_marker", "discovery": &"disc_rune_marker"},
		{"inputs": ["material:ember_clay", "essence:fire"], "result": &"form_kiln_heart", "discovery": &"disc_kiln_heart"},
		{"inputs": ["material:ember_clay", "essence:water"], "result": &"form_steam_bowl", "discovery": &"disc_steam_bowl"},
		{"inputs": ["material:ember_clay", "essence:earth"], "result": &"form_clay_anchor", "discovery": &"disc_clay_anchor"},
		{"inputs": ["material:ember_clay", "essence:wind"], "result": &"form_ember_bellows", "discovery": &"disc_ember_bellows"},
		{"inputs": ["material:ember_clay", "essence:ku"], "result": &"form_moonflame", "discovery": &"disc_moonflame"},
	]
	for case: Dictionary in expected:
		var inputs: Array[String] = []
		for input_variant: Variant in case["inputs"]:
			inputs.append(str(input_variant))
		var entry = catalog.lookup_form(inputs)
		assert_not_null(entry, "Expected form ritual for %s" % str(case["result"]))
		assert_eq(entry.result_id, case["result"])
		assert_eq(entry.discovery_id, case["discovery"])

func test_seed_rituals_load_from_csv_with_bare_godai_components() -> void:
	var catalog = RitualRecipeCatalogScript.new()
	var meadow_entry = catalog.lookup_seed(["essence:wind"])
	assert_not_null(meadow_entry)
	assert_eq(meadow_entry.ritual_id, &"ritual_fu")
	assert_eq(meadow_entry.result_kind, &"seed")
	assert_eq(meadow_entry.result_id, &"recipe_fu")
	assert_eq(meadow_entry.discovery_id, &"recipe_fu")
	assert_eq(meadow_entry.input_keys, ["essence:wind"])
	assert_true(meadow_entry.required_elements.has(GodaiElement.Value.FU))

	var ashfall_entry = catalog.lookup_seed(["essence:wind", "essence:fire"])
	assert_not_null(ashfall_entry)
	assert_eq(ashfall_entry.ritual_id, &"ritual_ka_fu")
	assert_eq(ashfall_entry.result_id, &"recipe_ka_fu")
	assert_true(ashfall_entry.required_elements.has(GodaiElement.Value.KA))
	assert_true(ashfall_entry.required_elements.has(GodaiElement.Value.FU))

func test_form_placement_rules_are_data_driven() -> void:
	var catalog = RitualRecipeCatalogScript.new()
	assert_true(catalog.is_placeable_form(&"form_warm_hollow"))
	assert_eq(catalog.resolve_form_placement(&"form_warm_hollow", BiomeType.Value.MEADOW), &"building_meadow_dwelling")
	assert_eq(catalog.resolve_form_placement(&"form_warm_hollow", BiomeType.Value.EMBER_FIELD), &"building_scorched_hollow")
	assert_eq(catalog.resolve_form_placement(&"form_warm_hollow", BiomeType.Value.RIVER), &"")
	assert_true(catalog.is_placeable_form(&"form_fox_den"))
	assert_eq(catalog.resolve_form_placement(&"form_fox_den", BiomeType.Value.MEADOW), &"building_fox_den")
	assert_eq(catalog.resolve_form_placement(&"form_fox_den", BiomeType.Value.BADLANDS), &"building_fox_den")
	assert_eq(catalog.resolve_form_placement(&"form_fox_den", BiomeType.Value.RIVER), &"")
	assert_true(catalog.is_placeable_form(&"form_reed_nest"))
	assert_eq(catalog.resolve_form_placement(&"form_reed_nest", BiomeType.Value.RIVER), &"building_reed_nest")
	assert_eq(catalog.resolve_form_placement(&"form_reed_nest", BiomeType.Value.WETLANDS), &"building_reed_nest")
	assert_eq(catalog.resolve_form_placement(&"form_reed_nest", BiomeType.Value.MOONLIT_POOL), &"building_reed_nest")
	assert_eq(catalog.resolve_form_placement(&"form_reed_nest", BiomeType.Value.MEADOW), &"")
	assert_true(catalog.is_placeable_form(&"form_stone_basin"))
	assert_eq(catalog.resolve_form_placement(&"form_stone_basin", BiomeType.Value.RIVER), &"building_stone_basin")
	assert_true(catalog.is_placeable_form(&"form_root_network"))
	assert_eq(catalog.resolve_form_placement(&"form_root_network", BiomeType.Value.MEADOW), &"building_root_network")
	assert_true(catalog.is_placeable_form(&"form_wind_chime"))
	assert_eq(catalog.resolve_form_placement(&"form_wind_chime", BiomeType.Value.CLOUD_RIDGE), &"building_wind_chime")
	assert_true(catalog.is_placeable_form(&"form_kiln_heart"))
	assert_eq(catalog.resolve_form_placement(&"form_kiln_heart", BiomeType.Value.EMBER_FIELD), &"building_kiln_heart")
