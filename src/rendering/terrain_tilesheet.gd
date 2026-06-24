extends RefCounted

const CELL_SIZE: int = 256
const VARIANT_COUNT: int = 4

const ROW_MEADOW: int = 0
const ROW_WATER: int = 1
const ROW_MEADOW_WATER: int = 2


static func supports_biome(biome: int) -> bool:
	return biome == BiomeType.Value.MEADOW or biome == BiomeType.Value.RIVER


static func variant_for_coord(coord: Vector2i) -> int:
	var mixed_hash: int = coord.x * 73856093 ^ coord.y * 19349663
	return posmod(mixed_hash, VARIANT_COUNT)


static func row_for_biome(biome: int, has_meadow_water_edge: bool) -> int:
	if has_meadow_water_edge:
		return ROW_MEADOW_WATER
	if biome == BiomeType.Value.RIVER:
		return ROW_WATER
	return ROW_MEADOW


static func region_for(coord: Vector2i, biome: int, has_meadow_water_edge: bool) -> Rect2:
	var variant: int = variant_for_coord(coord)
	var row: int = row_for_biome(biome, has_meadow_water_edge)
	return Rect2(
		Vector2(float(variant * CELL_SIZE), float(row * CELL_SIZE)),
		Vector2(float(CELL_SIZE), float(CELL_SIZE))
	)
