# Tasks: Playable First Session

**Input**: Design documents from `/specs/027-playable-first-session/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [ ] T001 Review current ritual and material CSV rows in `data/discovery_editor/runtime/`.
- [ ] T002 Review title, HUD, ritual menu, pouch, and placement scenes for first-session blockers.

## Phase 2: Foundational

- [ ] T003 [P] Add or update focused ritual preview tests in `tests/unit/test_ritual_menu_ui.gd`.
- [ ] T004 [P] Add or update first-session persistence checks in `tests/unit/test_first_expansion_loop.gd`.

## Phase 3: User Story 1 - Start and Understand First Ritual (Priority: P1)

- [ ] T005 [US1] Ensure title-to-garden flow reaches a clear first action in `src/ui/TitleScreen.gd` and `src/ui/HUDController.gd`.
- [ ] T006 [US1] Ensure Wind/Fu preview creates Meadow Seed through `src/autoloads/seed_alchemy_service.gd`.
- [ ] T007 [US1] Validate first ritual menu readability in `scenes/UI/SeedAlchemyPanel.tscn`.

## Phase 4: User Story 2 - Plant, Grow, and Harvest (Priority: P1)

- [ ] T008 [US2] Verify Meadow Seed placement through `src/grid/GardenView.gd` and `src/autoloads/GameState.gd`.
- [ ] T009 [US2] Verify Meadow material spawning and Living Wood harvest through `tests/unit/test_biome_material_harvesting.gd`.
- [ ] T010 [US2] Confirm save/load preserves first seed, biome, and material state.

## Phase 5: User Story 3 - First Spirit and Dwelling (Priority: P1)

- [ ] T011 [US3] Verify Red Fox invite/spawn path in `src/spirits/spirit_service.gd`.
- [ ] T012 [US3] Verify Living Wood + Fire Essence creates Warm Hollow via runtime ritual data.
- [ ] T013 [US3] Verify Warm Hollow resolves into a valid Meadow dwelling.
- [ ] T014 [US3] Verify Red Fox automatically becomes housed when the Meadow dwelling is placed and that housed state is visible.
- [ ] T015 [US3] Run the full manual first-session script in `quickstart.md`.

## Dependencies & Execution Order

Complete US1 before US2, then US3. Do not mark the spec verified until the fresh-save manual script and focused tests both pass.
