# Tasks: Hexagonal Tile System

**Input**: Design documents from `/specs/014-hex-tiles/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: GUT automated tests are required for all deterministic logic (hex math,
bitmask canonical table, adjacency rules, cluster BFS, save version gate). Scene-heavy
and visual rendering work requires explicit manual validation tasks in addition.

**Organization**: Tasks are grouped by user story to enable independent implementation
and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)
- All file paths are absolute from the project root

---

## Phase 1: Setup

**Purpose**: Confirm working state before making any changes.

- [x] T001 Verify branch `014-hex-tiles` is active, all existing GUT tests pass via `tests/gut_runner.tscn`, and note any currently failing tests as pre-existing to exclude from this feature's scope

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core hex infrastructure that every user story depends on. No user story
work can begin until this phase is complete.

**⚠️ CRITICAL**: All tasks in this phase must be complete before Phase 3 or later.

- [x] T002 Create `src/grid/hex_utils.gd` — stateless pure-math script (no `class_name`, no autoload); implement `get_neighbors(coord: Vector2i) → Array[Vector2i]` (6 pointy-top axial offsets), `axial_to_pixel(coord: Vector2i, radius: float) → Vector2`, `pixel_to_axial(px: Vector2, radius: float) → Vector2i` (via cube-rounding), `axial_distance(a: Vector2i, b: Vector2i) → int`, `axial_ring(center: Vector2i, radius: int) → Array[Vector2i]`; HEX_NEIGHBORS constant as per data-model.md
- [x] T003 [P] Write `tests/unit/test_hex_utils.gd` — GUT tests covering: each of the 6 neighbor offsets from a known coord, round-trip `axial_to_pixel` → `pixel_to_axial` for multiple coords, `axial_distance` for adjacent (1) and same-tile (0) cases, `axial_ring` returns correct count at radius 1 (6) and radius 2 (12)
- [x] T004 Update `src/grid/spatial_query.gd` — replace `get_cardinal_neighbors()` with `get_hex_neighbors()` using `preload("res://src/grid/hex_utils.gd")` and `HexUtils.get_neighbors()`; update `get_connected_region()` BFS to call `get_hex_neighbors()`; update `count_biomes_in_radius()` to use `HexUtils.axial_distance()` instead of Chebyshev distance
- [x] T005 Update `src/grid/GridMap.gd` — update `is_placement_valid()` to check the 6 hex-adjacency offsets from `HexUtils.get_neighbors()` instead of the 4 cardinal offsets; no other changes to GridMap interface
- [x] T006 [P] Update `src/rendering/tile_render_state.gd` — rename field `bitmask8` → `bitmask6` (int, range 0–63); update field comment `canonical` range to 0–12; search and update all references to `bitmask8` in `src/rendering/` (`voxel_renderer.gd`, `tile_chunk_renderer.gd`, `bitmask_autotiler.gd`) to use `bitmask6`

**Checkpoint**: Run `tests/gut_runner.tscn` — T003 tests must pass. All other tests may be broken (expected) until their phases complete.

---

## Phase 3: User Story 1 — Navigate a Hexagonal Grid (Priority: P1) 🎯 MVP

**Goal**: The player can place tiles on a hex grid; every tile has 6 neighbors;
placement validity uses hex adjacency; mouse input resolves to the correct hex tile.

**Independent Test**: Open `scenes/Garden.tscn`, play in editor. Place a tile at origin.
Confirm that the 6 surrounding positions (not 4) are highlighted as valid placements.
Click between tiles — confirm no tile is selected. Run T007 GUT tests.

### Tests for User Story 1

- [x] T007 [P] [US1] Write `tests/unit/test_hex_placement.gd` — GUT tests covering: origin tile has 6 valid placement candidates; edge tile at extreme coord has fewer than 6 in-bounds neighbors without error; placed tile blocks its own coord; `is_placement_valid()` accepts hex-adjacent coord; `is_placement_valid()` rejects non-adjacent coord

### Implementation for User Story 1

- [x] T008 [US1] Update `src/grid/PlacementController.gd` — replace the pixel→square-coord calculation (`floori(pos.x / TILE_SIZE)`) with `HexUtils.pixel_to_axial(mouse_pos, TILE_RADIUS)` using `preload("res://src/grid/hex_utils.gd")`; use explicit `Vector2i` type annotation on the result (not `:=`) to satisfy warnings-as-errors; update long-press mixing coord resolution the same way
- [x] T009 [US1] Verify `src/autoloads/GameState.gd` — confirm `try_place_tile()` and `try_mix_tile()` delegate validity entirely to `GridMap.is_placement_valid()`; if any inline cardinal-offset check exists in GameState, replace with a call to `GridMap`; add no new logic
- [ ] T010 [US1] Manual validation: open `scenes/Garden.tscn`, press Play, place tiles and verify (a) 6 neighbors are highlighted as valid, (b) mouse click lands on the visually correct tile (even if still drawn as a square — hit logic correctness is what matters here), (c) no GDScript errors in Output panel

**Checkpoint**: T007 GUT tests pass. Manual navigation confirms 6-way adjacency. US1 is independently functional.

---

## Phase 4: User Story 2 — Discover Neighboring Hex Tiles (Priority: P2)

**Goal**: The discovery system evaluates up to 6 neighbors per scan; cluster and shape
pattern matchers work on hex coordinates; existing discovery IDs remain valid.

**Independent Test**: In a test scene or via GUT, place a 3-tile cluster of the same biome
in hex formation. Trigger a pattern scan. Confirm a cluster discovery fires and no
duplicate or "already discovered" errors appear. Run T011–T013 GUT tests.

### Tests for User Story 2

- [x] T011 [P] [US2] Write `tests/unit/test_hex_cluster.gd` — GUT tests covering: 3-tile hex cluster detected by `ClusterMatcher` BFS; 1-tile island (no neighbors) returns size 1; BFS does not cross non-matching biome; edge tile with fewer than 6 neighbors does not error during BFS
- [x] T012 [P] [US2] Update `tests/unit/patterns/test_cluster_matcher.gd` — replace any `Vector2i(x,y)` square-adjacency fixture coords with equivalent axial hex coords; confirm test intent is preserved
- [x] T013 [P] [US2] Update `tests/unit/patterns/test_shape_matcher.gd` — replace square-offset templates with 3–4 representative hex axial offset patterns (e.g., a straight line of 3, a triangular triad); confirm shape match and no-match cases both still pass

### Implementation for User Story 2

- [x] T014 [US2] Update `src/biomes/matchers/cluster_matcher.gd` — replace the BFS neighbor call (currently cardinal) with `SpatialQuery.get_hex_neighbors()` or the equivalent direct call; use explicit `Array[Vector2i]` type annotation on neighbor results
- [x] T015 [US2] Update `src/biomes/matchers/shape_matcher.gd` — replace hard-coded square offset arrays with hex axial offsets matching the updated pattern resources (T018); the matcher logic itself (iterate offsets, check biome) needs no structural change — only the default/built-in offsets
- [x] T016 [P] [US2] Update `src/biomes/matchers/ratio_proximity_matcher.gd` — replace any Chebyshev or Manhattan distance calculation with `HexUtils.axial_distance()`; use `preload("res://src/grid/hex_utils.gd")` for the import; apply explicit type annotation to distance result
- [x] T017 [US2] Verify `src/biomes/matchers/compound_matcher.gd` — read the file and confirm it has no direct coordinate arithmetic or neighbor calls; if it does, update them; if it only delegates to other matchers, add a comment confirming no change needed and close the task
- [x] T018 [US2] Replace shape pattern `.tres` resource files under `res://resources/patterns/` (or equivalent path) — re-author offset arrays to use hex axial coordinates; define at minimum: a 3-tile straight line, a 3-tile triangular cluster, a 6-tile hex ring (radius 1), a 7-tile hex flower (centre + ring); preserve discovery IDs so `DiscoveryRegistry` entries remain valid
- [ ] T019 [US2] Manual validation: place tiles to form a 3-hex cluster, trigger a scan (by placing or mixing), confirm discovery event fires in the Output panel with correct discovery ID; confirm no duplicate fire on the same cluster

