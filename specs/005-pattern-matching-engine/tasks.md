# Tasks: Pattern Matching Engine

**Input**: Design documents from `/specs/005-pattern-matching-engine/`
**Prerequisites**: spec.md (available), plan.md (missing at generation time), research.md (not available), data-model.md (not available), contracts/ (not available)

**Tests**: Include unit and integration/performance tests because the feature spec defines measurable test outcomes and explicit independent test criteria.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare pattern content directory, test scaffolding, and autoload wiring points.

- [X] T001 Create pattern resource directory and placeholder README in src/biomes/patterns/README.md
- [X] T002 Create pattern-matching test fixture directory in tests/unit/patterns/.gdkeep
- [X] T003 [P] Add pattern engine autoload slot in project.godot
- [X] T004 [P] Create baseline pattern content file for manual smoke checks in src/biomes/patterns/deep_stand_cluster.tres

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build shared infrastructure required by all story implementations.

**CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 Define PatternDefinition resource class with exported fields for all pattern types in src/biomes/pattern_definition.gd
- [X] T006 Define discovery signal payload helper and coordinate serialization helpers in src/biomes/discovery_signal.gd
- [X] T007 Implement pattern loader service for scanning and validating `.tres` resources in src/biomes/pattern_loader.gd
- [X] T008 [P] Implement shared spatial query helpers (contiguous search, radius lookup, relative offset sampling) in src/grid/spatial_query.gd
- [X] T009 Implement discovery journal/registry adapter for duplicate suppression checks in src/biomes/discovery_registry.gd
- [X] T010 Implement asynchronous scan queue coordinator (single worker, queued placements, deterministic flush) in src/biomes/pattern_scan_scheduler.gd
- [X] T011 Wire tile-placement event hook to scheduler enqueue path in src/biomes/pattern_scan_scheduler.gd
- [X] T012 Add warning/error logging utility for invalid pattern data handling in src/autoloads/runtime_logger.gd

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Background Pattern Scan After Every Tile Placement (Priority: P1) 🎯 MVP

**Goal**: Run non-blocking scans after each placement and emit immediate discovery signals within frame budget.

**Independent Test**: Seed a 1,000-tile garden with a near-complete cluster; place the final tile and verify same-cycle signal emission and sub-16ms scan cost.

### Tests for User Story 1

- [X] T013 [P] [US1] Add unit tests for asynchronous enqueue and same-cycle completion behavior in tests/unit/patterns/test_scan_scheduler.gd
- [X] T014 [P] [US1] Add integration test for 1,000-tile full scan budget and dual-trigger pass in tests/unit/test_pattern_scan_performance.gd

### Implementation for User Story 1

- [X] T015 [US1] Implement PatternMatcher entrypoint and `discovery_triggered` signal contract in src/biomes/pattern_matcher.gd
- [X] T016 [US1] Integrate scheduler with PatternMatcher to trigger scan after every tile placement in src/biomes/pattern_scan_scheduler.gd
- [X] T017 [US1] Implement multi-match aggregation per scan pass with deterministic ordering by discovery ID in src/biomes/pattern_matcher.gd
- [X] T018 [US1] Add frame-time instrumentation around scan execution and expose metrics hooks in src/biomes/pattern_scan_scheduler.gd

**Checkpoint**: User Story 1 must run scans without render-loop blocking and emit all matches from a single pass.

---

## Phase 4: User Story 2 - No Duplicate Discovery Signals (Priority: P1)

**Goal**: Ensure each discovery ID is emitted exactly once across all future scans.

**Independent Test**: Trigger a known discovery, then extend the same region and confirm no repeated signal for that discovery ID.

### Tests for User Story 2

- [X] T019 [P] [US2] Add unit tests for duplicate suppression against persisted discovery IDs in tests/unit/patterns/test_discovery_registry.gd
- [X] T020 [P] [US2] Add integration test for same-pass distinct discovery IDs without mutual suppression in tests/unit/test_pattern_duplicate_suppression.gd

### Implementation for User Story 2

- [X] T021 [US2] Implement pre-emit duplicate guard using discovery registry lookup in src/biomes/pattern_matcher.gd
- [X] T022 [US2] Persist newly emitted discovery IDs atomically after each completed scan pass in src/biomes/discovery_registry.gd
- [X] T023 [US2] Ensure queued back-to-back scans read a stable post-placement discovery state in src/biomes/pattern_scan_scheduler.gd

**Checkpoint**: Re-evaluation cannot emit previously logged discovery IDs, while distinct IDs still emit once each.

---

## Phase 5: User Story 3 - Data-Driven Pattern Definitions (Priority: P1)

**Goal**: Add discoveries through resource files only, with robust validation and skip-on-error behavior.

**Independent Test**: Add a new `.tres` pattern file without code changes; verify loading, triggering, and invalid resource skip warnings.

### Tests for User Story 3

- [X] T024 [P] [US3] Add loader tests for valid resource ingestion and malformed resource rejection in tests/unit/patterns/test_pattern_loader.gd
- [X] T025 [P] [US3] Add integration test for hot-added pattern resource detection at startup in tests/unit/test_data_driven_pattern_addition.gd

### Implementation for User Story 3

- [X] T026 [US3] Implement directory scan and resource parse pipeline for PatternDefinition files in src/biomes/pattern_loader.gd
- [X] T027 [US3] Add schema-level validation and warning logs for malformed pattern definitions in src/biomes/pattern_loader.gd
- [X] T028 [US3] Register loaded pattern definitions with matcher initialization path in src/biomes/pattern_matcher.gd
- [X] T029 [US3] Add sample data-driven shape pattern resource for validation in src/biomes/patterns/sample_shape_pattern.tres

