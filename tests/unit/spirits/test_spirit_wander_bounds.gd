## Test Suite: SpiritWanderBounds
##
## GUT unit tests for SpiritWanderBounds.from_coords() and centroid().
## Run via tests/gut_runner.tscn

extends GutTest


func test_from_coords_single_coord_with_radius_produces_correct_rect() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	var result: Rect2i = SpiritWanderBounds.from_coords(coords, 3)
	assert_eq(result.position, Vector2i(-3, -3),
		"Single coord at origin with radius=3 should start at (-3,-3)")
	assert_eq(result.size, Vector2i(7, 7),
		"Single coord at origin with radius=3 should have size (7,7)")


func test_from_coords_single_coord_offset_with_radius() -> void:
	var coords: Array[Vector2i] = [Vector2i(5, 2)]
	var result: Rect2i = SpiritWanderBounds.from_coords(coords, 4)
	assert_eq(result.position, Vector2i(1, -2),
		"Single coord (5,2) with radius=4 should start at (1,-2)")
	assert_eq(result.size, Vector2i(9, 9),
		"Single coord with radius=4 should have size (9,9)")


func test_from_coords_multiple_coords_has_correct_size() -> void:
	var coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2)
	]
	var result: Rect2i = SpiritWanderBounds.from_coords(coords, 2)
	# Tile span: x=[0,2], y=[0,2] -> size = (3,3) + 2*2 = (7,7)
	assert_eq(result.size, Vector2i(7, 7),
		"3 coords spanning 3x3 with radius=2 should have size (7,7)")
	assert_eq(result.position, Vector2i(-2, -2),
		"Position should be (min_x-radius, min_y-radius)")


func test_from_coords_empty_returns_empty_rect() -> void:
	var coords: Array[Vector2i] = []
	var result: Rect2i = SpiritWanderBounds.from_coords(coords, 5)
	assert_eq(result, Rect2i(), "Empty coords should return empty Rect2i")


func test_centroid_symmetric_coords_returns_center() -> void:
	var coords: Array[Vector2i] = [
		Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)
	]
	var result: Vector2i = SpiritWanderBounds.centroid(coords)
	assert_eq(result, Vector2i(0, 0), "Symmetric coords should have centroid at origin")


func test_centroid_single_coord_returns_that_coord() -> void:
	var coords: Array[Vector2i] = [Vector2i(3, -1)]
	var result: Vector2i = SpiritWanderBounds.centroid(coords)
	assert_eq(result, Vector2i(3, -1), "Single coord centroid should be the coord itself")


func test_centroid_empty_returns_zero() -> void:
	var coords: Array[Vector2i] = []
	var result: Vector2i = SpiritWanderBounds.centroid(coords)
	assert_eq(result, Vector2i.ZERO, "Empty coords centroid should return Vector2i.ZERO")


func test_centroid_line_returns_midpoint() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(4, 0)]
	var result: Vector2i = SpiritWanderBounds.centroid(coords)
	assert_eq(result, Vector2i(2, 0), "Centroid of (0,0)-(4,0) should be (2,0)")
