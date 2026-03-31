# Contract: Seed Crafting Attempt (Phase 1)

## Purpose

Define deterministic craft-attempt semantics for 3x3 grid seed crafting in Phase 1, including recipe scope, success conditions, failure outcomes, token-consumption ordering, inventory-full behavior, and UI feedback expectations.

## Scope contract

1. Recipe evaluation includes only Phase 1 seed recipes.
2. Supported input cardinalities are exactly 1 token and 2 tokens.
3. Inputs with 0 tokens, 3+ tokens, or non-seed legacy structure combinations are non-matching for this phase.
4. Structure recipes, house recipes, placement outputs, and migration paths are out of scope.

## Input normalization contract

1. Craft attempt reads all 9 slots.
2. Empty slots are ignored for recipe-key creation.
3. Token order is canonicalized so dual-token matches are position-insensitive.
4. Canonicalized keys must resolve identically regardless of slot indices.

## Outcome contract

Possible outcomes:
- `success`
- `empty_input`
- `no_matching_seed_recipe`
- `locked_element`
- `inventory_full`

Rules:
1. `success` requires a valid recipe, unlock eligibility, and available plant inventory capacity.
2. Non-success outcomes must not produce output seeds.
3. Every outcome must provide a user-facing feedback message key.

## Consumption and mutation ordering contract

Operation sequence is authoritative:

1. Resolve seed recipe from normalized grid input.
2. Validate unlock gate (Ku requirement where applicable).
3. Validate plant inventory capacity for exactly one output item.
4. Insert one output seed into plant inventory.
5. Only after successful insert, consume recipe tokens and clear consumed slots.

Implications:
- Tokens are consumed only on successful craft.
- Successful craft clears only consumed slots.
- Failed craft attempts leave grid tokens unchanged.

## Inventory-full contract

For a valid recipe when plant inventory is full:

1. Craft completion is blocked.
2. No output seed is created.
3. No tokens are consumed.
4. All recipe tokens remain in their current grid slots.
5. Inventory-full feedback is shown.

## Determinism contract

1. Identical grid token content, unlock state, and inventory capacity must always produce the same outcome.
2. Slot positions must not influence one-token or two-token recipe resolution.
3. Success always produces exactly one output seed item.

## Mobile interaction contract

1. Each interactive grid slot must expose a minimum touch target of 48x48 px.
2. Touch target compliance applies regardless of visual styling.