**Checkpoint**: T011–T013 GUT tests pass. Discovery fires on hex clusters. US2 is independently functional.

---

## Phase 5: User Story 3 — Visually Appealing Hex Map Presentation (Priority: P3)

**Goal**: All tiles are rendered as hexagons; bitmask autotiling uses 6-bit hex bitmask
with 13 canonical forms; biome transitions and mountain clusters use hex adjacency;
GardenView draws hex polygons.

**Independent Test**: Open `scenes/Garden.tscn`, press Play. Place tiles of two different
biomes side by side. Confirm: (a) tiles are visually hexagonal, (b) biome transition
decoration appears at shared hex edge, (c) a 10+ Stone tile cluster produces a mountain
mesh, (d) no tile overlap or gap in the layout. Run T020–T023 GUT tests.

### Tests for User Story 3

- [x] T020 [P] [US3] Write `tests/unit/test_hex_bitmask.gd` — GUT tests covering: exhaustive check that all 64 raw bitmask values map to a canonical value in range 0–12; canonical(0b000000) == 0 (island); canonical(0b111111) == 12 (full); verify at least 2 rotation-equivalent raw values produce the same canonical; verify at least 1 reflection-equivalent pair produces the same canonical
- [x] T021 [P] [US3] Update `tests/unit/test_bitmask_autotiler.gd` — replace 8-bit / 47-canonical fixtures with 6-bit / 13-canonical fixtures; rewrite test cases to use hex neighbor coords; confirm all tests still cover bitmask computation and canonical resolution
- [x] T022 [P] [US3] Update `tests/unit/test_biome_transition.gd` — replace cardinal-direction neighbor pairs with hex-direction pairs; confirm transition detection still fires for all 6 hex directions
- [x] T023 [P] [US3] Update `tests/unit/test_mountain_cluster.gd` — replace cardinal neighbor scan fixtures with hex neighbor coords; confirm cluster union-find still detects ≥10-tile Stone clusters correctly

