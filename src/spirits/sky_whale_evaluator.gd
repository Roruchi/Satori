class_name SkyWhaleEvaluator
extends RefCounted

const REQUIRED_TILE_COUNT: int = 1000
const BALANCE_DEVIATION_MAX: float = 0.15
const SPIRIT_ID: String = "spirit_sky_whale"

# Maps each biome to its macro group: FOREST=0, WATER=1, STONE=2, EARTH=3.
# Hybrid biomes are folded into their dominant macro biome.
const MACRO_MAP: Dictionary = {
	0: 0,  # FOREST   -> FOREST
	1: 1,  # WATER    -> WATER
	2: 2,  # STONE    -> STONE
	3: 3,  # EARTH    -> EARTH
	4: 0,  # SWAMP    -> FOREST
	5: 2,  # TUNDRA   -> STONE
	6: 3,  # MUDFLAT  -> EARTH
	7: 0,  # MOSSY_CRAG -> FOREST
	8: 0,  # SAVANNAH -> FOREST
	9: 2,  # CANYON   -> STONE
}

const _MACRO_BIOMES: Array[int] = [0, 1, 2, 3]

func evaluate(grid: RefCounted) -> bool:
	if grid.total_tile_count < REQUIRED_TILE_COUNT:
		return false
	var macro_counts: Dictionary = _count_macros(grid)
	var total: float = float(grid.total_tile_count)
	var even_share: float = 1.0 / float(_MACRO_BIOMES.size())
	for macro: int in _MACRO_BIOMES:
		var frac: float = float(int(macro_counts.get(macro, 0))) / total
		if abs(frac - even_share) > BALANCE_DEVIATION_MAX:
			return false
	return true

func get_balance_hint(grid: RefCounted) -> String:
	if grid.total_tile_count == 0:
		return "balanced"
	var macro_counts: Dictionary = _count_macros(grid)
	var total: float = float(grid.total_tile_count)
	var even_share: float = 1.0 / float(_MACRO_BIOMES.size())
	var macro_names: Dictionary = {0: "FOREST", 1: "WATER", 2: "STONE", 3: "EARTH"}
	for macro: int in _MACRO_BIOMES:
		var frac: float = float(int(macro_counts.get(macro, 0))) / total
		if abs(frac - even_share) > BALANCE_DEVIATION_MAX:
			return str(macro_names.get(macro, "unknown"))
	return "balanced"

func _count_macros(grid: RefCounted) -> Dictionary:
	var counts: Dictionary = {}
	for macro: int in _MACRO_BIOMES:
		counts[macro] = 0
	for coord_variant in grid.tiles.keys():
		var tile: GardenTile = grid.get_tile(coord_variant)
		if tile == null:
			continue
		var macro: int = int(MACRO_MAP.get(tile.biome, tile.biome))
		if counts.has(macro):
			counts[macro] = int(counts[macro]) + 1
	return counts
