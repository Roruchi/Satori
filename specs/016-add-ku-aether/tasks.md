# Tasks: Mixable Ku Recipes

**Input**: Design documents from `/specs/016-add-ku-aether/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Validation tasks are required for this feature. Include GUT coverage for deterministic recipe/unlock/discovery logic and manual validation for codex UX and progression flow.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Every task includes an exact file path

## Path Conventions

- Godot source: `src/`
- Godot scenes/UI scripts: `src/ui/`
- Resource data: `.tres` files under `src/`
- Automated tests: `tests/unit/`
- Feature docs: `specs/016-add-ku-aether/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare test and validation scaffolding shared across all stories.

- [X] T001 Create codex service GUT suite scaffold for Ku guidance assertions in tests/unit/test_codex_service.gd
- [X] T002 Add Ku feature validation checklist headings to specs/016-add-ku-aether/quickstart.md
- [X] T003 [P] Add Ku-focused test section comments in tests/unit/seeds/test_seed_recipe_registry.gd and tests/unit/spirits/test_spirit_service.gd

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core guards and shared hooks that must be in place before story work.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete.

- [X] T004 Harden repeated Ku unlock gift handling for idempotent behavior in src/spirits/SpiritGiftProcessor.gd
- [X] T005 Add explicit Ku unlock state helper and duplicate-unlock signal guard in src/autoloads/seed_alchemy_service.gd
- [X] T006 Add regression coverage for repeated Mist Stag Ku unlock events in tests/unit/spirits/test_spirit_service.gd

**Checkpoint**: Shared unlock behavior and test scaffolding are ready.

---

## Phase 3: User Story 1 - Unlock and Mix Ku Pairings (Priority: P1) 🎯 MVP

**Goal**: Allow players to unlock Ku via Mist Stag and craft exactly four valid Ku pair recipes, while keeping solo Ku invalid.

**Independent Test**: From a Ku-locked state, trigger Mist Stag unlock path, then verify Chi+Ku/Sui+Ku/Ka+Ku/Fu+Ku preview and craft successfully while solo Ku remains invalid.

### Tests for User Story 1

- [X] T007 [P] [US1] Extend Ku recipe lookup assertions (four valid pairs + solo Ku invalid) in tests/unit/seeds/test_seed_recipe_registry.gd
- [X] T008 [US1] Add Ku unlock-to-craft flow tests for SeedAlchemy service behavior in tests/unit/seeds/test_seed_growth_service.gd

### Implementation for User Story 1

- [X] T009 [P] [US1] Create Ku recipe resources recipe_chi_ku.tres, recipe_sui_ku.tres, recipe_ka_ku.tres, and recipe_fu_ku.tres in src/seeds/recipes/
- [X] T010 [US1] Update craft preview names and invalid-mix feedback for Ku pairing UX in src/ui/SeedAlchemyPanel.gd
- [X] T011 [P] [US1] Add codex seed recipe entries seed_recipe_chi_ku.tres, seed_recipe_sui_ku.tres, seed_recipe_ka_ku.tres, and seed_recipe_fu_ku.tres in src/codex/entries/
- [X] T012 [US1] Ensure Ku recipe discovery marks codex state consistently after crafting in src/autoloads/seed_alchemy_service.gd
- [X] T013 [US1] Record manual unlock-and-mix verification evidence in specs/016-add-ku-aether/quickstart.md

**Checkpoint**: US1 is fully playable and testable as MVP.

---

## Phase 4: User Story 2 - Discover Aether-Themed World Content (Priority: P2)

**Goal**: Deliver four Ku biomes mapped one-to-one to four Shinto deity spirits and four worship-structure discoveries.

**Independent Test**: Bloom each Ku seed and verify distinct biome outcome plus exactly one mapped deity and one mapped structure discovery per Ku biome.

### Tests for User Story 2

- [X] T014 [P] [US2] Add deity summon coverage for spirit_oyamatsumi, spirit_suijin, spirit_kagutsuchi, and spirit_fujin in tests/unit/spirits/test_spirit_service.gd
- [X] T015 [P] [US2] Add tier2 discovery assertions for disc_iwakura_sanctum, disc_misogi_spring_shrine, disc_eternal_kagura_hall, and disc_heavenwind_torii in tests/unit/test_tier2_landmark_discoveries.gd
- [X] T016 [P] [US2] Add mapping-integrity regression checks for Ku recipe/biome/spirit/structure cardinality in tests/unit/test_data_driven_pattern_addition.gd

### Implementation for User Story 2

- [X] T017 [P] [US2] Add four Ku deity spirit catalog entries with respectful Shinto references in src/spirits/spirit_catalog_data.gd
- [X] T018 [P] [US2] Create spirit pattern resources spirit_oyamatsumi.tres, spirit_suijin.tres, spirit_kagutsuchi.tres, and spirit_fujin.tres in src/biomes/patterns/spirits/
- [X] T019 [P] [US2] Add four Ku worship structure metadata entries in src/biomes/discovery_catalog_data.gd
- [X] T020 [P] [US2] Create worship structure pattern resources iwakura_sanctum.tres, misogi_spring_shrine.tres, eternal_kagura_hall.tres, and heavenwind_torii.tres in src/biomes/patterns/tier2/
- [X] T021 [US2] Add codex entries for Ku deity spirits and Ku structures in src/codex/entries/spirit_oyamatsumi.tres, src/codex/entries/spirit_suijin.tres, src/codex/entries/spirit_kagutsuchi.tres, src/codex/entries/spirit_fujin.tres, src/codex/entries/disc_iwakura_sanctum.tres, src/codex/entries/disc_misogi_spring_shrine.tres, src/codex/entries/disc_eternal_kagura_hall.tres, and src/codex/entries/disc_heavenwind_torii.tres
- [X] T022 [US2] Record one-to-one Ku content mapping verification notes in specs/016-add-ku-aether/quickstart.md