### Implementation for User Story 3

- [x] T024 [US3] Update `src/rendering/bitmask_autotiler.gd` — implement 6-bit hex bitmask computation (bits 0–5 mapped to 6 hex directions per data-model.md); build the 64-element `_canonical: Array[int]` lookup table at `_ready()` using D6 symmetry reduction; remove all 8-bit / corner-dependency / Wang-blob logic; keep the public API (`get_canonical(coord, grid)`) unchanged so callers need no update
- [x] T025 [US3] Update `src/rendering/tile_mesh_library.gd` — change mesh slot indexing from `(biome, canonical_0-46)` to `(biome, canonical_0-12)`; update any compile-time assertions on canonical range; if placeholder meshes exist for 47 variants, reduce to 13 (or mark 14–46 as unused stubs to remove in Polish)
- [x] T026 [P] [US3] Update `src/rendering/tile_chunk_renderer.gd` — update chunk assignment to use `Vector2i(floori(coord.q / 8.0), floori(coord.r / 8.0))` in axial space; update any pixel-space chunk boundary calculations to use `HexUtils.axial_to_pixel()`; use `preload("res://src/grid/hex_utils.gd")`
- [x] T027 [P] [US3] Update `src/rendering/biome_transition_layer.gd` — replace cardinal neighbor offset iteration with hex neighbor offsets from `HexUtils.get_neighbors()`; confirm all 6 hex edge transition types are registered; use `preload("res://src/grid/hex_utils.gd")`
- [x] T028 [P] [US3] Update `src/rendering/mountain_cluster_tracker.gd` — replace cardinal neighbor scan in union-find with `HexUtils.get_neighbors()`; no change to the ≥10-tile threshold or the mountain mesh trigger logic; use `preload("res://src/grid/hex_utils.gd")`
- [x] T029 [US3] Update `src/rendering/voxel_renderer.gd` — replace all `coord * TILE_SIZE` world-position calculations with `HexUtils.axial_to_pixel(coord, TILE_RADIUS)` to get 2D pixel centre, then lift to 3D; use `preload("res://src/grid/hex_utils.gd")`; use explicit `Vector2` type annotation on pixel results
- [x] T030 [US3] Update `src/grid/GardenView.gd` — replace `draw_rect()` tile draws with `draw_polygon(_hex_vertices(centre, TILE_RADIUS), [color])` where `_hex_vertices` returns a `PackedVector2Array` of 6 pointy-top vertices; replace pixel→square-coord hover calculation with `HexUtils.pixel_to_axial()`; TILE_RADIUS constant replaces TILE_SIZE for hex sizing (set to 32.0 to preserve approximate tile footprint); use `preload("res://src/grid/hex_utils.gd")`
- [ ] T031 [US3] Manual visual validation: press Play in `scenes/Garden.tscn`, (a) confirm tiles appear as hexagons with no square artefacts, (b) place Forest next to Water and confirm reed decoration appears at the shared hex edge, (c) place ≥10 Stone tiles in a connected hex group and confirm mountain mesh replaces them, (d) confirm no visual gaps or overlapping tiles at any zoom level

