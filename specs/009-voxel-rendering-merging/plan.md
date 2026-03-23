# Implementation Plan: Voxel Rendering and Mesh Merging

**Branch**: `009-voxel-rendering-merging` | **Date**: 2026-03-23 | **Spec**: `specs/009-voxel-rendering-merging/spec.md`
**Input**: Feature specification from `specs/009-voxel-rendering-merging/spec.md`

## Summary

Replace the current immediate-mode 2D tile renderer (`GardenView.gd`) with a 3D voxel-based rendering pipeline that delivers:

1. **Bitmask autotiling** — each tile picks the correct voxel mesh variant (up to 8-bit) from its neighbour configuration, producing seamless edge and corner blending on every placement frame.
2. **Biome transition decoration** — when two different biomes share an edge (e.g. Forest + Water), a procedural decoration layer spawns voxel accent objects such as reeds or a riverbank on that shared edge.
3. **Mountain cluster merging** — a contiguous cluster of 10+ Stone tiles has its individual tile meshes replaced by a single unified Mountain mesh within the same render frame.
4. **Instanced rendering + LOD** — tiles within a chunk share one `MultiMeshInstance3D` draw call; tiles beyond the configurable LOD radius use lower-resolution geometry.
5. **Colorblind palette toggle** — a shader-uniform palette swap applies to all rendered tiles in the same frame.

The data layer (`GardenGrid`, `GardenTile`, `GameState`) is unchanged; the plan adds a new `rendering/` subsystem under `src/` and a companion `VoxelGarden.tscn` scene.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot built-ins (`MultiMeshInstance3D`, `ShaderMaterial`, `ArrayMesh`), existing `GameState` autoload, `GardenGrid`, `BiomeType`, GUT (`addons/gut/`)
**Storage**: Tile meshes are procedural / preloaded `.tres` resources; no new persistence layer required (rendering state is fully reconstructable from `GardenGrid` on load)
**Testing**: GUT unit/integration tests in `tests/unit/` + manual in-editor validation for visual correctness of mesh variants, cluster merge timing, and palette switch
**Target Platform**: Godot desktop dev runtime + mobile-targeted runtime (Android/iOS, Snapdragon 778G class reference hardware)
**Project Type**: Godot 3D feature in an existing single-project mobile-first garden game
**Performance Goals**: ≤16.7ms frame time (≥60 fps) at 5,000 placed tiles; ≤1 draw call per unique mesh variant per chunk; Mountain re-merge within one render frame
**Constraints**: Tile placement permanence preserved; no new autoloads whose key matches a script `class_name`; explicit type annotations in all Variant-return paths; `preload` for typed cross-script dependencies
**Scale/Scope**: Up to 5,000 tiles, 10 biome types, 256 possible 8-bit bitmask variants per biome, 1 Mountain cluster mesh per Stone cluster ≥10 tiles, N biome-pair transition edges

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Work maps directly to `specs/009-voxel-rendering-merging/spec.md` and its four user stories (autotiling, Mountain merge, performance, colorblind palette). Biome transition decoration extends US1 with no new spec violation.
- **Godot-Native Fit**: PASS. All runtime work stays in `src/rendering/` (GDScript), scenes in `scenes/`, no external build tools. `MultiMeshInstance3D` and `ShaderMaterial` are engine-native. New scene `VoxelGarden.tscn` wired via `project.godot` autoplay or scene change.
- **Validation Strategy**: PASS with required work. GUT unit tests cover bitmask computation, cluster detection, and LOD classification. Visual/mesh correctness and palette toggle require manual in-editor validation documented in `quickstart.md`.
- **World Rule Safety**: PASS. Rendering subsystem is purely presentational — it reads `GardenGrid` but never writes to it. Permanence, placement validity, and alchemy rules are unchanged.
- **Mobile Budgets**: PASS with monitoring. `MultiMeshInstance3D` instancing and chunk-local batching preserve the 60fps budget. LOD system reduces vertex count for distant tiles. Palette toggle is a single `set_shader_parameter` call.
- **Guardrails**: PASS. Autoload key `VoxelRenderer` does not match any `class_name`. All Array/Dictionary return paths use explicit types. Cross-script mesh resources loaded with `preload` where registration timing matters.

## Project Structure

### Documentation (this feature)

