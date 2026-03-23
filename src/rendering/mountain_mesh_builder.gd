## MountainMeshBuilder — builds a unified ArrayMesh covering all tiles
## in a Stone cluster that has reached the merge threshold.
##
## The resulting mesh is a single surface of extruded boxes, one per tile,
## merged into one draw call.  Replaces individual tile meshes with a
## cohesive Mountain silhouette.

const TILE_SIZE: float = 1.0
const BASE_HEIGHT: float = 0.3   ## Height of the base plateau
const PEAK_HEIGHT: float = 0.8   ## Max height at the cluster centroid

## Build a unified Mountain mesh for the given tile coordinates.
## Returns an ArrayMesh; the caller is responsible for creating the
## MeshInstance3D node and parenting it to the scene.
static func build_mesh(members: Array[Vector2i]) -> ArrayMesh:
	if members.is_empty():
		return ArrayMesh.new()

	# Compute cluster centroid for height gradient
	var centroid := Vector2.ZERO
	for coord in members:
		centroid += Vector2(coord)
	centroid /= float(members.size())

	# Find max distance from centroid to scale heights
	var max_dist := 1.0
	for coord in members:
		var d: float = Vector2(coord).distance_to(centroid)
		if d > max_dist:
			max_dist = d

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for coord in members:
		var dist: float = Vector2(coord).distance_to(centroid)
		var t: float = 1.0 - clampf(dist / max(max_dist, 0.01), 0.0, 1.0)
		var height: float = lerpf(BASE_HEIGHT, PEAK_HEIGHT, t)
		_add_tile_box(surface, coord, height)

	surface.generate_normals()
	return surface.commit()


## Add the vertices for one box tile (6 faces × 2 triangles × 3 verts = 36 verts).
## Coordinate convention: each tile is centred at `coord * TILE_SIZE` in world space.
## This matches TileChunkRenderer which places instances at Vector3(coord.x * TILE_SIZE, 0, coord.y * TILE_SIZE).
## The box spans ±TILE_SIZE/2 around that centre, making adjacent tiles touch exactly at their edges.
static func _add_tile_box(surface: SurfaceTool, coord: Vector2i, height: float) -> void:
	var x0: float = coord.x * TILE_SIZE - TILE_SIZE * 0.5
	var x1: float = x0 + TILE_SIZE
	var z0: float = coord.y * TILE_SIZE - TILE_SIZE * 0.5
	var z1: float = z0 + TILE_SIZE
	var y0: float = 0.0
	var y1: float = height

	# Stone grey colour embedded as vertex colour
	var col := Color(0.55, 0.55, 0.60)
	surface.set_color(col)

	# Top face (y = y1)
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x0, y1, z1))

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

	# Right face (x = x1)
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x1, y0, z1))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x1, y1, z1))
	surface.add_vertex(Vector3(x1, y1, z0))

	# Left face (x = x0)
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x0, y0, z0))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x0, y1, z0))
	surface.add_vertex(Vector3(x0, y1, z1))

	# Bottom face (y = y0) — optional, hidden by ground plane
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y0, z0))
	surface.add_vertex(Vector3(x0, y0, z1))
	surface.add_vertex(Vector3(x1, y0, z1))
