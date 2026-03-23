# Data Model: Voxel Rendering and Mesh Merging (Feature 009)

All runtime rendering entities are under `src/rendering/`. The garden data layer (`GardenGrid`, `GardenTile`) is unchanged.

---

## Entity: TileMeshVariant

**File**: `src/rendering/tile_mesh_library.gd` (loaded at startup)

Describes a single mesh asset for one (biome, canonical-bitmask) combination.

| Field | Type | Description |
|---|---|---|
| `biome` | `int` (BiomeType.Value) | Owning biome |
| `canonical_bitmask` | `int` | 0–46 — Wang/blob canonical index |
| `mesh_full` | `Mesh` | Full-detail voxel mesh |
| `mesh_lod` | `Mesh` | Reduced-LOD mesh (fewer voxels) |

**Key**: `(biome, canonical_bitmask)` — uniquely identifies one drawable variant.

**State transitions**: Read-only; loaded once from `res://assets/meshes/tiles/`.

**Validation rules**:
- `mesh_full` MUST NOT be null.
- `mesh_lod` defaults to `mesh_full` when no LOD asset exists (graceful degradation).
- `canonical_bitmask` MUST be in range `[0, 46]` (47 Wang tile classes).

---

## Entity: TileRenderState

**In-memory only** — held in `VoxelRenderer`'s internal dictionary.

Tracks the current rendering state of one placed tile.

| Field | Type | Description |
|---|---|---|
| `coord` | `Vector2i` | Grid coordinate |
| `biome` | `int` | BiomeType.Value at this coord |
| `bitmask8` | `int` | Raw 8-bit neighbour bitmask (0–255) |
| `canonical` | `int` | Mapped canonical index (0–46) |
| `chunk_id` | `Vector2i` | Owning 8×8 chunk coordinate |
| `in_mountain` | `bool` | True if part of a MountainCluster |

**State transitions**:
- Created on `tile_placed` signal.
- `bitmask8` / `canonical` updated whenever the tile or any of its 8 neighbours changes.
- `in_mountain` set `true` when the tile's Stone cluster reaches 10; set back `false` never (Stone tiles are permanent).

---

## Entity: TileChunk

**File**: `src/rendering/tile_chunk_renderer.gd`

Represents one 8×8 grid region and owns its `MultiMeshInstance3D` nodes.

| Field | Type | Description |
|---|---|---|
| `chunk_coord` | `Vector2i` | Chunk grid position (tile_coord / 8) |
| `dirty` | `bool` | True if at least one tile changed this frame |
| `instances_full` | `Dictionary` | variant_key → MultiMeshInstance3D (full LOD) |
| `instances_lod` | `Dictionary` | variant_key → MultiMeshInstance3D (low LOD) |

**State transitions**:
- `dirty = true` on any tile placement in this chunk.
- Rebuilt (MultiMesh data refreshed) in `_process` when `dirty` is true.
- `dirty = false` after rebuild completes.

**Validation rules**:
- Each `MultiMeshInstance3D` has exactly as many instances as tiles with the matching variant in this chunk.

---

## Entity: MountainCluster

**File**: `src/rendering/mountain_cluster_tracker.gd`

Tracks a contiguous region of Stone tiles and controls its merge state.

| Field | Type | Description |
|---|---|---|
| `id` | `int` | Auto-incrementing cluster identifier |
| `members` | `Array[Vector2i]` | All tile coordinates in the cluster |
| `merged` | `bool` | True when the cluster has ≥10 members and its Mountain mesh is active |
| `mesh_node` | `MeshInstance3D` | The live unified Mountain mesh node (null when not merged) |
| `bounds` | `Rect2i` | Axis-aligned bounding box of all member tiles |

**State transitions**:
- Created when a Stone tile is placed.
- Grows via union-find when an adjacent Stone tile is placed next to a tile in this cluster.
- Two existing clusters merge into one (smaller adopts larger's id, old cluster record removed) when a bridging Stone tile connects them.
- `merged = true` and `mesh_node` assigned when `members.size() >= 10`.
- Re-merge: when `merged == true` and a new member is added, `MountainMeshBuilder` rebuilds and replaces `mesh_node` in the same frame.

---

## Entity: TransitionDecoration

**File**: `src/rendering/biome_transition_layer.gd` (in-memory record)

Represents decoration objects spawned on one shared biome-pair edge.

| Field | Type | Description |
|---|---|---|
| `edge_key` | `String` | `"{coord_a}:{coord_b}"` sorted string key |
| `biome_a` | `int` | Lower BiomeType.Value of the pair |
| `biome_b` | `int` | Higher BiomeType.Value of the pair |
| `nodes` | `Array[Node3D]` | Spawned decoration nodes |

**State transitions**:
- Created when two tiles with a registered transition pair become neighbours.
- Destroyed never (placements are permanent).

---

## Bitmask Encoding

8-bit neighbour bitmask, one bit per direction (matching the standard RPG Maker / Godot TileSet autotile convention):

```
bit 0 = NW neighbour present and same biome (or cross-biome if counting)
bit 1 = N
bit 2 = NE
bit 3 = W
bit 4 = E
bit 5 = SW
bit 6 = S
bit 7 = SE
```

**Cross-biome rule**: For autotiling, a neighbour counts as "present" only when it is the same biome type OR when a biome transition decoration is registered for the pair. This prevents seams between visually-connected biome groups.

---

## Wang/Blob Canonical Reduction Table (excerpt)

The full 256→47 mapping is codified in `tile_mesh_library.gd`. Key canonical indices:

| Canonical Index | Description | Example raw bitmask values |
|---|---|---|
| 0 | Isolated (no same-biome neighbours) | 0x00 |
| 1 | N edge only | 0x02 |
| 2 | E edge only | 0x10 |
| 3 | S edge only | 0x40 |
| 4 | W edge only | 0x08 |
| 5 | NE corner | 0x12 |
| … | … | … |
| 46 | Fully surrounded (all 8 present) | 0xFF |

---

## Relationships

```
GardenGrid (data) ──read──▶ VoxelRenderer (orchestrator)
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
        BitmaskAutotiler  TileChunkRenderer  MountainClusterTracker
                │                │                │
        TileRenderState    TileMeshLibrary   MountainMeshBuilder
                │
        BiomeTransitionLayer
```

`VoxelRenderer` is the single integration point: it subscribes to `GameState.tile_placed` and `GameState.tile_mixed`, then delegates to each sub-system.
