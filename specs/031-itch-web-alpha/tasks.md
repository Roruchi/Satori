# Tasks: itch.io Web Alpha

**Input**: Design documents from `/specs/031-itch-web-alpha/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [ ] T001 Review `export_presets.cfg` include/exclude filters for alpha data/assets.
- [ ] T002 Confirm Godot Web export templates are available.
- [ ] T003 Confirm first-alpha Web export keeps PWA disabled.

## Phase 2: Foundational

- [ ] T004 [P] Update Web export filters if runtime data or alpha assets are missing.
- [ ] T005 [P] Review `tests/playwright/satori-web-smoke.spec.js` coverage against alpha smoke needs.
- [ ] T006 [P] Audit Web package so placeholder art, audio, icon, and UI assets do not appear on the primary alpha path or release shell.

## Phase 3: User Story 1 - Export Playable Web Build (Priority: P1)

- [ ] T007 [US1] Produce `build/web/index.html`.
- [ ] T008 [US1] Manually open build and confirm title screen and visible menu build version.

## Phase 4: User Story 2 - Preserve Runtime Data and Saves (Priority: P1)

- [ ] T009 [US2] Verify first ritual works in Web build.
- [ ] T010 [US2] Verify same-browser reload preserves save state.
- [ ] T011 [US2] Run Playwright smoke.

## Phase 5: User Story 3 - Package for itch.io (Priority: P2)

- [ ] T012 [US3] Document restricted manual packaging/upload steps.
- [ ] T013 [US3] Create restricted-alpha known issues notes.

## Dependencies & Execution Order

Do not package for itch.io until export, smoke, and persistence checks pass.
