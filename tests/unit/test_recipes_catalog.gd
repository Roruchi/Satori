## test_recipes_catalog.gd
##
## Validates that the live catalog data matches the reference table in
## specs/master/recipes.md.  Run via GUT (addons/gut).
##
## Coverage:
##   - 10 seed recipes registered (4 tier‑1 + 6 tier‑2)
##   - Each recipe maps to the correct BiomeType
##   - 12 tier‑1 discovery IDs present in DiscoveryCatalogData
##   - 10 tier‑2 discovery IDs present in DiscoveryCatalogData
##   - 30 spirit IDs present in SpiritCatalogData
##   - Key spirit gift types match the reference table

extends GutTest

# ---------------------------------------------------------------------------
# Seed recipes
# ---------------------------------------------------------------------------

func test_registry_has_exactly_10_seed_recipes() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	assert_eq(registry.all_known_recipes().size(), 10,
		"recipes.md defines 4 tier‑1 + 6 tier‑2 = 10 total seed recipes")


func test_tier1_recipes_produce_correct_biomes() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()

	var chi: SeedRecipe = registry.lookup([GodaiElement.Value.CHI])
	assert_not_null(chi, "Chi recipe must exist")
	assert_eq(chi.produces_biome, BiomeType.Value.STONE, "Chi → Stone")

	var sui: SeedRecipe = registry.lookup([GodaiElement.Value.SUI])
	assert_not_null(sui, "Sui recipe must exist")
	assert_eq(sui.produces_biome, BiomeType.Value.RIVER, "Sui → River")

	var ka: SeedRecipe = registry.lookup([GodaiElement.Value.KA])
	assert_not_null(ka, "Ka recipe must exist")
	assert_eq(ka.produces_biome, BiomeType.Value.EMBER_FIELD, "Ka → Ember Field")

	var fu: SeedRecipe = registry.lookup([GodaiElement.Value.FU])
	assert_not_null(fu, "Fu recipe must exist")
	assert_eq(fu.produces_biome, BiomeType.Value.MEADOW, "Fu → Meadow")


func test_tier2_recipes_produce_correct_biomes() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()

	var chi: int = GodaiElement.Value.CHI
	var sui: int = GodaiElement.Value.SUI
	var ka:  int = GodaiElement.Value.KA
	var fu:  int = GodaiElement.Value.FU

	var pairs: Array[Dictionary] = [
		{"elements": [chi, sui], "biome": BiomeType.Value.CLAY,         "name": "Chi+Sui → Clay"},
		{"elements": [chi, ka],  "biome": BiomeType.Value.DESERT,       "name": "Chi+Ka → Desert"},
		{"elements": [chi, fu],  "biome": BiomeType.Value.DUNE,         "name": "Chi+Fu → Dune"},
		{"elements": [sui, ka],  "biome": BiomeType.Value.HOT_SPRING,   "name": "Sui+Ka → Hot Spring"},
		{"elements": [sui, fu],  "biome": BiomeType.Value.BOG,          "name": "Sui+Fu → Bog"},
		{"elements": [ka, fu],   "biome": BiomeType.Value.CINDER_HEATH, "name": "Ka+Fu → Cinder Heath"},
	]

	for pair: Dictionary in pairs:
		var elements: Array[int] = pair["elements"]
		var recipe: SeedRecipe = registry.lookup(elements)
		assert_not_null(recipe, "Recipe must exist: %s" % pair["name"])
		assert_eq(recipe.produces_biome, int(pair["biome"]),
			"Wrong biome for: %s" % pair["name"])


func test_tier1_recipe_ids_match_reference_table() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var expected_ids: Array[String] = [
		"recipe_chi", "recipe_sui", "recipe_ka", "recipe_fu",
	]
	for recipe_id: String in expected_ids:
		assert_true(registry.is_recipe_known(recipe_id),
			"Tier 1 recipe missing from registry: %s" % recipe_id)


func test_tier2_recipe_ids_match_reference_table() -> void:
	var registry: SeedRecipeRegistry = SeedRecipeRegistry.new()
	var expected_ids: Array[String] = [
		"recipe_chi_sui", "recipe_chi_ka", "recipe_chi_fu",
		"recipe_sui_ka",  "recipe_sui_fu", "recipe_ka_fu",
	]
	for recipe_id: String in expected_ids:
		assert_true(registry.is_recipe_known(recipe_id),
			"Tier 2 recipe missing from registry: %s" % recipe_id)