**Checkpoint**: T020–T023 GUT tests pass. Visual hex layout confirmed. US3 is independently functional.

---

## Phase 6: User Story 4 — Save and Configuration Compatibility (Priority: P4)

**Goal**: The game writes `version: 2` to saves; on load, version < 2 or absent triggers
a user-friendly new-game prompt; no silent data corruption from old square-grid saves.

**Independent Test**: Manually create a minimal save dict without a `version` key (simulating
a pre-hex save), load the game, and confirm the new-game prompt appears without any
GDScript errors. Run T032 GUT tests.

### Tests for User Story 4

- [ ] T032 [P] [US4] Write `tests/unit/test_save_version_gate.gd` — GUT tests covering: loading a save dict without `version` key triggers the incompatibility path (returns false or emits signal); loading a save dict with `version: 1` triggers incompatibility; loading a save dict with `version: 2` proceeds normally; saving writes `version: 2` in the output dict

### Implementation for User Story 4

- [ ] T033 [US4] Update `src/autoloads/discovery_persistence.gd` — add `const SAVE_VERSION: int = 2` constant; on `save()` write `data["version"] = SAVE_VERSION`; on `load()` read `data.get("version", 0)` and if < 2 emit a new signal `save_incompatible` (or call a method on a UI autoload) instead of parsing tile data; preserve existing discovery-ID save/load path for version 2 data
- [ ] T034 [US4] Wire the incompatible-save UI response — in the appropriate UI scene (`scenes/UI/` or `src/ui/`) connect to the `save_incompatible` signal from `DiscoveryPersistence` and display a modal or label stating saves from the previous version are not compatible and offering a "New Game" button; keep the UI change minimal (one label + one button is sufficient)
- [ ] T035 [US4] Manual validation: (a) back up any existing save file, run the game — confirm fresh start works; (b) restore the old save file, run the game — confirm the incompatible-save message appears without GDScript errors and the "New Game" button starts a fresh hex garden

**Checkpoint**: T032 GUT tests pass. Save gate confirmed manually. US4 is independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Full integration validation, dead-code removal, and documentation close-out.

- [x] T036 [P] Run the full GUT suite (`tests/gut_runner.tscn`) — all tests must pass; fix any regressions in `test_biome_type.gd`, `test_tile_data.gd`, or discovery integration tests caused by the hex transition; document any remaining known failures with a tracking comment
- [ ] T037 [P] Full end-to-end playthrough manual validation: (a) start new game, place tiles in multiple biomes, mix tiles, trigger at least 2 distinct discovery events, verify discovery notification appears, (b) quit and relaunch — confirm save/load cycle completes with `version: 2`, (c) confirm no performance hitch on initial map load
- [x] T038 [P] Remove dead square-grid code — search `src/` for any remaining references to cardinal-only offsets `[Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]` not inside `hex_utils.gd`; replace or remove; search for `bitmask8` to confirm rename is complete; remove any commented-out square-tile drawing code in `GardenView.gd`
- [x] T039 Update `specs/014-hex-tiles/quickstart.md` — add any implementation notes discovered during development (e.g., actual `TILE_RADIUS` value used, any canonical index assignments that differ from the plan, any gotchas encountered); confirm all pitfalls in the current quickstart remain accurate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 (HexUtils + spatial_query + GridMap + tile_render_state)
- **US2 (Phase 4)**: Depends on Phase 2 (HexUtils + spatial_query) — independent of US1
- **US3 (Phase 5)**: Depends on Phase 2 (all foundational) — independent of US1 and US2
- **US4 (Phase 6)**: Depends on Phase 2 only (no hex math needed) — independent of US1–US3
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — no dependencies on US2/US3/US4
- **US2 (P2)**: After Phase 2 — no dependencies on US1/US3/US4
- **US3 (P3)**: After Phase 2 — no dependencies on US1/US2/US4
- **US4 (P4)**: After Phase 2 — no dependencies on US1/US2/US3

