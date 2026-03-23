# Tasks: Voxel Rendering and Mesh Merging

**Input**: Design documents from `specs/009-voxel-rendering-merging/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Automated GUT coverage is required for bitmask autotiling logic, Mountain cluster detection, and biome transition edge registration. Performance validation (60fps/5,000 tiles) and visual mesh correctness require manual in-editor validation documented in `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the `src/rendering/` subsystem directory, test scaffolding, and mesh asset stubs before any user story implementation begins.

- [ ] T001 Create `src/rendering/` directory marker and confirm it is tracked by git
- [ ] T002 [P] Create GUT test suite scaffold in `tests/unit/test_bitmask_autotiler.gd` with `class_name TestBitmaskAutotiler` and empty `describe_*` blocks
- [ ] T003 [P] Create GUT test suite scaffold in `tests/unit/test_mountain_cluster.gd` with `class_name TestMountainCluster` and empty `describe_*` blocks
- [ ] T004 [P] Create GUT test suite scaffold in `tests/unit/test_biome_transition.gd` with `class_name TestBiomeTransition` and empty `describe_*` blocks
- [ ] T005 Create mesh asset stub directory `assets/meshes/tiles/` with a `README.md` documenting the expected asset naming convention `{biome}_{canonical_idx}.tres`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement the core data-layer components required by all four user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T006 Implement `src/rendering/bitmask_autotiler.gd` — static class that computes the raw 8-bit neighbour bitmask for a tile coord given a `GardenGrid`; document bit layout (NW=0, N=1, NE=2, W=3, E=4, SW=5, S=6, SE=7); neighbour counts as "present" when it shares the same biome
- [ ] T007 Implement `src/rendering/tile_mesh_library.gd` — loads `TileMeshVariant` data at startup; exposes `get_mesh(biome: int, bitmask8: int, lod: bool) -> Mesh` using the 256→47 Wang canonical reduction table; exposes `get_transition_mesh(biome_a: int, biome_b: int)` returning `null` when no transition is registered; never returns null for `get_mesh` (fallback to isolated mesh)
- [ ] T008 [P] Implement `src/rendering/tile_chunk_renderer.gd` — owns one `MultiMeshInstance3D` per (canonical variant, LOD level) pair within an 8×8 chunk; exposes `mark_dirty()` and rebuilds `MultiMesh` data in `_process` when dirty; chunk coordinate derived from tile coord via integer division by 8
- [ ] T009 Implement `src/rendering/voxel_renderer.gd` — autoload-safe orchestrator (NOT registered as autoload); connects to `GameState.tile_placed` and `GameState.tile_mixed` in `_ready`; delegates placement events to `BitmaskAutotiler`, `TileChunkRenderer`, `MountainClusterTracker`, and `BiomeTransitionLayer`; maintains the `TileRenderState` dictionary keyed by `Vector2i`
- [ ] T010 Create `scenes/VoxelGarden.tscn` — root `Node3D` scene; child nodes: `TileChunkParent` (Node3D), `MountainMeshParent` (Node3D), `DecorationParent` (Node3D); no script on root node; attach `VoxelRenderer` script to `TileChunkParent`
- [ ] T011 Wire `VoxelGarden.tscn` into `scenes/Garden.tscn` as a child node of the scene root; keep `GardenView` (2D overlay for hover/animation) active alongside the new 3D rendering layer

**Checkpoint**: Foundation ready. `VoxelRenderer` is instantiated in the scene, subscribes to `GameState` signals, and the chunk/LOD structure exists — user stories can proceed.

---

## Phase 3: User Story 1 — Bitmask Autotiling + Biome Transition Decoration (Priority: P1) 🎯 MVP

**Goal**: Every placed tile and all its immediate neighbours immediately show the correct mesh variant based on 8-bit neighbour bitmask. Biome-pair edges (Forest↔Water, etc.) spawn procedural decoration voxels (reeds, riverbank).

