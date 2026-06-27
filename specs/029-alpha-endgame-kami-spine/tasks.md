# Tasks: Alpha Endgame Kami Spine

**Input**: Design documents from `/specs/029-alpha-endgame-kami-spine/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [x] T001 Decide the first alpha kami: Suijin.
- [x] T002 Define island separation: Ku Seed places Void and Void separates islands.
- [x] T003 Define Suijin invitation: Chi+Ku biome on island with 10 water tiles, no fire-based tiles, and Satori 1000.

## Phase 2: Foundational

- [ ] T004 [P] Add Ku unlock persistence tests.
- [ ] T005 [P] Add Void island-separation tests.
- [ ] T006 [P] Add Suijin invitation duplicate-safety tests.

## Phase 3: User Story 1 - Unlock Ku Fairly (Priority: P1)

- [ ] T007 [US1] Preserve or refine Mist Stag gating in `src/spirits/spirit_service.gd`.
- [ ] T008 [US1] Ensure Ku recipes remain locked before unlock and readable after unlock.
- [ ] T009 [US1] Verify Ku unlock persists after restart.

## Phase 4: User Story 2 - Reach an Endgame Island (Priority: P1)

- [ ] T010 [US2] Implement Ku Seed -> Void placement in `src/autoloads/seed_alchemy_service.gd` or the owning seed flow.
- [ ] T011 [US2] Implement Void island separation in the owning island/GameState service.
- [ ] T012 [US2] Add Codex/HUD guidance for Void island separation.
- [ ] T013 [US2] Verify Void separation persists after restart.

## Phase 5: User Story 3 - Invite One Kami (Priority: P1)

- [ ] T014 [US3] Add Suijin definition and Chi+Ku calm-water-island invitation condition.
- [ ] T015 [US3] Wire visible Suijin arrival and discovery/Codex entry.
- [ ] T016 [US3] Verify Suijin invitation is island-local and duplicate-safe.
- [ ] T017 [US3] Run full fresh-save manual endgame script.

## Dependencies & Execution Order

T001-T003 are blocking. US1 must complete before US2; US2 must complete before US3.
