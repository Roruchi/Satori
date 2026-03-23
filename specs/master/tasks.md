# Tasks: Satori Master Orchestration (F01-F13)

**Input**: Design documents from `/specs/master/` and supporting feature specs in `/specs/001-dev-tooling-harness/` through `/specs/013-accessibility-settings/`
**Prerequisites**: `specs/master/plan.md`, `specs/master/spec.md`

**Tests**: Include automated GUT coverage for deterministic gameplay rules, pattern/discovery idempotency, persistence, and regressions. Scene-heavy flows also require explicit manual validation tasks.

**Organization**: Tasks are grouped by master incremental feature stories so each phase can be tracked and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unresolved dependencies)
- **[Story]**: Master story label (`[US1]`..`[US13]` maps to F01..F13)
- Include exact file paths in descriptions

## Reference Inputs (Before Execution)

- `specs/004-biome-alchemy-mixing/tasks.md`
- `specs/005-pattern-matching-engine/tasks.md`
- `specs/010-camera-mobile-nav/tasks.md`
- Current runtime scripts under `src/` and scene structure under `scenes/`

## Phase 1: Setup (Shared Orchestration)

**Purpose**: Align master execution to current repository structure and existing subfeature artifacts.

- [ ] T001 Verify and align runtime entrypoint references in `specs/master/plan.md`, `specs/master/quickstart.md`, and `project.godot` so `scenes/Garden.tscn` is canonical; completion requires no runtime references to `scenes/Main.tscn`
- [ ] T002 Create missing master directories from the plan in `src/debug/`, `src/entities/`, `src/rendering/`, and `src/patterns/`
- [ ] T003 [P] Create missing test suites placeholders in `tests/unit/discoveries/.gdkeep`, `tests/unit/camera/.gdkeep`, `tests/unit/persistence/.gdkeep`, and `tests/unit/accessibility/.gdkeep`
- [ ] T004 [P] Add master cross-feature validation matrix (F01-F13 checkpoints) to `specs/master/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Stabilize shared infrastructure required by all downstream feature stories.

**⚠️ CRITICAL**: No user story phase should start until this phase is complete.

- [ ] T005 Finalize grid/discovery singleton contracts and typed signals in `src/autoloads/GameState.gd`; completion requires signature stability and passing assertions in `tests/unit/test_bootstrap_state.gd`
- [ ] T006 Finalize coordinate/chunk utility APIs for camera, rendering, and persistence in `src/grid/GridMap.gd`; completion requires passing lookup/chunk tests in `tests/unit/test_grid_map.gd`
- [ ] T007 [P] Add repository-level regression runner task wiring for GUT suites in `check-errors.ps1`
- [ ] T008 [P] Register any missing global services (audio/settings/save) in `project.godot`
- [ ] T009 Add foundational integration test coverage for startup state, origin tile, and autoload readiness in `tests/unit/test_bootstrap_state.gd`

**Checkpoint**: Foundation ready; feature stories can proceed in dependency order.

---

## Phase 3: User Story 1 - F01 Dev Tooling and Test Harness (Priority: P1)

**Goal**: Deliver a dedicated debug harness to accelerate validation of all later features.

**Independent Test**: Run debug scene with overlay, flood-fill, instant placement, and discovery log active without altering production placement rules.

### Implementation for User Story 1

- [ ] T010 [P] [US1] Create debug harness scene and root wiring in `scenes/Debug.tscn`
- [ ] T011 [P] [US1] Implement overlay, chunk lines, and shortcut help panel in `src/debug/DebugOverlay.gd`
- [ ] T012 [US1] Implement flood-fill seeding and instant placement toggles in `src/debug/FloodFill.gd`
- [ ] T013 [US1] Add pattern visualizer and discovery event console integration in `src/debug/PatternVisualizer.gd`

---

## Phase 4: User Story 2 - F02 Infinite Grid Engine (Priority: P1)

**Goal**: Ensure sparse infinite coordinate storage, chunk lifecycle, and bounds/tile-count tracking are production-safe.

**Independent Test**: Place/retrieve tiles across negative and large coordinates while camera movement loads/unloads chunks with stable performance.

### Tests for User Story 2

- [ ] T014 [P] [US2] Add O(1) lookup and negative-coordinate chunking coverage in `tests/unit/test_grid_map.gd`

### Implementation for User Story 2

- [ ] T015 [US2] Implement or complete chunk load/unload radius management in `src/grid/GridMap.gd`
- [ ] T016 [US2] Ensure garden bounds and total tile count are synchronously maintained in `src/grid/GridMap.gd`
- [ ] T017 [US2] Validate origin reservation behavior at startup through game-state bootstrap in `src/autoloads/GameState.gd`

---

## Phase 5: User Story 3 - F03 Tile Placement and Adjacency (Priority: P1)

**Goal**: Finalize long-press placement loop, adjacency validation, and valid-zone highlighting.

**Independent Test**: Long-press valid adjacent cells to place tiles; invalid coordinates reject with feedback; valid zones highlight on gesture start.

### Tests for User Story 3

- [ ] T018 [P] [US3] Add adjacency and long-press threshold coverage in `tests/unit/test_placement_controller.gd`

### Implementation for User Story 3

- [ ] T019 [US3] Complete long-press and gesture resolution paths in `src/grid/PlacementController.gd`
- [ ] T020 [US3] Implement valid-zone visualization and rejection feedback rendering in `src/grid/GardenView.gd`
- [ ] T021 [US3] Expand base-tile selector support (Forest/Water/Stone/Earth) in `src/ui/TileSelector.gd`

---

## Phase 6: User Story 4 - F04 Biome Alchemy Mixing and Locking (Priority: P1, Partially Implemented)

**Goal**: Close remaining gaps and verify full hybrid catalogue behavior across all 6 combinations.

**Independent Test**: All valid base-pair mixes produce the correct locked hybrid and all invalid mixes are rejected with distinct feedback.

### Tests for User Story 4

- [ ] T022 [P] [US4] Add full alchemy matrix and rejection-path tests in `tests/unit/test_alchemy_mixing.gd`

### Implementation for User Story 4

- [ ] T023 [US4] Verify all six mix combinations plus invalid combinations against runtime behavior and implement missing signal/feedback paths in `src/autoloads/GameState.gd`; completion requires green coverage in `tests/unit/test_alchemy_mixing.gd`
- [ ] T024 [US4] Finalize hybrid visual differentiation and persistent locked markers in `src/grid/GardenView.gd`

---

## Phase 7: User Story 5 - F05 Pattern Matching Engine (Priority: P1, Mostly Implemented)

**Goal**: Finish outstanding hardening and ensure scans remain non-blocking, idempotent, and data-driven.

**Independent Test**: Pattern scans after every placement emit expected discoveries once, under frame budget, with malformed definitions safely skipped.

### Tests for User Story 5

- [ ] T025 [P] [US5] Add explicit matcher coverage for cluster and shape rules in `tests/unit/test_pattern_engine.gd`
- [ ] T026 [P] [US5] Add explicit matcher coverage for ratio/proximity and distance rules in `tests/unit/test_pattern_engine.gd`
- [ ] T027 [US5] Add a performance assertion and baseline capture proving scan completion <=16 ms for ~1,000 tiles via `check-errors.ps1`

### Implementation for User Story 5

- [ ] T028 [US5] Close remaining scheduler integration gaps from existing 005 tasks in `src/biomes/pattern_scan_scheduler.gd`; completion requires stable deferred/asynchronous dispatch in test and play mode
- [ ] T029 [US5] Implement deterministic ordering and duplicate suppression edge-case handling in `src/biomes/pattern_matcher.gd`; completion requires idempotency assertions passing in `tests/unit/test_pattern_engine.gd`

---

## Phase 8: User Story 6 - F06 Tier 1 Biome Discoveries (Priority: P1)

**Goal**: Register and surface all Tier 1 discovery content with notification queueing and persistence hooks.

**Independent Test**: Seed each Tier 1 pattern, verify one-time notification + stinger + persistent discovery log entry.

### Tests for User Story 6

- [ ] T030 [P] [US6] Add Tier 1 discovery trigger/idempotency coverage in `tests/unit/test_tier1_discoveries.gd`

### Implementation for User Story 6

- [ ] T031 [US6] Add Tier 1 pattern resources and metadata catalog in `src/biomes/patterns/tier1/`
- [ ] T032 [US6] Implement queued discovery notification presenter in `src/ui/DiscoveryNotification.gd`
- [ ] T033 [US6] Wire Tier 1 discovery persistence writes into game state log in `src/autoloads/GameState.gd`

---

## Phase 9: User Story 7 - F07 Tier 2 Structural Landmarks (Priority: P1)

**Goal**: Add landmark shape definitions, one-time discovery logging, and on-tile landmark overlays.

**Independent Test**: Build each landmark recipe once; each discovery triggers once and contributing tiles render overlay markers.

### Tests for User Story 7

- [ ] T034 [P] [US7] Add landmark shape and idempotency coverage in `tests/unit/test_tier2_landmarks.gd`

### Implementation for User Story 7

- [ ] T035 [US7] Add Tier 2 landmark pattern resources with shape constraints in `src/biomes/patterns/tier2/`
- [ ] T036 [US7] Implement landmark overlay state rendering in `src/grid/GardenView.gd`
- [ ] T037 [US7] Extend discovery log model for landmark section queries in `src/autoloads/GameState.gd`

---

## Phase 10: User Story 8 - F08 Spirit Animal System (Priority: P1)

**Goal**: Implement data-driven spirit summon rules, spawning, autonomous wandering, and once-per-garden persistence.

**Independent Test**: Seed representative spirit conditions (including Sky-Whale), verify single spawn, bounded wandering, and restart persistence.

### Tests for User Story 8

- [ ] T038 [P] [US8] Add summon/wander/persistence coverage for spirit instances in `tests/unit/test_spirit_animals.gd`

### Implementation for User Story 8

- [ ] T039 [US8] Add spirit definition resources and condition catalog in `src/patterns/spirits/`
- [ ] T040 [US8] Implement spirit entity behavior and wander bounds updates in `src/entities/SpiritAnimal.gd`
- [ ] T041 [US8] Create spirit scene and spawn integration path in `scenes/Entities/SpiritAnimal.tscn`

---

## Phase 11: User Story 9 - F09 Voxel Rendering and Mesh Merging (Priority: P1)

**Goal**: Introduce bitmask autotiling, mountain cluster mesh merging, and rendering performance controls.

**Independent Test**: Tile neighbour updates refresh mesh variants in-frame; 10+ Stone clusters merge into mountain mesh; rendering remains performant at scale.

### Tests for User Story 9

- [ ] T042 [P] [US9] Add autotile and mountain-merge rendering logic tests in `tests/unit/test_voxel_rendering.gd`

### Implementation for User Story 9

- [ ] T043 [US9] Implement neighbour bitmask evaluation and variant mapping in `src/rendering/BitmaskAutotiler.gd`
- [ ] T044 [US9] Implement chunk-based tile mesh instancing in `src/rendering/TileMeshInstancer.gd`
- [ ] T045 [US9] Implement Stone cluster merge-to-mountain behavior in `src/rendering/MountainMerger.gd`

---

## Phase 12: User Story 10 - F10 Camera and Mobile Navigation (Priority: P1, Partially Implemented)

**Goal**: Finish remaining camera interactions (momentum, pinch, recenter, soft bounds) and thumb-zone layout.

**Independent Test**: On touch input, pan/zoom/recenter work together without accidental placement triggers; camera respects soft bounds.

### Tests for User Story 10

- [ ] T046 [P] [US10] Add momentum/pinch/double-tap regression coverage in `tests/unit/camera/test_camera_pan_controller.gd`

### Implementation for User Story 10

- [ ] T047 [US10] Complete pending 010 US2-US4 gesture logic in `src/camera/CameraPanController.gd`
- [ ] T048 [US10] Finalize drag-vs-tap suppression integration for placement safety in `src/grid/PlacementController.gd`
- [ ] T049 [US10] Apply thumb-zone layout updates for selector/settings anchors in `scenes/Garden.tscn`

---

## Phase 13: User Story 11 - F11 Ambient Soundscape (Priority: P1)

**Goal**: Deliver camera-driven ambient blending, queued discovery stingers, and runtime volume controls.

**Independent Test**: Panning across biome regions crossfades ambient tracks smoothly; stingers play once and queue correctly.

### Tests for User Story 11

- [ ] T050 [P] [US11] Add ambient-mix and stinger queue tests in `tests/unit/test_ambient_soundscape.gd`

### Implementation for User Story 11

- [ ] T051 [US11] Implement audio bus mapping and ambient mixer logic in `src/autoloads/AudioManager.gd`
- [ ] T052 [US11] Add biome/discovery audio bed data resources in `src/biomes/audio/`
- [ ] T053 [US11] Wire discovery-triggered stinger playback from pattern/discovery events in `src/autoloads/AudioManager.gd`

---

## Phase 14: User Story 12 - F12 Garden Persistence Save/Load (Priority: P1)

**Goal**: Ensure atomic save/load for tiles, discoveries, and spirits with background-safe auto-save.

**Independent Test**: Restart round-trips preserve complete garden state; autosave and lifecycle saves are reliable without corruption.

### Tests for User Story 12

- [ ] T054 [P] [US12] Add save/load round-trip and atomic-write failure tests in `tests/unit/persistence/test_save_load.gd`

### Implementation for User Story 12

- [ ] T055 [US12] Implement save operation queue and atomic file write path in `src/autoloads/SaveService.gd`
- [ ] T056 [US12] Integrate autosave cadence and background/close hooks in `src/autoloads/GameState.gd`
- [ ] T057 [US12] Implement save schema versioning and migration guardrails in `src/autoloads/SaveService.gd`

---

## Phase 15: User Story 13 - F13 Accessibility and Settings (Priority: P1)

**Goal**: Provide immediate, persistent settings controls for palette, haptics, and layered audio volumes.

**Independent Test**: Toggle settings from UI and confirm same-frame behavior updates plus restart persistence via dedicated config file.

### Tests for User Story 13

- [ ] T058 [P] [US13] Add settings persistence and capability fallback tests in `tests/unit/accessibility/test_settings_service.gd`

### Implementation for User Story 13

- [ ] T059 [US13] Implement settings persistence service and defaults in `src/autoloads/SettingsService.gd`
- [ ] T060 [US13] Create settings panel behavior and bindings in `src/ui/SettingsScreen.gd`
- [ ] T061 [US13] Add settings scene and thumb-zone entry button wiring in `scenes/UI/Settings.tscn`

---

## Phase 16: Polish and Cross-Cutting Concerns

**Purpose**: Final integration hardening across all completed stories.

- [ ] T062 [P] Document cross-feature completion notes and known constraints in `specs/master/quickstart.md`
- [ ] T063 Run full headless GUT suite and capture results in `check-errors.ps1`
- [ ] T064 Profile frame-time hotspots (pattern scan, render updates, camera) and tune to keep runtime stable at 60 fps in `src/biomes/pattern_scan_scheduler.gd`
- [ ] T065 [P] Validate save + settings compatibility and startup order by adding/maintaining assertions in `tests/unit/test_bootstrap_state.gd`
- [ ] T066 [P] Add final regression checklist for F01-F13 in `specs/master/tasks.md`
- [ ] T067 Add cold-start benchmark task and capture evidence proving playable state is reached <=10 s in `specs/master/quickstart.md`
- [ ] T068 Add memory profiling task and capture evidence proving runtime stays <200 MB at stress target in `specs/master/quickstart.md`
- [ ] T069 Add production-mode invariant tests proving undo/clear/reset actions are unavailable in `tests/unit/test_no_reset_invariant.gd`
- [ ] T070 Add release export validation ensuring debug scene/scripts and debug keybind flows are excluded from release behavior in `specs/master/quickstart.md`

---

## Dependencies and Execution Order

### Feature Dependency Graph (Master)

- F01 enables all subsequent testing and validation
- F02 -> F03 -> F04 -> F09
- F02 -> F10 -> F13
- F02 -> F12
- F05 -> F06 -> F11
- F05 -> F07 -> F08
- F06 + F07 -> F08

### Story Completion Order

1. US1 (F01)
2. US2 (F02)
3. US3 (F03)
4. US4 (F04)
5. US5 (F05)
6. US6 (F06)
7. US7 (F07)
8. US8 (F08)
9. US9 (F09)
10. US10 (F10)
11. US11 (F11)
12. US12 (F12)
13. US13 (F13)

### Parallel Opportunities by Story

- US1: T010 and T011 can run in parallel before T012/T013 integration
- US2: T014 can run in parallel with T016 while T015 stabilizes chunk lifecycle
- US3: T018 and T021 can run in parallel before T019/T020 final wiring
- US4: T022 can run in parallel with T024 while T023 verifies matrix parity and fills runtime signal/feedback gaps
- US5: T025 and T026 can run in parallel before performance validation in T027 and final matcher hardening in T029
- US6: T030 and T031 can run in parallel before notification/log wiring in T032/T033
- US7: T034 and T035 can run in parallel before overlay/log work in T036/T037
- US8: T038 and T039 can run in parallel before entity/scene integration in T040/T041
- US9: T042 can run in parallel with T043 before instancing/merge work in T044/T045
- US10: T046 and T049 can run in parallel before gesture/placement integration in T047/T048
- US11: T050 and T052 can run in parallel before manager integration in T051/T053
- US12: T054 and T057 can run in parallel before autosave integration in T055/T056
- US13: T058 and T061 can run in parallel before service/UI binding in T059/T060

---

## Implementation Strategy

### MVP Scope (Recommended)

1. Complete through US5 (F01-F05) to secure core loop + discovery engine
2. Validate with debug harness and GUT regressions before content tiers

### Incremental Delivery

1. Core interaction foundation: US1 -> US5
2. Discovery content: US6 -> US8
3. Presentation and navigation: US9 -> US11
4. Reliability and accessibility: US12 -> US13

### Notes

- Existing subfeature task files in `specs/004-biome-alchemy-mixing/tasks.md`, `specs/005-pattern-matching-engine/tasks.md`, and `specs/010-camera-mobile-nav/tasks.md` are explicitly incorporated via reconciliation tasks (T023, T028, T047)
- This master task list is intentionally dependency-ordered and executable as a single backlog for the full game implementation