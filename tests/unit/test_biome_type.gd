extends GutTest

func test_godai_base_values_are_stable() -> void:
	assert_eq(BiomeType.Value.STONE, 0)
	assert_eq(BiomeType.Value.RIVER, 1)
	assert_eq(BiomeType.Value.EMBER_FIELD, 2)
	assert_eq(BiomeType.Value.MEADOW, 3)
	assert_eq(BiomeType.Value.NONE, -1)

func test_mix_is_deprecated_and_returns_none() -> void:
	assert_eq(BiomeType.mix(BiomeType.Value.STONE, BiomeType.Value.RIVER), BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.RIVER, BiomeType.Value.STONE), BiomeType.Value.NONE)
	assert_eq(BiomeType.mix(BiomeType.Value.WETLANDS, BiomeType.Value.WHISTLING_CANYONS), BiomeType.Value.NONE)

func test_enum_count_includes_expected_named_values() -> void:
	var names: PackedStringArray = BiomeType.Value.keys()
	assert_true(names.has("NONE"))
	assert_true(names.has("STONE"))
	assert_true(names.has("RIVER"))
	assert_true(names.has("EMBER_FIELD"))
	assert_true(names.has("MEADOW"))
	assert_true(names.has("WETLANDS"))
	assert_true(names.has("BADLANDS"))
	assert_true(names.has("WHISTLING_CANYONS"))
	assert_true(names.has("PRISMATIC_TERRACES"))
	assert_true(names.has("FROSTLANDS"))
	assert_true(names.has("THE_ASHFALL"))
	assert_true(names.has("SACRED_STONE"))
	assert_true(names.has("MOONLIT_POOL"))
	assert_true(names.has("EMBER_SHRINE"))
	assert_true(names.has("CLOUD_RIDGE"))
