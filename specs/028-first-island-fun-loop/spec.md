# Feature Specification: First Island Fun Loop

**Feature Branch**: `028-first-island-fun-loop`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 2.

## Clarifications

- This spec starts after the first dwelling loop is possible.
- It owns repeatable first-island fun: Red Fox needs, explicit housing improvement through upgraded Fox Den, automatic migration, double Red Fox Satori generation, Satori feedback, Dew Bowl, Wind Chime, and valid/invalid project clarity.
- It does not own Ku unlock, Endgame island, or platform release.

## User Scenarios & Testing

### User Story 1 - Care About Spirits (Priority: P1)

As a player, I can see whether spirits are housed, restless, or supported by the island.

**Independent Test**: GUT coverage for spirit housing/Satori state plus manual hover/HUD validation.

**Acceptance Scenarios**:

1. **Given** an unhoused spirit, **When** time or state changes, **Then** the game communicates pressure clearly.
2. **Given** a housed spirit, **When** Satori evaluates, **Then** the positive state is visible or inferable.
3. **Given** Red Fox is housed, **When** I place the upgraded Fox Den, **Then** Red Fox migrates there automatically and grants double Red Fox Satori generation.

### User Story 2 - Build Useful Structures (Priority: P1)

As a player, I can choose and place Dew Bowl and Wind Chime beyond the first dwelling.

**Independent Test**: Structure ritual and placement tests plus manual project validation.

**Acceptance Scenarios**:

1. **Given** valid materials and essence, **When** I shape Dew Bowl, **Then** the form appears in inventory and has a visible storage/soothing purpose.
2. **Given** valid materials and essence, **When** I shape Wind Chime, **Then** the form appears in inventory and has a visible invitation/harvest purpose.

### User Story 3 - Understand Invalid Choices (Priority: P2)

As a player, I get actionable feedback when a ritual or structure project is invalid.

**Independent Test**: GUT tests for invalid rituals/projects and manual UI validation.

**Acceptance Scenarios**:

1. **Given** duplicate ritual slots, **When** I attempt a ritual, **Then** no output is created and feedback explains the duplicate rule.
2. **Given** an invalid structure project, **When** I confirm it, **Then** the project does not start and the feedback says what is missing.

## Edge Cases

- Multiple spirits compete for one house.
- Red Fox has basic housing but the upgraded Fox Den is not yet placed.
- A structure unlock appears before the player has enough context to use it.
- A player attempts a second project while one project is active.

## Requirements

### Functional Requirements

- **FR-001**: Red Fox housing state MUST be visible enough for a player to act.
- **FR-002**: Local Satori pressure and recovery MUST be understandable through immediate HUD feedback, hover/inspect detail, and Codex meaning.
- **FR-003**: Upgraded Fox Den MUST be explicit in the first-island loop as the first housing improvement for Red Fox.
- **FR-004**: When Fox Den is placed, Red Fox MUST migrate there automatically and grant double Satori generation for Red Fox only.
- **FR-005**: Dew Bowl MUST have a visible storage/soothing use in first-island play.
- **FR-006**: Wind Chime MUST have a visible invitation/harvest use in first-island play.
- **FR-007**: Duplicate ritual inputs MUST be rejected.
- **FR-008**: Invalid structure projects MUST be non-destructive and explain why they failed.
- **FR-009**: Save/load MUST preserve active spirits, houses, upgraded Fox Den migration, Red-Fox-only double Satori generation state, helper structures, Satori, materials, and discoveries.

### Experience & Runtime Constraints

- **EX-001**: Irreversible project confirmation MUST be explicit.
- **EX-002**: Structure and spirit feedback MUST be readable on mobile-like viewport.
- **EX-003**: Housing and Satori recomputes MUST remain performant for alpha-scale islands.

### Key Entities

- **IslandLoopState**: First-island spirit, Satori, and structure state.
- **FoxDen**: Upgraded Red Fox housing that automatically attracts Red Fox and grants double Satori generation for Red Fox only.
- **DewBowl**: Early storage/soothing helper structure.
- **WindChime**: Early invitation/harvest helper structure.
- **InvalidActionFeedback**: Non-destructive explanation for failed rituals or projects.

## Success Criteria

- **SC-001**: A player can keep one island stable through Red Fox housing, Fox Den migration with Red-Fox-only double Satori generation, and helper structure interactions.
- **SC-002**: Fox Den, Dew Bowl, and Wind Chime all change play or feedback in visible ways.
- **SC-003**: Invalid rituals and invalid projects are understandable and do not cause hidden irreversible mistakes.
