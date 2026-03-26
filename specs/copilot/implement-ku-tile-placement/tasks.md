# Tasks: Ku Tile Placement (Abyss Biome + Island System)

**Input**: Design documents from `/specs/copilot/implement-ku-tile-placement/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: GUT automated tests are required for the island-labelling algorithm (FR-004/005/006) and the per-island spirit summoning guard (FR-007/008/009). Manual validation is required for Ku tile placement visual and spirit re-spawn behaviour (scene interaction).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Extend BiomeType and confirm render colour — shared by all three user stories.

- [ ] T001 Add `KU = 14` to `BiomeType.Value` enum in `src/biomes/BiomeType.gd` with comment `# Ku (standalone abyss — void separator)`
- [ ] T002 [P] Add KU to the biome-colour lookup in `src/grid/GardenView.gd` (`_get_biome_color` or equivalent) with near-black colour `Color(0.05, 0.02, 0.1)`
- [ ] T003 [P] Update metadata comment in `src/grid/TileData.gd` to document the `"island_id"` key alongside existing `"discovery_ids"` and `"spirit_id"` entries

**Checkpoint**: BiomeType.KU is defined; GardenView can render it; TileData documents island_id.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Island-labelling infrastructure that US2 and US3 both depend on.

**⚠️ CRITICAL**: US2 and US3 cannot be implemented until this phase is complete.

- [ ] T004 Add `_island_map: Dictionary` private field to `GridMap` in `src/grid/GridMap.gd` (Vector2i → String)
- [ ] T005 Implement `compute_island_ids()` on `GridMap` in `src/grid/GridMap.gd`: BFS flood-fill over all non-KU tiles; writes `tile.metadata["island_id"]` for each tile; island ID = `"{q},{r}"` of lexicographically smallest coord in component; KU tiles get `tile.metadata["island_id"] = ""`
- [ ] T006 Implement `get_island_id(coord: Vector2i) -> String` on `GridMap` in `src/grid/GridMap.gd`: returns `_island_map.get(coord, "")` (thin wrapper for external callers)
- [ ] T007 Call `compute_island_ids()` at the end of `GridMap.place_tile()` in `src/grid/GridMap.gd` so island map is always current before `tile_placed` signal fires

**Checkpoint**: GridMap computes and stores island IDs after every tile placement. No spirit or UI changes yet.

---

## Phase 3: User Story 1 — Place a Ku (Abyss) Tile (Priority: P1) 🎯 MVP

**Goal**: Player can select and place a KU biome tile from the tile selector; it appears on the grid as a dark void hex.

**Independent Test**: Place a KU tile adjacent to the origin; verify `GameState.grid.get_tile(coord).biome == BiomeType.Value.KU`. Manual: Ku hex renders as near-black in Garden.

### Tests for User Story 1

- [ ] T008 [P] [US1] Add GUT test `test_island_labelling.gd` skeleton in `tests/unit/test_island_labelling.gd` with helper `_make_grid()` factory; add test `test_ku_tile_has_no_island_id` that places a KU tile and asserts `metadata["island_id"] == ""`

### Implementation for User Story 1

- [ ] T009 [US1] Verify TileSelector UI in `src/ui/TileSelector.gd` (and `scenes/UI/TileSelector.tscn` if needed) exposes `BiomeType.Value.KU` when Ku element is unlocked — confirm existing biome-iteration loop includes new enum value 14 or add explicit entry
- [ ] T010 [US1] Confirm PlacementController in `src/grid/PlacementController.gd` passes `selected_biome` through to `GameState.try_place_tile()` without biome-filtering that would block KU (no change expected; document confirmation in task notes)
- [ ] T011 [US1] Ensure `GridMap.is_placement_valid()` in `src/grid/GridMap.gd` allows KU tiles to be placed with the same adjacency rule as all other biomes (no special-casing needed; confirm and document)

