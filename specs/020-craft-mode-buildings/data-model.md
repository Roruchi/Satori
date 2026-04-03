# Data Model: Craft Mode Building Placement

## Entity: BuildingRecipePattern
- Purpose: Defines a craftable grid arrangement that outputs a building inventory item.
- Fields:
  - `recipe_id: StringName`
  - `normalized_tokens: Array[int]` (pattern key from 3x3 grid)
  - `occupied_slot_count: int` (must be >= 3)
  - `building_type_key: StringName`
  - `footprint_id: StringName`
  - `discovery_entry_id: StringName`
- Validation rules:
  - `occupied_slot_count >= 3`
  - `building_type_key` must map to exactly one footprint definition
  - `normalized_tokens` must be canonicalized before lookup

## Entity: BuildingDiscoveryState
- Purpose: Tracks whether a building recipe pattern has been discovered.
- Fields:
  - `discovered: Dictionary[StringName, bool]`
  - `first_discovered_at` (optional timestamp for telemetry/debug)
- Validation rules:
  - Discovery is recorded only on successful craft output.
  - Failed craft due to full inventory does not update discovery.

## Entity: InventorySlot
- Purpose: Shared inventory entry that may hold plant recipes or building stacks.
- Fields:
  - `entry_kind: StringName` (`plant_recipe` or `building_item`)
  - `type_key: StringName` (recipe id or building type key)
  - `count: int`
  - `stack_cap: int` (for building stacks fixed at 99)
- Validation rules:
  - Shared inventory has exactly 8 slots.
  - Building items stack only with exact matching `building_type_key`.
  - Building stack count must satisfy `1 <= count <= 99`.

## Entity: BuildingPlacementSession
- Purpose: Temporary state while player previews and confirms/cancels placement.
- Fields:
  - `active: bool`
  - `building_type_key: StringName`
  - `anchor_coord: Vector2i`
  - `footprint_tiles: Array[Vector2i]`
  - `is_valid: bool`
  - `invalid_reason: StringName`
- Validation rules:
  - Session can confirm only when `is_valid == true`.
  - Cancel exits session without world or inventory mutation.
  - Confirm consumes one building item and commits structure tiles.

## Entity: BuildingFootprint
- Purpose: Defines local tile offsets occupied by a building type.
- Fields:
  - `footprint_id: StringName`
  - `offsets: Array[Vector2i]`
  - `size_class: StringName` (`single_tile` or `multi_tile`)
- Validation rules:
  - `offsets` must be non-empty.
  - `single_tile` requires exactly one offset `(0,0)`.

## State Transitions

### Craft Attempt
1. `GridInputSubmitted` -> normalize slots.
2. `PatternMatched` or `NoMatch`.
3. If matched: check inventory insertion route.
4. `CraftSucceeded`:
   - output added to matching stack, or new stack when free slot exists, respecting cap 99.
   - ingredients consumed.
   - discovery recorded if first successful craft.
5. `CraftFailedInventoryFull`:
   - no ingredient consumption.
   - no discovery update.

### Placement Session
1. `Idle` -> player selects building item from inventory.
2. `Previewing` -> candidate anchor/footprint evaluated continuously.
3. `Confirm` (valid footprint only): world updated and one building item consumed.
4. `Cancel`: return to idle with no mutation.