**Independent Test**: Place a single Forest tile → verify isolated mesh. Place an adjacent Forest tile → verify both update to edge-connected variants in the same frame. Place a Water tile next to a Forest tile → verify reed and riverbank decorations appear on the shared edge.

### Tests for User Story 1

- [ ] T012 [P] [US1] Add GUT coverage in `tests/unit/test_bitmask_autotiler.gd`: single isolated tile bitmask = 0x00; east neighbour present = bit 4 set; all 8 neighbours present = 0xFF; mixed-biome neighbours do NOT set bits
- [ ] T013 [P] [US1] Add GUT coverage in `tests/unit/test_biome_transition.gd`: Forest↔Water pair returns non-null decoration; FOREST↔FOREST pair returns null; biome order is commutative (Water,Forest) == (Forest,Water)
- [ ] T014 [US1] Document manual validation steps for autotiling and biome transition edge cases in `specs/009-voxel-rendering-merging/quickstart.md` Steps 3 and 4

### Implementation for User Story 1

- [ ] T015 [US1] Implement `src/rendering/bitmask_autotiler.gd` `refresh_tile(coord: Vector2i, grid: GardenGrid) -> int` — computes and returns 8-bit bitmask; also refreshes all 8 neighbour bitmasks by calling into `VoxelRenderer._on_tile_bitmask_changed` for each affected coord
- [ ] T016 [US1] Add `_on_tile_placed(coord: Vector2i, tile: GardenTile)` handler in `src/rendering/voxel_renderer.gd` — calls `BitmaskAutotiler.refresh_tile`, updates `TileRenderState.bitmask8` and `.canonical`, marks owning `TileChunkRenderer` dirty, propagates neighbour refreshes
- [ ] T017 [US1] Implement `src/rendering/biome_transition_layer.gd` — `BiomeTransitionLibrary` dictionary keyed by sorted `[biome_a, biome_b]` pair; `on_tile_placed(coord: Vector2i, grid: GardenGrid)` iterates the 4 cardinal neighbours, checks each pair against the library, spawns `MeshInstance3D` decoration nodes at the shared edge midpoint, stores `TransitionDecoration` records keyed by edge key
- [ ] T018 [US1] Add the 5 MVP biome-pair entries to `BiomeTransitionLayer`'s `_init_library()`: FOREST↔WATER (reed + muddy bank), STONE↔WATER (rocky shore), EARTH↔WATER (sandy bank), FOREST↔EARTH (fallen log/root)
- [ ] T019 [US1] Wire `BiomeTransitionLayer` into `VoxelRenderer._on_tile_placed` — call `BiomeTransitionLayer.on_tile_placed(coord, GameState.grid)` after bitmask refresh; parent spawned nodes under `DecorationParent` in `VoxelGarden.tscn`
- [ ] T020 [US1] Cross-biome bitmask extension: update `BitmaskAutotiler.refresh_tile` so that a neighbour with a registered transition pair also sets the relevant bitmask bit (seamless visual blending between biomes)

**Checkpoint**: US1 autotiling and decoration are independently functional and demoable.

---

## Phase 4: User Story 2 — Mountain Cluster Merge at 10+ Stone Tiles (Priority: P1)

**Goal**: A contiguous cluster of 10+ Stone tiles has its individual tile meshes replaced by a single unified Mountain mesh within the same render frame. New tiles added to the cluster trigger a re-merge in the same frame.

**Independent Test**: Place 9 connected Stone tiles → verify individual voxel meshes. Place 10th → verify ALL 10 individual meshes are replaced by one Mountain mesh in the same frame. Place 11th → Mountain mesh re-merges to cover all 11.

### Tests for User Story 2

- [ ] T021 [P] [US2] Add GUT coverage in `tests/unit/test_mountain_cluster.gd`: single Stone tile creates a singleton cluster; two adjacent Stone tiles merge into one cluster; placing a 10th Stone tile in a connected cluster emits `cluster_merged`; two bridging clusters (8+8+1=17) emit one `cluster_merged`
- [ ] T022 [US2] Document manual validation steps in `specs/009-voxel-rendering-merging/quickstart.md` Step 5 (9→10→11 tile sequences and two-cluster bridge scenario)

