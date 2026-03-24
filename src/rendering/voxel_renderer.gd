## VoxelRenderer — orchestrator for the voxel tile rendering pipeline.
##
## Subscribes to GameState tile signals and delegates to:
##   BitmaskAutotiler      — computes 8-bit bitmask for each tile
##   TileMeshLibrary       — resolves (biome, bitmask) → Mesh
##   TileChunkRenderer     — batches tiles into MultiMesh draw calls per chunk
##   MountainClusterTracker — detects Stone clusters ≥10 tiles
##   MountainMeshBuilder   — builds unified Mountain mesh for merged clusters
##   BiomeTransitionLayer  — spawns edge decoration voxels
##   LodController         — manages chunk-level LOD switching
##
## NOT registered as an autoload — instantiated as a node in VoxelGarden.tscn.

extends Node3D

const _BitmaskAutotiler        = preload("res://src/rendering/bitmask_autotiler.gd")
const _TileChunkRendererScript = preload("res://src/rendering/tile_chunk_renderer.gd")
const _MountainMeshBuilder     = preload("res://src/rendering/mountain_mesh_builder.gd")

## Child node references (set up in VoxelGarden.tscn).
@onready var _chunk_parent: Node3D          = $TileChunkParent
@onready var _mountain_parent: Node3D      = $MountainMeshParent
@onready var _decoration_layer: BiomeTransitionLayer = $DecorationParent
@onready var _lod_controller: Node         = $LodController
@onready var _cluster_tracker: Node        = $MountainClusterTracker

## Mesh library singleton.
var _mesh_library: TileMeshLibrary = null

## All tile render states: Vector2i → TileRenderState.
var _render_states: Dictionary[Vector2i, TileRenderState] = {}

## Active TileChunkRenderer nodes: Vector2i (chunk coord) → TileChunkRenderer.
var _chunks: Dictionary[Vector2i, Node3D] = {}

## Shared shader material for all tile MMI nodes (enables one-call palette swap).
var _shared_material: Material = null

## Camera reference for LOD updates (auto-discovered in _ready).
var _camera: Camera3D = null


func _ready() -> void:
	# Initialise mesh library
	_mesh_library = TileMeshLibrary.new()
	_mesh_library.initialise()

	# Create a shared StandardMaterial3D for all tile meshes
	# (replace with the authored ShaderMaterial when tile_voxel.tres is available)
	_shared_material = StandardMaterial3D.new()

	# Wire cluster tracker signals
	_cluster_tracker.cluster_merged.connect(_on_cluster_merged)
	_cluster_tracker.cluster_grew.connect(_on_cluster_grew)

	# Inject references into LodController
	_lod_controller.chunk_parent = _chunk_parent

	# Find camera
	_camera = get_viewport().get_camera_3d()

	# Connect to GameState signals
	GameState.tile_placed.connect(_on_tile_placed)
	GameState.tile_mixed.connect(_on_tile_mixed)

	# Rebuild rendering state for all tiles already in the grid
	# (handles the origin tile placed during GameState._ready)
	for coord: Vector2i in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		_register_tile(coord, tile)


func _process(_delta: float) -> void:
	# LOD update
	if _camera != null:
		_lod_controller.update_lod(_camera.global_position)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_tile_placed(coord: Vector2i, tile: GardenTile) -> void:
	_register_tile(coord, tile)


func _on_tile_mixed(coord: Vector2i, tile: GardenTile) -> void:
	# Update render state for the mixed tile (biome may have changed)
	if not _render_states.has(coord):
		return
	var state: TileRenderState = _render_states[coord]
	state.biome = tile.biome
	_refresh_bitmask(coord)


# ---------------------------------------------------------------------------
# Core registration
# ---------------------------------------------------------------------------

func _register_tile(coord: Vector2i, tile: GardenTile) -> void:
	# Create render state
	var state: TileRenderState = TileRenderState.create(coord, tile.biome)
	_render_states[coord] = state

	# Compute initial bitmask
	_refresh_bitmask(coord)

	# Register Stone tiles with cluster tracker
	if tile.biome == BiomeType.Value.STONE:
		_cluster_tracker.register_tile(coord)

	# Spawn biome transition decorations
	_decoration_layer.on_tile_placed(coord, GameState.grid)

	# Mark owning chunk dirty
	_mark_chunk_dirty(state.chunk_id)