**Checkpoint**: New valid pattern resources are discovered automatically and invalid ones are skipped safely.

---

## Phase 6: User Story 4 - All Four Pattern Types Evaluate Correctly (Priority: P3)

**Goal**: Support cluster, shape, ratio/proximity, and compound evaluations with prerequisite chain handling.

**Independent Test**: Create one pattern per type plus compound prerequisite chain and confirm each emits once at the correct time.

### Tests for User Story 4

- [X] T030 [P] [US4] Add cluster and shape matcher correctness tests in tests/unit/patterns/test_cluster_shape_matchers.gd
- [X] T031 [P] [US4] Add ratio/proximity matcher correctness tests in tests/unit/patterns/test_ratio_proximity_matcher.gd
- [X] T032 [P] [US4] Add compound prerequisite-chain resolution tests for same-pass ordering in tests/unit/patterns/test_compound_matcher.gd

### Implementation for User Story 4

- [X] T033 [US4] Implement cluster matcher (contiguity, threshold, optional purity constraints) in src/biomes/matchers/cluster_matcher.gd
- [X] T034 [P] [US4] Implement shape matcher using relative offset recipes in src/biomes/matchers/shape_matcher.gd
- [X] T035 [P] [US4] Implement ratio/proximity matcher with center and neighbor-count requirements in src/biomes/matchers/ratio_proximity_matcher.gd
- [X] T036 [US4] Implement compound matcher with prerequisite discovery checks and same-pass chain resolution in src/biomes/matchers/compound_matcher.gd
- [X] T037 [US4] Integrate all matcher types into dispatcher strategy by `pattern_type` in src/biomes/pattern_matcher.gd

**Checkpoint**: All four pattern types evaluate correctly with deterministic emission behavior.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening, profiling verification, and documentation updates.

- [X] T038 [P] Add end-to-end dual-trigger deterministic ordering regression test in tests/unit/test_pattern_dual_trigger_ordering.gd
- [X] T039 Profile and tune scan path to keep 1,000-tile scans under 16ms on target device profile in src/biomes/pattern_scan_scheduler.gd
- [X] T040 [P] Document pattern authoring guide and validation rules in specs/005-pattern-matching-engine/quickstart.md
- [ ] T041 Run headless GUT suite for pattern engine coverage and capture baseline results in check-errors.ps1

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies; start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks all user story phases.
- **Phase 3-6 (User Stories)**: Depend on Phase 2 completion.
- **Phase 7 (Polish)**: Depends on completion of all target user stories.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; no dependency on other user stories.
- **US2 (P1)**: Depends on US1 signal path existence plus Foundational registry.
- **US3 (P1)**: Depends on Foundational loader/matcher interfaces; independent from US2.
- **US4 (P3)**: Depends on US1 matcher orchestration and US3 data-driven loading.

### Story Completion Order

- **Recommended**: US1 -> US2 and US3 in parallel -> US4
- **MVP Scope**: US1 only

### Within Each User Story

- Tests before implementation where applicable.
- Core matcher/resource model before scheduler integration updates.
- Deterministic ordering and duplicate suppression checks before completion.

---

## Parallel Opportunities

- **Setup**: T003 and T004 can run in parallel after T001.
- **Foundational**: T008 can run in parallel with T005-T007; T012 can run in parallel once logger integration points are identified.
- **US1**: T013 and T014 in parallel; T017 and T018 can proceed after T015.
- **US2**: T019 and T020 in parallel; T022 and T023 can proceed after T021 starts.
- **US3**: T024 and T025 in parallel; T027 and T029 can proceed after T026.
- **US4**: T030, T031, and T032 in parallel; T034 and T035 in parallel after T033 contract is defined.
- **Polish**: T038 and T040 in parallel; T039 can run while docs/tests finalize.

---

## Parallel Example: User Story 1

```bash
# Parallel test authoring
Task: "T013 [US1] Asynchronous enqueue/same-cycle tests"
Task: "T014 [US1] 1,000-tile performance and dual-trigger test"

# Parallel implementation after matcher contract exists
Task: "T017 [US1] Deterministic multi-match aggregation"
Task: "T018 [US1] Frame-time instrumentation"
```

## Parallel Example: User Story 2

```bash
Task: "T019 [US2] Duplicate suppression unit tests"
Task: "T020 [US2] Distinct-ID same-pass integration test"
```

## Parallel Example: User Story 3

```bash
Task: "T024 [US3] Loader validation tests"
Task: "T025 [US3] Data-driven addition integration test"
```

## Parallel Example: User Story 4

```bash
Task: "T030 [US4] Cluster/shape matcher tests"
Task: "T031 [US4] Ratio/proximity matcher tests"
Task: "T032 [US4] Compound chain tests"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup).
2. Complete Phase 2 (Foundational).
3. Complete Phase 3 (US1).
4. Validate independent test criteria for US1 before expanding scope.

### Incremental Delivery

1. Build and validate US1 scan pipeline (MVP).
2. Add US2 one-time emission guarantees.
3. Add US3 data-driven authoring path.
4. Add US4 full pattern type coverage.
5. Execute Polish tasks and performance verification.

### Multi-Developer Parallel Strategy

1. Team completes Setup and Foundational tasks together.
2. Developer A: US2.
3. Developer B: US3.
4. Developer C: US4 scaffolding/tests in parallel after US1 interfaces stabilize.

---

## Notes

- Tasks follow strict checklist format: checkbox, Task ID, optional [P], required [US#] in story phases, actionable description with file path.
- If `plan.md` is later added, re-run `/speckit.tasks` to refine task granularity against finalized architecture.
