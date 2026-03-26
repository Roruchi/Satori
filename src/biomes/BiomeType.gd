class_name BiomeType
extends RefCounted

enum Value {
	NONE              = -1,
	# Godai-aligned biome IDs.
	STONE             = 0,  # Chi
	RIVER             = 1,  # Sui
	EMBER_FIELD       = 2,  # Ka
	MEADOW            = 3,  # Fu
	WETLANDS          = 4,  # Chi + Sui — mud, patience, submerged life
	BADLANDS          = 5,  # Chi + Ka  — baked earth, survival, time
	WHISTLING_CANYONS = 6,  # Chi + Fu  — vertical erosion, sweeping change
	PRISMATIC_TERRACES = 7, # Sui + Ka  — geothermal warmth, scalding pools
	FROSTLANDS        = 8,  # Sui + Fu  — piercing wind, frozen water, endurance
	THE_ASHFALL       = 9,  # Ka + Fu   — scorch marks, glowing ash in the wind
	SACRED_STONE      = 10, # Chi + Ku
	MOONLIT_POOL      = 11, # Sui + Ku
	EMBER_SHRINE      = 12, # Ka + Ku
	CLOUD_RIDGE       = 13, # Fu + Ku
	KU                = 14, # Ku (standalone abyss — void separator)

	# Legacy aliases — kept for backward compatibility with older call sites.
	FOREST       = 0,
	WATER        = 1,
	EARTH        = 3,
	CLAY         = 4,
	SWAMP        = 4,
	DESERT       = 5,
	TUNDRA       = 5,
	DUNE         = 6,
	MUDFLAT      = 6,
	HOT_SPRING   = 7,
	MOSSY_CRAG   = 7,
	BOG          = 8,
	SAVANNAH     = 8,
	CINDER_HEATH = 9,
	CANYON       = 9,
	VEIL_MARSH   = 11,
}

## Deprecated — use SeedRecipeRegistry.lookup() instead.
static func mix(_a: BiomeType.Value, _b: BiomeType.Value) -> BiomeType.Value:
	return BiomeType.Value.NONE
