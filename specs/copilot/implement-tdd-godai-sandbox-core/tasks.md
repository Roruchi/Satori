# Tasks: Godai Sandbox Core (v6.0) - Phase A

**Input**: Design documents from `/specs/copilot/implement-tdd-godai-sandbox-core/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Validation tasks are REQUIRED and follow TDD for the scoped implementation slice.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure feature docs and contracts are in place for implementation.

- [x] T001 Sync feature specification into /home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/spec.md
- [x] T002 Create planning artifacts in /home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/{plan.md,research.md,data-model.md,quickstart.md}
- [x] T003 Create gameplay contract doc in /home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/contracts/gameplay-signals.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add core building blocks needed before user-story-level implementation.

- [x] T004 Create Kusho domain model in /home/runner/work/Satori/Satori/src/autoloads/kusho_pool.gd
- [x] T005 [P] Add unit coverage skeleton for Kusho model in /home/runner/work/Satori/Satori/tests/unit/test_kusho_pool.gd

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Permanent Intent Sandbox Loop (Priority: P1) 🎯 MVP Slice

**Goal**: Deliver deterministic Kusho counter behavior supporting capped charges, depletion, and low-state detection.

**Independent Test**: GUT tests validate consume/add/cap/depletion semantics independent of scene UI wiring.

### Tests for User Story 1

- [x] T006 [US1] Implement TDD assertions for consume/deplete/low-state in /home/runner/work/Satori/Satori/tests/unit/test_kusho_pool.gd
- [x] T007 [US1] Implement TDD assertions for cap/overflow behavior in /home/runner/work/Satori/Satori/tests/unit/test_kusho_pool.gd

### Implementation for User Story 1

- [x] T008 [US1] Implement KushoPool APIs (set/get/consume/add/is_low/is_depleted/are_all_depleted) in /home/runner/work/Satori/Satori/src/autoloads/kusho_pool.gd

**Checkpoint**: KushoPool behavior is fully testable and deterministic.

---

## Phase 4: User Story 2 - Living Garden Growth and Blueprint Confirmation (Priority: P1)

**Goal**: Deliver Keisu resonance decay that influences procedural background pitch for 5 seconds.

**Independent Test**: GUT tests validate resonance timer, pitch scaling >1.0 after trigger, and return to neutral after decay.

### Tests for User Story 2

- [x] T009 [US2] Add resonance trigger/decay tests in /home/runner/work/Satori/Satori/tests/unit/test_soundscape_engine.gd

### Implementation for User Story 2

- [x] T010 [US2] Add resonance state + public trigger/getter in /home/runner/work/Satori/Satori/src/audio/soundscape_engine.gd
- [x] T011 [US2] Add pitch_scale property support for procedural beds in /home/runner/work/Satori/Satori/src/audio/procedural_audio_bed.gd
- [x] T012 [US2] Apply resonance pitch scale to biome/spirit/procedural/stinger players in /home/runner/work/Satori/Satori/src/audio/soundscape_engine.gd

**Checkpoint**: Resonance pitch influence is functional and testable independent of full bell UI flow.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T013 Update completed checkboxes and execution notes in /home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/tasks.md
- [x] T014 Run targeted validation command from workflow in local environment (or document blocker) in /home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/quickstart.md

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → Phase 3/4 → Phase 5
- US1 tasks (T006–T008) are independent from US2 tasks (T009–T012) once Phase 2 is done.
- TDD ordering: test tasks (T006/T007/T009) precede implementation tasks (T008/T010/T011/T012).

## Parallel Opportunities

- T005 can run in parallel with T004.
- No parallel tasks should touch the same file concurrently.

## Implementation Strategy

### MVP First
1. Complete KushoPool model and tests (US1).
2. Add resonance pitch decay and tests (US2).
3. Validate targeted tests and document outcomes.
