extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func _make_cluster(id: String, threshold: int) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = id
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = threshold
	return pattern

func _make_compound(id: String, prerequisite_id: String, threshold: int) -> PatternDefinition:
	var pattern := PatternDefinition.new()
	pattern.discovery_id = id
	pattern.pattern_type = PatternDefinition.PatternType.COMPOUND
	pattern.prerequisite_ids = [prerequisite_id]
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = threshold
	return pattern

func test_compound_chain_resolves_in_same_scan_pass() -> void:
	var matcher := PatternMatcher.new()
	matcher.set_patterns([
		_make_compound("disc_c", "disc_b", 3),
		_make_compound("disc_b", "disc_a", 3),
		_make_cluster("disc_a", 3),
	])

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)

	assert_eq(emitted, ["disc_a", "disc_b", "disc_c"], "Compound chain should resolve deterministically within one pass")
