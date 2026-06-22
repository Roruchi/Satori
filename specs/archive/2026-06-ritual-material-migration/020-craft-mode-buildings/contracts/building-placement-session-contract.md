# Contract: Building Placement Session

## Purpose
Defines confirm/cancel placement behavior for inventory-selected building items.

## Scope Boundary
- This contract applies to building placement sessions only.
- Regular non-building tile placement remains immediate and does not use confirm/cancel.

## Entry Points
- Start session: player selects building inventory entry.
- Update preview: pointer/touch hover over candidate anchor tile.
- Commit action: explicit confirm or cancel.

## Validation Rules
- Compute full footprint tile set from selected building type and anchor.
- Placement is valid only when every footprint tile is:
  - in bounds,
  - placeable for structures,
  - not blocked by incompatible occupancy.

## Confirm Behavior
- Preconditions:
  - active session with valid footprint.
  - inventory has at least one matching building item count.
- Effects:
  - place structure across full footprint.
  - consume exactly one building item from selected stack.
  - if selected stack count reaches zero, remove stack.
  - close session.

## Cancel Behavior
- Effects:
  - close session.
  - do not mutate world tiles.
  - do not mutate inventory counts.

## Failure Behavior
- Invalid footprint on confirm:
  - placement blocked.
  - inventory unchanged.
  - session remains active with feedback.
