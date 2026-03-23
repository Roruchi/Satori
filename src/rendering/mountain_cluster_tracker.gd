## MountainClusterTracker — union-find tracker for contiguous Stone tile clusters.
##
## Emits `cluster_merged(cluster_id: int)` when a cluster reaches or exceeds
## 10 tiles.  Also emits `cluster_grew(cluster_id: int)` when a tile is added
## to an already-merged cluster (triggers re-merge in VoxelRenderer).
##
## Uses a path-compressed union-find (disjoint set) structure for near-O(1)
## amortised cost per placement.

extends Node

signal cluster_merged(cluster_id: int)
signal cluster_grew(cluster_id: int)

const MERGE_THRESHOLD: int = 10

## All active MountainCluster value objects, keyed by cluster id.
var _clusters: Dictionary[int, MountainCluster] = {}

## Maps every registered Stone tile coord → cluster id (representative root).
var _coord_to_root: Dictionary[Vector2i, int] = {}

## Union-find parent table: id → id.
var _parent: Dictionary[int, int] = {}

## Union-find rank (for union-by-rank).
var _rank: Dictionary[int, int] = {}

## Auto-incrementing cluster id counter.
var _next_id: int = 0

## Cardinal neighbour offsets.
const _CARDINALS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]


## Register a newly placed Stone tile at `coord`.
## Must be called only once per coord.
func register_tile(coord: Vector2i) -> void:
	# Create a singleton cluster for this tile
	var new_id: int = _new_cluster(coord)

	# Union with all adjacent Stone clusters
	for offset in _CARDINALS:
		var neighbour: Vector2i = coord + offset
		if _coord_to_root.has(neighbour):
			_union(new_id, _find(_coord_to_root[neighbour]))

	# Check merge threshold
	var root: int = _find(new_id)
	var cluster: MountainCluster = _clusters[root]
	if cluster.members.size() >= MERGE_THRESHOLD:
		if not cluster.merged:
			cluster.merged = true
			cluster_merged.emit(root)
		else:
			cluster_grew.emit(root)


## Return the MountainCluster for a given id, or null if unknown.
func get_cluster(cluster_id: int) -> MountainCluster:
	if not _clusters.has(cluster_id):
		return null
	var root: int = _find(cluster_id)
	return _clusters.get(root, null)


## Return the cluster that owns `coord`, or null if coord is unregistered.
func get_cluster_for_coord(coord: Vector2i) -> MountainCluster:
	if not _coord_to_root.has(coord):
		return null
	var root: int = _find(_coord_to_root[coord])
	return _clusters.get(root, null)


## Return true if `coord` belongs to a merged (≥10 tile) cluster.
func is_merged(coord: Vector2i) -> bool:
	var cluster: MountainCluster = get_cluster_for_coord(coord)
	return cluster != null and cluster.merged


# ---------------------------------------------------------------------------
# Union-Find internals
# ---------------------------------------------------------------------------

func _new_cluster(coord: Vector2i) -> int:
	var id: int = _next_id
	_next_id += 1

	var cluster := MountainCluster.new()
	cluster.id = id
	cluster.members = [coord]
	cluster.merged = false
	cluster.mesh_node = null
	cluster.bounds = Rect2i(coord, Vector2i(1, 1))

	_clusters[id] = cluster
	_coord_to_root[coord] = id
	_parent[id] = id
	_rank[id] = 0

	return id


## Path-compressed find.
func _find(id: int) -> int:
	if _parent[id] != id:
		_parent[id] = _find(_parent[id])
	return _parent[id]


## Union-by-rank with cluster data merging.
func _union(id_a: int, id_b: int) -> void:
	var root_a: int = _find(id_a)
	var root_b: int = _find(id_b)
	if root_a == root_b:
		return

	# Merge smaller rank into larger
	var winner: int
	var loser: int
	if _rank[root_a] >= _rank[root_b]:
		winner = root_a
		loser = root_b
	else:
		winner = root_b
		loser = root_a

	_parent[loser] = winner
	if _rank[winner] == _rank[loser]:
		_rank[winner] += 1

	# Absorb loser's members into winner's cluster
	var w_cluster: MountainCluster = _clusters[winner]
	var l_cluster: MountainCluster = _clusters[loser]
	for coord in l_cluster.members:
		w_cluster.members.append(coord)
		_coord_to_root[coord] = winner
		w_cluster.bounds = w_cluster.bounds.expand(coord)

	# Remove the retired cluster record
	_clusters.erase(loser)
