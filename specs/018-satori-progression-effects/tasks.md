# Tasks: Satori Progression & Architectural Effects

**Input**: Design documents from `/specs/018-satori-progression-effects/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Validation tasks are required for this feature. Deterministic progression logic, era-driven spirit-tier behavior, and unique monument guard behavior must include GUT coverage; scene/UI confirmation behavior requires manual in-editor validation notes.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: User story label (US1, US2, US3, US4)
- All task descriptions include exact repository file paths

## Path Conventions

- Godot source: `src/`
- Pattern/resources: `src/biomes/patterns/` and related catalog scripts
- Automated tests: `tests/unit/`
- Feature docs: `specs/018-satori-progression-effects/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared docs and test harness entry points for progression implementation.

- [ ] T001 Add progression verification checklist headings and execution placeholders in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`
- [ ] T002 Add Satori progression test section scaffold in `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T003 [P] Add unique-monument matcher test section scaffold in `/home/runner/work/Satori/Satori/tests/unit/patterns/test_pattern_loader.gd`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement foundational progression/state contracts required by all user stories.

**⚠️ CRITICAL**: No user story tasks should start until this phase is complete.

- [ ] T004 Extend progression constants/enums for eras and thresholds in `/home/runner/work/Satori/Satori/src/satori/SatoriIds.gd`
- [ ] T005 Add structure metadata fields (`tier`, `cap_increase`, `is_unique`, effect descriptors) in `/home/runner/work/Satori/Satori/src/biomes/pattern_definition.gd`
- [ ] T006 Implement reusable era-derivation helpers and spirit-tier predicates in `/home/runner/work/Satori/Satori/src/satori/SatoriConditionEvaluator.gd`
- [ ] T007 [P] Add baseline data coverage for new structure metadata parsing in `/home/runner/work/Satori/Satori/tests/unit/patterns/test_pattern_loader.gd`
- [ ] T008 Wire baseline progression state fields and signals in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`

**Checkpoint**: Shared progression primitives and metadata contracts are in place.

---

## Phase 3: User Story 1 - Balance Spirit Housing to Maintain Positive Growth (Priority: P1) 🎯 MVP

**Goal**: Implement deterministic per-minute Satori generation/penalty with floor and cap clamps.

**Independent Test**: GUT verifies formula/clamp behavior across edge cases; manual in-editor check confirms visible meter updates.

### Tests for User Story 1

- [ ] T009 [P] [US1] Add minute-tick delta formula and clamp cases to `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T010 [US1] Add housed/unhoused aggregation test coverage in `/home/runner/work/Satori/Satori/tests/unit/spirits/test_spirit_service.gd`

### Implementation for User Story 1

- [ ] T011 [US1] Implement 60-second tick processing and base delta computation in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T012 [US1] Expose housed/unhoused snapshot query methods for tick input in `/home/runner/work/Satori/Satori/src/spirits/spirit_service.gd`
- [ ] T013 [US1] Apply clamp-to-range update path for Satori value updates in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T014 [US1] Ensure Tier 1 dwellings are buildable and can assign spirits to housing slots in `/home/runner/work/Satori/Satori/src/grid/PlacementController.gd` and `/home/runner/work/Satori/Satori/src/spirits/spirit_service.gd`
- [ ] T015 [US1] Record manual tick/clamp and dwelling-build verification outcomes in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`

**Checkpoint**: Satori generation loop is functional and independently testable.

---

## Phase 4: User Story 2 - Expand Capacity Through Structures (Priority: P1)

**Goal**: Increase Satori cap via structure tiers (+50/+250/+1000) and maintain consistent cap behavior.

**Independent Test**: GUT validates cap increments per tier and cumulative stacking behavior.

### Tests for User Story 2

- [ ] T016 [P] [US2] Add tier cap-contribution tests in `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T017 [US2] Add structure metadata-to-cap mapping tests in `/home/runner/work/Satori/Satori/tests/unit/patterns/test_pattern_loader.gd`

### Implementation for User Story 2

