## Test Suite: BitmaskAutotiler
##
## GUT unit tests for src/rendering/bitmask_autotiler.gd
## Run via tests/gut_runner.tscn

extends GutTest

const _BitmaskAutotiler = preload("res://src/rendering/bitmask_autotiler.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# BitmaskAutotiler.compute_bitmask
# ---------------------------------------------------------------------------

func test_isolated_tile_returns_zero() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Isolated tile should have bitmask 0x00")


func test_east_neighbour_sets_bit4() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	# bit 4 = E
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 4) != 0, "East neighbour should set bit 4")


func test_north_neighbour_sets_bit1() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, -1), BiomeType.Value.FOREST)
	# bit 1 = N
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 1) != 0, "North neighbour should set bit 1")


func test_all_8_neighbours_returns_0xff() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			grid.place_tile(Vector2i(dx, dy), BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0xFF, "All 8 same-biome neighbours should yield 0xFF")


func test_different_biome_neighbour_does_not_set_bits() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Different-biome neighbour must not set any bitmask bits")


func test_mixed_same_and_different_biomes() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)   # E — bit 4
	grid.place_tile(Vector2i(-1, 0), BiomeType.Value.WATER)   # W — different, no bit
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 1 << 4, "Only same-biome east neighbour should set bit 4")


# ---------------------------------------------------------------------------
# BitmaskAutotiler.to_canonical
# ---------------------------------------------------------------------------

func test_canonical_zero_for_isolated() -> void:
	var canonical: int = _BitmaskAutotiler.to_canonical(0x00)
	assert_eq(canonical, 0, "Isolated bitmask 0 should map to canonical index 0")


func test_canonical_is_in_valid_range() -> void:
	for raw in range(256):
		var canonical: int = _BitmaskAutotiler.to_canonical(raw)
		assert_true(canonical >= 0 and canonical <= 46,
			"Canonical index must be in [0, 46] for raw bitmask %d" % raw)


func test_canonical_fully_surrounded() -> void:
	var canonical: int = _BitmaskAutotiler.to_canonical(0xFF)
	# 0xFF after normalization → all 4 cardinals + all 4 diagonals survive = card=4, diag=15
	# → canonical = 31 + 15 = 46
	assert_eq(canonical, 46, "Fully surrounded (0xFF) should map to canonical index 46")
