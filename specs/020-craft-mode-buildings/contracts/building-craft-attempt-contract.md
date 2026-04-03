# Contract: Building Craft Attempt

## Purpose
Defines deterministic outcomes for building crafting from the 3x3 craft grid.

## Entry Point
- Caller: `SeedAlchemyPanel` (or successor craft UI).
- Service: `SeedAlchemyServiceNode` building-craft attempt API.
- Input:
  - `slot_tokens: Array[int]` length 9.

## Preconditions
- Grid normalization is applied before pattern lookup.
- Only patterns with occupied count >= 3 qualify as building recipe candidates.

## Outcome Contract

### `success`
- Conditions:
  - valid building pattern match.
  - inventory insertion succeeds via one of:
    - add to existing exact-type stack below 99.
    - create new same-type stack in free slot when existing stack at 99.
    - create first stack in free slot.
- Effects:
  - consumes required input tokens.
  - emits craft-success feedback.
  - emits discovery signal only if first successful craft for recipe.

### `inventory_full`
- Conditions:
  - valid building pattern match.
  - no insertion path available (all 8 slots occupied, or only exact-type stacks already 99 and no free slot).
- Effects:
  - no token consumption.
  - no discovery unlock.
  - emits inventory-full feedback.

### `no_match`
- Conditions:
  - normalized input does not match known building or seed recipe under active mode scope.
- Effects:
  - no token consumption.

## Invariants
- Building stacks must never exceed 99.
- Different building types never cohabit one stack.
- Failed attempts are non-destructive.