### Implementation for User Story 2

- [ ] T023 [US2] Implement `src/rendering/mountain_cluster_tracker.gd` — union-find data structure over Stone tile coordinates; `register_tile(coord: Vector2i)` adds coord to existing cluster or creates singleton; merges adjacent clusters; emits `cluster_merged(cluster_id: int)` when threshold is crossed; `get_cluster(id)`, `get_cluster_for_coord(coord)`, and `is_merged(coord)` API
- [ ] T024 [US2] Implement `src/rendering/mountain_mesh_builder.gd` — `build_mesh(members: Array[Vector2i]) -> Mesh` constructs a single `ArrayMesh` covering all member tile positions (simple extruded box per tile merged into one surface); used only for clusters ≥10
- [ ] T025 [US2] Connect `MountainClusterTracker.cluster_merged` signal in `VoxelRenderer._ready`; handler hides all individual `TileRenderState` mesh instances for cluster members and instantiates a `MeshInstance3D` using `MountainMeshBuilder.build_mesh`, parented under `MountainMeshParent`; sets `TileRenderState.in_mountain = true` for all members
- [ ] T026 [US2] Implement re-merge path in `VoxelRenderer` — when a new Stone tile is placed into an already-merged cluster (`is_merged` returns true), destroy the existing Mountain `MeshInstance3D` and call `MountainMeshBuilder.build_mesh` with the updated member list, replacing the node in the same `_process` frame

**Checkpoint**: US2 Mountain merge is independently functional alongside US1.

---

## Phase 5: User Story 3 — 60fps Performance with Instanced Rendering and LOD (Priority: P2)

**Goal**: A 5,000-tile garden sustains 60fps on mid-range mobile. Tiles share instanced draw calls per chunk. Distant chunks use reduced-LOD meshes.

**Independent Test**: Generate a 5,000-tile garden (headless or debug scene); measure frame time over 60s pan; confirm ≤16.7ms sustained. Zoom to max distance; confirm LOD mesh switch visible.

### Tests for User Story 3

- [ ] T027 [P] [US3] Add GUT coverage in `tests/unit/test_mountain_cluster.gd` (extend existing suite): chunk coordinate calculation for edge tiles (coord (7,7) → chunk (0,0); coord (8,0) → chunk (1,0)); `TileChunkRenderer.mark_dirty()` sets `dirty = true`; rebuild clears `dirty` flag
- [ ] T028 [US3] Document manual performance validation in `specs/009-voxel-rendering-merging/quickstart.md` Step 6 (Godot Profiler, 60s pan, LOD switch confirmation)

### Implementation for User Story 3

- [ ] T029 [US3] Ensure `TileChunkRenderer` uses `MultiMeshInstance3D` correctly: one `MultiMesh` per canonical variant; `MultiMesh.instance_count` set to current tile count for that variant in the chunk; `MultiMesh.set_instance_transform(i, transform)` called for each tile during rebuild; rebuild deferred to `_process` (one rebuild per dirty chunk per frame)
- [ ] T030 [US3] Implement `src/rendering/lod_controller.gd` — export `lod_distance: float = 640.0` (20 tile-units × 32px); `update(camera_position: Vector3)` iterates all active `TileChunkRenderer` nodes and sets `MultiMeshInstance3D.visibility_range_end` / `visibility_range_begin` on the full-detail and LOD `MultiMesh` nodes to implement the chunk-level LOD switch
- [ ] T031 [US3] Add `LodController` node to `VoxelGarden.tscn` and call `lod_controller.update(camera.global_position)` each frame from a `_process` hook in `VoxelRenderer`
- [ ] T032 [US3] Wire chunk-dirty batching: when multiple tiles in the same chunk are placed in one frame (burst placement), `mark_dirty()` is idempotent — the chunk rebuilds exactly once per frame regardless of how many tiles were placed

**Checkpoint**: US3 performance optimisations are in place; US1 and US2 visual behaviour is unchanged.