### Within Each User Story

- GUT test tasks are marked [P] and can be written alongside implementation
- Implementation tasks within a story follow file-dependency order (utilities before consumers)
- Manual validation task is always last within its story

### Parallel Opportunities

Within Phase 2: T003 and T006 can run in parallel with T002 (different files). T004 requires T002. T005 requires T004.

Within Phase 3: T007 can run in parallel with T008/T009. T010 requires T008 and T009.

Within Phase 4: T011, T012, T013 can run in parallel. T014 requires T004 (Phase 2). T015 requires T014. T016 is independent of T014/T015. T017 requires T014+T015. T018 requires T015. T019 requires T014–T018.

Within Phase 5: T020–T023 can run in parallel. T024 requires T006. T025 requires T024. T026–T028 can run in parallel with each other (after T004). T029 requires T024. T030 requires T002. T031 requires T024–T030.

Within Phase 6: T032 can run in parallel with T033. T034 requires T033. T035 requires T033+T034.

Within Phase 7: T036, T037, T038 can run in parallel.

---

## Parallel Example: Phase 2

```text
T002 Create src/grid/hex_utils.gd                          (must be first)
  └─ T003 [P] Write tests/unit/test_hex_utils.gd           (parallel with T002)
  └─ T006 [P] Update src/rendering/tile_render_state.gd    (parallel with T002)
  └─ T004 Update src/grid/spatial_query.gd                 (after T002)
       └─ T005 Update src/grid/GridMap.gd                  (after T004)
```

## Parallel Example: Phase 5 (US3)

```text
T024 Update src/rendering/bitmask_autotiler.gd             (after Phase 2)
  └─ T025 Update src/rendering/tile_mesh_library.gd        (after T024)
  └─ T029 Update src/rendering/voxel_renderer.gd           (after T024)

T026 [P] Update src/rendering/tile_chunk_renderer.gd       (parallel with T024)
T027 [P] Update src/rendering/biome_transition_layer.gd    (parallel with T024)
T028 [P] Update src/rendering/mountain_cluster_tracker.gd  (parallel with T024)
T030 Update src/grid/GardenView.gd                         (after T002, parallel with T024+)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T006) — **critical blocker**
3. Complete Phase 3: US1 (T007–T010)
4. **STOP and VALIDATE**: 6-directional hex grid works, mouse hit-test correct, GUT passes
5. Demonstrate: player can navigate hex garden

### Incremental Delivery

1. Setup + Foundational → hex math + adjacency ready
2. US1 → hex navigation works → MVP demo
3. US2 → discovery fires on 6-neighbor hex clusters → discovery demo
4. US3 → tiles look like hexagons → visual polish demo
5. US4 → save gate in place → safe for players to update

### Notes

- [P] tasks = different files, no blocking dependencies on in-progress tasks
- [Story] label maps task to user story for traceability
- Each user story is independently completable and demonstrable
- Commit after each task or logical group; do not batch across stories
- Stop at each Checkpoint to validate the story before proceeding
- Avoid: hardcoded square offsets anywhere outside `hex_utils.gd`, `:=` on `HexUtils` returns in warnings-as-errors files, `class_name` on `hex_utils.gd`
