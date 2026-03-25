class_name SpiritWanderBounds
extends RefCounted

## Compute a Rect2i in tile-coords that bounds the given coords, expanded by wander_radius.
static func from_coords(coords: Array[Vector2i], wander_radius: int) -> Rect2i:
	if coords.is_empty():
		return Rect2i()
	var min_x: int = coords[0].x
	var max_x: int = coords[0].x
	var min_y: int = coords[0].y
	var max_y: int = coords[0].y
	for coord: Vector2i in coords:
		min_x = min(min_x, coord.x)
		max_x = max(max_x, coord.x)
		min_y = min(min_y, coord.y)
		max_y = max(max_y, coord.y)
	var pos := Vector2i(min_x - wander_radius, min_y - wander_radius)
	var size := Vector2i(
		max_x - min_x + 1 + wander_radius * 2,
		max_y - min_y + 1 + wander_radius * 2
	)
	return Rect2i(pos, size)

## Compute the centroid tile coord of the given coords.
static func centroid(coords: Array[Vector2i]) -> Vector2i:
	if coords.is_empty():
		return Vector2i.ZERO
	var sum_x: int = 0
	var sum_y: int = 0
	for coord: Vector2i in coords:
		sum_x += coord.x
		sum_y += coord.y
	return Vector2i(sum_x / coords.size(), sum_y / coords.size())
