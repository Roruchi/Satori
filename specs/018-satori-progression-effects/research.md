# Research: Satori Progression & Architectural Effects

**Branch**: `018-satori-progression-effects` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)

## 1. Minute-tick Satori math ordering

**Decision**: Compute minute delta as `housed_count - (unhoused_count * 2)`, apply all active structure modifiers within the same deterministic tick, then clamp final result to `[0, current_cap]`.

**Rationale**: This matches RFC technical details and ensures boundary behavior is predictable under mixed positive/negative influence.

**Alternatives considered**:
- Clamp before applying structure effects: rejected because it can hide expected bonuses/penalties.
- Multiple staggered sub-ticks: rejected as unnecessary complexity for a 60-second cadence.

## 2. Era transition authority and signaling

**Decision**: Evaluate era whenever Satori changes and emit `era_changed(new_era)` only when derived era differs from previous era.

**Rationale**: Single-source era derivation avoids duplicate transitions and keeps gate logic idempotent when values change but remain in the same range.

**Alternatives considered**:
- Poll era every frame: rejected for waste and possible duplicate event storms.
- Fire era signal every tick regardless of change: rejected due to noisy downstream behavior.

## 3. Unique monument enforcement point

**Decision**: Block unique monument confirmation before Bell appears/confirmation finalizes by querying active built count for that structure ID.

**Rationale**: RFC explicitly requires pre-confirmation prevention with red highlight/blocked feedback, and this minimizes invalid state transitions.

**Alternatives considered**:
- Allow Bell then fail on confirm: rejected because RFC asks to prevent Bell appearance when unique already exists.
- Allow build then auto-dissolve post-build: rejected as unclear UX and higher rollback complexity.

## 4. Data extension strategy for structures

**Decision**: Extend existing structure/pattern resource metadata with uniqueness and progression-related effect descriptors instead of introducing a parallel structure schema.

**Rationale**: The codebase is already data-driven via pattern/catalog resources; extending existing fields minimizes migration risk.

**Alternatives considered**:
- New standalone structure database singleton: rejected as over-architecture.
- Hardcoded switch tables in service scripts only: rejected as brittle and harder to scale.

## 5. Tier effect modeling approach

**Decision**: Represent tier contributions and effects as explicit catalog metadata tied to discovered/built structure instances; apply island/localized effects through existing island/spirit context references.

**Rationale**: This keeps source-of-truth with content resources and allows test coverage to verify effect behavior per structure type.

**Alternatives considered**:
- Tier-only generic effects without per-structure identity: rejected because RFC defines structure-specific behavior.
- Pure UI-only era/effect simulation: rejected because progression must alter gameplay outcomes.
