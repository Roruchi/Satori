# Tasks: Alpha Save Safety

**Input**: Design documents from `/specs/030-alpha-save-safety/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [ ] T001 Audit current `src/autoloads/save_game_service.gd` coverage and registered autoload state.
- [ ] T002 List all alpha-critical fields from specs 027, 028, and 029.
- [ ] T003 Record observed desktop, Web, and Android `user://` save behavior during validation.

## Phase 2: Foundational

- [ ] T004 [P] Add save snapshot schema/version tests.
- [ ] T005 [P] Add first-session save round-trip tests.
- [ ] T006 [P] Add endgame/Suijin save round-trip tests after spec 029 lands.

## Phase 3: User Story 1 - Save Complete Alpha State (Priority: P1)

- [ ] T007 [US1] Ensure all alpha-critical fields serialize.
- [ ] T008 [US1] Ensure all alpha-critical fields restore.
- [ ] T009 [US1] Ensure confirmed active project timers/progress restore without duplication, refund, cancellation, or instant completion.
- [ ] T010 [US1] Run manual checkpoint save/reload script.

## Phase 4: User Story 2 - Autosave Safely (Priority: P1)

- [ ] T011 [US2] Wire autosave requests to meaningful progress events.
- [ ] T012 [US2] Add lifecycle save hooks for app close/background where supported.
- [ ] T013 [US2] Verify failed writes do not corrupt existing saves.

## Phase 5: User Story 3 - Version External Alpha Saves (Priority: P2)

- [ ] T014 [US3] Add save schema version if missing.
- [ ] T015 [US3] Store producing build version in `0.x.y-alpha+<build_id>` format.
- [ ] T016 [US3] Add unsupported-save handling.
- [ ] T017 [US3] Document save compatibility in external alpha notes.

## Dependencies & Execution Order

Save safety can start after first-session state exists, but final verification depends on endgame/kami implementation.