# ---------------------------------------------------------------------------
# Tier 1 discoveries
# ---------------------------------------------------------------------------

func test_tier1_catalog_has_exactly_12_entries() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	assert_eq(data.get_tier1_entries().size(), 12,
		"recipes.md lists 12 Tier 1 discoveries")


func test_all_tier1_discovery_ids_present() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	var entries: Array[Dictionary] = data.get_tier1_entries()
	var actual_ids: Array[String] = []
	for entry: Dictionary in entries:
		actual_ids.append(str(entry.get("discovery_id", "")))

	var expected_ids: Array[String] = [
		"disc_river",
		"disc_deep_stand",
		"disc_glade",
		"disc_mirror_archipelago",
		"disc_barren_expanse",
		"disc_great_reef",
		"disc_lotus_pond",
		"disc_mountain_peak",
		"disc_boreal_forest",
		"disc_peat_bog",
		"disc_obsidian_expanse",
		"disc_waterfall",
	]
	for expected_id: String in expected_ids:
		assert_true(actual_ids.has(expected_id),
			"Tier 1 discovery missing from catalog: %s" % expected_id)


func test_all_tier1_entries_have_tier_value_1() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	for entry: Dictionary in data.get_tier1_entries():
		assert_eq(int(entry.get("tier", 0)), 1,
			"Expected tier=1 for: %s" % str(entry.get("discovery_id", "")))


# ---------------------------------------------------------------------------
# Tier 2 discoveries
# ---------------------------------------------------------------------------

func test_tier2_catalog_has_exactly_10_entries() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	assert_eq(data.get_tier2_entries().size(), 10,
		"recipes.md lists 10 Tier 2 structural landmarks")


func test_all_tier2_discovery_ids_present() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	var entries: Array[Dictionary] = data.get_tier2_entries()
	var actual_ids: Array[String] = []
	for entry: Dictionary in entries:
		actual_ids.append(str(entry.get("discovery_id", "")))

	var expected_ids: Array[String] = [
		"disc_origin_shrine",
		"disc_bridge_of_sighs",
		"disc_lotus_pagoda",
		"disc_monks_rest",
		"disc_star_gazing_deck",
		"disc_sun_dial",
		"disc_whale_bone_arch",
		"disc_echoing_cavern",
		"disc_bamboo_chime",
		"disc_floating_pavilion",
	]
	for expected_id: String in expected_ids:
		assert_true(actual_ids.has(expected_id),
			"Tier 2 discovery missing from catalog: %s" % expected_id)


func test_all_tier2_entries_have_tier_value_2() -> void:
	var data: DiscoveryCatalogData = DiscoveryCatalogData.new()
	for entry: Dictionary in data.get_tier2_entries():
		assert_eq(int(entry.get("tier", 0)), 2,
			"Expected tier=2 for: %s" % str(entry.get("discovery_id", "")))


# ---------------------------------------------------------------------------
# Spirit catalog
# ---------------------------------------------------------------------------

func test_spirit_catalog_has_exactly_30_entries() -> void:
	var data: SpiritCatalogData = SpiritCatalogData.new()
	assert_eq(data.get_entries().size(), 30,
		"recipes.md lists 30 spirit animals")


func test_all_30_spirit_ids_present() -> void:
	var data: SpiritCatalogData = SpiritCatalogData.new()
	var entries: Array[Dictionary] = data.get_entries()
	var actual_ids: Array[String] = []
	for entry: Dictionary in entries:
		actual_ids.append(str(entry.get("spirit_id", "")))

	var expected_ids: Array[String] = [
		"spirit_red_fox",        "spirit_mist_stag",        "spirit_emerald_snake",
		"spirit_owl_of_silence", "spirit_tree_frog",         "spirit_white_heron",
		"spirit_koi_fish",       "spirit_river_otter",       "spirit_blue_kingfisher",
		"spirit_dragonfly",      "spirit_mountain_goat",     "spirit_stone_golem",
		"spirit_granite_ram",    "spirit_sun_lizard",        "spirit_rock_badger",
		"spirit_golden_bee",     "spirit_jade_beetle",       "spirit_meadow_lark",
		"spirit_field_mouse",    "spirit_hare",              "spirit_marsh_frog",
		"spirit_peat_salamander","spirit_swamp_crane",       "spirit_murk_crocodile",
		"spirit_mud_crab",       "spirit_frost_owl",         "spirit_boreal_wolf",
		"spirit_tundra_lynx",    "spirit_ice_cavern_bat",    "spirit_sky_whale",
	]
	for expected_id: String in expected_ids:
		assert_true(actual_ids.has(expected_id),
			"Spirit missing from catalog: %s" % expected_id)


