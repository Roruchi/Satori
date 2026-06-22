# Feature Specification: First-Session Clarity and Structure Feedback

**Feature Branch**: `021-first-session-clarity`  
**Created**: 2026-06-21  
**Status**: Archived / Superseded by `022-ritual-menu-slots`, `023-biome-natural-materials` and `024-spirit-assistants-components`  
**Input**: User description: "Maak een Speckit-spec, design en tasks voor de grootste verbeterpunten: een duidelijkere eerste sessie, consistente speltermen en betere feedback voor structuurcrafting."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guided First Session (Priority: P1)

As a new player, I want the game to guide me through my first important actions so I can understand the loop without leaving the game or guessing the rules.

**Why this priority**: The current game has a strong but opaque early loop. A guided first session reduces early drop-off and makes the core loop legible before the player hits more complex systems.

**Independent Test**: Can be validated with GUT coverage for guide-state progression and manual in-editor verification on a fresh profile. The story is complete if a new player can follow the guide, perform the taught action, and finish the first-session flow once.

**Acceptance Scenarios**:

1. **Given** a fresh profile, **When** the garden scene starts, **Then** a short first-session guide appears and points the player to the first meaningful action.
2. **Given** the player completes the guided action for the current step, **When** the game detects success, **Then** the guide advances to the next step or dismisses itself when the flow is complete.
3. **Given** the guide has been completed once for the profile, **When** the player starts a later session, **Then** the guide does not reappear unless the profile is reset or a debug path explicitly re-enables it.
4. **Given** the player skips the guide, **When** they continue playing, **Then** gameplay remains fully available and no core action is blocked.

---

### User Story 2 - Consistent Player Vocabulary (Priority: P2)

As a player, I want the game to use the same terms for the same actions everywhere so that mode buttons, prompts, and feedback do not contradict each other.

**Why this priority**: The current UI and runtime still mix legacy and current language. Consistent terminology reduces confusion and makes the game easier to teach and remember.

**Independent Test**: Can be validated with snapshot-style manual review of HUD text, world prompts, Codex labels, and structure/craft feedback. The story is complete when the visible player-facing copy uses one approved vocabulary set.

**Acceptance Scenarios**:

1. **Given** the HUD is visible, **When** the player reads the mode buttons and panels, **Then** the same action names are used everywhere for the same interaction.
2. **Given** the player hovers or taps a structure-related item, **When** the game shows a prompt, **Then** the prompt uses the same approved terminology as the rest of the UI.
3. **Given** a legacy or internal term exists in code, **When** that term is not intended for player-facing copy, **Then** it is not shown to the player in menus, tooltips, or feedback text.

---

### User Story 3 - Clear Structure Craft Feedback (Priority: P3)

As a player, I want structure crafting to tell me exactly what is required, what is blocked, and what changed so I can finish a structure without trial-and-error.

**Why this priority**: Structure-related flows are the hardest to understand once the player leaves the first tutorial moments. Clear feedback turns a brittle hidden-rule system into a readable progression step.

**Independent Test**: Can be validated with GUT coverage for blocked/success craft outcomes and manual in-editor checks for recipe previews, invalid states, and confirm/cancel behavior.

**Acceptance Scenarios**:

1. **Given** a valid structure recipe is assembled, **When** the player opens the craft panel, **Then** the panel shows the output, required inputs, and a readable preview state.
2. **Given** a structure recipe is invalid or incomplete, **When** the player confirms craft, **Then** the game shows one explicit blocking reason and one actionable hint.
3. **Given** a structure is unlocked only through Codex or discovery, **When** the player looks it up, **Then** the game shows a clue that points to the right in-game direction without requiring external documentation.
4. **Given** craft confirmation fails, **When** the failure is shown, **Then** no resources are consumed and the world state is unchanged.

### Edge Cases

- A returning player should not see the first-session guide again after completing it once.
- If guide state is missing or corrupted, the game should fail safely and prefer showing the guide rather than hiding core instructions.
- If the player switches modes while a guide step is active, the guide must stay in sync with the current state and not dead-end.
- If a structure preview is invalid, the game should explain why using one primary reason instead of a long list of competing errors.
- If accessibility options change text readability, guide and feedback overlays must remain legible on small screens.
- If the player skips onboarding, the rest of the game must remain playable and deterministic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST show a first-session guidance flow to a fresh profile during the first meaningful garden session.
- **FR-002**: The guidance flow MUST advance based on player actions and MUST be dismissible without blocking gameplay.
- **FR-003**: The guidance flow MUST teach the player the minimum set of core actions needed to understand the loop: place, mix/craft, and inspect progression.
- **FR-004**: The guidance flow MUST persist completion state separately from the garden save data.
- **FR-005**: Player-facing HUD labels, prompts, and feedback MUST use one consistent vocabulary for the same interaction across all visible surfaces.
- **FR-006**: Legacy or internal terminology MUST NOT appear in player-facing copy unless the term is intentionally retained as the approved label.
- **FR-007**: Structure crafting UI MUST show the output item, required inputs, and current preview state before the player confirms.
- **FR-008**: Blocked structure craft attempts MUST present one explicit blocking reason and one actionable corrective hint.
- **FR-009**: Successful and failed structure craft attempts MUST preserve deterministic state transitions and MUST not consume resources on failure.
- **FR-010**: Codex and in-world guidance for locked structures MUST be readable in-game and MUST not depend on external documentation.
- **FR-011**: The feature MUST preserve the permanent-emergence rule set and MUST not introduce undo or reset behavior into player flow.
- **FR-012**: The feature MUST remain usable on mobile layouts and MUST keep guidance and feedback within thumb-reachable UI regions where applicable.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Guidance overlays MUST not add noticeable startup delay or introduce a new long-loading path.
- **EX-002**: The feature MUST preserve deterministic garden behavior and MUST not change placement, discovery, or persistence rules outside the documented guidance and copy changes.
- **EX-003**: Any new overlays or UI text MUST remain readable under existing accessibility settings and small-screen layouts.
- **EX-004**: The first-session flow MUST be lightweight enough to coexist with the current mobile-first 60 fps budget.

### Key Entities *(include if feature involves data)*

- **FirstSessionGuideState**: Persistent per-profile state that tracks whether the onboarding flow has been completed and which step is active.
- **Guide Step**: A single actionable instruction in the first-session flow, tied to one player action or one visible explanation.
- **Mode Vocabulary Map**: The approved set of player-facing terms used by HUD buttons, prompts, and feedback text.
- **Structure Feedback Snapshot**: The current readable structure craft state, including output name, requirements, blocked reason, and confirmability.
- **Progression Hint**: Player-facing clue text for locked or undiscovered structure-related content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In fresh-profile playtests, at least 80% of players complete the first placement and first mix or craft step without external instruction.
- **SC-002**: In playtests, at least 80% of players can explain what the main visible modes do after one session using only in-game labels and prompts.
- **SC-003**: In acceptance checks, 100% of blocked structure craft attempts show one explicit reason and one corrective hint.
- **SC-004**: In acceptance checks, 100% of successful structure craft attempts show the correct output and required-input preview before confirmation.
- **SC-005**: In regression checks, returning profiles do not see the first-session guide after completion.
- **SC-006**: In manual validation, all guidance and feedback surfaces remain legible on the project’s mobile-oriented HUD layout.