- [ ] T018 [P] [US2] Add/update Tier 1 structure resources with cap metadata in `/home/runner/work/Satori/Satori/src/biomes/patterns/tier1/`
- [ ] T019 [P] [US2] Add/update Tier 2 structure resources with cap metadata in `/home/runner/work/Satori/Satori/src/biomes/patterns/tier2/`
- [ ] T020 [P] [US2] Add/update Tier 3 monument resources with cap metadata in `/home/runner/work/Satori/Satori/src/biomes/patterns/tier3/`
- [ ] T021 [US2] Implement cap recomputation from active structures in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T022 [US2] Integrate structure cap metadata exposure in `/home/runner/work/Satori/Satori/src/biomes/discovery_catalog_data.gd`
- [ ] T023 [US2] Record manual cap-growth verification outcomes in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`

**Checkpoint**: Cap progression through architecture is complete and independently testable.

---

## Phase 5: User Story 3 - Unlock and Lose Era-Based Progression Gates (Priority: P2)

**Goal**: Implement era transitions, `era_changed` signaling, and spirit summon/despawn behavior at thresholds.

**Independent Test**: GUT validates all threshold crossings in both directions with correct spirit-tier eligibility and summon/despawn behavior.

### Tests for User Story 3

- [ ] T024 [P] [US3] Add era boundary transition tests (up/down) in `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T025 [P] [US3] Add spirit-tier availability tests (Tier 2/Tier 3/Tier 4) in `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T026 [US3] Add summon-on-rise and despawn-on-fall era-transition tests in `/home/runner/work/Satori/Satori/tests/unit/spirits/test_spirit_service.gd`

### Implementation for User Story 3

- [ ] T027 [US3] Implement era recomputation and change-only signal emission in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T028 [US3] Update spirit tier assignments (Mist Stag Tier 2, all Kami/deities Tier 3, Sky Whale Tier 4) in `/home/runner/work/Satori/Satori/src/spirits/spirit_catalog_data.gd`
- [ ] T029 [US3] Wire era-transition summon/despawn checks in `/home/runner/work/Satori/Satori/src/spirits/spirit_service.gd`
- [ ] T030 [US3] Add era and Satori amount/cap HUD update plumbing for player-facing feedback in `/home/runner/work/Satori/Satori/src/grid/GardenView.gd` and `/home/runner/work/Satori/Satori/src/ui/`
- [ ] T031 [US3] Record manual era transition, summon/despawn, and HUD verification in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`

**Checkpoint**: Era-based progression gating is complete and independently testable.

---

## Phase 6: User Story 4 - Receive Tier-Specific Structure Effects and Monument Uniqueness Enforcement (Priority: P2)

**Goal**: Apply cataloged structure effects and enforce unique monument pre-confirmation blocking.

**Independent Test**: GUT validates each structure effect and unique-monument rejection; manual flow confirms blocked Bell UI/feedback.

### Tests for User Story 4

- [ ] T032 [P] [US4] Add unique-monument rejection tests in `/home/runner/work/Satori/Satori/tests/unit/spirits/test_shrine_interact_flow.gd`
- [ ] T033 [P] [US4] Add structure-effect behavior tests (Guidance Lantern, Pagoda, Void Mirror, Great Torii) in `/home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd`
- [ ] T034 [US4] Add matcher-level guard tests for `is_unique` blocking in `/home/runner/work/Satori/Satori/tests/unit/patterns/test_pattern_loader.gd`

### Implementation for User Story 4

