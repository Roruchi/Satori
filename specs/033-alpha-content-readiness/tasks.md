# Tasks: Alpha Content and External Readiness

**Input**: Design documents from `/specs/033-alpha-content-readiness/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [x] T001 List current alpha-included spirits, structures, materials, and Codex entries.
- [x] T002 List intentionally deferred content.
- [x] T003 List all alpha-facing art, audio, icon, and UI assets on the obvious path.

## Phase 2: Foundational

- [x] T004 [P] Add or update data validation for included content.
- [x] T005 [P] Add or update save/load validation for included content.
- [x] T006 Decide build version display location: menu.
- [x] T007 [P] Audit assets and replace, hide, gate, or defer every placeholder on the primary alpha path or release shell.

## Phase 3: User Story 1 - Add Enough Variety (Priority: P1)

- [x] T008 [US1] Select smallest useful housing/helper structure chain: upgraded Fox Den, Dew Bowl, and Wind Chime.
- [x] T009 [US1] Wire selected content through Codex, save/load, and tests.
- [x] T010 [US1] Polish first ritual, Red Fox, Meadow dwelling, upgraded Fox Den migration/Red-Fox-only double Satori generation, Dew Bowl, Wind Chime, Mist Stag, Ku Seed, Void separation, Chi+Ku calm-water island, and Suijin invitation surfaces.
- [x] T011 [US1] Manual playtest beyond first island.

## Phase 4: User Story 2 - Avoid Broken-Looking Gaps (Priority: P1)

- [x] T012 [US2] Hide, gate, or clearly defer unavailable content.
- [x] T013 [US2] Audit normal UI for broken-looking alpha gaps.
- [x] T014 [US2] Confirm no placeholder art, audio, icon, or UI assets remain on the primary alpha path or release shell.

## Phase 5: User Story 3 - Prepare Web Alpha Testers (Priority: P1)

- [x] T015 [US3] Add visible menu build version in `0.x.y-alpha+<build_id>` format.
- [x] T016 [US3] Write Web tester brief and known issues, with Android called out as a later platform gate.
- [x] T017 [US3] Complete Web fresh-save playthrough to Suijin.
- [x] T018 [US3] Record Android follow-up dependency in tester notes and hand off `032-android-alpha` as the final roadmap phase.

## Dependencies & Execution Order

This spec should start after the core alpha spine and save safety are usable. It may proceed while `031-itch-web-alpha` is blocked on external itch.io page/upload work, and it intentionally precedes `032-android-alpha` so Android validates a polished route.
