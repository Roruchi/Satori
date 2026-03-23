extends GutTest


func test_factory_sets_coord() -> void:
	var tile := GardenTile.create(Vector2i(3, 7), BiomeType.Value.FOREST)
	assert_eq(tile.coord, Vector2i(3, 7))


func test_factory_sets_biome() -> void:
	var tile := GardenTile.create(Vector2i(0, 0), BiomeType.Value.WATER)
	assert_eq(tile.biome, BiomeType.Value.WATER)


func test_locked_defaults_to_false() -> void:
	var tile := GardenTile.create(Vector2i(0, 0), BiomeType.Value.STONE)
	assert_false(tile.locked, "newly created tile should not be locked")


func test_metadata_defaults_to_empty_dictionary() -> void:
	var tile := GardenTile.create(Vector2i(0, 0), BiomeType.Value.EARTH)
	assert_eq(tile.metadata, {})


func test_setting_locked_true_persists() -> void:
	var tile := GardenTile.create(Vector2i(1, 2), BiomeType.Value.FOREST)
	tile.locked = true
	assert_true(tile.locked)


func test_negative_coord_is_stored_correctly() -> void:
	var tile := GardenTile.create(Vector2i(-5, -12), BiomeType.Value.STONE)
	assert_eq(tile.coord, Vector2i(-5, -12))


func test_metadata_accepts_arbitrary_keys() -> void:
	var tile := GardenTile.create(Vector2i(0, 0), BiomeType.Value.WATER)
	tile.metadata["discovery_ids"] = ["tier1_river"]
	assert_eq(tile.metadata["discovery_ids"], ["tier1_river"])
