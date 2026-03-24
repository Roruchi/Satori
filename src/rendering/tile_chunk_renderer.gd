## TileChunkRenderer — renders all tiles within one 8×8 grid chunk.
##
## Owns one MultiMeshInstance3D per (canonical variant, LOD level) combination.
## When `mark_dirty()` is called, the MultiMesh data is rebuilt on the next
## _process frame — at most ONE rebuild per chunk per frame regardless of how
## many tiles were placed that frame (idempotent dirty flag).

extends Node3D

const CHUNK_SIZE: int = 8
const TILE_SIZE: float = 1.0     ## World-space size of one tile (1 unit = 32px at standard zoom)
const TILE_HEIGHT: float = 0.0   ## Y offset for tile meshes (ground plane)

## Chunk grid coordinate — set by VoxelRenderer when this node is created.
var chunk_coord: Vector2i = Vector2i.ZERO

## Dirty flag — set via mark_dirty(), cleared after rebuild in _process.
var dirty: bool = false

## Owning mesh library reference — injected by VoxelRenderer.
var mesh_library: TileMeshLibrary = null

## Snapshot of tiles in this chunk: coord → TileRenderState.
## Refreshed from VoxelRenderer._render_states each rebuild.
var _tile_states: Dictionary[Vector2i, TileRenderState] = {}

## MultiMeshInstance3D nodes keyed by (canonical: int, lod: bool) packed as String.
var _mmis: Dictionary[String, MultiMeshInstance3D] = {}

## Shared shader material (injected by VoxelRenderer for colorblind support).
var shared_material: Material = null


## Called by VoxelRenderer each time a tile in this chunk changes.
func mark_dirty() -> void:
	dirty = true


## Inject a full snapshot of the current tile render states for this chunk.
## Called by VoxelRenderer before marking dirty.
func update_tile_states(states: Dictionary) -> void:
	_tile_states.clear()
	for key in states:
		_tile_states[key] = states[key] as TileRenderState


func _process(_delta: float) -> void:
	if dirty:
		dirty = false
		_rebuild()


## Rebuild all MultiMesh data for this chunk from the current tile states.
func _rebuild() -> void:
	if mesh_library == null:
		return

	# Group tiles by (biome, canonical, lod) key so each biome×variant gets its own MultiMesh
	# key → { biome: int, canonical: int, lod: bool, tiles: Array[TileRenderState] }
	var groups: Dictionary = {}

	for state: TileRenderState in _tile_states.values():
		# Skip tiles that are part of a merged Mountain cluster (rendered elsewhere)
		if state.in_mountain:
			continue
		for lod_level: bool in [false, true]:
			var key: String = "%d|%d|%s" % [state.biome, state.canonical, "l" if lod_level else "f"]
			if not groups.has(key):
				groups[key] = {"biome": state.biome, "canonical": state.canonical, "lod": lod_level, "tiles": []}
			(groups[key]["tiles"] as Array).append(state)

	# Ensure MMI nodes exist for each group
	for key: String in groups.keys():
		_ensure_mmi(key, groups[key]["biome"] as int, groups[key]["canonical"] as int, groups[key]["lod"] as bool)

	# Update each MMI
	for key: String in _mmis.keys():
		var mmi: MultiMeshInstance3D = _mmis[key]
		if not groups.has(key):
			mmi.visible = false
			continue
		var tiles: Array = groups[key]["tiles"]
		mmi.visible = true
		var mm: MultiMesh = mmi.multimesh
		mm.instance_count = tiles.size()
		for i: int in range(tiles.size()):
			var state: TileRenderState = tiles[i] as TileRenderState
			var world_pos := Vector3(
				state.coord.x * TILE_SIZE,
				TILE_HEIGHT,
				state.coord.y * TILE_SIZE
			)
			mm.set_instance_transform(i, Transform3D(Basis(), world_pos))
			# Encode biome index as custom data (channel 0) for shader palette
			if mm.use_custom_data:
				mm.set_instance_custom_data(i, Color(float(state.biome) / 10.0, 0.0, 0.0, 1.0))


## Ensure a MultiMeshInstance3D exists for the given key.
func _ensure_mmi(key: String, biome: int, canonical: int, lod: bool) -> void:
	if _mmis.has(key):
		return

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	# Use the correct biome + canonical mesh for this group
	mm.mesh = mesh_library.get_mesh(biome, canonical, lod)
	mmi.multimesh = mm

	if shared_material != null:
		mmi.material_override = shared_material

	add_child(mmi)
	_mmis[key] = mmi


## Return the chunk coordinate for a given tile coordinate.
static func tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / CHUNK_SIZE), floori(float(tile.y) / CHUNK_SIZE))
