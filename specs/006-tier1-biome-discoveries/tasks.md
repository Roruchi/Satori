# Tasks: Tier 1 Biome Cluster Discoveries (MVP)

**Input**: Design documents from `specs/006-tier1-biome-discoveries/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Automated GUT coverage is required for deterministic discovery triggering, queue ordering/timing, duplicate suppression, and persistence restore behavior.

**Organization**: Tasks are grouped by user story to keep each story independently implementable and testable.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare feature test harness and content scaffolding.

- [ ] T001 Create Tier 1 discovery fixture directory marker in tests/unit/fixtures/discoveries/.keep
- [ ] T002 Create discovery pipeline test suite scaffold in tests/unit/test_tier1_discovery_pipeline.gd
- [ ] T003 [P] Create discovery persistence test suite scaffold in tests/unit/test_tier1_discovery_persistence.gd
- [ ] T004 [P] Create discovery audio mapping test suite scaffold in tests/unit/test_tier1_discovery_audio_map.gd

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared discovery assets and runtime contracts required by all stories.

**CRITICAL**: Complete this phase before starting user stories.

- [ ] T005 Implement discovery metadata catalog model and lookup API in src/biomes/discovery_catalog.gd
- [ ] T006 Define all 12 Tier 1 discovery metadata entries in src/biomes/discovery_catalog_data.gd
- [ ] T007 Add typed discovery payload value object for queue/persistence handoff in src/biomes/discovery_payload.gd
- [ ] T008 Implement notification queue controller shell with enqueue/dequeue API in src/ui/discovery_notification_queue.gd
- [ ] T009 [P] Implement discovery audio playback wrapper with no-fail visual fallback in src/ui/discovery_audio_player.gd
- [ ] T010 Add Tier 1 pattern resource files for all discovery IDs in src/biomes/patterns/tier1/
- [ ] T011 Wire Tier 1 pattern directory loading into pattern bootstrap path in src/biomes/pattern_loader.gd
- [ ] T012 Add discovery event router that combines signal + metadata lookup in src/biomes/discovery_event_router.gd

**Checkpoint**: Foundation ready. User stories can proceed.

---

## Phase 3: User Story 1 - Discovery Notification and Audio Stinger on First Match (Priority: P1) 🎯 MVP

**Goal**: Show named/flavor discovery notifications and play stingers exactly once when a new Tier 1 discovery fires.

**Independent Test**: Trigger The Deep Stand and The River in isolation, verify immediate notification + stinger, 4-second auto-dismiss, and sequential queue for dual-trigger placement.

### Tests for User Story 1

- [ ] T013 [P] [US1] Add deterministic first-trigger notification test coverage in tests/unit/test_tier1_discovery_pipeline.gd
- [ ] T014 [P] [US1] Add dual-trigger queue ordering/no-overlap coverage in tests/unit/test_tier1_discovery_pipeline.gd
- [ ] T015 [US1] Add 4-second auto-dismiss timing assertions in tests/unit/test_tier1_discovery_pipeline.gd
- [ ] T016 [US1] Document manual validation steps for notification and queue behavior in specs/006-tier1-biome-discoveries/quickstart.md

### Implementation for User Story 1

- [ ] T017 [US1] Replace single-toast discovery UI flow with queued notification flow in src/ui/TileSelector.gd
- [ ] T018 [US1] Implement queue item lifecycle timing and next-item transition in src/ui/discovery_notification_queue.gd
- [ ] T019 [US1] Integrate metadata resolution and queue enqueue on discovery signal in src/biomes/discovery_event_router.gd
- [ ] T020 [US1] Integrate stinger playback on queue activation in src/ui/discovery_audio_player.gd
- [ ] T021 [US1] Wire discovery queue/audio nodes into main scene in scenes/Garden.tscn
- [ ] T022 [US1] Ensure duplicate suppression still gates event emission before UI/audio handling in src/biomes/pattern_matcher.gd

**Checkpoint**: US1 is independently functional and demoable as MVP.

---

## Phase 4: User Story 2 - Persistent Discovery Log Survives App Restart (Priority: P2)

**Goal**: Persist discovery log entries with timestamp/coords and hydrate suppression state on startup.

**Independent Test**: Trigger several discoveries, restart app/session, verify log entries and timestamps persist and previously discovered IDs do not re-fire.

### Tests for User Story 2

- [ ] T023 [P] [US2] Add discovery log write/read round-trip coverage in tests/unit/test_tier1_discovery_persistence.gd
- [ ] T024 [P] [US2] Add startup hydration duplicate-suppression coverage in tests/unit/test_tier1_discovery_persistence.gd
- [ ] T025 [US2] Add timestamp immutability assertions across reload in tests/unit/test_tier1_discovery_persistence.gd
- [ ] T026 [US2] Document restart persistence validation flow in specs/006-tier1-biome-discoveries/quickstart.md

### Implementation for User Story 2

- [ ] T027 [US2] Implement discovery log aggregate with append/contains/serialize/deserialize APIs in src/biomes/discovery_log.gd
- [ ] T028 [US2] Implement discovery save/load adapter for user:// garden payload integration in src/autoloads/discovery_persistence.gd
- [ ] T029 [US2] Record discovery payloads (ID, name, timestamp, coords) on first trigger in src/biomes/discovery_event_router.gd
- [ ] T030 [US2] Hydrate PatternMatcher discovery registry from persisted log during startup in src/biomes/pattern_scan_scheduler.gd
- [ ] T031 [US2] Wire discovery persistence lifecycle hooks into game state startup/shutdown in src/autoloads/GameState.gd
- [ ] T032 [US2] Register discovery persistence autoload configuration in project.godot

**Checkpoint**: US2 works independently with restart-safe discovery history.

---

## Phase 5: User Story 3 - Distinct Audio per Discovery (Priority: P3)

**Goal**: Ensure each Tier 1 discovery uses a unique stinger key and playback remains non-jarring during queued discoveries.

**Independent Test**: Trigger all 12 discoveries and verify one-to-one unique audio keys, valid asset mapping, and controlled handoff between consecutive stingers.

### Tests for User Story 3

- [ ] T033 [P] [US3] Add uniqueness assertion for 12 Tier 1 audio keys in tests/unit/test_tier1_discovery_audio_map.gd
- [ ] T034 [P] [US3] Add audio-key-to-asset resolution coverage in tests/unit/test_tier1_discovery_audio_map.gd
- [ ] T035 [US3] Add queued playback handoff/ducking behavior coverage in tests/unit/test_tier1_discovery_pipeline.gd
- [ ] T036 [US3] Document mute/silent-device expected behavior in specs/006-tier1-biome-discoveries/quickstart.md

### Implementation for User Story 3

- [ ] T037 [US3] Populate unique audio_key values for all 12 discoveries in src/biomes/discovery_catalog_data.gd
- [ ] T038 [US3] Add Tier 1 stinger asset mapping table and fallback handling in src/ui/discovery_audio_player.gd
- [ ] T039 [US3] Implement non-overlapping playback handoff/duck policy for queued stingers in src/ui/discovery_audio_player.gd
- [ ] T040 [US3] Add placeholder Tier 1 stinger asset manifest for runtime loading in assets/audio/discoveries/README.md

**Checkpoint**: US3 audio distinctness and queue playback quality are independently validated.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final integration hardening and release-readiness checks.

- [ ] T041 [P] Run full headless GUT suite for discovery regressions via tests/gut_runner.tscn
- [ ] T042 Validate all quickstart manual scenarios and record outcomes in specs/006-tier1-biome-discoveries/quickstart.md
- [ ] T043 [P] Align contract docs with final implementation field names in specs/006-tier1-biome-discoveries/contracts/discovery-event-contract.md
- [ ] T044 [P] Align persistence schema doc with final save payload shape in specs/006-tier1-biome-discoveries/contracts/discovery-log-schema.md
- [ ] T045 Verify scan timing budget remains within target under discovery load in tests/unit/test_pattern_scan_performance.gd

---

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 (Setup): start immediately.
- Phase 2 (Foundational): depends on Phase 1 and blocks all user stories.
- Phase 3 (US1): depends on Phase 2.
- Phase 4 (US2): depends on Phase 2; can begin after US1 MVP validation.
- Phase 5 (US3): depends on Phase 2; can begin after core US1 integration exists.
- Phase 6 (Polish): depends on completed target stories.

### User Story Dependencies

- US1 (P1): no dependency on other user stories.
- US2 (P2): independent once foundation exists, but validates best after US1 event router wiring is in place.
- US3 (P3): independent once foundation exists, but reuses US1 queue/audio integration paths.

### Recommended Story Completion Order

1. US1 (MVP)
2. US2
3. US3

---

## Parallel Execution Examples

### User Story 1

```text
T013 tests/unit/test_tier1_discovery_pipeline.gd
T014 tests/unit/test_tier1_discovery_pipeline.gd
T017 src/ui/TileSelector.gd
```

### User Story 2

```text
T023 tests/unit/test_tier1_discovery_persistence.gd
T024 tests/unit/test_tier1_discovery_persistence.gd
T027 src/biomes/discovery_log.gd
```

### User Story 3

```text
T033 tests/unit/test_tier1_discovery_audio_map.gd
T034 tests/unit/test_tier1_discovery_audio_map.gd
T038 src/ui/discovery_audio_player.gd
```

---

## Implementation Strategy

### MVP First (US1)

1. Finish Phase 1 and Phase 2.
2. Deliver Phase 3 (US1).
3. Validate US1 independently before expanding scope.

### Incremental Delivery

1. Add US2 persistence after US1 is stable.
2. Add US3 audio distinctness and polish.
3. Run Phase 6 regression and manual validation before handoff.

### Notes

- `[P]` tasks are parallelizable when they touch separate files or can be safely co-developed.
- Keep each user story independently testable to preserve rollout flexibility.
- Preserve deterministic discovery ordering and duplicate suppression guarantees across all phases.
