## MountainMeshBuilder — builds a unified ArrayMesh covering all tiles
## in a Stone cluster that has reached the merge threshold.
##
## The resulting mesh is a single surface of extruded boxes, one per tile,
## merged into one draw call.  Replaces individual tile meshes with a
## cohesive Mountain silhouette.

const _HexUtils = preload("res://src/grid/hex_utils.gd")

const TILE_RADIUS: float = 1.0   ## Hex circumradius in world units (matches TileChunkRenderer)
const BASE_HEIGHT: float = 0.35  ## Height of the base plateau
const PEAK_HEIGHT: float = 0.90  ## Max height at the cluster centroid
const SNOW_START_T: float = 0.72 ## Normalised height fraction where snow begins

## Build a unified Mountain mesh for the given tile coordinates.
## Returns an ArrayMesh; the caller is responsible for creating the
## MeshInstance3D node and parenting it to the scene.
static func build_mesh(members: Array[Vector2i]) -> ArrayMesh:
	if members.is_empty():
		return ArrayMesh.new()

	# Compute cluster centroid in world pixel space for height gradient
	var centroid := Vector2.ZERO
	for coord in members:
		centroid += _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	centroid /= float(members.size())

	# Find max distance from centroid to scale heights
	var max_dist := 1.0
	for coord in members:
		var d: float = _HexUtils.axial_to_pixel(coord, TILE_RADIUS).distance_to(centroid)
		if d > max_dist:
			max_dist = d

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for coord in members:
		var dist: float = _HexUtils.axial_to_pixel(coord, TILE_RADIUS).distance_to(centroid)
		var t: float = 1.0 - clampf(dist / max(max_dist, 0.01), 0.0, 1.0)
		var height: float = lerpf(BASE_HEIGHT, PEAK_HEIGHT, t)
		_add_tile_box(surface, coord, height, t)

	surface.generate_normals()
	return surface.commit()


## Add the vertices for one box tile (6 faces × 2 triangles × 3 verts = 36 verts).
## Each tile is centred at its hex world position; box half-extent uses the hex inradius
## (sqrt(3)/2 * TILE_RADIUS) so adjacent hex tiles nearly touch at their flat edges.
## The `t` parameter (0.0 = edge, 1.0 = centre) drives height-based colour mixing.
static func _add_tile_box(surface: SurfaceTool, coord: Vector2i, height: float, t: float) -> void:
	var px: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
	var half: float = TILE_RADIUS * sqrt(3.0) * 0.5   ## hex inradius
	var x0: float = px.x - half
	var x1: float = px.x + half
	var z0: float = px.y - half
	var z1: float = px.y + half
	var y0: float = 0.0
	var y1: float = height

	# Colour selection: snow white for peaks, mid grey for mid slopes, dark base
	var snow_col  := Color(0.94, 0.97, 1.00)
	var mid_col   := Color(0.62, 0.64, 0.68)
	var base_col  := Color(0.40, 0.40, 0.46)
	var col: Color
	if t >= SNOW_START_T:
		var snow_t: float = (t - SNOW_START_T) / (1.0 - SNOW_START_T)
		col = mid_col.lerp(snow_col, snow_t)
	else:
		col = base_col.lerp(mid_col, t / SNOW_START_T)
	surface.set_color(col)

	# Top face (y = y1) — slightly brighter for the exposed surface
	var top_col: Color = col.lightened(0.12)
	surface.set_color(top_col)
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y1, z1))

	var side_col: Color = col.darkened(0.20)
	surface.set_color(side_col)

	# Front face (z = z1)
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y0, z1))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y1, z1))

	# Back face (z = z0)
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z0))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z0))

	var right_col: Color = col.lightened(0.08)
	surface.set_color(right_col)

	# Right face (x = x1) — lit by directional light from the right
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x1, y0, z1))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x1, y1, z0))

	var left_col: Color = col.darkened(0.30)
	surface.set_color(left_col)

	# Left face (x = x0) — in shadow
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x0, y0, z0))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x0, y1, z1))

	surface.set_color(base_col.darkened(0.15))

	# Bottom face (y = y0) — optional, hidden by ground plane
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y0, z1))
