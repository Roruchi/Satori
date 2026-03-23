extends GutTest


# ---------------------------------------------------------------------------
# Individual combo assertions
# ---------------------------------------------------------------------------

func test_forest_plus_water_produces_swamp() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.FOREST, BiomeType.Value.WATER),
		BiomeType.Value.SWAMP
	)


func test_stone_plus_water_produces_tundra() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.STONE, BiomeType.Value.WATER),
		BiomeType.Value.TUNDRA
	)


func test_earth_plus_water_produces_mudflat() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.EARTH, BiomeType.Value.WATER),
		BiomeType.Value.MUDFLAT
	)


func test_forest_plus_stone_produces_mossy_crag() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.FOREST, BiomeType.Value.STONE),
		BiomeType.Value.MOSSY_CRAG
	)


func test_forest_plus_earth_produces_savannah() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.FOREST, BiomeType.Value.EARTH),
		BiomeType.Value.SAVANNAH
	)


func test_stone_plus_earth_produces_canyon() -> void:
	assert_eq(
		BiomeType.mix(BiomeType.Value.STONE, BiomeType.Value.EARTH),
		BiomeType.Value.CANYON
	)


# ---------------------------------------------------------------------------
# Invalid-input assertions
# ---------------------------------------------------------------------------

func test_same_biome_returns_none() -> void:
	assert_eq(BiomeType.mix(BiomeType.Value.FOREST, BiomeType.Value.FOREST), BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.WATER,  BiomeType.Value.WATER),  BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.STONE,  BiomeType.Value.STONE),  BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.EARTH,  BiomeType.Value.EARTH),  BiomeType.Value.NONE)


func test_hybrid_input_returns_none() -> void:
	assert_eq(BiomeType.mix(BiomeType.Value.SWAMP,  BiomeType.Value.WATER),  BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.TUNDRA, BiomeType.Value.FOREST), BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.CANYON, BiomeType.Value.EARTH),  BiomeType.Value.NONE)


func test_none_input_returns_none() -> void:
	assert_eq(BiomeType.mix(BiomeType.Value.NONE, BiomeType.Value.FOREST), BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.WATER, BiomeType.Value.NONE),  BiomeType.Value.NONE)


# ---------------------------------------------------------------------------
# Commutativity
# ---------------------------------------------------------------------------

func test_mix_is_commutative_for_all_base_combos() -> void:
	var bases := [
		BiomeType.Value.FOREST,
		BiomeType.Value.WATER,
		BiomeType.Value.STONE,
		BiomeType.Value.EARTH,
	]
	for i: int in range(bases.size()):
		for j: int in range(i + 1, bases.size()):
			assert_eq(
				BiomeType.mix(bases[i], bases[j]),
				BiomeType.mix(bases[j], bases[i]),
				"mix(%s, %s) should be commutative" % [bases[i], bases[j]]
			)
