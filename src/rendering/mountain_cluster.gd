## MountainCluster — value object for a contiguous Stone tile cluster.
## Owned and managed exclusively by MountainClusterTracker.
class_name MountainCluster
extends RefCounted

## Auto-incrementing cluster identifier.
var id: int = -1

## All tile coordinates belonging to this cluster.
var members: Array[Vector2i] = []

## True when cluster has reached MERGE_THRESHOLD (≥10 tiles) and its
## unified Mountain mesh is active.
var merged: bool = false

## The live MeshInstance3D node for the Mountain mesh (null when not merged).
var mesh_node: MeshInstance3D = null

## Axis-aligned bounding box spanning all member tiles.
var bounds: Rect2i = Rect2i()
