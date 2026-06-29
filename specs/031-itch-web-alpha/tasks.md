# Tasks: itch.io Web Alpha

**Input**: Design documents from `/specs/031-itch-web-alpha/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [x] T001 Review `export_presets.cfg` include/exclude filters for alpha data/assets.
- [x] T002 Confirm Godot Web export templates are available.
- [x] T003 Confirm first-alpha Web export keeps PWA disabled.

## Phase 2: Foundational

- [x] T004 [P] Update Web export filters if runtime data or alpha assets are missing.
- [x] T005 [P] Review `tests/playwright/satori-web-smoke.spec.js` coverage against alpha smoke needs.
- [x] T006 [P] Audit Web package so placeholder art, audio, icon, and UI assets do not appear on the primary alpha path or release shell.

## Phase 3: User Story 1 - Export Playable Web Build (Priority: P1)

- [x] T007 [US1] Produce `build/web/index.html`.
- [x] T008 [US1] Manually open build and confirm title screen and visible menu build version.

## Phase 4: User Story 2 - Preserve Runtime Data and Saves (Priority: P1)

- [x] T009 [US2] Verify first ritual works in Web build.
- [x] T010 [US2] Verify same-browser reload preserves save state.
- [x] T011 [US2] Run Playwright smoke.

## Phase 5: User Story 3 - Package for itch.io (Priority: P2)

- [x] T012 [US3] Document restricted manual packaging/upload steps.
- [x] T013 [US3] Create restricted-alpha known issues notes.

## Phase 6: Actual itch.io Page Gate

- [x] T014 [US3] Draft the itch.io page content and publication checklist in `specs/031-itch-web-alpha/itch-page.md`.
- [x] T015 [US3] Create or identify the restricted/draft itch.io project page for Satori and record its page URL, owner, slug, and access mode in `specs/031-itch-web-alpha/evidence.md`.
- [x] T016 [US3] Populate the itch.io page with tester-facing content: game description, visuals, controls, alpha scope, known issues, browser save guidance, build version, and feedback route.
- [x] T017 [US3] Upload the validated `build/web/` package to that itch.io page as an HTML/browser-playable build or channel, recording the channel/upload identifier and build version in `specs/031-itch-web-alpha/evidence.md`.
- [ ] T018 [US3] Smoke the actual itch.io page for content completeness plus title screen, new game, first ritual, first placement, and same-browser reload persistence, recording results in `specs/031-itch-web-alpha/evidence.md`.
- [ ] T019 [US3] Only after T015-T018 pass, update `docs/alpha-roadmap.md` Phase 5 from Blocked to Verified with current itch.io page evidence.

## Dependencies & Execution Order

Do not package for itch.io until export, smoke, and persistence checks pass.

T015-T019 require a real itch.io account/project page and cannot be satisfied by local export evidence alone.