- [ ] T035 [US4] Enforce unique structure guard in scan/emit confirmation path in `/home/runner/work/Satori/Satori/src/biomes/pattern_matcher.gd`
- [ ] T036 [US4] Enforce pre-confirmation Bell blocking and feedback in `/home/runner/work/Satori/Satori/src/grid/PlacementController.gd`
- [ ] T037 [US4] Implement Tier 2 local effects (storage/swiftness/drop-off/tending/pacification) in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T038 [US4] Implement Tier 3 monument effects (Great Torii burst, Pagoda passive+housing, Void Mirror multiplier) in `/home/runner/work/Satori/Satori/src/autoloads/satori_service.gd`
- [ ] T039 [US4] Add visual blocked-state feedback for unique monument attempts in `/home/runner/work/Satori/Satori/src/grid/GardenView.gd`
- [ ] T040 [US4] Record manual unique-monument and structure-effect verification outcomes in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`

**Checkpoint**: Structure effects and uniqueness enforcement are complete and independently testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finalize docs/contracts, execute regression validation, and collect verification artifacts.

- [ ] T041 [P] Sync implementation notes with contracts in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/contracts/progression-signals-and-thresholds.md` and `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/contracts/unique-monument-confirmation.md`
- [ ] T042 [P] Run targeted progression test suites and log results in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`
- [ ] T043 Run full GUT suite and record final pass/fail evidence in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`
- [ ] T044 Capture and attach UI verification screenshot(s) for progression/unique-block feedback in `/home/runner/work/Satori/Satori/specs/018-satori-progression-effects/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks all story work.
- **Phase 3 (US1)** and **Phase 4 (US2)**: Start after Foundational; both are P1 and can be parallelized by file ownership.
- **Phase 5 (US3)**: Depends on US1 progression loop and foundational era helpers.
- **Phase 6 (US4)**: Depends on US2 structure metadata plus US1/US3 progression state.
- **Phase 7 (Polish)**: Depends on completion of all targeted stories.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational completion.
- **US2 (P1)**: Independent after foundational completion, but informs US4 effect wiring via structure metadata.
- **US3 (P2)**: Depends on US1 Satori value updates.
- **US4 (P2)**: Depends on US2 metadata and US1/US3 progression state.

### Within Each User Story

- Add/extend automated tests before or alongside implementation.
- Add/update data/resource metadata before service-level integration.
- Complete manual verification notes before marking story complete.

### Parallel Opportunities

- Foundational: T007 can run with T004-T006/T008.
- US1: T009 and T010 can run in parallel before/with T011-T013.
- US2: T017/T018/T019 are parallelizable resource updates.
- US3: T023 and T024 can run in parallel.
- US4: T029/T030/T031 parallel tests; T034/T035 can proceed after T032/T033 contract wiring.
- Polish: T038 and T039 parallel; T040 follows targeted passes.

---

## Parallel Example: User Story 1

```text
Task: "Add minute-tick delta tests in /home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd"
Task: "Add housed/unhoused snapshot tests in /home/runner/work/Satori/Satori/tests/unit/spirits/test_spirit_service.gd"
Task: "Implement tick processing in /home/runner/work/Satori/Satori/src/autoloads/satori_service.gd"
```

## Parallel Example: User Story 2

```text
Task: "Update Tier 1 structure resources in /home/runner/work/Satori/Satori/src/biomes/patterns/tier1/"
Task: "Update Tier 2 structure resources in /home/runner/work/Satori/Satori/src/biomes/patterns/tier2/"
Task: "Update Tier 3 structure resources in /home/runner/work/Satori/Satori/src/biomes/patterns/tier3/"
```

## Parallel Example: User Story 4

```text
Task: "Add unique-monument rejection tests in /home/runner/work/Satori/Satori/tests/unit/spirits/test_shrine_interact_flow.gd"
Task: "Add structure effect tests in /home/runner/work/Satori/Satori/tests/unit/test_satori_service.gd"
Task: "Implement unique guard in /home/runner/work/Satori/Satori/src/biomes/pattern_matcher.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Setup + Foundational (Phases 1-2).
2. Deliver US1 minute-loop and clamps (Phase 3).
3. Validate US1 independently with GUT + manual checks.
4. Demo MVP progression pressure loop.

### Incremental Delivery

1. Deliver US1 + US2 (both P1) for core progression and cap growth.
2. Add US3 era gating once baseline progression is stable.
3. Add US4 structure effects and uniqueness enforcement.
4. Finish with Phase 7 regression/polish and documentation evidence.

### Suggested MVP Scope

- **MVP**: US1 only (deterministic Satori loop + clamps), optionally US2 if cap growth is required for immediate playtest progression.

---

## Notes

- All tasks follow required checklist format: checkbox + Task ID + optional [P] + optional [USx] + concrete file path.
- Manual validation evidence is explicitly tracked in `quickstart.md`.
- Final implementation should preserve existing permanent-emergence and save compatibility guarantees.
