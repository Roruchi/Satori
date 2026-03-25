class_name BiomeType
extends RefCounted

enum Value {
	NONE         = -1,
	# Godai-aligned biome IDs.
	STONE        = 0,  # Chi
	RIVER        = 1,  # Sui
	EMBER_FIELD  = 2,  # Ka
	MEADOW       = 3,  # Fu
	CLAY         = 4,  # Chi + Sui
	DESERT       = 5,  # Chi + Ka
	DUNE         = 6,  # Chi + Fu
	HOT_SPRING   = 7,  # Sui + Ka
	BOG          = 8,  # Sui + Fu
	CINDER_HEATH = 9,  # Ka + Fu
	SACRED_STONE = 10, # Chi + Ku
	VEIL_MARSH   = 11, # Sui + Ku
	EMBER_SHRINE = 12, # Ka + Ku
	CLOUD_RIDGE  = 13, # Fu + Ku

	# Legacy aliases kept to avoid broad breakage while migrating call sites.
	FOREST     = 0,
	WATER      = 1,
	EARTH      = 3,
	SWAMP      = 4,
	TUNDRA     = 5,
	MUDFLAT    = 6,
	MOSSY_CRAG = 7,
	SAVANNAH   = 8,
	CANYON     = 9,
}

## Deprecated — use SeedRecipeRegistry.lookup() instead.
static func mix(_a: BiomeType.Value, _b: BiomeType.Value) -> BiomeType.Value:
	return BiomeType.Value.NONE
