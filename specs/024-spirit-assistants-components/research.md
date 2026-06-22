# Research: Spirit Happiness, Ritual Assistants and Components

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## 1. Mood as Relationship State

**Decision**: Model mood as persistent relationship state on each spirit instance, derived first from housing and later from biome fit, comfort structures and island state.

**Rationale**: Current code already computes housing. Mood should build on that rather than replacing housing assignment.

**Alternatives Considered**:

- Make every housed spirit immediately assistant-ready. Rejected because it removes the care/happiness progression.

## 2. Assistant Availability

**Decision**: A spirit becomes selectable only when assistant-ready and the assistant feature gate is unlocked.

**Rationale**: Assistants are later progression. This keeps the first ten minutes simple while giving happy spirits a clear future role.

**Alternatives Considered**:

- Allow any visible spirit to assist. Rejected because restless/unhoused spirits would become resources.

## 3. Elemental Intent from Spirits

**Decision**: Spirit definitions expose assistant element tags. Red Fox counts as Fire; Hare supports Meadow/Earth shelter paths.

**Rationale**: The master plan says a spirit assistant counts as embodied elemental intent and may replace or resonate with essence in advanced rituals.

**Alternatives Considered**:

- Require spirits plus matching essence for all rituals. Rejected because some advanced rituals should let a spirit carry intent.

## 4. Component Availability

**Decision**: Components are stable ritual input identities that may be available through discovery, inventory, symbolic memory or a placed structure.

**Rationale**: The master plan says a component is not always a separate inventory item. This avoids making endgame about stockpiles.

**Alternatives Considered**:

- Make every component a material-like inventory stack. Rejected because placed structures and memories would lose meaning.

## 5. Confirm-Time Revalidation

**Decision**: Ritual confirmation rechecks assistant and component availability even if preview succeeded.

**Rationale**: Spirit mood, housing and placed structure context can change between preview and confirm.

**Alternatives Considered**:

- Trust preview state. Rejected because it can consume resources or create discoveries based on stale context.