---

## Phase 6: User Story 4 — Colorblind High-Contrast Palette (Priority: P3)

**Goal**: Toggling the colorblind palette in settings immediately switches all rendered tile colours to high-contrast variants in the same frame. New tiles placed while the palette is active render in the high-contrast variant from the first frame.

**Independent Test**: Toggle colorblind palette ON with all biome types visible → verify all change colour in one frame. Toggle OFF → verify all revert. Place a new tile with palette ON → verify no standard-colour flash.

### Tests for User Story 4

- [ ] T033 [P] [US4] Add GUT coverage in `tests/unit/test_bitmask_autotiler.gd` (extend existing suite): `TileMeshLibrary` returns a different material/colour parameter when `colorblind_mode = true` vs `false`; toggling the global flag updates the material shader parameter
- [ ] T034 [US4] Document manual colorblind palette validation in `specs/009-voxel-rendering-merging/quickstart.md` Step 7

### Implementation for User Story 4

- [ ] T035 [US4] Author a shared `ShaderMaterial` resource at `assets/materials/tile_voxel.tres` with a custom Godot spatial shader; the shader reads `uniform sampler2D palette_lut` (a 10×2 pixel texture: row 0 = standard colours, row 1 = high-contrast colours) and `uniform float use_colorblind` (0.0 or 1.0); biome index is passed as per-instance custom data float
- [ ] T036 [US4] Create the two-row LUT texture `assets/materials/palette_lut.png` (10 pixels wide × 2 pixels tall): row 0 encodes the 10 standard biome colours matching `GardenView._biome_color()`; row 1 encodes high-contrast equivalents that differ in both hue and luminance
- [ ] T037 [US4] Assign `tile_voxel.tres` as the material on all `MultiMeshInstance3D` nodes created by `TileChunkRenderer`; set per-instance custom data channel 0 to the biome index float
- [ ] T038 [US4] Add `toggle_colorblind_palette(enabled: bool)` method to `VoxelRenderer`; calls `tile_voxel_material.set_shader_parameter("use_colorblind", 1.0 if enabled else 0.0)` — one call updates all tiles simultaneously
- [ ] T039 [US4] Connect `toggle_colorblind_palette` to the accessibility settings signal from spec 013 (stub connection with `# TODO: connect to spec-013 settings signal` comment if spec 013 is not yet delivered); wire manual toggle via `TileSelector.gd` for dev validation

**Checkpoint**: All four user stories are independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final integration hardening, regression validation, and artifact alignment.

