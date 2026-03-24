extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")


func test_shape_partial_matches_rotated_recipe_variants() -> void:
	var evaluator := SpiritRiddleEvaluator.new()
	var registry := DiscoveryRegistry.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "spirit_red_fox"
	pattern.pattern_type = PatternDefinition.PatternType.SHAPE
	pattern.shape_recipe = [
		{"offset": Vector2i(0, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(1, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(0, 1), "biome": BiomeType.Value.FOREST},
	]

	var grid := GridMapScript.new()
	# Two of the three tiles for a rotated triangle should still qualify as partial progress.
	grid.place_tile(Vector2i(2, 2), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 3), BiomeType.Value.FOREST)

	assert_true(
		evaluator.evaluate_partial(pattern, grid, registry),
		"Rotated partial shape should surface a spirit riddle hint"
	)