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
	assert_eq(BiomeType.mix(BiomeType.Value.CLAY, BiomeType.Value.DUNE), BiomeType.Value.NONE)

func test_enum_count_includes_expected_named_values() -> void:
	var names: PackedStringArray = BiomeType.Value.keys()
	assert_true(names.has("NONE"))
	assert_true(names.has("STONE"))
	assert_true(names.has("RIVER"))
	assert_true(names.has("EMBER_FIELD"))
	assert_true(names.has("MEADOW"))
	assert_true(names.has("CLAY"))
	assert_true(names.has("DESERT"))
	assert_true(names.has("DUNE"))
	assert_true(names.has("HOT_SPRING"))
	assert_true(names.has("BOG"))
	assert_true(names.has("CINDER_HEATH"))
	assert_true(names.has("SACRED_STONE"))
	assert_true(names.has("VEIL_MARSH"))
	assert_true(names.has("EMBER_SHRINE"))
	assert_true(names.has("CLOUD_RIDGE"))
