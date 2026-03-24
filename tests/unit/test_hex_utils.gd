## Test Suite: HexUtils
##
## GUT unit tests for src/grid/hex_utils.gd
## Run via tests/gut_runner.tscn

extends GutTest

const HexUtils = preload("res://src/grid/hex_utils.gd")


# ---------------------------------------------------------------------------
# get_neighbors
# ---------------------------------------------------------------------------

func test_get_neighbors_returns_6_coords() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_eq(neighbors.size(), 6, "get_neighbors must return exactly 6 coords")


func test_get_neighbors_contains_all_6_offsets() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	for offset: Vector2i in HexUtils.HEX_NEIGHBORS:
		assert_true(neighbors.has(offset),
			"Neighbor list must contain offset %s" % str(offset))


func test_get_neighbors_origin_matches_hex_neighbors_constant() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_eq(neighbors.size(), HexUtils.HEX_NEIGHBORS.size())
	for i: int in range(6):
		assert_eq(neighbors[i], HexUtils.HEX_NEIGHBORS[i])


func test_get_neighbors_offset_coords_are_shifted_from_center() -> void:
	var center := Vector2i(3, -2)
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(center)
	for nb: Vector2i in neighbors:
		var diff: Vector2i = nb - center
		assert_true(HexUtils.HEX_NEIGHBORS.has(diff),
			"Each neighbor must differ from center by exactly one HEX_NEIGHBOR offset")


func test_e_neighbor_is_at_1_0() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(1, 0)), "E neighbor must be at (1,0)")


func test_w_neighbor_is_at_minus1_0() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(-1, 0)), "W neighbor must be at (-1,0)")


func test_se_neighbor_is_at_0_1() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(0, 1)), "SE neighbor must be at (0,1)")


func test_nw_neighbor_is_at_0_minus1() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(0, -1)), "NW neighbor must be at (0,-1)")


func test_ne_neighbor_is_at_1_minus1() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(1, -1)), "NE neighbor must be at (1,-1)")


func test_sw_neighbor_is_at_minus1_1() -> void:
	var neighbors: Array[Vector2i] = HexUtils.get_neighbors(Vector2i.ZERO)
	assert_true(neighbors.has(Vector2i(-1, 1)), "SW neighbor must be at (-1,1)")


# ---------------------------------------------------------------------------
# axial_distance
# ---------------------------------------------------------------------------

func test_distance_same_tile_is_zero() -> void:
	var d: int = HexUtils.axial_distance(Vector2i(2, -3), Vector2i(2, -3))
	assert_eq(d, 0, "Distance from a tile to itself must be 0")


func test_distance_adjacent_tile_is_one() -> void:
	for offset: Vector2i in HexUtils.HEX_NEIGHBORS:
		var d: int = HexUtils.axial_distance(Vector2i.ZERO, offset)
		assert_eq(d, 1,
			"Distance to neighbor %s must be 1" % str(offset))


func test_distance_is_symmetric() -> void:
	var a := Vector2i(2, -1)
	var b := Vector2i(-3, 4)
	assert_eq(HexUtils.axial_distance(a, b), HexUtils.axial_distance(b, a),
		"Distance must be symmetric")


func test_distance_known_value() -> void:
	# (0,0) to (3,0): q-axis, 3 steps
	var d: int = HexUtils.axial_distance(Vector2i.ZERO, Vector2i(3, 0))
	assert_eq(d, 3, "Distance from (0,0) to (3,0) must be 3")


func test_distance_diagonal_known_value() -> void:
	# (0,0) to (2,2): cube coords (2,2,-4) → distance = max(2,2,4) = 4
	var d: int = HexUtils.axial_distance(Vector2i.ZERO, Vector2i(2, 2))
	assert_eq(d, 4, "Distance from (0,0) to (2,2) must be 4")


# ---------------------------------------------------------------------------
# axial_to_pixel
# ---------------------------------------------------------------------------