```text
specs/009-voxel-rendering-merging/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── tile-mesh-variant-contract.md
│   └── mountain-cluster-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   └── GameState.gd               # unchanged; rendering subscribes to tile_placed
├── biomes/
│   └── BiomeType.gd               # unchanged
├── grid/
│   ├── GridMap.gd                 # unchanged
│   ├── TileData.gd                # unchanged
│   └── PlacementController.gd     # unchanged
├── rendering/
│   ├── bitmask_autotiler.gd       # NEW: 8-bit neighbour bitmask computation
│   ├── tile_mesh_library.gd       # NEW: (biome, bitmask) → MeshInstance3D lookup
│   ├── tile_chunk_renderer.gd     # NEW: MultiMeshInstance3D per chunk per variant
│   ├── mountain_cluster_tracker.gd# NEW: Stone cluster detection + merge trigger
│   ├── mountain_mesh_builder.gd   # NEW: builds unified Mountain ArrayMesh
│   ├── biome_transition_layer.gd  # NEW: cross-biome edge → decoration spawner
│   ├── lod_controller.gd          # NEW: chunk distance → LOD level
│   └── voxel_renderer.gd          # NEW: orchestrator; subscribes to GameState signals
└── ui/
    └── TileSelector.gd            # unchanged (palette toggle wired here later)

scenes/
├── Garden.tscn                    # updated: swap GardenView for VoxelGarden child
├── VoxelGarden.tscn               # NEW: root of the 3D rendering subscene
└── UI/

tests/
├── gut_runner.tscn
└── unit/
    ├── test_bitmask_autotiler.gd   # NEW
    ├── test_mountain_cluster.gd    # NEW
    └── test_biome_transition.gd    # NEW

specs/009-voxel-rendering-merging/
└── ...feature artifacts...
```

**Structure Decision**: All new runtime logic lives under `src/rendering/`; `VoxelGarden.tscn` is a self-contained 3D subscene that the top-level `Garden.tscn` mounts. The existing `GardenView.gd` (2D) is replaced by wiring the 2D camera overlay to the new system; the 2D hover/animation UI layer in `GardenView.gd` is preserved as a thin overlay.

## Phase 0: Research Plan

Research tasks generated from technical unknowns and integration decisions:

1. Confirm the most efficient Godot 4.6 strategy for per-chunk batched voxel tile instancing (`MultiMeshInstance3D` vs `RenderingServer` direct mesh instances vs `GPUParticles3D` abuse).
2. Determine the lowest-memory representation for 8-bit bitmask variant meshes: pre-built `.tres` mesh resources vs. procedural `ArrayMesh` generation at startup.
3. Evaluate Godot 4.6 shader uniform array strategies for a per-biome colorblind palette swap that applies to all active materials in one call.
4. Confirm whether Godot 4.6 LOD via `GeometryInstance3D.lod_bias` / `visibility_range_*` properties satisfies the mobile LOD requirement or whether a manual chunk-swap approach is needed.
5. Determine the safe chunk size (NxN tiles) that keeps per-chunk `MultiMesh` rebuild cost under one frame budget when a flood of placements arrives.
6. Research the minimum set of biome-pair transition types required for MVP (Forest↔Water = reed/riverbank; others TBD) and how to encode them in a data-driven way.

## Phase 1: Design Plan

1. Define rendering domain entities and state transitions → `data-model.md`.
2. Define interface contracts for mesh variant lookup and Mountain cluster API → `contracts/`.
3. Write practical implementation and validation runbook → `quickstart.md`.
4. Run agent context update script.
5. Re-run Constitution Check post-design.

## Phase 2: Task Planning Approach (for /speckit.tasks)

1. Foundation tasks: `BitmaskAutotiler`, `TileMeshLibrary`, and `TileChunkRenderer` scaffolding.
2. Story-aligned tasks:
   - US1: autotiling bitmask update + biome transition decoration on placement.
   - US2: Mountain cluster tracker + unified mesh builder.
   - US3: instanced rendering + LOD controller.
   - US4: colorblind palette shader toggle.
3. Verification tasks: GUT suites + manual visual validation checklist.
4. Integration tasks: wire `VoxelGarden.tscn` into `Garden.tscn`, run full regression + budget check.

## Post-Design Constitution Check

- **Spec Traceability**: PASS. All design artifacts are scoped to feature 009.
- **Godot-Native Fit**: PASS. Design uses `MultiMeshInstance3D`, `ShaderMaterial`, and GDScript throughout.
- **Validation Strategy**: PASS. Automated GUT tests for logic-layer components; manual validation documented for rendering correctness.
- **World Rule Safety**: PASS. Rendering subsystem is purely read-only with respect to `GardenGrid`.
- **Mobile Budgets**: PASS. Chunk-batched instancing, LOD, and a single shader palette call are all known-good mobile patterns in Godot 4.
- **Guardrails**: PASS. All guardrails documented and preserved in design choices.

## Complexity Tracking

No constitution violations requiring exception records.
