# Implementation Plan: Hexagonal Tile System

**Branch**: `014-hex-tiles` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/014-hex-tiles/spec.md`

## Summary

Replace the square-tile grid with a hexagonal-tile grid throughout Satori. All tile
positions switch from square `Vector2i(x, y)` to axial hex `Vector2i(q, r)` using a
pointy-top orientation. The 4-directional neighbor system becomes 6-directional. The
8-bit Wang-blob autotiler (47 canonical square forms) is replaced with a 6-bit hex
bitmask (13 canonical hex forms). GardenView's square draw calls become hexagon
polygons. Input hit-testing switches to cube-rounding pixel→axial conversion. Pattern
matchers update their BFS and offset templates to hex coordinates. Existing saves are
version-gated to protect against corrupt state. No external dependencies are added;
the change stays entirely within the existing Godot-native architecture.

## Technical Context

**Language/Version**: GDScript — Godot 4.6
**Primary Dependencies**: Godot 4.6 engine (Jolt Physics, Forward Plus / Direct3D 12); GUT for testing
**Storage**: Sparse `Dictionary` grid (no database); save file via `DiscoveryPersistence` autoload
**Testing**: GUT (`addons/gut/`, `tests/gut_runner.tscn`); manual in-editor play
**Target Platform**: Mobile-first (mid-range devices); desktop secondary
**Project Type**: Single-project Godot game (GDScript in `src/`, scenes in `scenes/`)
**Performance Goals**: Stable 60 fps on target mobile hardware; no frame hitch on map load; neighbor look-up O(1)
**Constraints**: No breaking changes to BiomeType mixing rules, discovery IDs, or autoload interface contracts; save version gated
**Scale/Scope**: Same map size footprint as current square garden; rendering pipeline already batches via MultiMesh

## Constitution Check

### Pre-Design Evaluation

- **Spec Traceability** ✅
  All work is rooted in `specs/014-hex-tiles/spec.md`. Every implementation task maps
  to a user story (US1 grid, US2 discovery, US3 visuals, US4 save compatibility) or
  to shared foundational work (HexUtils, save version gate).

- **Godot-Native Fit** ✅
  All changes remain in GDScript under `src/`, scenes under `scenes/`, wiring in
  `project.godot`. No new autoloads are introduced. `HexUtils` is a stateless script
  loaded via `preload()`, not promoted to an autoload. MultiMesh batching and the
  existing chunk/LOD architecture are preserved.

- **Validation Strategy** ✅
  - GUT unit tests: `HexUtils` round-trips, bitmask canonical table, hex placement
    adjacency, cluster BFS on hex grid, pattern offset matching.
  - GUT integration tests: full placement → scan → discovery loop on hex grid.
  - Manual in-editor: visual hex layout, biome transition decoration, mountain cluster
    merging, mouse hit-test accuracy at tile edges.
  - Existing tests (`test_bitmask_autotiler.gd`, `test_mountain_cluster.gd`, etc.)
    are updated to use hex coordinates and new bitmask range.

- **World Rule Safety** ✅
  Permanence rules are unchanged (locked tiles remain locked, no undo). Discovery IDs
  are coordinate-independent strings; existing IDs remain valid. Save compatibility is
  handled by a version gate that routes incompatible saves to a new-game flow — no
  silent data corruption. `DiscoveryPersistence` (discovery IDs) is compatible without
  change; only map-coordinate data is affected.

- **Mobile Budgets** ✅
  - Hex polygon draw calls in `GardenView` replace `draw_rect()` with `draw_polygon()`
    at the same tile count; no additional draw calls introduced.
  - MultiMesh batching in the voxel pipeline is preserved; fewer canonical forms (13
    vs 47) means fewer MultiMesh groups per chunk → potential render batch reduction.
  - `pixel_to_axial()` (cube-rounding) executes in O(1) with only arithmetic; no
    performance regression on input handling.
  - Startup and save/load times are unaffected (no new file I/O paths).
  - Touch / thumb-zone input: hex hit-test is purely mathematical, no larger touch
    target impact.

- **Guardrails** ✅
  - `hex_utils.gd` must NOT declare `class_name` (load-order risk). Use `preload()`.
  - No new autoloads introduced; existing autoload names unchanged.
  - All functions in `HexUtils` that return `Array[Vector2i]`, `Vector2`, or `Vector2i`
    must be consumed with explicit type annotations (not `:=`) in warnings-as-errors
    files.
  - `bitmask8` field in `TileRenderState` is renamed `bitmask6`; all references in
    `voxel_renderer.gd` and `tile_chunk_renderer.gd` must be updated to avoid silent
    name drift.

## Project Structure

### Documentation (this feature)

```text
specs/014-hex-tiles/
├── plan.md              # This file
├── research.md          # Coordinate system, bitmask, shape, chunk, save decisions
├── data-model.md        # HexCoord, HexUtils API, bitmask canonical table, save version
├── quickstart.md        # Dev reference: offsets, rendering, pitfalls
├── checklists/
│   └── requirements.md  # Spec quality checklist (all passing)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   ├── GameState.gd              ← minor: placement validity now calls hex adjacency
│   └── discovery_persistence.gd ← add version gate on load; write version:2 on save
├── biomes/
│   ├── matchers/
│   │   ├── cluster_matcher.gd    ← BFS uses hex neighbors (get_hex_neighbors)
│   │   ├── shape_matcher.gd      ← offset templates updated to axial hex offsets
│   │   ├── ratio_proximity_matcher.gd ← use HexUtils.axial_distance()
│   │   └── compound_matcher.gd   ← no direct neighbor calls; delegates (verify only)
│   └── pattern_scan_scheduler.gd ← no change expected; verify pass-through
├── grid/
│   ├── hex_utils.gd              ← NEW: axial math, pixel↔axial, neighbor offsets
│   ├── TileData.gd               ← coord semantics change (no type change)
│   ├── GridMap.gd                ← is_placement_valid() uses 6 hex offsets
│   ├── GardenView.gd             ← draw_polygon() hex tiles; pixel↔axial hit-test
│   ├── PlacementController.gd    ← pixel_to_axial() for coord resolution
│   └── spatial_query.gd          ← get_cardinal_neighbors() → get_hex_neighbors()
└── rendering/
    ├── bitmask_autotiler.gd      ← 6-bit bitmask; build 64→13 canonical table
    ├── tile_render_state.gd      ← bitmask8→bitmask6; canonical range 0–12
    ├── tile_chunk_renderer.gd    ← chunk assignment via axial int-division
    ├── biome_transition_layer.gd ← hex neighbor offsets for transition detection
    ├── mountain_cluster_tracker.gd ← hex neighbor offsets for union-find scan
    ├── voxel_renderer.gd         ← axial↔world coord via HexUtils
    └── tile_mesh_library.gd      ← resolve (biome, canonical_0-12) → Mesh