func test_origin_maps_to_zero_pixel() -> void:
	var px: Vector2 = HexUtils.axial_to_pixel(Vector2i.ZERO, 32.0)
	assert_almost_eq(px.x, 0.0, 0.001, "Origin x must be 0")
	assert_almost_eq(px.y, 0.0, 0.001, "Origin y must be 0")


func test_e_neighbor_maps_to_positive_x() -> void:
	var px: Vector2 = HexUtils.axial_to_pixel(Vector2i(1, 0), 32.0)
	assert_true(px.x > 0.0, "E neighbor must have positive pixel x")
	assert_almost_eq(px.y, 0.0, 0.001, "E neighbor pixel y must be 0")


# ---------------------------------------------------------------------------
# pixel_to_axial (round-trip)
# ---------------------------------------------------------------------------

func test_roundtrip_origin() -> void:
	var result: Vector2i = HexUtils.pixel_to_axial(Vector2.ZERO, 32.0)
	assert_eq(result, Vector2i.ZERO, "pixel_to_axial(axial_to_pixel(origin)) must return origin")


func test_roundtrip_e_neighbor() -> void:
	var coord := Vector2i(1, 0)
	var px: Vector2 = HexUtils.axial_to_pixel(coord, 32.0)
	var back: Vector2i = HexUtils.pixel_to_axial(px, 32.0)
	assert_eq(back, coord, "Round-trip for E neighbor must return (1,0)")


func test_roundtrip_arbitrary_coord() -> void:
	var coord := Vector2i(3, -2)
	var px: Vector2 = HexUtils.axial_to_pixel(coord, 48.0)
	var back: Vector2i = HexUtils.pixel_to_axial(px, 48.0)
	assert_eq(back, coord, "Round-trip for (3,-2) must return (3,-2)")


func test_roundtrip_several_coords() -> void:
	var coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1),
		Vector2i(2, -2), Vector2i(0, 3), Vector2i(-3, 0),
	]
	for coord: Vector2i in coords:
		var px: Vector2 = HexUtils.axial_to_pixel(coord, 24.0)
		var back: Vector2i = HexUtils.pixel_to_axial(px, 24.0)
		assert_eq(back, coord, "Round-trip must hold for coord %s" % str(coord))


# ---------------------------------------------------------------------------
# axial_ring
# ---------------------------------------------------------------------------

func test_ring_radius_0_returns_empty() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 0)
	assert_eq(ring.size(), 0, "Ring of radius 0 must be empty")


func test_ring_radius_1_returns_6_tiles() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 1)
	assert_eq(ring.size(), 6, "Ring of radius 1 must have 6 tiles")


func test_ring_radius_2_returns_12_tiles() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 2)
	assert_eq(ring.size(), 12, "Ring of radius 2 must have 12 tiles")


func test_ring_radius_3_returns_18_tiles() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 3)
	assert_eq(ring.size(), 18, "Ring of radius 3 must have 18 tiles")


func test_ring_radius_1_tiles_are_all_at_distance_1() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 1)
	for coord: Vector2i in ring:
		assert_eq(HexUtils.axial_distance(Vector2i.ZERO, coord), 1,
			"All ring-1 tiles must be at distance 1 from center")


func test_ring_radius_2_tiles_are_all_at_distance_2() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 2)
	for coord: Vector2i in ring:
		assert_eq(HexUtils.axial_distance(Vector2i.ZERO, coord), 2,
			"All ring-2 tiles must be at distance 2 from center")


func test_ring_radius_1_matches_hex_neighbors() -> void:
	var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, 1)
	for nb: Vector2i in HexUtils.HEX_NEIGHBORS:
		assert_true(ring.has(nb),
			"Ring-1 must contain neighbor %s" % str(nb))


func test_ring_no_duplicates() -> void:
	for r: int in [1, 2, 3]:
		var ring: Array[Vector2i] = HexUtils.axial_ring(Vector2i.ZERO, r)
		var seen: Dictionary = {}
		for coord: Vector2i in ring:
			assert_false(seen.has(coord),
				"Ring must not contain duplicate coords at radius %d" % r)
			seen[coord] = true
