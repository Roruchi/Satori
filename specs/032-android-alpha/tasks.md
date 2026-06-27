# Tasks: Android Alpha

**Input**: Design documents from `/specs/032-android-alpha/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

## Phase 1: Setup

- [ ] T001 Confirm Android export templates, SDK, and JDK availability.
- [x] T002 Decide package id, orientation, versioning, and icon: `com.lunaverse.satori`, no orientation lock, `0.x.y-alpha+<build_id>` menu version, title-emblem icon.
- [ ] T003 Decide signing approach for debug and release-like alpha builds.

## Phase 2: Foundational

- [ ] T004 Add Android export preset to `export_presets.cfg`.
- [ ] T005 Confirm release/debug feature flags do not expose debug-only flows.
- [ ] T006 Audit Android package so placeholder art, audio, icon, and UI assets do not appear on the primary alpha path or release shell.

## Phase 3: User Story 1 - Build and Install Android Alpha (Priority: P1)

- [ ] T007 [US1] Export debug APK or equivalent.
- [ ] T008 [US1] Install on device/emulator and launch to title with title-emblem icon and visible menu build version.

## Phase 4: User Story 2 - Play With Touch (Priority: P1)

- [ ] T009 [US2] Validate touch pan/zoom/tap/placement.
- [ ] T010 [US2] Validate ritual, build/project, Codex, and settings touch targets.
- [ ] T011 [US2] Validate portrait-primary phone layout and no broken landscape layout with no orientation lock.
- [ ] T012 [US2] Fix blocking mobile layout/control issues.

## Phase 5: User Story 3 - Resume Safely (Priority: P1)

- [ ] T013 [US3] Validate background/resume save.
- [ ] T014 [US3] Validate close/reopen save.
- [ ] T015 [US3] Document Android alpha build steps.

## Dependencies & Execution Order

Android external testing depends on save safety and at least the first-session spine.
