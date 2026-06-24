extends GutTest

const _TerrainTilesheet = preload("res://src/rendering/terrain_tilesheet.gd")
const _TERRAIN_TILESET_PATH: String = "res://assets/tiles/satori_terrain_tilesheet.png"


func test_terrain_tilesheet_texture_has_expected_grid() -> void:
	var image: Image = Image.load_from_file(_TERRAIN_TILESET_PATH)
	assert_not_null(image, "Terrain tilesheet should load as an Image")
	assert_eq(image.get_width(), _TerrainTilesheet.CELL_SIZE * _TerrainTilesheet.VARIANT_COUNT)
	assert_eq(image.get_height(), _TerrainTilesheet.CELL_SIZE * 3)


func test_meadow_and_river_are_supported() -> void:
	assert_true(_TerrainTilesheet.supports_biome(BiomeType.Value.MEADOW))
	assert_true(_TerrainTilesheet.supports_biome(BiomeType.Value.RIVER))
	assert_false(_TerrainTilesheet.supports_biome(BiomeType.Value.STONE))


func test_variant_for_coord_is_deterministic_and_in_range() -> void:
	var coord := Vector2i(12, -7)
	var first: int = _TerrainTilesheet.variant_for_coord(coord)
	var second: int = _TerrainTilesheet.variant_for_coord(coord)
	assert_eq(first, second)
	assert_true(first >= 0 and first < _TerrainTilesheet.VARIANT_COUNT)


func test_region_rows_match_biome_and_blend_rules() -> void:
	var meadow_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.MEADOW, false)
	var river_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.RIVER, false)
	var blend_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.MEADOW, true)

	assert_eq(int(meadow_region.position.y), _TerrainTilesheet.ROW_MEADOW * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(river_region.position.y), _TerrainTilesheet.ROW_WATER * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(blend_region.position.y), _TerrainTilesheet.ROW_MEADOW_WATER * _TerrainTilesheet.CELL_SIZE)
