# Feature Specification: Alpha Endgame Kami Spine

**Feature Branch**: `029-alpha-endgame-kami-spine`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 3.

## Clarifications

- This is the alpha finale: Mist Stag gates Ku, Ku Seed places Void that separates islands, and Suijin is invited by placing the Chi+Ku biome on a qualifying calm water island.
- A qualifying Suijin island has at least 10 water tiles, no fire-based tiles, local Satori 1000, and the Chi+Ku biome placed on that island.
- This spec excludes the full kami roster, restoration endgame, and broad spirit assistant system.

## User Scenarios & Testing

### User Story 1 - Unlock Ku Fairly (Priority: P1)

As a player, I can reach Ku through a readable milestone rather than a random unlock.

**Independent Test**: GUT tests for era gating, Mist Stag/Ku unlock, and locked Ku recipe behavior.

**Acceptance Scenarios**:

1. **Given** the player is too early, **When** Mist Stag conditions are checked, **Then** it cannot spawn.
2. **Given** the player reaches the intended condition, **When** Mist Stag grants Ku, **Then** Ku becomes available and persists.

### User Story 2 - Separate Islands With Void (Priority: P1)

As a player with Ku unlocked, I can create Ku Seed, place Void, and use Void to separate islands through normal play.

**Independent Test**: Focused island-state tests plus manual playthrough from Ku unlock to Void-separated islands.

**Acceptance Scenarios**:

1. **Given** Ku is unlocked, **When** I shape and place Ku Seed, **Then** Void is placed.
2. **Given** placed Void, **When** island membership is evaluated, **Then** Void separates islands and the separation persists.

### User Story 3 - Invite One Kami (Priority: P1)

As a player on a calm water island, I can place the Chi+Ku biome under the right conditions and see Suijin arrive.

**Independent Test**: GUT condition tests plus full manual fresh-save playthrough to Suijin invitation.

**Acceptance Scenarios**:

1. **Given** an island with fewer than 10 water tiles, any fire-based tile, or Satori below 1000, **When** the Chi+Ku biome is placed, **Then** Suijin does not arrive.
2. **Given** an island with at least 10 water tiles, no fire-based tiles, and Satori 1000, **When** the Chi+Ku biome is placed there, **Then** Suijin appears once and persists.

## Edge Cases

- Ku is unlocked, saved, and reloaded before placing Void.
- Void is placed between tiles that previously belonged to one island.
- The player places Chi+Ku on a water-rich island that still has one fire-based tile.
- The player reaches Satori 1000 without 10 water tiles.
- The Suijin condition is satisfied twice.

## Requirements

### Functional Requirements

- **FR-001**: Mist Stag MUST prevent Ku from unlocking too early.
- **FR-002**: Ku unlock MUST persist and unlock Ku Seed and Chi+Ku seed behavior.
- **FR-003**: Ku Seed MUST place Void.
- **FR-004**: Placed Void MUST separate islands.
- **FR-005**: Chi+Ku seed MUST create the required Suijin-invitation biome.
- **FR-006**: Suijin MUST require the Chi+Ku biome to be placed on an island with at least 10 water tiles, no fire-based tiles, and local Satori 1000.
- **FR-007**: Suijin MUST arrive visibly, only once per eligible island state, and persist after restart.
- **FR-008**: Non-qualifying islands MUST NOT accidentally satisfy the alpha finale.

### Experience & Runtime Constraints

- **EX-001**: Void and Chi+Ku placement MUST respect irreversible placement/world-state rules.
- **EX-002**: Ku and kami guidance MUST be readable in normal UI/Codex on mobile-like layouts.
- **EX-003**: Pattern and invitation checks MUST remain performant for alpha-scale gardens.

### Key Entities

- **KuUnlockState**: Player access to Ku recipes and charges.
- **VoidTile**: Ku-created separator that splits island membership.
- **CalmWaterIsland**: Island with at least 10 water tiles, no fire-based tiles, and Satori 1000.
- **SuijinInvitation**: Chi+Ku biome placement, arrival, and persistence record for Suijin.

## Success Criteria

- **SC-001**: A fresh-save playthrough can unlock Ku, place Void, create a qualifying calm water island, place the Chi+Ku biome, and invite Suijin without debug tools.
- **SC-002**: Ku, Void-separated island state, Chi+Ku biome placement, and Suijin persist across restart.
- **SC-003**: Suijin cannot be invited from the wrong island scope or duplicated by repeated scans.
