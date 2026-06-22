# Data Model: Phase 1 Seed Crafting in 3x3 Grid

**Branch**: `019-seed-crafting-grid` | **Date**: 2026-03-31 | **Spec**: [spec.md](spec.md)

## CraftGridSlot

Represents one slot in the 3x3 crafting grid.

Fields:
- `slot_index: int` (0..8)
- `token: String` (`""` for empty, otherwise one of `CHI|SUI|KA|FU|KU`)

Validation:
- Exactly 9 slots exist.
- Slot token cardinality is 0 or 1.

## CraftGridState

Current player input for a craft attempt.

Fields:
- `slots: Array[CraftGridSlot]` (length 9)

Derived views:
- `occupied_tokens: Array[String]` (non-empty tokens in slot order)
- `occupied_slot_indices: Array[int]`

Validation:
- `slots.size() == 9`
- Each occupied token must be a known element token.

## SeedRecipeDefinition

Phase 1 seed mapping definition.

Fields:
- `recipe_id: String`
- `input_tokens: Array[String]` (length 1 or 2)
- `normalized_key: String` (canonicalized key for position-insensitive matching)
- `output_seed_id: String`
- `requires_ku_unlock: bool`

Validation:
- Length of `input_tokens` is 1 or 2.
- `normalized_key` is unique for Phase 1 seed recipes.
- Ku-containing recipes set `requires_ku_unlock = true`.

## SeedRecipeCatalogPhase1

Authoritative recipe set for this feature.

Fields:
- `single_token_recipes: Dictionary[String, SeedRecipeDefinition]`
- `dual_token_recipes: Dictionary[String, SeedRecipeDefinition]`

Validation:
- Contains all FR-005 and FR-006 mappings.
- Contains no structure/house recipes.

## CraftAttemptContext

Inputs used for one craft confirmation.

Fields:
- `grid_state: CraftGridState`
- `unlock_state: Dictionary` (includes Ku unlock)
- `inventory_state: Dictionary` (plant inventory capacity + availability)

Validation:
- Context snapshot is read before commit.
- Unlock and capacity checks run before token consumption.

## CraftAttemptResult

Deterministic craft outcome contract.

Fields:
- `outcome: String` (`success|empty_input|no_matching_seed_recipe|locked_element|inventory_full`)
- `matched_recipe_id: String` (empty on non-match)
- `output_seed_id: String` (empty on non-success)
- `consumed_slot_indices: Array[int]`
- `feedback_message_key: String`

Validation:
- `success` requires exactly one output seed and at least one consumed slot.
- `inventory_full` requires valid recipe match but no output and no consumed slots.
- Non-success outcomes must keep grid tokens unchanged.

## PlantInventoryMutation

Commit step for successful craft only.

Fields:
- `output_seed_id: String`
- `quantity_delta: int` (always `+1` in this phase)
- `commit_succeeded: bool`

Validation:
- Commit succeeds before token consumption/slot clearing.
- Quantity delta is exactly `+1` for each successful attempt.

## State transitions

1. **Input Assembly**: `CraftGridState` from 9 UI slots.
2. **Resolution**: canonicalize `occupied_tokens`; lookup in `SeedRecipeCatalogPhase1`.
3. **Gate Checks**: verify Ku unlock when required.
4. **Capacity Check**: verify plant inventory has space for one output seed.
5. **Commit (success path only)**:
   - Add output seed to plant inventory.
   - Consume recipe tokens.
   - Clear consumed grid slots.
6. **Blocked path (inventory full)**:
   - Return `inventory_full` result.
   - Preserve all in-grid tokens and slot occupancy.
