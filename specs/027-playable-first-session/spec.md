# Feature Specification: Playable First Session

**Feature Branch**: `027-playable-first-session`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 1.

## Clarifications

- This spec owns the first 10 minutes: title flow, first ritual, Meadow seed, First Bloom pacing, Living Wood, Red Fox, Warm Hollow, first dwelling, and automatic Red Fox housing.
- It may use existing systems, but completion requires current validation evidence.
- It does not own first island depth, Ku, Endgame island, platform export, or external tester packaging.

## User Scenarios & Testing

### User Story 1 - Start and Understand First Ritual (Priority: P1)

As a new player, I can start the game and understand how to perform the first ritual without external instructions.

**Independent Test**: Fresh save manual flow plus focused UI tests for title, ritual menu, and seed preview.

**Acceptance Scenarios**:

1. **Given** a fresh launch, **When** I start a new game, **Then** I reach the garden with a clear next action.
2. **Given** the ritual menu, **When** I select Wind/Fu, **Then** Meadow Seed is previewed and can be created.

### User Story 2 - Plant, Grow, and Harvest (Priority: P1)

As a new player, I can plant the first seed, watch it grow, and harvest the first material.

**Independent Test**: GUT coverage for seed growth/material harvesting plus manual first-session playthrough.

**Acceptance Scenarios**:

1. **Given** a Meadow Seed, **When** I plant it, **Then** a Meadow biome appears or grows through the intended path.
2. **Given** a mature Meadow, **When** material appears and I harvest it, **Then** Living Wood enters inventory.

### User Story 3 - Red Fox and First Dwelling (Priority: P1)

As a new player, I can invite or encounter Red Fox, create a valid first dwelling, and see Red Fox housed there automatically.

**Independent Test**: Focused spirit/structure tests and manual playthrough from fresh save through housed Red Fox.

**Acceptance Scenarios**:

1. **Given** early Meadow progress, **When** Red Fox appears, **Then** its need or housing state is visible.
2. **Given** Living Wood and Fire Essence, **When** I shape Warm Hollow and place it correctly, **Then** a valid dwelling exists.
3. **Given** Red Fox and a valid Meadow dwelling, **When** the dwelling is placed, **Then** Red Fox is housed automatically and the state is visible.

## Edge Cases

- The player opens the ritual menu before having enough inputs.
- The player tries to place the first seed in an invalid location.
- The player creates Warm Hollow but attempts invalid placement.
- The player places valid housing before noticing Red Fox's need state.
- The player closes and reloads mid-first-session.

## Requirements

### Functional Requirements

- **FR-001**: The first actionable ritual MUST be discoverable from the normal UI.
- **FR-002**: Wind/Fu MUST create or preview Meadow Seed in the alpha first-session path.
- **FR-003**: Meadow MUST produce the first Living Wood quickly through a normal-play First Bloom pacing rule, with visible growth feedback and no debug-only grants.
- **FR-004**: Red Fox MUST be the first spirit in the alpha path.
- **FR-005**: Living Wood plus Fire Essence MUST create Warm Hollow.
- **FR-006**: Warm Hollow MUST resolve into a valid Meadow dwelling on Meadow.
- **FR-007**: Red Fox MUST automatically become housed when a valid Meadow dwelling is placed.
- **FR-008**: The first-session path MUST survive save/load.

### Experience & Runtime Constraints

- **EX-001**: Placement feedback MUST respect irreversible world rules.
- **EX-002**: Ritual, pouch, placement, and feedback UI MUST be usable on mobile-like aspect ratios.
- **EX-003**: First-session validation MUST not rely on debug-only grants.

### Key Entities

- **FirstSessionStep**: The current expected player action.
- **StarterRitual**: Wind/Fu to Meadow Seed.
- **FirstBloom**: Non-debug first-session growth acceleration that gets the player to the first Living Wood quickly.
- **FirstDwelling**: Warm Hollow resolved into a Meadow dwelling with Red Fox automatically housed.

## Success Criteria

- **SC-001**: A fresh player can complete Meadow -> Living Wood -> Red Fox -> Warm Hollow -> Meadow dwelling -> housed Red Fox without external instructions.
- **SC-002**: No alpha-critical first-session UI overlaps or clips on a mobile-like viewport.
- **SC-003**: Focused GUT coverage validates ritual, pouch, First Bloom growth, harvest, structure placement, and Red Fox behavior.
