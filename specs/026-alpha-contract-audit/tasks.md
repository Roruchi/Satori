# Tasks: Alpha Contract and State Audit

**Input**: Design documents from `/specs/026-alpha-contract-audit/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

**Tests**: Documentation-only setup, followed by command/manual validation tasks.

## Phase 1: Setup

- [x] T001 Add alpha spec tracker to `docs/alpha-roadmap.md`.
- [x] T002 Link every roadmap phase to its owning numbered spec.
- [x] T003 Add status definitions for spec drafting and alpha implementation.

## Phase 2: Audit Evidence Model

- [x] T004 Define alpha gate status fields in `docs/alpha-roadmap.md`.
- [x] T005 [P] Confirm dirty worktree state with `git -c safe.directory=C:/Repo/Personal/Games/Satori status --short --branch`.
- [x] T006 [P] Record intended validation commands in this spec quickstart.

## Phase 3: User Story 1 - Freeze Alpha Acceptance (Priority: P1)

- [x] T007 [US1] Verify the roadmap alpha finale is Ku, Void island separation, Chi+Ku calm-water island preparation, and Suijin invitation.
- [x] T008 [US1] Confirm every future spec traces back to a roadmap phase.

## Phase 4: User Story 2 - Audit Current Game State (Priority: P1)

- [x] T009 [US2] Run parse validation through `tools/godot.ps1`.
- [x] T010 [US2] Run boot smoke validation through `tools/godot.ps1`.
- [x] T011 [US2] Execute the manual alpha spine audit from `quickstart.md`.
- [x] T012 [US2] Record each incomplete or unverified gate against its owning alpha spec.

## Phase 5: User Story 3 - Preserve Priority Order (Priority: P2)

- [x] T013 [US3] Sort roadmap tracker rows by implementation priority.
- [x] T014 [US3] Confirm dependencies flow from audit to first session to first island to endgame to platform release.

## Dependencies & Execution Order

Complete T001-T004 before running the manual audit. T009-T012 should be repeated after each implementation spec reaches a validation checkpoint.
