# Data Model: Ritual Menu and Slot-Based Creation

**Branch**: `022-ritual-menu-slots` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## RitualInputIdentity

Canonical identity for one selectable ritual input.

Fields:

- `kind: StringName` (`essence|material|component|spirit`)
- `id: StringName` (`fire`, `living_wood`, `warm_hollow`, `spirit_red_fox`)
- `element_tags: Array[int]`
- `display_name: String`
- `unlocked: bool`
- `available_count: int` for consumable inputs; spirits/components that are not consumed may expose `1` when available

Derived:

- `identity_key: String` formatted as `<kind>:<id>`

Validation:

- `kind` must be one of the allowed values.
- `identity_key` must be stable across sessions.
- A ritual attempt cannot contain the same `identity_key` twice.

## RitualSlot

One selected ritual input in the menu.

Fields:

- `slot_index: int` (`0..2`)
- `input_key: String`

Validation:

- Exactly three slot positions may exist in UI state.
- Empty slots use an empty input key.
- Filled slots must reference available `RitualInputIdentity` data.

## RitualAttempt

Snapshot used for preview and confirmation.

Fields:

- `slots: Array[RitualSlot]`
- `normalized_keys: Array[String]`
- `context: RitualContext`

Validation:

- At least one filled slot is required.
- At most three filled slots are allowed.
- At least one filled slot must be `kind = essence`.
- `normalized_keys` are sorted and unique.
- Duplicate keys produce `duplicate_input` before any catalog lookup.

## RitualContext

Optional context used by advanced or placement-aware rituals.

Fields:

- `island_id: String`
- `target_coord: Vector2i`
- `target_biome: int`
- `nearby_spirit_ids: Array[String]`
- `active_spirit_ids: Array[String]`
- `satori_state: Dictionary`
- `unlocked_ids: Dictionary`

Validation:

- Context may be empty for simple seed and early form rituals.
- Placement context is evaluated at placement time, not at initial form discovery time.

## RitualRecipeDefinition

Data-driven rule for a ritual result.

Fields:

- `ritual_id: StringName`
- `input_keys: Array[String]`
- `result_id: StringName`
- `result_kind: StringName` (`seed|form|component|hint|memory|state`)
- `requires_unlocked_ids: Array[StringName]`
- `requires_context: Dictionary`
- `consume_input_keys: Array[String]`
- `codex_entry_id: StringName`
- `fallback_result_id: StringName`

Validation:

- `input_keys` must be unique.
- `input_keys` must include at least one essence.
- `consume_input_keys` must be a subset of `input_keys`.
- One normalized key may map to multiple context-gated definitions only if priorities are deterministic.

## RitualAttemptResult

Outcome returned from preview or confirm.

Fields:

- `outcome: StringName` (`success|empty_input|duplicate_input|missing_essence|locked_input|no_match|inventory_full|context_blocked`)
- `feedback_key: StringName`
- `guidance: String`
- `ritual_id: StringName`
- `result_kind: StringName`
- `result_id: StringName`
- `consumed_input_keys: Array[String]`
- `discovered_id: StringName`

Validation:

- `success` requires a non-empty `result_id`.
- Failure outcomes must have empty `consumed_input_keys`.
- `inventory_full` requires a matched ritual whose output could not be inserted.

## PlaceableForm

Inventory item or symbolic form created by a ritual before placement.

Fields:

- `form_id: StringName` (`warm_hollow`)
- `display_name: String`
- `default_structure_id: StringName`
- `placement_rules: Array[FormPlacementRule]`
- `footprint_id: StringName`

Validation:

- A form can be placed only on existing biome tiles.
- The final structure ID is resolved at placement confirmation.

## FormPlacementRule

Context rule for final structure identity.

Fields:

- `form_id: StringName`
- `priority: int`
- `requires_biome_tags: Array[StringName]`
- `requires_spirit_id: StringName`
- `result_structure_id: StringName`
- `codex_entry_id: StringName`

Initial Warm Hollow rules:

- `warm_hollow` on Meadow -> `meadow_dwelling`
- `warm_hollow` on Fire/Hearth -> `scorched_hollow`
- `warm_hollow` with Red Fox context -> Fox Den path
- `warm_hollow` with Hare context -> Hare Hollow path

Validation:

- Rule priority must be deterministic.
- If no special rule matches, use the form's default structure ID or block placement with context guidance.
