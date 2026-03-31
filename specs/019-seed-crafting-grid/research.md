# Research: Phase 1 Seed Crafting in 3x3 Grid

**Branch**: `019-seed-crafting-grid` | **Date**: 2026-03-31 | **Spec**: [spec.md](spec.md)

## 1. Recipe-key normalization from 3x3 inputs

**Decision**: Normalize craft inputs by collecting non-empty tokens from the 3x3 grid, rejecting counts outside `{1,2}`, and building an order-independent key for matching (single token key for count 1, sorted two-token key for count 2).

**Rationale**: Position-insensitive behavior (FR-004) is guaranteed when recipe resolution depends only on token multiset content, not slot indices.

**Alternatives considered**:
- Evaluate recipes against all slot permutations: rejected due to unnecessary complexity and higher maintenance cost.
- Store slot-position-aware recipes: rejected because this phase explicitly requires forgiving position-insensitive matching.

## 2. Craft operation ordering (consume-on-success)

**Decision**: Use a strict attempt sequence: resolve recipe -> validate unlock gates -> validate plant inventory capacity -> commit output insert -> then consume recipe tokens and clear consumed slots.

**Rationale**: This ordering enforces clarified decisions and FR-009/FR-010/FR-011 exactly. No token removal happens unless craft completion is successful.

**Alternatives considered**:
- Consume tokens before inventory insert attempt: rejected because full inventory could destroy player inputs without output.
- Consume tokens on any valid recipe regardless of completion: rejected because requirement states consumption only on successful craft.

## 3. Inventory-full valid-recipe handling

**Decision**: Treat inventory-full for an otherwise valid recipe as a blocked completion outcome, with no output created, no token consumption, no slot clearing, and explicit inventory-full feedback.

**Rationale**: Matches clarified decision #2 and FR-011 while preserving player intent and preventing silent loss.

**Alternatives considered**:
- Auto-drop output into world or overflow queue: rejected as out of current inventory contract scope.
- Allow craft and discard output: rejected because it is non-transparent and destructive.

## 4. Seed-only phase boundary and legacy compatibility

**Decision**: Resolver scope for this feature includes only the Phase 1 seed recipe map (single/dual token seeds). Any legacy structure/house combinations are categorized as non-matching seed input.

**Rationale**: Keeps implementation aligned with explicit out-of-scope boundaries and avoids accidental migration coupling.

**Alternatives considered**:
- Add dual routing to structure crafting in same flow: rejected because migration is explicitly deferred.
- Soft-deprecate legacy flows in this phase: rejected as premature scope expansion.

## 5. Mobile slot touch target requirement

**Decision**: Each interactive crafting slot will provide a minimum effective hit area of 48x48 px through control sizing and/or explicit touch area expansion in UI scene/script definitions.

**Rationale**: Satisfies EX-003 and aligns with mobile ergonomics targets in the constitution.

**Alternatives considered**:
- Keep existing slot sizes and rely on visual scale only: rejected because visual size does not guarantee touch hit area.
- Defer mobile hit-area pass to later polish: rejected because requirement is mandatory for this phase.
