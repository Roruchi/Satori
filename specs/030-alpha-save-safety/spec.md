# Feature Specification: Alpha Save Safety

**Feature Branch**: `030-alpha-save-safety`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 4.

## Clarifications

- This spec owns save/load reliability for alpha-critical state across desktop, Web, and Android.
- It does not own Web packaging or Android export setup, but it provides their persistence gates.
- External alpha builds use zero-based SemVer with alpha prerelease and build metadata, displayed in the menu, for example `0.1.0-alpha+20260627.1`.
- Confirmed active projects are alpha-critical state. Reloading may not silently cancel, duplicate, or complete them.

## User Scenarios & Testing

### User Story 1 - Save Complete Alpha State (Priority: P1)

As a player, I can close and reopen the game without losing alpha-critical progress.

**Independent Test**: Save/load GUT round trips plus manual restart at multiple progression points.

**Acceptance Scenarios**:

1. **Given** first-session progress, **When** I save and reload, **Then** tiles, seeds, materials, spirit, and dwelling remain.
2. **Given** endgame progress, **When** I save and reload, **Then** Ku, Void-separated islands, Chi+Ku calm-water island state, Satori threshold, and Suijin state remain.

### User Story 2 - Autosave Safely (Priority: P1)

As a player, I do not need to manually save after every meaningful action.

**Independent Test**: GUT and manual lifecycle checks for autosave triggers.

**Acceptance Scenarios**:

1. **Given** a meaningful progress event, **When** autosave runs, **Then** a restart restores that event.
2. **Given** a write failure, **When** save fails, **Then** existing save data is not corrupted silently.

### User Story 3 - Version External Alpha Saves (Priority: P2)

As the developer, I can change saves after alpha starts without blindly breaking tester gardens.

**Independent Test**: Schema/version tests and manual migration guard review.

**Acceptance Scenarios**:

1. **Given** a saved alpha file, **When** it loads, **Then** its schema version is recognized.
2. **Given** an unsupported save, **When** load is attempted, **Then** the game reports the issue instead of corrupting state.

## Requirements

- **FR-001**: Save data MUST include alpha-critical tiles, seeds, materials, discoveries, spirits, houses, structures, Satori, unlocks, active projects, Void-separated islands, Chi+Ku calm-water island state, and Suijin invitation/presence state.
- **FR-002**: Saves MUST use atomic or corruption-resistant writes where the platform allows it.
- **FR-003**: Autosave MUST trigger on meaningful progress and app lifecycle events.
- **FR-004**: Save schema version MUST be stored and checked.
- **FR-005**: Load failure MUST be visible and non-destructive.
- **FR-006**: Save/load MUST preserve confirmed active project timers/progress without silent refund, cancellation, duplication, or instant completion.
- **FR-007**: Save metadata MUST include the build version in zero-based SemVer alpha format with build metadata.

### Experience & Runtime Constraints

- **EX-001**: Save/load MUST preserve irreversible world history.
- **EX-002**: Save failure messaging MUST fit mobile UI.
- **EX-003**: Cold start into playable state SHOULD target 10 seconds for alpha-scale saves.

### Key Entities

- **SaveSnapshot**: Serialized alpha-critical game state.
- **SaveVersion**: Schema identifier, migration guard, and producing build version.
- **AutosaveTrigger**: Event that requests save.

## Success Criteria

- **SC-001**: First-session, first-island, and endgame states round-trip through save/load.
- **SC-002**: Autosave preserves recent meaningful progress.
- **SC-003**: Unsupported or failed loads do not silently corrupt the garden.
