# Feature Specification: Spirit Happiness, Ritual Assistants and Components

**Feature Branch**: `024-spirit-assistants-components`
**Created**: 2026-06-22
**Status**: Draft
**Input**: User description: "Happier spirits, spirits as assistants in ritual, and using components in rituals."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Spirits Become Happier Through Care (Priority: P1)

As a player, I want spirits to move from visiting or restless into housed and happy states so that caring for spirits matters beyond simple housing assignment.

**Why this priority**: Assistant rituals should be earned by relationship and care, not by treating spirits as inventory.

**Independent Test**: Can be validated with GUT coverage for mood transitions and manual in-editor checks for Red Fox and Hare housing/comfort feedback.

**Acceptance Scenarios**:

1. **Given** Red Fox is visiting and a valid Meadow Dwelling exists on the same island, **When** housing assignment updates, **Then** Red Fox becomes housed.
2. **Given** a housed spirit's biome and comfort needs are met for the configured duration, **When** mood evaluates, **Then** the spirit can become happy.
3. **Given** a spirit remains unhoused too long, **When** mood evaluates, **Then** the spirit becomes restless and may lower local Satori.

---

### User Story 2 - Happy Spirits Assist Rituals (Priority: P2)

As a player, I want a happy or assistant-ready spirit to help a ritual without being consumed so that spirits feel alive and meaningful.

**Why this priority**: The master plan explicitly says spirits are assistants, not resources, and occupy one ritual slot later in progression.

**Independent Test**: Can be validated with GUT coverage for assistant availability, no-consumption behavior and ritual resolution with Red Fox or Hare.

**Acceptance Scenarios**:

1. **Given** Red Fox is happy and assistant-ready, **When** the player opens the ritual menu, **Then** Red Fox appears as an available assistant input.
2. **Given** Red Fox assists a ritual, **When** the ritual succeeds, **Then** Red Fox remains active, housed and available according to cooldown rules.
3. **Given** a spirit is restless or not housed, **When** the ritual menu lists assistants, **Then** that spirit is unavailable or shown with a clear reason.
4. **Given** a player tries to add the same spirit assistant twice, **When** the second selection is attempted, **Then** duplicate-slot rules block it.

---

### User Story 3 - Components Unlock Deeper Rituals (Priority: P3)

As a player, I want discovered or placed structures to become ritual components so that later recipes use meaningful forms instead of large material stacks.

**Why this priority**: Components are how the endgame scales without grind. They also connect early structures like Wind Chime and Tiny Shrine to future discoveries.

**Independent Test**: Can be validated with GUT coverage for component availability and ritual resolution; manual Codex review confirms components are explained after discovery.

**Acceptance Scenarios**:

1. **Given** Wind Chime is discovered or placed, **When** component availability is evaluated, **Then** Wind Chime can appear as a component input if its progression gate is unlocked.
2. **Given** a component + essence + spirit ritual is valid, **When** the player confirms it, **Then** the result is produced without consuming the spirit.
3. **Given** a component requires a placed structure, **When** the structure is not placed on the relevant island, **Then** the ritual is blocked with a context hint.

---

### User Story 4 - Preserve the First Expansion Loop (Priority: P1)

As a player, I want the migration to rituals and materials to preserve the existing expansion arc so I can still get spirits, build houses, unlock Mist Stag, unlock Ku and start a second island with new spirits.

**Why this priority**: This is the end-to-end proof that the new direction did not break the current game. Ritual assistants and components are not successful if the playable spirit/island loop collapses.

**Independent Test**: Can be validated through a manual in-editor 10-minute flow with optional debug time acceleration plus automated regression coverage for the critical state transitions.

**Acceptance Scenarios**:

1. **Given** a fresh garden, **When** the player creates Meadow and grows the opening ecosystem, **Then** spirits still appear from current or migrated triggers.
2. **Given** a Meadow spirit appears, **When** the player creates and places a valid dwelling, **Then** the spirit can be housed.
3. **Given** the player reaches the Mist Stag trigger condition, **When** the trigger resolves, **Then** Mist Stag appears and can still unlock Ku.
4. **Given** Ku is unlocked, **When** the player performs the island-starting path, **Then** a second island can be started.
5. **Given** the second island has valid biome/spirit conditions, **When** discovery scans run, **Then** new island-local spirits can appear there.

