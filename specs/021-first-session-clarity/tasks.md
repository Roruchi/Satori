# Tasks: First-Session Clarity and Structure Feedback

**Input**: Design documents from `specs/021-first-session-clarity/`
**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories)

**Tests**: Required. Each user story includes automated GUT coverage plus manual in-editor validation for UI-heavy behavior.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel if the files do not conflict
- **[Story]**: Which user story the task belongs to
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the shared state and copy hooks that the stories will reuse.

- [ ] T001 [P] Add first-session completion storage helpers in `src/autoloads/garden_settings.gd`
- [ ] T002 [P] Add a shared player-facing vocabulary map in `src/ui/ui_copy.gd`
- [ ] T003 Create the first-session guide scene shell in `scenes/UI/FirstSessionGuide.tscn` and `src/ui/FirstSessionGuide.gd`

---

## Phase 2: User Story 1 - Guided First Session (Priority: P1)

**Goal**: A fresh profile gets a lightweight guide that teaches the first important actions and then stays out of the way.

**Independent Test**: Fresh-profile manual run plus GUT coverage for step progression and completion persistence.

### Tests for User Story 1

- [ ] T004 [P] [US1] Add GUT coverage for first-session progression in `tests/unit/test_first_session_guide.gd`
- [ ] T005 [US1] Add a manual verification checklist for fresh-profile onboarding in `specs/021-first-session-clarity/plan.md` or the implementation notes

### Implementation for User Story 1

- [ ] T006 [P] [US1] Wire the guide into `scenes/Garden.tscn` and `src/ui/HUDController.gd`
- [ ] T007 [US1] Implement step advancement hooks for placement, mix/craft, and Codex inspection in `src/ui/FirstSessionGuide.gd`
- [ ] T008 [US1] Persist guide completion separately from the garden save in `src/autoloads/garden_settings.gd`

**Checkpoint**: The first-session guide should be visible, step through the intended actions, and remain skipped after completion.

---

## Phase 3: User Story 2 - Consistent Player Vocabulary (Priority: P2)

**Goal**: The same action should have the same visible name everywhere in the player-facing UI.

**Independent Test**: Manual UI review plus GUT coverage for the shared copy source and the most important label consumers.

### Tests for User Story 2

- [ ] T009 [P] [US2] Add GUT coverage for the shared copy map in `tests/unit/test_ui_copy.gd`
- [ ] T010 [US2] Add manual validation notes for HUD, popovers, and panel labels in `specs/021-first-session-clarity/plan.md` or the implementation notes

### Implementation for User Story 2

- [ ] T011 [P] [US2] Update visible mode labels and action labels in `src/ui/HUDController.gd`
- [ ] T012 [P] [US2] Normalize interaction prompts in `src/grid/PlacementController.gd` and `src/grid/GardenView.gd`
- [ ] T013 [P] [US2] Normalize craft, Codex, and settings wording in `src/ui/SeedAlchemyPanel.gd`, `src/ui/CodexPanel.gd`, and `src/ui/SettingsMenu.gd`

**Checkpoint**: The player should see one consistent vocabulary set across the main HUD and related feedback surfaces.

---

## Phase 4: User Story 3 - Clear Structure Craft Feedback (Priority: P3)

**Goal**: Structure crafting should clearly explain what is required, what is blocked, and what will happen next.

**Independent Test**: GUT coverage for success and failure feedback plus manual verification of preview, blocked-reason text, and no-resource-loss behavior.

### Tests for User Story 3

- [ ] T014 [P] [US3] Add GUT coverage for blocked and successful structure craft feedback in `tests/unit/test_structure_feedback_flow.gd`
- [ ] T015 [US3] Add manual verification notes for structure preview and Codex hint readability in `specs/021-first-session-clarity/plan.md` or the implementation notes

### Implementation for User Story 3

- [ ] T016 [P] [US3] Extend structure craft result data in `src/seeds/BuildingCraftAttemptResult.gd` or the existing craft feedback path so blocked reasons are explicit
- [ ] T017 [US3] Render output, requirements, and blocked reasons in `src/ui/SeedAlchemyPanel.gd`
- [ ] T018 [US3] Surface readable structure guidance in `src/autoloads/codex_service.gd` and `src/ui/CodexPanel.gd`
- [ ] T019 [US3] Keep failure paths deterministic and resource-safe in the craft/placement flow used by `src/grid/PlacementController.gd`

**Checkpoint**: Structure-related feedback should explain the next step clearly and never mutate state on failure.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup across all three stories.

- [ ] T020 [P] Update any remaining player-facing strings in `src/` to match the approved vocabulary map
- [ ] T021 [P] Add regression checks for the first-session skip path and repeat-session behavior in `tests/unit/`
- [ ] T022 [P] Verify mobile layout readability and thumb-zone placement in `scenes/UI/` and `src/ui/HUDController.gd`
- [ ] T023 Run the project parse/error check after the new scripts and typed signals are added

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup**: No dependencies
- **User Stories**: Depend on Setup completion
- **Polish**: Depends on the three user stories being complete

### User Story Dependencies

- **US1**: Can start after Setup
- **US2**: Can start after Setup and may reuse the shared vocabulary map from US1 setup
- **US3**: Can start after Setup and may reuse the vocabulary map and HUD wiring from US1 and US2

### Parallel Opportunities

- T001 and T002 can run in parallel.
- T004 and T009 can run in parallel.
- T011, T012, and T013 can run in parallel if they do not touch the same visible copy sources at the same time.
- T016, T017, and T018 can proceed in parallel once the feedback shape is agreed.

---

## Implementation Strategy

### MVP First

1. Finish Setup.
2. Deliver US1 as the first playable improvement.
3. Validate the guide in a fresh profile.
4. Add US2 to remove confusing terminology.
5. Add US3 to make structure crafting self-explanatory.

### Incremental Delivery

1. First-session guide
2. Consistent labels and prompts
3. Clear structure craft feedback

### Notes

- Keep the guide lightweight and non-blocking.
- Keep the vocabulary map as the single source of truth for visible terms.
- Keep structure failures deterministic and state-safe.

