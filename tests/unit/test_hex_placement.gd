## Test Suite: Hex Grid Placement
##
## GUT unit tests for GridMap.is_placement_valid() with hex adjacency.
## Run via tests/gut_runner.tscn

extends GutTest

const HexUtils = preload("res://src/grid/hex_utils.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# Origin placement
# ---------------------------------------------------------------------------

func test_origin_valid_on_empty_grid() -> void:
	var grid: RefCounted = _make_grid()
	assert_true(grid.is_placement_valid(Vector2i.ZERO),
		"Origin must be valid on an empty grid")


func test_origin_invalid_when_occupied() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	assert_false(grid.is_placement_valid(Vector2i.ZERO),
		"Origin must be invalid once occupied")


# ---------------------------------------------------------------------------
# Hex adjacency — 6 valid neighbors
# ---------------------------------------------------------------------------

func test_all_6_hex_neighbors_are_valid_after_origin_placed() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var valid_count: int = 0
	for offset: Vector2i in HexUtils.HEX_NEIGHBORS:
		if grid.is_placement_valid(offset):
			valid_count += 1
	assert_eq(valid_count, 6,
		"All 6 hex neighbors of the origin must be valid placements")


func test_cardinal_square_neighbor_not_adjacent_in_hex() -> void:
	# (1, 1) is a square-grid diagonal — NOT a hex neighbor of (0,0)
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	assert_false(grid.is_placement_valid(Vector2i(1, 1)),
		"(1,1) is not a hex neighbor of origin and must not be valid via origin alone")


func test_non_adjacent_coord_invalid_with_single_tile() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	assert_false(grid.is_placement_valid(Vector2i(2, 0)),
		"Coord 2 steps away must not be valid with only origin placed")


# ---------------------------------------------------------------------------
# Chained placement
# ---------------------------------------------------------------------------

func test_placement_expands_valid_frontier() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	# (2,0) is a hex neighbor of (1,0) — must now be valid
	assert_true(grid.is_placement_valid(Vector2i(2, 0)),
		"(2,0) must be valid once (1,0) is occupied")


func test_placed_tile_coord_becomes_invalid() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	assert_false(grid.is_placement_valid(Vector2i(1, 0)),
		"An already-occupied coord must not be valid for placement")


# ---------------------------------------------------------------------------
# No errors on isolated extreme coordinates
# ---------------------------------------------------------------------------

func test_extreme_coord_does_not_error() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	# Edge tile — has < 6 in-bounds occupied neighbors, but must not crash
	var result: bool = grid.is_placement_valid(Vector2i(1000, -500))
	assert_false(result, "Extreme coord far from any tile must return false without errors")


func test_negative_coords_work_correctly() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	# (-1, 0) is the W neighbor — must be valid
	assert_true(grid.is_placement_valid(Vector2i(-1, 0)),
		"W neighbor (-1,0) must be a valid placement")
