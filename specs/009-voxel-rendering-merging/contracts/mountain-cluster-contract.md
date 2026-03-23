# Contract: Mountain Cluster API

**Owner**: `src/rendering/mountain_cluster_tracker.gd`
**Consumers**: `VoxelRenderer`, `TileChunkRenderer`

---

## Purpose

`MountainClusterTracker` is the authoritative subsystem for maintaining the union-find structure of contiguous Stone tile clusters and for deciding when a cluster must switch to the merged Mountain mesh representation.

---

## Signals

### `cluster_merged(cluster_id: int)`

Emitted **within the same frame** a cluster reaches or exceeds 10 members, or when its shape changes after already being merged.

**Payload**: The integer `cluster_id` of the newly-merged (or re-merged) cluster.

**Consumers** must call `get_cluster(cluster_id)` immediately to retrieve the current `MountainCluster` state.

---

### `cluster_grew(cluster_id: int)`

Emitted whenever a Stone tile is added to an existing merged cluster (size already ≥ 10). Re-merge logic is triggered by this signal.

---

## API

### `register_tile(coord: Vector2i) -> void`

Called by `VoxelRenderer` when a Stone tile is placed at `coord`. Adds the tile to an existing cluster or creates a new singleton cluster. Merges adjacent clusters if applicable. Emits `cluster_merged` if the resulting cluster size crosses the 10-tile threshold.

**Preconditions**: `coord` is an unregistered Stone tile.
**Postconditions**: `coord` belongs to exactly one cluster.

---

### `get_cluster(cluster_id: int) -> MountainCluster`

Returns the live `MountainCluster` object. Returns `null` if `cluster_id` is unknown.

---

### `get_cluster_for_coord(coord: Vector2i) -> MountainCluster`

Returns the cluster that owns the tile at `coord`, or `null` if `coord` is not a registered Stone tile.

---

### `is_merged(coord: Vector2i) -> bool`

Returns `true` if `coord` belongs to a cluster with ≥10 members whose Mountain mesh is currently active.

---

## Invariants

- Every registered Stone tile belongs to exactly one cluster (union-find invariant).
- `cluster_merged` is emitted within the same `_process` cycle as the placement that caused the threshold to be crossed.
- Cluster IDs are stable — a cluster that grows never changes its ID (the smaller cluster's ID is retired during merges).
- The `MountainCluster.members` array is always current; it MUST NOT be mutated by callers.

---

## Versioning

This contract is stable for feature 009 scope. The removal API (tile removal) is explicitly out of scope per the spec's permanence model.
