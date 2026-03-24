## Test Suite: Hex Cluster BFS
##
## GUT unit tests for ClusterMatcher and SpatialQuery.get_connected_region()
## operating on a hex grid.
## Run via tests/gut_runner.tscn

extends GutTest

const HexUtils = preload("res://src/grid/hex_utils.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


func _make_lookup(grid: RefCounted) -> Callable:
	return func(coord: Vector2i) -> GardenTile:
		return grid.get_tile(coord)


# ---------------------------------------------------------------------------
# SpatialQuery.get_connected_region — hex BFS
# ---------------------------------------------------------------------------

func test_single_tile_cluster_has_size_1() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i.ZERO, BiomeType.Value.FOREST, _make_lookup(grid))
	assert_eq(region.size(), 1, "Single island tile must produce cluster of size 1")


func test_3_tile_hex_line_detected_as_cluster() -> void:
	var grid: RefCounted = _make_grid()
	# Three tiles in a straight line: (0,0), (1,0), (2,0)
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i.ZERO, BiomeType.Value.FOREST, _make_lookup(grid))
	assert_eq(region.size(), 3,
		"Three connected tiles in a line must form a cluster of size 3")


func test_3_tile_hex_triangle_detected_as_cluster() -> void:
	var grid: RefCounted = _make_grid()
	# Triangular cluster using hex adjacency: (0,0), (1,0), (0,1)
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.FOREST)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i.ZERO, BiomeType.Value.FOREST, _make_lookup(grid))
	assert_eq(region.size(), 3,
		"Triangular hex cluster must be detected as size 3")


func test_bfs_does_not_cross_different_biome() -> void:
	var grid: RefCounted = _make_grid()
	# (0,0) Forest, (1,0) Water, (2,0) Forest — the two Forest tiles are not connected
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i.ZERO, BiomeType.Value.FOREST, _make_lookup(grid))
	assert_eq(region.size(), 1,
		"BFS must not cross a different-biome tile: region should be size 1")


func test_square_diagonal_not_adjacent_in_hex() -> void:
	# (0,0) and (1,1) are square-grid diagonal neighbors — NOT hex-adjacent
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 1), BiomeType.Value.FOREST)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i.ZERO, BiomeType.Value.FOREST, _make_lookup(grid))
	assert_eq(region.size(), 1,
		"Square-diagonal (1,1) must NOT be connected to (0,0) in hex BFS")


func test_edge_tile_with_few_neighbors_no_error() -> void:
	var grid: RefCounted = _make_grid()
	# Isolated tile at an extreme coordinate — all 6 neighbor calls return null
	grid.place_tile(Vector2i(100, -200), BiomeType.Value.STONE)
	var sq := SpatialQuery.new()
	var region: Array[Vector2i] = sq.get_connected_region(
		Vector2i(100, -200), BiomeType.Value.STONE, _make_lookup(grid))
	assert_eq(region.size(), 1,
		"Edge tile with no placed neighbors must return cluster of 1 without errors")


# ---------------------------------------------------------------------------
# ClusterMatcher integration
# ---------------------------------------------------------------------------

func test_cluster_matcher_detects_hex_cluster_at_threshold() -> void:
	var matcher := ClusterMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "test_hex_cluster"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 3

	var grid: RefCounted = _make_grid()
	# Hex-adjacent trio
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.FOREST)

	var sq := SpatialQuery.new()
	var signal_obj: DiscoverySignal = matcher.evaluate(pattern, grid, sq)
	assert_not_null(signal_obj,
		"ClusterMatcher must return a DiscoverySignal for a 3-tile hex cluster at threshold 3")


func test_cluster_matcher_returns_null_below_threshold() -> void:
	var matcher := ClusterMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "test_hex_cluster_small"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 5

	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)

	var sq := SpatialQuery.new()
	var signal_obj: DiscoverySignal = matcher.evaluate(pattern, grid, sq)
	assert_null(signal_obj,
		"ClusterMatcher must return null when cluster size is below threshold")
