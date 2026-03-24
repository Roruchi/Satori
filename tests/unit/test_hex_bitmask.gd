## Test Suite: Hex Bitmask Autotiler
##
## GUT unit tests for the 6-bit hex bitmask and D6 canonical reduction in
## src/rendering/bitmask_autotiler.gd
## Run via tests/gut_runner.tscn

extends GutTest

const _BitmaskAutotiler = preload("res://src/rendering/bitmask_autotiler.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# compute_bitmask — 6-bit hex bitmask
# ---------------------------------------------------------------------------

func test_isolated_tile_bitmask_is_zero() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Isolated tile must have bitmask 0")


func test_e_neighbor_sets_bit0() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)   # E neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 0) != 0, "E neighbor must set bit 0")


func test_w_neighbor_sets_bit1() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(-1, 0), BiomeType.Value.FOREST)  # W neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 1) != 0, "W neighbor must set bit 1")


func test_se_neighbor_sets_bit2() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.FOREST)   # SE neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 2) != 0, "SE neighbor must set bit 2")


func test_nw_neighbor_sets_bit3() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, -1), BiomeType.Value.FOREST)  # NW neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 3) != 0, "NW neighbor must set bit 3")


func test_ne_neighbor_sets_bit4() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, -1), BiomeType.Value.FOREST)  # NE neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 4) != 0, "NE neighbor must set bit 4")


func test_sw_neighbor_sets_bit5() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(-1, 1), BiomeType.Value.FOREST)  # SW neighbor
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_true(bitmask & (1 << 5) != 0, "SW neighbor must set bit 5")


func test_all_6_hex_neighbors_yield_bitmask_63() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	var offsets: Array[Vector2i] = [
		Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1),
		Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)
	]
	for off: Vector2i in offsets:
		grid.place_tile(off, BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0x3F, "All 6 same-biome hex neighbors must yield bitmask 0x3F (63)")


func test_different_biome_neighbor_does_not_set_bit() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Different-biome neighbor must not set any bitmask bits")


func test_bitmask_square_diagonal_not_included() -> void:
	# (1,1) is a square diagonal — NOT a hex neighbor
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 1), BiomeType.Value.FOREST)
	var bitmask: int = _BitmaskAutotiler.compute_bitmask(Vector2i.ZERO, grid)
	assert_eq(bitmask, 0, "Square-diagonal (1,1) must not contribute to hex bitmask")


# ---------------------------------------------------------------------------
# to_canonical — D6 canonical reduction (0–12)
# ---------------------------------------------------------------------------

func test_canonical_isolated_is_0() -> void:
	var c: int = _BitmaskAutotiler.to_canonical(0)
	assert_eq(c, 0, "Isolated tile (bitmask 0) must map to canonical 0")


func test_canonical_full_is_12() -> void:
	var c: int = _BitmaskAutotiler.to_canonical(0x3F)
	assert_eq(c, 12, "Fully surrounded (bitmask 63) must map to canonical 12")


func test_canonical_range_0_to_12_for_all_inputs() -> void:
	for raw: int in range(64):
		var c: int = _BitmaskAutotiler.to_canonical(raw)
		assert_true(c >= 0 and c <= 12,
			"Canonical index must be in [0,12] for raw bitmask %d (got %d)" % [raw, c])


func test_canonical_exactly_13_distinct_values() -> void:
	var seen: Dictionary = {}
	for raw: int in range(64):
		seen[_BitmaskAutotiler.to_canonical(raw)] = true
	assert_eq(seen.size(), 13,
		"There must be exactly 13 distinct canonical classes across all 64 raw bitmasks")


func test_rotation_equivalent_raw_values_share_canonical() -> void:
	# E only (bit0=1) and SE only (bit2=4) are rotations of each other
	var c_e: int = _BitmaskAutotiler.to_canonical(1)   # E only
	var c_se: int = _BitmaskAutotiler.to_canonical(4)  # SE only
	assert_eq(c_e, c_se,
		"E-only and SE-only bitmasks must share the same canonical index (both are single-tip)")


func test_reflection_equivalent_raw_values_share_canonical() -> void:
	# E+SE (bits 0,2 = mask 5) reflects to E+NE (bits 0,4 = mask 17)
	var c_ese: int = _BitmaskAutotiler.to_canonical(5)   # E + SE
	var c_ene: int = _BitmaskAutotiler.to_canonical(17)  # E + NE
	assert_eq(c_ese, c_ene,
		"E+SE and E+NE are reflections; they must share the same canonical index")


func test_opposite_pair_canonical_equals_for_all_3_opposite_pairs() -> void:
	# E+W (bits 0,1 = mask 3), SE+NW (bits 2,3 = mask 12), NE+SW (bits 4,5 = mask 48)
	var c0: int = _BitmaskAutotiler.to_canonical(3)   # E + W
	var c1: int = _BitmaskAutotiler.to_canonical(12)  # SE + NW
	var c2: int = _BitmaskAutotiler.to_canonical(48)  # NE + SW
	assert_eq(c0, c1, "E+W and SE+NW must share canonical (both are opposite pairs)")
	assert_eq(c1, c2, "SE+NW and NE+SW must share canonical (both are opposite pairs)")
