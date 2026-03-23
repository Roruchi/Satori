class_name BiomeType
extends RefCounted

enum Value {
	NONE       = -1,
	FOREST     = 0,
	WATER      = 1,
	STONE      = 2,
	EARTH      = 3,
	SWAMP      = 4,  # Forest + Water
	TUNDRA     = 5,  # Stone  + Water
	MUDFLAT    = 6,  # Earth  + Water
	MOSSY_CRAG = 7,  # Forest + Stone
	SAVANNAH   = 8,  # Forest + Earth
	CANYON     = 9,  # Stone  + Earth
}

## Returns the hybrid biome produced by mixing two base tiles.
## Returns NONE if either input is not a base tile, if inputs are the same,
## or if the combination has no defined result.
static func mix(a: BiomeType.Value, b: BiomeType.Value) -> BiomeType.Value:
	if a == b or a == BiomeType.Value.NONE or b == BiomeType.Value.NONE:
		return BiomeType.Value.NONE
	# Only base tiles (0–3) can be mixed; hybrids are locked
	if int(a) > 3 or int(b) > 3:
		return BiomeType.Value.NONE

	# Normalise to (lo, hi) so mixing is commutative
	var lo := mini(int(a), int(b))
	var hi := maxi(int(a), int(b))

	match [lo, hi]:
		[0, 1]: return BiomeType.Value.SWAMP       # FOREST + WATER
		[0, 2]: return BiomeType.Value.MOSSY_CRAG  # FOREST + STONE
		[0, 3]: return BiomeType.Value.SAVANNAH    # FOREST + EARTH
		[1, 2]: return BiomeType.Value.TUNDRA      # STONE  + WATER
		[1, 3]: return BiomeType.Value.MUDFLAT     # EARTH  + WATER
		[2, 3]: return BiomeType.Value.CANYON      # STONE  + EARTH

	return BiomeType.Value.NONE