**Checkpoint**: US2 content chain is complete and independently verifiable.

---

## Phase 5: User Story 3 - Codex Guidance for Ku Progression (Priority: P3)

**Goal**: Provide clear pre-unlock codex guidance naming Mist Stag without numeric thresholds, then transition to discovered-state presentation after unlock.

**Independent Test**: On fresh profile, verify codex shows directional Mist Stag hint pre-unlock and discovered-state text post-unlock.

### Tests for User Story 3

- [X] T023 [P] [US3] Implement pre-unlock vs post-unlock Ku guidance tests in tests/unit/test_codex_service.gd

### Implementation for User Story 3

- [X] T024 [US3] Add Ku unlock guidance codex entry resource with non-numeric Mist Stag hint in src/codex/entries/ku_unlock_guidance.tres
- [X] T025 [US3] Implement Ku hint-state resolution logic (hinted vs discovered) in src/autoloads/codex_service.gd
- [X] T026 [US3] Update codex panel rendering to distinguish hinted vs discovered Ku progression copy in src/ui/CodexPanel.gd
- [X] T027 [US3] Record fresh-profile codex guidance validation steps and outcomes in specs/016-add-ku-aether/quickstart.md

**Checkpoint**: US3 guidance flow is independently testable and complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, regression checks, and documentation alignment.

- [X] T028 [P] Run Ku-targeted GUT suites and log pass/fail evidence in specs/016-add-ku-aether/quickstart.md
- [X] T029 [P] Sync implementation notes with contracts in specs/016-add-ku-aether/contracts/ku-unlock-and-recipes.md and specs/016-add-ku-aether/contracts/ku-content-mapping.md
- [X] T030 Verify non-Ku recipe compatibility and no new persistence guarantees in tests/unit/seeds/test_seed_recipe_registry.gd and tests/unit/test_tier1_discovery_persistence.gd

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies, start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2; defines MVP.
- **Phase 4 (US2)**: Depends on Phase 2 and integrates with US1 recipe outputs.
- **Phase 5 (US3)**: Depends on Phase 2 and Ku unlock behavior from US1.
- **Phase 6 (Polish)**: Depends on completion of US1-US3.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; no dependency on US2/US3.
- **US2 (P2)**: Starts after Foundational; relies on Ku recipe outputs delivered in US1 for end-to-end validation.
- **US3 (P3)**: Starts after Foundational; validates codex transitions against Ku unlock state delivered in US1.

### Within Each User Story

- Write/extend tests before or alongside implementation.
- Add data resources before service/UI integration.
- Complete manual validation notes before closing the story.

### Parallel Opportunities

- Setup: T003 can run with T001/T002.
- Foundational: T004 and T005 can proceed in parallel before T006.
- US1: T007 and T009/T011 can run in parallel; T010/T012 follow resource availability.
- US2: T014/T015/T016 and T017/T018/T019/T020 are parallelizable by file ownership.
- US3: T023 can run in parallel with T024 before T025/T026 integration.
- Polish: T028 and T029 can run in parallel before T030 sign-off.

---

## Parallel Example: User Story 1

```text
Task: "Extend Ku recipe lookup assertions in tests/unit/seeds/test_seed_recipe_registry.gd"
Task: "Create Ku recipe resources in src/seeds/recipes/recipe_chi_ku.tres, src/seeds/recipes/recipe_sui_ku.tres, src/seeds/recipes/recipe_ka_ku.tres, src/seeds/recipes/recipe_fu_ku.tres"
Task: "Add codex seed recipe entries in src/codex/entries/seed_recipe_chi_ku.tres, src/codex/entries/seed_recipe_sui_ku.tres, src/codex/entries/seed_recipe_ka_ku.tres, src/codex/entries/seed_recipe_fu_ku.tres"
```

## Parallel Example: User Story 2

```text
Task: "Add deity summon coverage in tests/unit/spirits/test_spirit_service.gd"
Task: "Add four Ku deity entries in src/spirits/spirit_catalog_data.gd"
Task: "Create four spirit patterns in src/biomes/patterns/spirits/"
Task: "Create four structure patterns in src/biomes/patterns/tier2/"
```

## Parallel Example: User Story 3

```text
Task: "Implement guidance-state tests in tests/unit/test_codex_service.gd"
Task: "Add Ku guidance resource in src/codex/entries/ku_unlock_guidance.tres"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Finish Phase 1 (Setup).
2. Finish Phase 2 (Foundational unlock guards).
3. Complete Phase 3 (US1 unlock + recipe crafting).
4. Validate US1 independently via GUT + manual quickstart checks.
5. Demo/deploy MVP slice.

### Incremental Delivery

1. Setup + Foundational.
2. Deliver US1, validate, and stabilize.
3. Deliver US2 content mappings and discoveries, validate independently.
4. Deliver US3 codex guidance transitions, validate independently.
5. Run polish and regression checks before merge.

### Parallel Team Strategy

1. Team completes Phases 1-2 together.
2. After foundation:
   - Developer A: US1 (recipes + alchemy panel)
   - Developer B: US2 (spirit/structure content + patterns)
   - Developer C: US3 (codex guidance + panel behavior)
3. Rejoin for Phase 6 regression and contract sync.

---

## Notes

- `[P]` means file-level parallel safety; coordinate ordering where integration tasks depend on data tasks.
- Keep Ku pre-unlock codex hint narrative and non-numeric.
- Preserve Mist Stag as the only Ku unlock trigger.
- Preserve existing save/load semantics (no new persistence guarantees in this feature).
