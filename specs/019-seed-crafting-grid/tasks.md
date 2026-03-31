# Tasks: Phase 1 Seed Crafting in 3x3 Grid

**Input**: Design documents from `/specs/019-seed-crafting-grid/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Validation tasks are REQUIRED for this feature. Deterministic crafting, consume-on-success ordering, inventory-full blocking, and regression-prone UI/interaction logic must include automated GUT coverage plus explicit manual validation tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare focused test and validation scaffolding for the seed-grid migration.

<!-- sequential -->
- [ ] T001 Create focused Phase 1 craft-attempt test suite scaffold in tests/unit/seeds/test_seed_crafting_grid.gd
<!-- sequential -->
- [ ] T002 Add Phase 1 validation checklist section for automated/manual execution logging in specs/019-seed-crafting-grid/quickstart.md
<!-- sequential -->
- [ ] T003 Add implementation-traceability checklist entries for clarified mandatory behaviors in specs/019-seed-crafting-grid/checklists/requirements.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core craft-attempt primitives and deterministic resolver/attempt flow that all user stories depend on.

**CRITICAL**: No user story implementation starts before this phase is complete.

<!-- parallel-group: 1 -->
- [ ] T004 [P] Add craft-attempt outcome value object with typed outcome/reason fields in src/seeds/SeedCraftAttemptResult.gd
- [ ] T005 [P] Add 3x3 grid normalization helper for one/two-token canonical keys in src/seeds/SeedCraftGridNormalizer.gd
- [ ] T006 [P] Add Phase 1 seed-recipe catalog helper constrained to FR-005/FR-006 mappings in src/seeds/SeedRecipeCatalogPhase1.gd
<!-- sequential -->
- [ ] T007 Update recipe lookup rules for seed-only Phase 1 matching (one or two tokens only) in src/seeds/SeedRecipeRegistry.gd
<!-- sequential -->
- [ ] T008 Implement deterministic craft-attempt pipeline (resolve -> unlock gate -> inventory capacity -> insert -> consume) in src/autoloads/seed_alchemy_service.gd
<!-- sequential -->
- [ ] T009 Add craft-attempt feedback signal payload carrying outcome key and consumed slot indices in src/autoloads/seed_alchemy_service.gd

**Checkpoint**: Foundation ready; user stories can now be implemented.

---

## Phase 3: User Story 1 - Craft Single-Element Seeds from a 3x3 Grid (Priority: P1) 🎯 MVP

**Goal**: Deliver 3x3 slot-based single-token crafting that outputs exactly one seed to plant inventory and clears only consumed slots.

**Independent Test**: Player places each single token in any slot, confirms craft, sees exactly one expected seed in pouch, and only consumed slot(s) clear.

### Tests for User Story 1

<!-- sequential -->
- [ ] T010 [US1] Add GUT coverage for all FR-005 single-token mappings and single-output pouch insertion in tests/unit/seeds/test_seed_crafting_grid.gd

### Implementation for User Story 1

<!-- parallel-group: 2 -->
- [ ] T011 [P] [US1] Refactor panel input state from element list to 9-slot occupancy model in src/ui/SeedAlchemyPanel.gd
- [ ] T012 [P] [US1] Replace current craft input controls with a 3x3 slot grid and minimum 48x48 slot targets in scenes/UI/SeedAlchemyPanel.tscn
<!-- sequential -->
- [ ] T013 [US1] Wire slot interactions and confirm action to submit full 9-slot craft input in src/ui/SeedAlchemyPanel.gd
<!-- sequential -->
- [ ] T014 [US1] Apply successful-craft slot clearing using consumed slot indices only in src/ui/SeedAlchemyPanel.gd
<!-- sequential -->
- [ ] T015 [US1] Ensure successful craft inserts exactly one seed into pouch before any token consumption in src/autoloads/seed_alchemy_service.gd
<!-- sequential -->
- [ ] T016 [US1] Record manual single-token flow validation steps and first-attempt timing evidence in specs/019-seed-crafting-grid/quickstart.md

**Checkpoint**: User Story 1 is functional and independently testable.

---

## Phase 4: User Story 2 - Craft Dual-Element Seeds with Position-Insensitive Matching (Priority: P1)

**Goal**: Deliver position-insensitive two-token recipe resolution across the 3x3 grid for all Phase 1 dual seed mappings.

**Independent Test**: For every FR-006 dual recipe, at least 3 slot arrangements produce the same output seed.

### Tests for User Story 2

<!-- sequential -->
- [ ] T017 [US2] Add permutation-based GUT coverage (>=3 arrangements per dual recipe) for FR-006 mappings in tests/unit/seeds/test_seed_crafting_grid.gd

### Implementation for User Story 2

<!-- parallel-group: 3 -->
- [ ] T018 [P] [US2] Enforce order-independent dual-token canonicalization and lookup behavior in src/seeds/SeedRecipeRegistry.gd
- [ ] T019 [P] [US2] Update dual-token preview and confirm-state UI behavior for position-insensitive matches in src/ui/SeedAlchemyPanel.gd
<!-- sequential -->
- [ ] T020 [US2] Enforce Ku unlock gating for all Ku-including dual recipes in attempt resolution in src/autoloads/seed_alchemy_service.gd
<!-- sequential -->
- [ ] T021 [US2] Document dual-recipe permutation validation matrix and outcomes in specs/019-seed-crafting-grid/quickstart.md

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Receive Clear Failure Feedback for Non-Seed Inputs (Priority: P2)

**Goal**: Return deterministic non-destructive failure outcomes for empty input, invalid input, locked Ku, and inventory-full blocking.

**Independent Test**: Each failure condition shows the expected feedback, creates no output, and preserves grid tokens unless craft succeeds.

### Tests for User Story 3

<!-- sequential -->
- [ ] T022 [US3] Add GUT coverage for empty_input, no_matching_seed_recipe, locked_element, and inventory_full outcomes in tests/unit/seeds/test_seed_crafting_grid.gd

### Implementation for User Story 3

<!-- parallel-group: 4 -->
- [ ] T023 [P] [US3] Add explicit UI feedback mapping for success/invalid/locked/full states in src/ui/SeedAlchemyPanel.gd
- [ ] T024 [P] [US3] Return deterministic outcome payload including feedback key and consumed slots for every attempt in src/autoloads/seed_alchemy_service.gd
<!-- sequential -->
- [ ] T025 [US3] Block valid craft completion when pouch is full while keeping recipe tokens in-grid in src/ui/SeedAlchemyPanel.gd
<!-- sequential -->
- [ ] T026 [US3] Treat 3+ token and legacy structure-like combinations as no-matching seed input in src/seeds/SeedRecipeRegistry.gd
<!-- sequential -->
- [ ] T027 [US3] Add manual verification steps for inventory-full token retention and locked-Ku guidance messaging in specs/019-seed-crafting-grid/quickstart.md

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression hardening and final validation.

<!-- parallel-group: 5 -->
- [ ] T028 [P] Add regression assertions ensuring charge consumption happens only on successful craft in tests/unit/seeds/test_seed_recipe_registry.gd
- [ ] T029 [P] Add focused manual checklist entries for 48x48 effective slot touch-target verification in specs/019-seed-crafting-grid/quickstart.md
<!-- sequential -->
- [ ] T030 Run focused GUT suite command and record pass/fail evidence in specs/019-seed-crafting-grid/quickstart.md
<!-- sequential -->
- [ ] T031 Run headless Godot parse check and record validation notes in specs/019-seed-crafting-grid/checklists/requirements.md
<!-- sequential -->
- [ ] T032 Remove obsolete two-token-only UI assumptions and dead helper branches in src/ui/SeedAlchemyPanel.gd

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Stories (Phase 3-5)**: Depend on Foundational completion.
- **Polish (Phase 6)**: Depends on completion of selected user stories.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; no dependency on other stories.
- **US2 (P1)**: Starts after Foundational; integrates with shared resolver/UI but remains independently testable.
- **US3 (P2)**: Starts after Foundational; validates failure/outcome behavior independently.

### Within Each User Story

- Tests first for deterministic behavior.
- Core resolver/service behavior before final UI feedback polish.
- Manual validation tasks close each story.

## Dependency Graph

`Setup -> Foundational -> (US1 || US2 || US3) -> Polish`

---

## Parallel Execution Examples

### US1 Example

<!-- parallel-group: 2 -->
1. T011 in src/ui/SeedAlchemyPanel.gd
2. T012 in scenes/UI/SeedAlchemyPanel.tscn

### US2 Example

<!-- parallel-group: 3 -->
1. T018 in src/seeds/SeedRecipeRegistry.gd
2. T019 in src/ui/SeedAlchemyPanel.gd

### US3 Example

<!-- parallel-group: 4 -->
1. T023 in src/ui/SeedAlchemyPanel.gd
2. T024 in src/autoloads/seed_alchemy_service.gd

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1 and Phase 2.
2. Deliver Phase 3 (US1) and validate independently.
3. Demo/review before expanding scope.

### Incremental Delivery

1. Add US2 for dual-token position-insensitive support.
2. Add US3 for deterministic failure and feedback handling.
3. Run Polish phase validation and regression checks.

### Parallel Team Strategy

1. Team completes Setup + Foundational together.
2. Fan out using parallel groups (max 3 concurrent tasks/group).
3. Merge story increments only after story-level independent checks pass.

---

## Notes

- Seed recipes only in Phase 1; structures/build migrations remain out of scope.
- Craft output destination is plant inventory only.
- Clarified mandatory behaviors are authoritative: consume-on-success only, inventory-full blocks while keeping tokens in-grid, successful craft clears consumed slots, and mobile slot targets are >= 48x48.