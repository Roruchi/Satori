extends RefCounted

const CELL_SIZE: int = 256
const VARIANT_COUNT: int = 4
const TERRAIN_FRAME_COUNT: int = 1
const EDGE_DECAL_FRAME_COUNT: int = 1

const ROW_STONE: int = 0
const ROW_WATER: int = 1
const ROW_RIVER: int = ROW_WATER
const ROW_EMBER_FIELD: int = 2
const ROW_MEADOW: int = 3
const ROW_WETLANDS: int = 4
const ROW_BADLANDS: int = 5
const ROW_WHISTLING_CANYONS: int = 6
const ROW_PRISMATIC_TERRACES: int = 7
const ROW_FROSTLANDS: int = 8
const ROW_THE_ASHFALL: int = 9
const ROW_SACRED_STONE: int = 10
const ROW_MOONLIT_POOL: int = 11
const ROW_EMBER_SHRINE: int = 12
const ROW_CLOUD_RIDGE: int = 13
const ROW_KU: int = 14
const TERRAIN_ROW_COUNT: int = 15
const EDGE_DECAL_ROW_COUNT: int = 1

const _BIOME_ROWS: Dictionary = {
	BiomeType.Value.STONE: ROW_STONE,
	BiomeType.Value.RIVER: ROW_RIVER,
	BiomeType.Value.EMBER_FIELD: ROW_EMBER_FIELD,
	BiomeType.Value.MEADOW: ROW_MEADOW,
	BiomeType.Value.WETLANDS: ROW_WETLANDS,
	BiomeType.Value.BADLANDS: ROW_BADLANDS,
	BiomeType.Value.WHISTLING_CANYONS: ROW_WHISTLING_CANYONS,
	BiomeType.Value.PRISMATIC_TERRACES: ROW_PRISMATIC_TERRACES,
	BiomeType.Value.FROSTLANDS: ROW_FROSTLANDS,
	BiomeType.Value.THE_ASHFALL: ROW_THE_ASHFALL,
	BiomeType.Value.SACRED_STONE: ROW_SACRED_STONE,
	BiomeType.Value.MOONLIT_POOL: ROW_MOONLIT_POOL,
	BiomeType.Value.EMBER_SHRINE: ROW_EMBER_SHRINE,
	BiomeType.Value.CLOUD_RIDGE: ROW_CLOUD_RIDGE,
	BiomeType.Value.KU: ROW_KU,
}


static func supports_biome(biome: int) -> bool:
	return _BIOME_ROWS.has(biome)


static func variant_for_coord(coord: Vector2i) -> int:
	var mixed_hash: int = coord.x * 73856093 ^ coord.y * 19349663
	return posmod(mixed_hash, VARIANT_COUNT)


static func row_for_biome(biome: int) -> int:
	return int(_BIOME_ROWS.get(biome, ROW_MEADOW))


static func region_for(coord: Vector2i, biome: int, frame: int = 0) -> Rect2:
	var variant: int = variant_for_coord(coord)
	var frame_index: int = posmod(frame, TERRAIN_FRAME_COUNT)
	var row: int = row_for_biome(biome)
	return _region_for_variant_and_row(variant, row, frame_index)


static func edge_decal_region_for(coord: Vector2i, frame: int = 0) -> Rect2:
	var variant: int = variant_for_coord(coord)
	var frame_index: int = posmod(frame, EDGE_DECAL_FRAME_COUNT)
	return _region_for_variant_and_row(variant, 0, frame_index)


static func _region_for_variant_and_row(variant: int, row: int, frame: int) -> Rect2:
	var column: int = variant + frame * VARIANT_COUNT
	return Rect2(
		Vector2(float(column * CELL_SIZE), float(row * CELL_SIZE)),
		Vector2(float(CELL_SIZE), float(CELL_SIZE))
	)
