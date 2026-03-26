## Test Suite: SpiritCatalog
##
## GUT unit tests for SpiritCatalog loading from SpiritCatalogData,
## lookup behavior, and entry enumeration.
## Run via tests/gut_runner.tscn

extends GutTest

var _catalog: SpiritCatalog
var _expected_count: int = 0


func before_each() -> void:
	_catalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	_expected_count = data.get_entries().size()
	_catalog.load_from_data(data)


func test_catalog_loads_all_entries() -> void:
	assert_eq(_catalog.get_all_spirit_ids().size(), _expected_count,
		"Catalog should load exactly %d spirit entries" % _expected_count)


func test_catalog_lookup_returns_correct_entry_for_red_fox() -> void:
	var entry: Dictionary = _catalog.lookup("spirit_red_fox")
	assert_false(entry.is_empty(), "Lookup for spirit_red_fox should return non-empty dict")
	assert_eq(entry["spirit_id"], "spirit_red_fox", "spirit_id should match")
	assert_eq(entry["display_name"], "Red Fox", "display_name should be 'Red Fox'")
	assert_eq(entry["wander_radius"], 4, "wander_radius should be 4")


func test_catalog_lookup_returns_correct_entry_for_sky_whale() -> void:
	var entry: Dictionary = _catalog.lookup("spirit_sky_whale")
	assert_false(entry.is_empty(), "Lookup for spirit_sky_whale should return non-empty dict")
	assert_eq(entry["spirit_id"], "spirit_sky_whale", "spirit_id should match")
	assert_eq(entry["wander_radius"], 50, "Sky Whale wander_radius should be 50")


func test_catalog_lookup_returns_empty_dict_for_unknown_id() -> void:
	var entry: Dictionary = _catalog.lookup("spirit_nonexistent")
	assert_true(entry.is_empty(), "Unknown spirit_id should return empty dict")


func test_catalog_has_entry_returns_true_for_known_id() -> void:
	assert_true(_catalog.has_entry("spirit_mist_stag"), "has_entry should return true for known spirit")


func test_catalog_has_entry_returns_false_for_unknown_id() -> void:
	assert_false(_catalog.has_entry("spirit_does_not_exist"),
		"has_entry should return false for unknown spirit")


func test_catalog_get_all_spirit_ids_returns_all_ids() -> void:
	var ids: Array[String] = _catalog.get_all_spirit_ids()
	assert_eq(ids.size(), _expected_count, "get_all_spirit_ids should return all spirit IDs")


func test_catalog_all_entries_have_required_fields() -> void:
	var ids: Array[String] = _catalog.get_all_spirit_ids()
	for sid: String in ids:
		var entry: Dictionary = _catalog.lookup(sid)
		assert_true(entry.has("spirit_id"), "%s entry missing spirit_id" % sid)
		assert_true(entry.has("display_name"), "%s entry missing display_name" % sid)
		assert_true(entry.has("riddle_text"), "%s entry missing riddle_text" % sid)
		assert_true(entry.has("wander_radius"), "%s entry missing wander_radius" % sid)
		assert_true(entry.has("color_hint"), "%s entry missing color_hint" % sid)


func test_catalog_lookup_color_hint_is_color_type() -> void:
	var entry: Dictionary = _catalog.lookup("spirit_boreal_wolf")
	assert_true(entry["color_hint"] is Color,
		"color_hint should be a Color instance")
