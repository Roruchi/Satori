## Test Suite: BitmaskAutotiler
##
## GUT unit tests for src/rendering/bitmask_autotiler.gd
## Updated for 6-bit hex bitmask with 13 canonical forms.
## Run via tests/gut_runner.tscn

extends GutTest

const _BitmaskAutotiler = preload("res://src/rendering/bitmask_autotiler.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# BitmaskAutotiler.compute_bitmask — 6-bit hex
# ---------------------------------------------------------------------------

func test_isolated_tile_returns_zero() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Isolated tile should have bitmask 0x00")


func test_e_neighbour_sets_bit0() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 0) != 0, "E neighbour should set bit 0")


func test_se_neighbour_sets_bit2() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 2) != 0, "SE neighbour should set bit 2")


func test_all_6_hex_neighbours_returns_0x3f() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var offsets: Array[Vector2i] = [
		Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1),
		Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)
	]
	for off: Vector2i in offsets:
		grid.place_tile(off, BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0x3F, "All 6 same-biome hex neighbours should yield 0x3F")


func test_different_biome_neighbour_does_not_set_bits() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Different-biome neighbour must not set any bitmask bits")


func test_mixed_same_and_different_biomes() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)    # E — bit 0
	grid.place_tile(Vector2i(-1, 0), BiomeType.Value.WATER)    # W — different, no bit
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 1 << 0, "Only same-biome east neighbour should set bit 0")


# ---------------------------------------------------------------------------
# BitmaskAutotiler.to_canonical — D6 reduction, range 0–12
# ---------------------------------------------------------------------------

func test_canonical_zero_for_isolated() -> void:
	var canonical: int = _BitmaskAutotiler.to_canonical(0x00)
	assert_eq(canonical, 0, "Isolated bitmask 0 should map to canonical index 0")


func test_canonical_twelve_for_fully_surrounded() -> void:
	var canonical: int = _BitmaskAutotiler.to_canonical(0x3F)
	assert_eq(canonical, 12, "Fully surrounded (0x3F) should map to canonical index 12")


func test_canonical_is_in_valid_range() -> void:
	for raw: int in range(64):
		var canonical: int = _BitmaskAutotiler.to_canonical(raw)
		assert_true(canonical >= 0 and canonical <= 12,
			"Canonical index must be in [0, 12] for raw bitmask %d" % raw)


func test_canonical_has_exactly_13_distinct_values() -> void:
	var seen: Dictionary = {}
	for raw: int in range(64):
		seen[_BitmaskAutotiler.to_canonical(raw)] = true
	assert_eq(seen.size(), 13,
		"Exactly 13 distinct canonical classes must exist across all 64 raw bitmasks")