# ---------------------------------------------------------------------------
# Spirit gift types (cross-check with recipes.md gift table)
# ---------------------------------------------------------------------------

func _find_spirit(spirit_id: String) -> Dictionary:
	var data: SpiritCatalogData = SpiritCatalogData.new()
	for entry: Dictionary in data.get_entries():
		if str(entry.get("spirit_id", "")) == spirit_id:
			return entry
	return {}


func test_mist_stag_grants_ku_unlock() -> void:
	var entry: Dictionary = _find_spirit("spirit_mist_stag")
	assert_false(entry.is_empty(), "Mist Stag must exist in catalog")
	assert_eq(int(entry.get("gift_type", -1)), SpiritGiftType.Value.KU_UNLOCK,
		"Mist Stag must grant KU_UNLOCK (1)")


func test_river_otter_grants_tier3_recipe_and_correct_payload() -> void:
	var entry: Dictionary = _find_spirit("spirit_river_otter")
	assert_false(entry.is_empty(), "River Otter must exist in catalog")
	assert_eq(int(entry.get("gift_type", -1)), SpiritGiftType.Value.TIER3_RECIPE,
		"River Otter must grant TIER3_RECIPE (2)")
	assert_eq(str(entry.get("gift_payload", "")), "recipe_chi_sui_fu",
		"River Otter payload must be recipe_chi_sui_fu")


func test_meadow_lark_grants_growing_slot_expand() -> void:
	var entry: Dictionary = _find_spirit("spirit_meadow_lark")
	assert_false(entry.is_empty(), "Meadow Lark must exist in catalog")
	assert_eq(int(entry.get("gift_type", -1)), SpiritGiftType.Value.GROWING_SLOT_EXPAND,
		"Meadow Lark must grant GROWING_SLOT_EXPAND (4)")


func test_spirits_with_no_gift_have_gift_type_none() -> void:
	var gift_none_ids: Array[String] = [
		"spirit_red_fox", "spirit_white_heron", "spirit_koi_fish",
		"spirit_blue_kingfisher", "spirit_mountain_goat", "spirit_golden_bee",
		"spirit_boreal_wolf",
	]
	for spirit_id: String in gift_none_ids:
		var entry: Dictionary = _find_spirit(spirit_id)
		assert_false(entry.is_empty(), "Spirit missing: %s" % spirit_id)
		assert_eq(int(entry.get("gift_type", -1)), SpiritGiftType.Value.NONE,
			"%s must have gift_type NONE (0)" % spirit_id)


# ---------------------------------------------------------------------------
# Spirit relations (harmony / tension pairs from recipes.md)
# ---------------------------------------------------------------------------

func test_koi_fish_harmony_with_blue_kingfisher() -> void:
	var entry: Dictionary = _find_spirit("spirit_koi_fish")
	assert_eq(str(entry.get("harmony_partner_id", "")), "spirit_blue_kingfisher",
		"Koi Fish harmony partner must be Blue Kingfisher")


func test_red_fox_tension_with_hare() -> void:
	var entry: Dictionary = _find_spirit("spirit_red_fox")
	assert_eq(str(entry.get("tension_partner_id", "")), "spirit_hare",
		"Red Fox tension partner must be Hare")


func test_boreal_wolf_tension_with_tundra_lynx() -> void:
	var entry: Dictionary = _find_spirit("spirit_boreal_wolf")
	assert_eq(str(entry.get("tension_partner_id", "")), "spirit_tundra_lynx",
		"Boreal Wolf tension partner must be Tundra Lynx")