**Checkpoint**: Ku tile can be placed via normal plant-mode interaction and renders correctly.

---

## Phase 4: User Story 2 — Islands Are Identified and Isolated (Priority: P2)

**Goal**: Placing a Ku tile between two connected non-Ku groups assigns them distinct island IDs; all tiles in the same connected component share one island ID.

**Independent Test**: GUT test `test_island_labelling.gd` — build a grid with a Ku strip between two Stone groups; assert both groups have different non-empty island IDs.

### Tests for User Story 2

- [ ] T012 [P] [US2] Extend `tests/unit/test_island_labelling.gd` with:
  - `test_single_island_all_same_id`: place 3 connected Stone tiles; assert all share the same `island_id`
  - `test_ku_splits_two_groups`: build `S K S` linear layout; assert left and right have distinct island IDs
  - `test_connected_around_ku_is_one_island`: build a U-shape around a Ku tile; assert all non-Ku tiles share one island ID
  - `test_island_id_is_canonical_coord`: build a small cluster; assert `island_id` equals `"{min_q},{min_r}"` of the component

### Implementation for User Story 2

- [ ] T013 [US2] Review `compute_island_ids()` implementation from T005 against test cases from T012; fix any BFS ordering or ID-derivation bugs revealed by running GUT tests
- [ ] T014 [US2] Add manual validation entry to `specs/copilot/implement-ku-tile-placement/quickstart.md` Step 2 confirming island IDs are distinct (print via GUT or editor debug script)

**Checkpoint**: Island IDs are correctly assigned and stable. T012 GUT tests all pass.

---

## Phase 5: User Story 3 — Spirits Respawn Per Island (Priority: P3)

**Goal**: A spirit previously summoned on Island A can spawn again on Island B (separated by Ku tiles). Same-island deduplication is preserved.

**Independent Test**: GUT test `test_spirit_island_scope.gd` — simulate discovery trigger on island "0,0", then simulate same discovery on island "1,0"; assert spirit spawned twice under different keys and `is_summoned_on_island()` returns correct results.

### Tests for User Story 3

- [ ] T015 [P] [US3] Create `tests/unit/test_spirit_island_scope.gd` with GUT tests:
  - `test_record_and_check_island_keyed`: create two SpiritInstances with same spirit_id but different island_ids; call `record_instance()` for both; assert both keys exist in `_summoned_ids`
  - `test_is_summoned_on_island_true_and_false`: after recording spirit on island "0,0"; assert `is_summoned_on_island("spirit_x","0,0") == true` and `is_summoned_on_island("spirit_x","1,0") == false`
  - `test_spirit_instance_serialise_island_id`: create instance with island_id="2,3"; serialise then deserialise; assert island_id round-trips correctly

### Implementation for User Story 3

- [ ] T016 [US3] Add `island_id: String = ""` field to `SpiritInstance` in `src/spirits/spirit_instance.gd`; update `serialize()` to include `"island_id"` key; update `deserialize()` to read `"island_id"` with `""` default
- [ ] T017 [US3] Add `is_summoned_on_island(spirit_id: String, island_id: String) -> bool` and `_island_spirit_key(instance: SpiritInstance) -> String` methods to `SpiritPersistence` in `src/autoloads/spirit_persistence.gd`; update `record_instance()` to use compound key when `instance.island_id` is non-empty; keep bare `spirit_id` key fallback for empty island_id
- [ ] T018 [US3] Add `_spirit_key(spirit_id: String, island_id: String) -> String` and `_island_for_coords(coords: Array[Vector2i]) -> String` helpers to `SpiritService` in `src/spirits/spirit_service.gd`
- [ ] T019 [US3] Update `SpiritService._on_discovery_triggered()` in `src/spirits/spirit_service.gd`: resolve island_id from triggering_coords via `_island_for_coords()`; build compound key; guard on compound key in `_active_instances`; pass island_id into `_summon_spirit()`
- [ ] T020 [US3] Update `SpiritService._summon_spirit()` signature to accept `island_id: String = ""`; set `instance.island_id = island_id`; store in `_active_instances` under compound key from `_spirit_key()`
- [ ] T021 [US3] Update `SpiritService.restore_from_persistence()` in `src/spirits/spirit_service.gd` to restore `_active_instances` using the same compound key (read `instance.island_id` from deserialised data)
- [ ] T022 [US3] Run GUT tests from T015; fix any issues in T016–T021