scenes/
├── Garden.tscn                   ← no structural change; verify VoxelGarden still wires
└── UI/                           ← no change

tests/
├── gut_runner.tscn               ← no change
└── unit/
    ├── test_hex_utils.gd         ← NEW: neighbor offsets, pixel↔axial, distance
    ├── test_hex_bitmask.gd       ← NEW: 64→13 canonical table exhaustive check
    ├── test_hex_placement.gd     ← NEW: adjacency validation, edge tile neighbors
    ├── test_hex_cluster.gd       ← NEW: BFS cluster matching on hex grid
    ├── test_bitmask_autotiler.gd ← UPDATED: hex offsets, new canonical range
    ├── test_mountain_cluster.gd  ← UPDATED: hex neighbor scan
    ├── test_biome_transition.gd  ← UPDATED: hex transition offsets
    └── patterns/
        └── test_shape_*.gd       ← UPDATED: hex offset templates

specs/014-hex-tiles/
└── ...artifacts above...
```

**Structure Decision**: All new code lives within the existing `src/` subdirectories.
`hex_utils.gd` goes in `src/grid/` as the grid subsystem's coordinate authority.
No new directories are introduced.

## Complexity Tracking

No Constitution violations requiring justification. All changes are mechanical
replacements within existing architectural boundaries.
