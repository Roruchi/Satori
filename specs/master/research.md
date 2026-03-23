# Research: Satori — Full Game

**Branch**: `master` | **Date**: 2026-03-23

---

## Grid Coordinate System

**Decision**: Square grid using `Vector2i` axial coordinates.

**Rationale**:
- Godot 4's built-in `TileMap` node uses square/isometric grids natively; re-using it avoids custom rendering
- The game's "voxel diorama" aesthetic is explicitly orthographic, which maps cleanly to square tiles
- Hex coordinates add complexity (offset conversion, 6-directional neighbour logic) with no gameplay benefit given the design doc describes "ring", "line", "cross", and "U" shapes — all of which are geometrically simpler on a square grid
- Adjacency rule ("must be adjacent to existing tile") means 4 neighbours (cardinal) suffices; 8-neighbour variant used for diagonal shape recipes

**Alternatives considered**: Hexagonal (rejected: complexity, no visual benefit); Triangular (rejected: unusual, poor tooling)

---

## Testing Framework

**Decision**: GUT v9+ (Godot Unit Testing)

**Rationale**:
- GUT v9+ fully supports Godot 4 GDScript; test classes extend `GutTest` with `assert_eq`, `assert_true`, `watch_signals`, and signal assertion helpers
- Ships a built-in editor panel (bottom dock) for running tests interactively, and a headless CLI runner (`addons/gut/gut_cmdln.gd`) for CI
- Installed as a standard Godot addon (`addons/gut/`) — no external toolchain needed
- Active maintenance as of 2026; large community and well-documented migration path from GUT 7/8

**Alternatives considered**: GdUnit4 (also Godot 4 compatible, but GUT preferred for its simpler setup and editor integration); WAT (less active)

---

## Grid Storage

**Decision**: Sparse `Dictionary` keyed by `Vector2i`

**Rationale**:
- Only placed tiles need to be stored; the garden is sparse relative to its potential infinite extent
- `Dictionary` in GDScript provides O(1) average lookup, insert, and delete
- Serialises trivially via `var_to_bytes` / `var_to_str`
- Chunk partitioning: outer dictionary keyed by chunk coordinate (`Vector2i(x/16, y/16)`); inner dictionary keyed by local tile coordinate — natural 2-level structure

**Alternatives considered**: `Array` (O(n) lookup, wastes memory for sparse data); External spatial DB (overkill at projected scale)

---

## World Partitioning (Chunking)

**Decision**: 16×16 tile chunks; Dictionary-of-Dictionaries; load/unload driven by camera viewport

**Rationale**:
- Design doc specifies 16×16 chunks explicitly for 60 fps performance on mid-range mobile
- Camera viewport covers ~5×8 chunks at normal zoom; maintain a 2-chunk border of loaded chunks around viewport
- Chunks not in the load radius are serialised to the save buffer and freed from memory
- Godot's `MultiMeshInstance3D` used per-chunk for efficient instanced tile rendering

**Alternatives considered**: Unlimited flat dictionary (viable for small gardens, but memory unbounded); Fixed 32×32 (fewer handoffs but larger memory spikes)

---

## Pattern Scan Threading

**Decision**: Godot 4 `Thread` with `Mutex` guards; results delivered via `call_deferred`

**Rationale**:
- Pattern scan after each placement could touch O(n) tiles in worst case; cannot block the render thread
- Godot 4's `Thread` class is stable and idiomatic; no external concurrency library needed
- `Mutex` protects the tile dictionary during scan reads; placements queue if scan is in flight
- Results dispatched back to main thread via `call_deferred` to safely emit signals and mutate scene state

**Alternatives considered**: `WorkerThreadPool` (acceptable alternative, slightly more complex API); Coroutine-based incremental scan (simpler but may still stutter on large gardens)

---

## Serialisation Format

**Decision**: Godot's `var_to_bytes` (binary) with a version header

**Rationale**:
- Native to GDScript; no dependencies
- Compact for large dictionaries
- Version byte prepended to enable forward-compatible migration
- Falls back to human-readable `var_to_str` JSON for debug exports

**Alternatives considered**: Custom binary protocol (unnecessary complexity); SQLite (via GDExtension — overkill and adds a dependency)

---

## Voxel Mesh Strategy

**Decision**: `MultiMeshInstance3D` per chunk + `MeshLibrary` of biome mesh variants; `MeshInstance3D` for merged Mountain

**Rationale**:
- `MultiMeshInstance3D` renders thousands of identical meshes in one draw call — essential for 60 fps with large gardens
- Bitmask autotiling selects the correct variant (straight edge, corner, isolated, etc.) from a `MeshLibrary`
- Mountain Growth collapses a cluster into a single authored `MeshInstance3D` — unique enough per cluster that instancing isn't worth it

**Alternatives considered**: Individual `MeshInstance3D` per tile (draw call explosion); Voxel plugin (adds dependency, less control)

---

## Audio Architecture

**Decision**: Godot `AudioStreamPlayer` per biome bus; `AudioServer` volume bus mixing driven by camera biome-ratio sample

**Rationale**:
- Godot's `AudioServer` bus system designed exactly for this: independent volume control per channel with smooth tweening
- Biome ratio sampled each `_process` tick by counting biome types within a circle of radius R around the camera; each biome bus volume set proportionally
- `Tween` node handles smooth crossfade

**Alternatives considered**: Positional `AudioStreamPlayer3D` per tile (CPU-intensive, panning artifacts on infinite grid); External audio middleware (Wwise/FMOD — far too heavy for a Godot mobile project)

---

## Spirit Animal Behaviour

**Decision**: Simple state-machine wandering within a bounding rect of the triggering cluster using `NavigationAgent3D` or manual `MoveToward`

**Rationale**:
- Spirits are ambient, not interactive — complex pathfinding unnecessary
- Bounding their wander to the triggering cluster region keeps them visually associated with their discovery
- `NavigationAgent3D` acceptable if a navmesh can be baked per-cluster; else simple `Vector2.move_toward` with obstacle avoidance is sufficient for the aesthetic goal

**Alternatives considered**: Full A* pathfinding (overkill); Random walk with no bounds (spirits would wander off-screen)

---

## Unresolved Items

None — all NEEDS CLARIFICATION items resolved above.