**Checkpoint**: Per-island spirit spawning works. T015 GUT tests all pass. Existing spirit tests remain green.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression validation, documentation completion, and code hygiene.

- [ ] T023 [P] Run full GUT test suite headless (`godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit`) and confirm all existing tests still pass
- [ ] T024 [P] Perform manual validation per `specs/copilot/implement-ku-tile-placement/quickstart.md` Steps 1–4 in Garden.tscn
- [ ] T025 Update `specs/copilot/implement-ku-tile-placement/quickstart.md` with any findings or corrections from T024
- [ ] T026 [P] Add KU to any GardenView biome-colour or bitmask lookup tables in `src/grid/GardenView.gd` that enumerate all valid biome IDs, ensuring no `assert` or range-check errors fire when KU tiles are rendered

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T001 (BiomeType.KU defined) — BLOCKS US2 and US3
- **US1 (Phase 3)**: Depends only on T001; can start alongside Phase 2
- **US2 (Phase 4)**: Depends on Phase 2 (island BFS) being complete
- **US3 (Phase 5)**: Depends on Phase 2 (island IDs) and Phase 4 (island correctness validated)
- **Polish (Phase 6)**: Depends on Phases 3, 4, 5

### User Story Dependencies

- **US1 (P1)**: Requires T001 only — independently deliverable
- **US2 (P2)**: Requires T004–T007 (Foundational) — independently testable via GUT
- **US3 (P3)**: Requires T004–T007 (Foundational) + US2 verified correct — independently testable via GUT

### Within Each User Story

- GUT tests are written first (TDD) then implementation fixes pass them
- `src/` data changes before scene/UI wiring
- Story complete before moving to next priority

### Parallel Opportunities

- T002 and T003 (Phase 1) can run in parallel with T004 (Phase 2)
- T008 (US1 test skeleton) can run in parallel with T004–T007 (Foundational)
- T012 (US2 tests) can run in parallel with T009–T011 (US1 implementation)
- T015 (US3 tests) can run in parallel with T013–T014 (US2 implementation)
- T023, T024, T026 (Polish) can run in parallel

---

## Parallel Example: Phase 2 + Phase 3 Overlap

```text
Phase 2 running: T004, T005, T006, T007 (GridMap island BFS)
Phase 3 running concurrently: T008 (write GUT test skeleton), T009 (audit TileSelector)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: T001–T003
2. Complete Phase 2: T004–T007
3. Complete Phase 3: T008–T011
4. **STOP and VALIDATE**: KU tile places and renders correctly
5. Demo: Abyss biome visible in garden

### Incremental Delivery

1. Setup + Foundational → BFS island map in place
2. Add US1 → KU tile placeable, renders dark void
3. Add US2 → Islands labelled, GUT green
4. Add US3 → Spirits re-spawn per island, GUT green
5. Each phase adds value without breaking previous phases

---

## Notes

- [P] tasks = different files, no shared state, can run in parallel
- [Story] label maps task to spec.md user story for traceability
- `BiomeType.Value.KU = 14` must exist before any other task compiles
- GDScript `Dictionary.get()` returns `Variant`; always cast with `str()` or `int()` to avoid Variant-inferred `:=` warnings-as-errors
- Autoload name for `spirit_persistence.gd` is `SpiritPersistence` — do NOT use `class_name SpiritPersistence` in that file
- Commit after each phase checkpoint
