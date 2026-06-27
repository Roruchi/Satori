# Tasks: First Island Fun Loop

**Input**: Design documents from `/specs/028-first-island-fun-loop/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [x] T001 Verify Fox Den, Dew Bowl, and Wind Chime runtime data.
- [x] T002 Review current Satori and spirit feedback surfaces.

## Phase 2: Foundational

- [x] T003 [P] Add or update duplicate ritual rejection tests.
- [x] T004 [P] Add or update Fox Den, Dew Bowl, and Wind Chime placement/effect tests.
- [x] T005 [P] Add or update Satori pressure/recovery tests.

## Phase 3: User Story 1 - Care About Spirits (Priority: P1)

- [x] T006 [US1] Make Red Fox housing/restless state visible in `src/ui/HUDController.gd`, hover UI, and Codex.
- [x] T007 [US1] Verify Satori changes from housed/unhoused spirits in `src/autoloads/satori_service.gd`.
- [x] T008 [US1] Verify upgraded Fox Den is reachable from the Red Fox housing loop.
- [x] T009 [US1] Verify Red Fox migrates to Fox Den automatically and grants double Satori generation for Red Fox only.
- [x] T010 [US1] Validate manual spirit care loop.

## Phase 4: User Story 2 - Build Useful Structures (Priority: P1)

- [x] T011 [US2] Ensure Dew Bowl and Wind Chime rituals exist in runtime CSV data.
- [x] T012 [US2] Implement or verify Dew Bowl storage/soothing effect in the owning service.
- [x] T013 [US2] Implement or verify Wind Chime invitation/harvest effect in the owning service.
- [x] T014 [US2] Verify Fox Den migration/Red-Fox-only double Satori generation, Dew Bowl, and Wind Chime survive save/load.

## Phase 5: User Story 3 - Understand Invalid Choices (Priority: P2)

- [x] T015 [US3] Enforce duplicate ritual rejection in `src/autoloads/seed_alchemy_service.gd`.
- [x] T016 [US3] Add actionable invalid project feedback in build/project UI.
- [x] T017 [US3] Validate invalid paths are non-destructive.

## Dependencies & Execution Order

Complete T001-T005 before story implementation. US1 and US2 can proceed in parallel after foundation; US3 must complete before alpha tester release.