### Edge Cases

- Spirits are never consumed by rituals.
- A spirit assistant counts as one ritual slot and must obey no-duplicate rules.
- Component inputs must have stable identities and must not collide with material or structure IDs.
- A placed component requirement must be island-local when the recipe says so.
- If a spirit despawns, is dormant or becomes unhappy during a ritual preview, confirmation revalidates and may fail non-destructively.
- If a component is symbolic rather than inventory-based, preview must still make availability clear.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Spirits MUST have a mood/state model that can represent visiting, housed, happy, restless, unhappy, dormant, elder and assistant-ready states.
- **FR-002**: Mood evaluation MUST consider housing status at minimum.
- **FR-003**: Mood evaluation SHOULD consider preferred biome, local island context and relevant comfort structures as data becomes available.
- **FR-004**: Housed and happy spirits MUST improve or support local Satori according to existing Satori service rules or a planned extension.
- **FR-005**: Restless or unhappy spirits MUST be able to reduce local Satori or produce a warning state.
- **FR-006**: Assistant-ready spirits MUST appear as selectable ritual inputs after the assistant feature gate is unlocked.
- **FR-007**: Spirit assistants MUST never be consumed by ritual success or failure.
- **FR-008**: Spirit assistants MUST occupy one ritual slot and obey the no-duplicate input rule.
- **FR-009**: Red Fox MUST be able to count as Fire intent for assistant ritual matching.
- **FR-010**: Hare MUST be able to support Meadow/Earth shelter paths such as Hare Hollow.
- **FR-011**: Discovered or placed structures MUST be representable as component inputs.
- **FR-012**: Components MUST support both symbolic availability and placed-on-island requirements.
- **FR-013**: Component rituals MUST avoid large stack costs and prefer meaningful context, Satori, placement or spirit state requirements.
- **FR-014**: Ritual confirmation with assistants/components MUST revalidate current spirit and component availability.
- **FR-015**: The implementation MUST keep `specs/master/recipes.md` synchronized if assistant or component unlocks change.
- **FR-016**: The feature MUST preserve current or migrated spirit discovery for early Meadow spirits.
- **FR-017**: The feature MUST preserve current or migrated housing assignment for Red Fox, Hare and other Meadow-preferred spirits.
- **FR-018**: The feature MUST preserve the Mist Stag unlock path or replace it with a documented ritual/material path that still grants Ku.
- **FR-019**: The feature MUST preserve the ability to unlock Ku and start a second island.
- **FR-020**: The feature MUST preserve island-local spirit spawning on the second island after it is created.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Spirit mood feedback MUST be readable without overwhelming the garden view.
- **EX-002**: Assistant selection MUST remain mobile-usable within the three-slot ritual menu.
- **EX-003**: Mood evaluation MUST be batched or event-driven and must not scan all spirits every frame.
- **EX-004**: Spirit state changes must persist and restore safely across save/load.

### Key Entities *(include if feature involves data)*

- **SpiritMoodState**: Persistent state and timers for each active spirit.
- **AssistantAvailability**: Derived view describing whether a spirit may be selected for rituals and why.
- **AssistantInputIdentity**: Ritual input identity for one spirit assistant.
- **ComponentDefinition**: Data describing a symbolic, inventory or placed-structure component.
- **ComponentAvailability**: Derived view of whether a component is usable in the current ritual context.
- **ComponentRitualRule**: Ritual definition using component, essence and optional spirit assistant inputs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Red Fox and Hare can both be housed through Meadow Dwelling or its variants without making Fox Den the only Meadow house.
- **SC-002**: 100% of assistant ritual tests confirm spirits are not consumed.
- **SC-003**: Restless/happy mood transitions are deterministic and persist through save/load.
- **SC-004**: At least one component ritual can be previewed and resolved through the same three-slot ritual menu.
- **SC-005**: Ritual confirmation fails safely if assistant or component availability changes after preview.
- **SC-006**: End-to-end playtest reaches Meadow spirit invitation, valid housing, Mist Stag, Ku unlock, second island creation and at least one new spirit on the second island.
