# Tasks: Craft Mode Building Placement and Build Mode Retirement

**Input**: Design documents from `/specs/020-craft-mode-buildings/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Validation tasks are REQUIRED for this feature. Deterministic craft resolution, discovery gating, inventory stack semantics, and placement confirm/cancel flows require automated GUT coverage plus manual in-editor validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare implementation scaffolding and validation surfaces for build-mode retirement and inventory-driven building placement.

- [ ] T001 Add feature-specific validation checklist sections for automated and manual runs in specs/020-craft-mode-buildings/quickstart.md
- [ ] T002 Create dedicated GUT test scaffold for building craft/inventory semantics in tests/unit/seeds/test_building_crafting_inventory.gd
- [ ] T003 Create dedicated GUT test scaffold for building placement session behavior in tests/unit/test_building_placement_session.gd

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared runtime primitives required before user story implementation.

**CRITICAL**: No user story work starts before this phase is complete.

- [ ] T004 [P] Add building craft attempt result type and feedback keys in src/seeds/BuildingCraftAttemptResult.gd
- [ ] T005 [P] Add building footprint definition resource/script for one-tile and multi-tile structures in src/grid/BuildingFootprint.gd
- [ ] T006 [P] Add building recipe pattern catalog structure keyed by normalized craft-grid tokens in src/seeds/BuildingRecipeCatalog.gd
- [ ] T007 [P] Add building inventory stack entry value object with type key and count cap metadata in src/seeds/BuildingInventoryEntry.gd
- [ ] T008 Extend SeedPouch shared inventory model to exactly 8 slots and mixed entry-kind support in src/seeds/SeedPouch.gd
- [ ] T009 Extend SeedAlchemyService craft API contracts to branch seed vs building outcomes in src/autoloads/seed_alchemy_service.gd
- [ ] T010 Add building placement session state container and lifecycle helpers in src/grid/BuildingPlacementSession.gd
- [ ] T011 Wire building craft and placement script preloads into relevant runtime consumers in src/ui/SeedAlchemyPanel.gd

**Checkpoint**: Foundation complete; user stories can start.

---

## Phase 3: User Story 1 - Craft Buildings in Craft Mode (Priority: P1) 🎯 MVP

**Goal**: Craft buildings from 3+ slot ingredient patterns in Craft mode, retire Build mode crafting entry points, and enforce discovery/inventory semantics.

**Independent Test**: GUT verifies pattern match, discovery on success only, full-inventory failure with no consumption, exact-type stack behavior with 99 cap and rollover; manual run confirms no separate Build mode entry for crafting.

### Tests for User Story 1

- [ ] T012 [P] [US1] Add GUT cases for valid/invalid building pattern matching and minimum 3-slot requirement in tests/unit/seeds/test_building_crafting_inventory.gd
- [ ] T013 [P] [US1] Add GUT cases for discovery recording only on successful craft output in tests/unit/seeds/test_building_crafting_inventory.gd
- [ ] T014 [P] [US1] Add GUT cases for full-inventory failure preserving ingredients and discovery lock state in tests/unit/seeds/test_building_crafting_inventory.gd
- [ ] T015 [P] [US1] Add GUT cases for exact-type-only stacking, 99-cap enforcement, and free-slot rollover in tests/unit/seeds/test_building_crafting_inventory.gd

### Implementation for User Story 1

- [ ] T016 [P] [US1] Extend craft-grid normalization and building pattern lookup pipeline in src/autoloads/seed_alchemy_service.gd
- [ ] T017 [P] [US1] Implement building recipe catalog entries (including house pattern) in src/seeds/BuildingRecipeCatalog.gd
- [ ] T018 [US1] Emit building-specific craft outcomes and feedback keys from craft attempts in src/autoloads/seed_alchemy_service.gd
- [ ] T019 [US1] Apply discovery-on-success-only logic for building recipes in src/autoloads/seed_alchemy_service.gd
- [ ] T020 [US1] Implement shared-inventory insertion rules for building items (exact-type stack, cap 99, rollover, hard fail) in src/seeds/SeedPouch.gd
- [ ] T021 [US1] Update craft panel feedback/rendering for building craft outcomes and failure messaging in src/ui/SeedAlchemyPanel.gd
- [ ] T022 [US1] Remove Build tab/mode from HUD mode enum, tab labels, and mode switching logic in src/ui/HUDController.gd
- [ ] T023 [US1] Remove Build button node wiring and layout references from HUD scene in scenes/UI/HUD.tscn
- [ ] T024 [US1] Record manual validation evidence for craft-mode building creation and Build mode retirement in specs/020-craft-mode-buildings/quickstart.md

**Checkpoint**: User Story 1 is independently functional and testable.

---

## Phase 4: User Story 2 - Place Buildings from Inventory (Priority: P2)

**Goal**: Select crafted building items from inventory and place one-tile or multi-tile structures on valid tiles.

**Independent Test**: GUT verifies footprint validity checks and blocked placement states; manual run confirms preview behavior for one-tile and multi-tile buildings.

### Tests for User Story 2

- [ ] T025 [P] [US2] Add GUT cases for one-tile building placement validity and occupancy blocking in tests/unit/test_building_placement_session.gd
- [ ] T026 [P] [US2] Add GUT cases for multi-tile footprint validation (blocked, out-of-bounds, valid) in tests/unit/test_building_placement_session.gd
- [ ] T027 [P] [US2] Add GUT regression for immediate non-building tile placement remaining unchanged in tests/unit/test_build_mode_regressions.gd

### Implementation for User Story 2

- [ ] T028 [P] [US2] Add inventory selection hooks for building entries in top-bar inventory display logic in src/ui/SeedPouchDisplay.gd
- [ ] T029 [P] [US2] Implement building placement preview state updates and validity evaluation in src/grid/PlacementController.gd
- [ ] T030 [US2] Implement footprint projection and tile eligibility checks using building footprint data in src/grid/PlacementController.gd
- [ ] T031 [US2] Render building placement preview highlights for valid and invalid footprint tiles in src/grid/GardenView.gd
- [ ] T032 [US2] Wire inventory-selected building type into placement session start and stop transitions in src/ui/HUDController.gd
- [ ] T033 [US2] Record manual validation evidence for one-tile and multi-tile preview behavior in specs/020-craft-mode-buildings/quickstart.md

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Confirm or Cancel Building Placement (Priority: P3)

**Goal**: Require explicit confirm/cancel for building placement while keeping normal non-building tile placement immediate.

**Independent Test**: GUT verifies confirm consumes one building item and places structure, cancel keeps world/inventory unchanged, and non-building tile placement remains no-confirm.

### Tests for User Story 3

- [ ] T034 [P] [US3] Add GUT cases for confirm transition consuming exactly one building item and committing placement in tests/unit/test_building_placement_session.gd
- [ ] T035 [P] [US3] Add GUT cases for cancel transition preserving inventory and world state in tests/unit/test_building_placement_session.gd
- [ ] T036 [P] [US3] Add GUT regression ensuring building confirm flow does not gate normal tile placement with confirm in tests/unit/test_build_mode_regressions.gd

### Implementation for User Story 3

- [ ] T037 [P] [US3] Add explicit confirm and cancel input handlers for active building placement sessions in src/grid/PlacementController.gd
- [ ] T038 [P] [US3] Add confirm/cancel prompts and state feedback in HUD layer for active building placement in src/ui/HUDController.gd
- [ ] T039 [US3] Implement confirm commit path to consume one matching building stack entry and write final structure tiles in src/grid/PlacementController.gd
- [ ] T040 [US3] Implement cancel path to clear session state with no inventory or world mutation in src/grid/PlacementController.gd
- [ ] T041 [US3] Preserve immediate non-building tile placement path without confirm requirement in src/grid/PlacementController.gd
- [ ] T042 [US3] Record manual validation evidence for confirm/cancel placement and immediate normal tile placement in specs/020-craft-mode-buildings/quickstart.md

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening across all stories, docs, and regressions.

- [ ] T043 [P] Update feature documentation notes and implementation traceability in specs/020-craft-mode-buildings/plan.md
- [ ] T044 [P] Update quickstart automated command outcomes and manual pass/fail logs in specs/020-craft-mode-buildings/quickstart.md
- [ ] T045 [P] Update unlock reference tables if recipe/discovery IDs changed in specs/master/recipes.md
- [ ] T046 Add or adjust recipes catalog sync assertions for any unlock table changes in tests/unit/test_recipes_catalog.gd
- [ ] T047 Run focused building craft/placement GUT suites and record outcomes in specs/020-craft-mode-buildings/quickstart.md
- [ ] T048 Run headless parse and targeted gameplay regression checks and record outcomes in specs/020-craft-mode-buildings/checklists/requirements.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2 and uses crafted building inventory model from US1 artifacts.
- **Phase 5 (US3)**: Depends on Phase 4 placement session flows.
- **Phase 6 (Polish)**: Depends on completion of selected user stories.

### User Story Dependencies

- **US1 (P1)**: First deliverable and MVP.
- **US2 (P2)**: Requires foundational systems; can be validated independently with seeded building inventory fixtures.
- **US3 (P3)**: Builds on US2 session pipeline and hardens interaction guarantees.

### Within Each User Story

- Add GUT tests before or alongside implementation for deterministic behavior.
- Implement core runtime logic before UI polish.
- Complete manual validation tasks before closing story.

## Dependency Graph

`Setup -> Foundational -> US1 -> US2 -> US3 -> Polish`

---

## Parallel Execution Examples

### User Story 1

```text
T012 tests/unit/seeds/test_building_crafting_inventory.gd
T016 src/autoloads/seed_alchemy_service.gd
T017 src/seeds/BuildingRecipeCatalog.gd
```

### User Story 2

```text
T025 tests/unit/test_building_placement_session.gd
T028 src/ui/SeedPouchDisplay.gd
T029 src/grid/PlacementController.gd
```

### User Story 3

```text
T034 tests/unit/test_building_placement_session.gd
T037 src/grid/PlacementController.gd
T038 src/ui/HUDController.gd
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete US1 tasks through T024.
3. Validate US1 independently via targeted GUT and manual checks.
4. Demo/review before proceeding.

### Incremental Delivery

1. Deliver US1 (craft + inventory + build mode retirement).
2. Deliver US2 (inventory-driven placement with footprint validation).
3. Deliver US3 (confirm/cancel flow and no-confirm normal tile placement guarantee).
4. Finish cross-cutting polish and documentation sync.

### Parallel Team Strategy

1. Team completes Setup and Foundational together.
2. Split by streams after foundation:
   - Stream A: Craft/inventory semantics.
   - Stream B: Placement preview/footprint rendering.
   - Stream C: Regression tests and docs updates.
3. Merge when story-level independent tests pass.

---

## Notes

- [P] tasks are file-separated and safe for parallel execution.
- Story labels map tasks directly to user stories for traceability.
- Every task includes an explicit file path.
- Building placement requires confirm/cancel; non-building tile placement stays immediate.
