## LodController — manages chunk-level LOD switching based on camera distance.
##
## Each TileChunkRenderer owns two sets of MultiMeshInstance3D nodes:
## full-detail and LOD.  This controller sets the visibility_range_end on the
## full-detail set and visibility_range_begin on the LOD set so Godot's
## built-in visibility range system handles the transition.
##
## Call `update(camera_position)` each frame from VoxelRenderer._process.

extends Node

## Distance (in world units) beyond which chunks switch to low-detail rendering.
## Default: 20 tile-units × 1.0 world unit/tile = 20.0
@export var lod_distance: float = 20.0

## Reference to the TileChunkParent node that holds all TileChunkRenderer nodes.
var chunk_parent: Node3D = null


## Update LOD visibility ranges for all chunks based on current camera position.
func update_lod(camera_world_pos: Vector3) -> void:
	if chunk_parent == null:
		return

	for chunk_node in chunk_parent.get_children():
		if not chunk_node is Node3D:
			continue
		var chunk_pos: Vector3 = chunk_node.global_position
		var dist: float = Vector3(chunk_pos.x, 0.0, chunk_pos.z).distance_to(
			Vector3(camera_world_pos.x, 0.0, camera_world_pos.z)
		)
		_set_chunk_lod(chunk_node, dist > lod_distance)


## Apply full-detail or LOD state to one TileChunkRenderer node.
## TileChunkRenderer exposes its MMI nodes via its _mmis dictionary.
## We toggle visibility of each MMI based on whether its key ends in |f (full) or |l (lod).
func _set_chunk_lod(chunk_node: Node, use_lod: bool) -> void:
	for child in chunk_node.get_children():
		if child is MultiMeshInstance3D:
			var node_name: String = child.name
			if node_name.ends_with("_full"):
				child.visible = not use_lod
			elif node_name.ends_with("_lod"):
				child.visible = use_lod