- [ ] T040 [P] Run full headless GUT suite via `tests/gut_runner.tscn` and confirm zero regressions across all existing and new test files
- [ ] T041 Validate all `quickstart.md` manual scenarios (Steps 3–7) and record pass/fail outcomes in `specs/009-voxel-rendering-merging/quickstart.md`
- [ ] T042 [P] Confirm `TileMeshLibrary` contract is satisfied: `get_mesh` never returns null, same inputs always produce same output — add assertion in `tests/unit/test_bitmask_autotiler.gd`
- [ ] T043 [P] Confirm `MountainClusterTracker` contract is satisfied: `cluster_merged` fires in same `_process` cycle, union-find invariant — add assertion in `tests/unit/test_mountain_cluster.gd`
- [ ] T044 Verify that `GardenView.gd` 2D overlay (hover highlight, mix animation, reject animation) still functions correctly alongside the new 3D `VoxelGarden` layer — record result in `quickstart.md`
- [ ] T045 [P] Update `specs/009-voxel-rendering-merging/contracts/tile-mesh-variant-contract.md` and `contracts/mountain-cluster-contract.md` if any API signatures changed during implementation
- [ ] T046 Add `src/rendering/` to `.gitignore` exclusion audit — confirm no `.import` or `.godot` artifacts committed
- [ ] T047 [P] Performance budget final check: open Godot Profiler with 5,000-tile garden and record sustained frame time in `specs/009-voxel-rendering-merging/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Start immediately — no prerequisites.
- **Phase 2 (Foundational)**: Depends on Phase 1; BLOCKS all user story phases.
- **Phase 3 (US1 — Autotiling)**: Depends on Phase 2; no dependency on US2–US4.
- **Phase 4 (US2 — Mountain)**: Depends on Phase 2; no dependency on US1 rendering logic but shares `VoxelRenderer` integration.
- **Phase 5 (US3 — Performance)**: Depends on Phase 2; completes the chunk/LOD layer that US1 and US2 already use.
- **Phase 6 (US4 — Palette)**: Depends on Phase 2 and the shared material from US3 (T035–T037).
- **Phase 7 (Polish)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Can start immediately after Phase 2. No dependencies on US2–US4.
- **US2 (P1)**: Can start immediately after Phase 2. No dependencies on US1–US4, but shares `VoxelRenderer`.
- **US3 (P2)**: Can start after Phase 2. Complements US1/US2 but does not block them.
- **US4 (P3)**: Depends on the shared `ShaderMaterial` authored in US3 (T035). Start US4 after T035 is complete.

### Recommended Story Completion Order

1. US1 (autotiling + transitions) — highest visual impact, validates the core pipeline.
2. US2 (Mountain merge) — dramatic visual milestone, validates cluster detection.
3. US3 (performance + LOD) — ensures garden scales to 5,000 tiles.
4. US4 (colorblind palette) — accessibility layer, depends on US3 material.

---

## Parallel Execution Examples

### Phase 2 (Foundational)

```text
T006  src/rendering/bitmask_autotiler.gd
T008  src/rendering/tile_chunk_renderer.gd
```

### User Story 1

```text
T012  tests/unit/test_bitmask_autotiler.gd
T013  tests/unit/test_biome_transition.gd
T015  src/rendering/bitmask_autotiler.gd  (refresh_tile)
T017  src/rendering/biome_transition_layer.gd
```

### User Story 2

```text
T021  tests/unit/test_mountain_cluster.gd
T023  src/rendering/mountain_cluster_tracker.gd
T024  src/rendering/mountain_mesh_builder.gd
```

### User Story 3

```text
T027  tests/unit/test_mountain_cluster.gd  (chunk extend)
T029  src/rendering/tile_chunk_renderer.gd  (MultiMesh wiring)
T030  src/rendering/lod_controller.gd
```

### User Story 4

```text
T033  tests/unit/test_bitmask_autotiler.gd  (palette extend)
T035  assets/materials/tile_voxel.tres
T036  assets/materials/palette_lut.png
```

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1 (Setup).
2. Complete Phase 2 (Foundational).
3. Complete Phase 3 (US1 — Autotiling + Transitions).
4. **STOP and VALIDATE**: Run GUT suites; perform quickstart.md manual validation Steps 3 and 4.
5. Demo: place tiles and observe seamless bitmask blending and biome edge decorations.

### Incremental Delivery

1. Setup + Foundational → rendering infrastructure in place.
2. US1 → autotiling and biome transitions working → demo-ready MVP.
3. US2 → Mountain merge visual milestone.
4. US3 → 5,000-tile performance confirmed.
5. US4 → colorblind accessibility complete.
6. Polish phase → full regression pass + artifact alignment.

---

## Notes

- `[P]` tasks touch separate files or extend separate sections of the same test file — safe to parallelise.
- `[US*]` labels map each task to the user story from `specs/009-voxel-rendering-merging/spec.md`.
- Each user story phase is independently testable: autotiling and Mountain merge can be validated separately.
- Voxel meshes in `assets/meshes/tiles/` are artist-created `.tres` `ArrayMesh` resources; stub them with a coloured box mesh during development and replace with final assets without code changes.
- Mountain cluster tracker uses a union-find (disjoint set) algorithm to keep cluster merge at near-O(1) amortised cost.
- `GardenView.gd` (2D hover/animation overlay) intentionally stays active — it renders above the 3D scene via the `Camera2D` / `Node2D` layer ordering.
