## HexUtils — pure math utilities for axial (pointy-top) hexagonal coordinates.
##
## No class_name: loaded via preload() to avoid scan-order issues.
## No node, no autoload — all functions are static.
##
## Coordinate system: axial (q, r) stored as Vector2i.
## Pointy-top orientation: vertex pointing up/down, flat sides left/right.
##
## Neighbour directions (CW from E): E, SE, SW, W, NW, NE

extends RefCounted

## The six hex neighbour offsets in axial coords (pointy-top).
## Bit assignment used by BitmaskAutotiler:
##   bit 0 = E   bit 1 = W   bit 2 = SE   bit 3 = NW   bit 4 = NE   bit 5 = SW
const HEX_NEIGHBORS: Array[Vector2i] = [
	Vector2i( 1,  0),  # E   (bit 0)
	Vector2i(-1,  0),  # W   (bit 1)
	Vector2i( 0,  1),  # SE  (bit 2)
	Vector2i( 0, -1),  # NW  (bit 3)
	Vector2i( 1, -1),  # NE  (bit 4)
	Vector2i(-1,  1),  # SW  (bit 5)
]


## Return the 6 axial neighbours of coord.
static func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset: Vector2i in HEX_NEIGHBORS:
		neighbors.append(coord + offset)
	return neighbors


## Convert axial coord to pixel centre (pointy-top).
##   px = radius * sqrt(3) * (q + r / 2)
##   py = radius * 1.5     * r
static func axial_to_pixel(coord: Vector2i, radius: float) -> Vector2:
	var px: float = radius * sqrt(3.0) * (float(coord.x) + float(coord.y) * 0.5)
	var py: float = radius * 1.5 * float(coord.y)
	return Vector2(px, py)


## Convert a pixel position to the nearest axial hex coord (via cube-rounding).
static func pixel_to_axial(px: Vector2, radius: float) -> Vector2i:
	var fq: float = (px.x * sqrt(3.0) / 3.0 - px.y / 3.0) / radius
	var fr: float = (px.y * 2.0 / 3.0) / radius
	var fs: float = -fq - fr
	return _cube_round_to_axial(fq, fr, fs)


## Hex distance between two axial coords.
static func axial_distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	var ds: int = -dq - dr
	return (abs(dq) + abs(dr) + abs(ds)) / 2


## Return all axial coords at exactly `radius` hex steps from center.
## Returns an empty array for radius <= 0.
static func axial_ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius <= 0:
		return []
	var results: Array[Vector2i] = []
	# Start at center + SW * radius, then walk 6 sides CW
	var coord: Vector2i = center + HEX_NEIGHBORS[5] * radius  # SW * radius
	const _RING_DIRS: Array[Vector2i] = [
		Vector2i( 1,  0),  # E
		Vector2i( 1, -1),  # NE
		Vector2i( 0, -1),  # NW
		Vector2i(-1,  0),  # W
		Vector2i(-1,  1),  # SW
		Vector2i( 0,  1),  # SE
	]
	for side: int in range(6):
		for _step: int in range(radius):
			results.append(coord)
			coord = coord + _RING_DIRS[side]
	return results


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Round fractional cube coordinates to the nearest integer hex (returns axial).
static func _cube_round_to_axial(fq: float, fr: float, fs: float) -> Vector2i:
	var rq: int = roundi(fq)
	var rr: int = roundi(fr)
	var rs: int = roundi(fs)
	var q_diff: float = abs(float(rq) - fq)
	var r_diff: float = abs(float(rr) - fr)
	var s_diff: float = abs(float(rs) - fs)
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	# rs is derived (axial only stores q and r)
	return Vector2i(rq, rr)
