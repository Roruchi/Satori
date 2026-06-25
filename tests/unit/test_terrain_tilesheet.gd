extends GutTest

const _TerrainTilesheet = preload("res://src/rendering/terrain_tilesheet.gd")
const _TERRAIN_TILESET_PATH: String = "res://assets/tiles/satori_terrain_tilesheet.png"
const _EDGE_DECAL_PATH: String = "res://assets/tiles/satori_edge_decal.png"


func test_terrain_tilesheet_texture_has_expected_grid() -> void:
	var image: Image = _load_image(_TERRAIN_TILESET_PATH)
	assert_not_null(image, "Terrain tilesheet should load as an Image")
	assert_eq(image.get_width(), _TerrainTilesheet.CELL_SIZE * _TerrainTilesheet.VARIANT_COUNT * _TerrainTilesheet.TERRAIN_FRAME_COUNT)
	assert_eq(image.get_height(), _TerrainTilesheet.CELL_SIZE * _TerrainTilesheet.TERRAIN_ROW_COUNT)


func test_edge_decal_texture_has_expected_grid() -> void:
	var image: Image = _load_image(_EDGE_DECAL_PATH)
	assert_not_null(image, "Edge decal should load as an Image")
	assert_eq(image.get_width(), _TerrainTilesheet.CELL_SIZE * _TerrainTilesheet.VARIANT_COUNT * _TerrainTilesheet.EDGE_DECAL_FRAME_COUNT)
	assert_eq(image.get_height(), _TerrainTilesheet.CELL_SIZE * _TerrainTilesheet.EDGE_DECAL_ROW_COUNT)


func test_current_biomes_are_supported() -> void:
	for biome: int in _current_biomes():
		assert_true(_TerrainTilesheet.supports_biome(biome), "Biome %d should have a terrain atlas row" % biome)
	assert_false(_TerrainTilesheet.supports_biome(BiomeType.Value.NONE))


func test_variant_for_coord_is_deterministic_and_in_range() -> void:
	var coord := Vector2i(12, -7)
	var first: int = _TerrainTilesheet.variant_for_coord(coord)
	var second: int = _TerrainTilesheet.variant_for_coord(coord)
	assert_eq(first, second)
	assert_true(first >= 0 and first < _TerrainTilesheet.VARIANT_COUNT)


func test_region_rows_match_biome_rules() -> void:
	var meadow_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.MEADOW)
	var river_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.RIVER)
	var stone_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.STONE)
	var ku_region: Rect2 = _TerrainTilesheet.region_for(Vector2i.ZERO, BiomeType.Value.KU)
	var edge_decal_region: Rect2 = _TerrainTilesheet.edge_decal_region_for(Vector2i.ZERO)

	assert_eq(int(meadow_region.position.y), _TerrainTilesheet.ROW_MEADOW * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(river_region.position.y), _TerrainTilesheet.ROW_WATER * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(stone_region.position.y), _TerrainTilesheet.ROW_STONE * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(ku_region.position.y), _TerrainTilesheet.ROW_KU * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(edge_decal_region.position.y), 0)


func test_current_biome_rows_are_unique_and_in_atlas() -> void:
	var seen_rows: Dictionary = {}
	for biome: int in _current_biomes():
		var row: int = _TerrainTilesheet.row_for_biome(biome)
		assert_true(row >= 0 and row < _TerrainTilesheet.TERRAIN_ROW_COUNT)
		assert_false(seen_rows.has(row), "Atlas row %d should be assigned once" % row)
		seen_rows[row] = true


func test_frame_regions_advance_by_variant_blocks() -> void:
	var coord := Vector2i(2, 5)
	var variant: int = _TerrainTilesheet.variant_for_coord(coord)
	var frame: int = 3
	var expected_column: int = variant + frame * _TerrainTilesheet.VARIANT_COUNT
	var region: Rect2 = _TerrainTilesheet._region_for_variant_and_row(variant, _TerrainTilesheet.ROW_WATER, frame)

	assert_eq(int(region.position.x), expected_column * _TerrainTilesheet.CELL_SIZE)
	assert_eq(int(region.position.y), _TerrainTilesheet.ROW_WATER * _TerrainTilesheet.CELL_SIZE)


func _current_biomes() -> Array[int]:
	return [
		BiomeType.Value.STONE,
		BiomeType.Value.RIVER,
		BiomeType.Value.EMBER_FIELD,
		BiomeType.Value.MEADOW,
		BiomeType.Value.WETLANDS,
		BiomeType.Value.BADLANDS,
		BiomeType.Value.WHISTLING_CANYONS,
		BiomeType.Value.PRISMATIC_TERRACES,
		BiomeType.Value.FROSTLANDS,
		BiomeType.Value.THE_ASHFALL,
		BiomeType.Value.SACRED_STONE,
		BiomeType.Value.MOONLIT_POOL,
		BiomeType.Value.EMBER_SHRINE,
		BiomeType.Value.CLOUD_RIDGE,
		BiomeType.Value.KU,
	]


func _load_image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))
