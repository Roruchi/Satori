## BiomeTransitionLayer — spawns procedural decoration voxels on biome-pair edges.
##
## When two tiles with a registered biome-pair transition become hex
## neighbours, this layer spawns lightweight MeshInstance3D decoration nodes
## at the shared edge midpoint.
##
## The library of transitions is data-driven:
##   _library[pair_key] → Resource (with "mesh" meta)
##
## Decorations are permanent (placements are permanent in Satori).
## The same edge is never decorated twice.

class_name BiomeTransitionLayer
extends Node3D

const _HexUtils = preload("res://src/grid/hex_utils.gd")

const TILE_RADIUS: float = 1.0

## Registered biome-pair → TransitionDecorationData.
var _library: Dictionary = {}

## Active edge records to prevent double-spawning: edge_key → true.
var _active_edges: Dictionary = {}


func _ready() -> void:
	_init_library()


## Return the TransitionDecorationData for a biome pair, or null if none.
## Lookup is commutative: (a,b) == (b,a).
func get_transition(biome_a: int, biome_b: int) -> Resource:
	if biome_a == biome_b:
		return null
	return _library.get(_pair_key(biome_a, biome_b), null)


## Called by VoxelRenderer when a tile is placed at `coord`.
## Checks all 6 hex neighbours for registered biome-pair transitions
## and spawns decorations for any new edges found.
func on_tile_placed(coord: Vector2i, grid: RefCounted) -> void:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return

	for offset in _HexUtils.HEX_NEIGHBORS:
		var neighbour_coord: Vector2i = coord + offset
		var neighbour: GardenTile = grid.get_tile(neighbour_coord)
		if neighbour == null:
			continue

		var data: Resource = get_transition(tile.biome, neighbour.biome)
		if data == null:
			continue

		# Build a canonical, order-independent edge key
		var edge_key: String = _edge_key(coord, neighbour_coord)
		if _active_edges.has(edge_key):
			continue  # already decorated

		_active_edges[edge_key] = true
		_spawn_decoration(coord, neighbour_coord, tile.biome, neighbour.biome, data)


## Spawn decoration nodes for a biome-pair edge.
## `primary_coord` is the tile whose biome drives decoration placement.
func _spawn_decoration(
	primary_coord: Vector2i,
	secondary_coord: Vector2i,
	biome_a: int,
	biome_b: int,
	data: Resource
) -> void:
	# Place decoration at the world-space midpoint of the shared edge
	var px_a: Vector2 = _HexUtils.axial_to_pixel(primary_coord, TILE_RADIUS)
	var px_b: Vector2 = _HexUtils.axial_to_pixel(secondary_coord, TILE_RADIUS)
	var world_a := Vector3(px_a.x, 0.0, px_a.y)
	var world_b := Vector3(px_b.x, 0.0, px_b.y)
	var midpoint: Vector3 = (world_a + world_b) * 0.5

	# Use the mesh from the data resource, or a generated fallback
	var mesh: Mesh = data.get("mesh") if data else null
	if mesh == null:
		mesh = _make_reed_mesh(biome_a, biome_b)

	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = midpoint
	node.name = "Decoration_%s_%s" % [str(primary_coord), str(secondary_coord)]
	add_child(node)


## Build the MVP transition library with all 5 registered biome-pair types.
func _init_library() -> void:
	_register(BiomeType.Value.FOREST, BiomeType.Value.WATER,   _make_reed_data())
	_register(BiomeType.Value.STONE,  BiomeType.Value.WATER,   _make_rocky_shore_data())
	_register(BiomeType.Value.EARTH,  BiomeType.Value.WATER,   _make_sandy_bank_data())
	_register(BiomeType.Value.FOREST, BiomeType.Value.EARTH,   _make_fallen_log_data())


func _register(biome_a: int, biome_b: int, data: Resource) -> void:
	_library[_pair_key(biome_a, biome_b)] = data


# ---------------------------------------------------------------------------
# Fallback procedural decoration mesh generators
# (replaced by authored .tres assets when available)
# ---------------------------------------------------------------------------

## Reed cluster: 3 thin vertical sticks in a line, coloured dark green.
func _make_reed_data() -> Resource:
	var res := Resource.new()
	res.set_meta("mesh", _make_reed_mesh(BiomeType.Value.FOREST, BiomeType.Value.WATER))
	return res


func _make_reed_mesh(_biome_a: int, _biome_b: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(0.15, 0.45, 0.15))
	# Three small box "reeds" offset from centre
	var offsets: Array[Vector3] = [
		Vector3(-0.15, 0.0, 0.0),
		Vector3(0.0,   0.0, 0.0),
		Vector3(0.15,  0.0, 0.0),
	]
	for off in offsets:
		_add_reed_stick(st, off)
	st.generate_normals()
	return st.commit()


func _add_reed_stick(st: SurfaceTool, offset: Vector3) -> void:
	var hw: float = 0.04   ## half-width
	var h: float  = 0.35   ## height
	var x0 := offset.x - hw
	var x1 := offset.x + hw
	var z0 := offset.z - hw
	var z1 := offset.z + hw
	# Top face
	st.add_vertex(Vector3(x0, h, z0))
	st.add_vertex(Vector3(x1, h, z0))
	st.add_vertex(Vector3(x1, h, z1))
	st.add_vertex(Vector3(x0, h, z0))
	st.add_vertex(Vector3(x1, h, z1))
	st.add_vertex(Vector3(x0, h, z1))
	# Front face
	st.add_vertex(Vector3(x0, 0.0, z1))
	st.add_vertex(Vector3(x1, 0.0, z1))
	st.add_vertex(Vector3(x1, h, z1))
	st.add_vertex(Vector3(x0, 0.0, z1))
	st.add_vertex(Vector3(x1, h, z1))
	st.add_vertex(Vector3(x0, h, z1))


## Rocky shore: a low, wide flat box in a grey-blue tone.
func _make_rocky_shore_data() -> Resource:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.08, 0.3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.50, 0.55)
	mesh.surface_set_material(0, mat)
	var res := Resource.new()
	res.set_meta("mesh", mesh)
	return res


## Sandy bank: low flat box in a sandy tan.
func _make_sandy_bank_data() -> Resource:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.06, 0.25)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.50)
	mesh.surface_set_material(0, mat)
	var res := Resource.new()
	res.set_meta("mesh", mesh)
	return res


## Fallen log: elongated cylinder-ish box in brown.
func _make_fallen_log_data() -> Resource:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.7, 0.12, 0.18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.28, 0.10)
	mesh.surface_set_material(0, mat)
	var res := Resource.new()
	res.set_meta("mesh", mesh)
	return res


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Deterministic, order-independent string key for a tile-pair edge.
static func _edge_key(a: Vector2i, b: Vector2i) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return "%d,%d|%d,%d" % [a.x, a.y, b.x, b.y]
	return "%d,%d|%d,%d" % [b.x, b.y, a.x, a.y]


## Deterministic, order-independent string key for a biome pair.
static func _pair_key(a: int, b: int) -> String:
	if a <= b:
		return "%d_%d" % [a, b]
	return "%d_%d" % [b, a]