## Refresh the bitmask for `coord` and all 8 of its neighbours.
func _refresh_bitmask(coord: Vector2i) -> void:
	var affected: Array[Vector2i] = [coord]

	# Collect all 8 neighbours that have a render state
	const OFFSETS: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
	]
	for off: Vector2i in OFFSETS:
		var n: Vector2i = coord + off
		if _render_states.has(n):
			affected.append(n)

	# Update bitmask and canonical for each affected tile
	for affected_coord: Vector2i in affected:
		if not _render_states.has(affected_coord):
			continue
		var state: TileRenderState = _render_states[affected_coord]
		state.bitmask8 = _BitmaskAutotiler.compute_bitmask(affected_coord, GameState.grid)
		state.canonical = _BitmaskAutotiler.to_canonical(state.bitmask8)
		_mark_chunk_dirty(state.chunk_id)


## Ensure a TileChunkRenderer exists for `chunk_coord` and mark it dirty.
func _mark_chunk_dirty(chunk_coord: Vector2i) -> void:
	var chunk: Node3D = _get_or_create_chunk(chunk_coord)
	# Inject current tile snapshot for this chunk
	var chunk_states: Dictionary = {}
	for coord: Vector2i in _render_states:
		var s: TileRenderState = _render_states[coord]
		if s.chunk_id == chunk_coord:
			chunk_states[coord] = s
	chunk.update_tile_states(chunk_states)
	chunk.mark_dirty()


func _get_or_create_chunk(chunk_coord: Vector2i) -> Node3D:
	if _chunks.has(chunk_coord):
		return _chunks[chunk_coord]

	var chunk: Node3D = _TileChunkRendererScript.new()
	chunk.chunk_coord = chunk_coord
	chunk.mesh_library = _mesh_library
	chunk.shared_material = _shared_material
	# Position the chunk node at its world-space origin
	chunk.position = Vector3(
		chunk_coord.x * 8.0,
		0.0,
		chunk_coord.y * 8.0
	)
	_chunk_parent.add_child(chunk)
	_chunks[chunk_coord] = chunk
	return chunk


# ---------------------------------------------------------------------------
# Mountain cluster merge handlers
# ---------------------------------------------------------------------------

func _on_cluster_merged(cluster_id: int) -> void:
	var cluster: MountainCluster = _cluster_tracker.get_cluster(cluster_id)
	if cluster == null:
		return
	_rebuild_mountain_mesh(cluster)


func _on_cluster_grew(cluster_id: int) -> void:
	var cluster: MountainCluster = _cluster_tracker.get_cluster(cluster_id)
	if cluster == null:
		return
	_rebuild_mountain_mesh(cluster)


## Build (or rebuild) the Mountain mesh for a merged cluster.
func _rebuild_mountain_mesh(cluster: MountainCluster) -> void:
	# Remove existing Mountain mesh node
	if cluster.mesh_node != null:
		cluster.mesh_node.queue_free()
		cluster.mesh_node = null

	# Hide individual tile meshes for all cluster members
	for coord: Vector2i in cluster.members:
		if not _render_states.has(coord):
			continue
		var state: TileRenderState = _render_states[coord]
		state.in_mountain = true
		_mark_chunk_dirty(state.chunk_id)

	# Build and add new unified Mountain mesh
	var mesh: ArrayMesh = _MountainMeshBuilder.build_mesh(cluster.members)
	var mmi := MeshInstance3D.new()
	mmi.mesh = mesh
	mmi.name = "Mountain_%d" % cluster.id
	_mountain_parent.add_child(mmi)
	cluster.mesh_node = mmi


# ---------------------------------------------------------------------------
# Colorblind palette toggle
# ---------------------------------------------------------------------------

## Toggle the colorblind palette for all rendered tile meshes.
## One call updates all tiles via the shared ShaderMaterial.
func toggle_colorblind_palette(enabled: bool) -> void:
	if _shared_material is ShaderMaterial:
		(_shared_material as ShaderMaterial).set_shader_parameter(
			"use_colorblind", 1.0 if enabled else 0.0
		)
	# When using StandardMaterial3D fallback, albedo switching is not available
	# without per-tile updates; this path is a no-op until the shader is authored.
	# TODO: connect to spec-013 (Accessibility Settings) signal once that spec is delivered,
	# which will add a global settings autoload with an `accessibility_palette_changed` signal
