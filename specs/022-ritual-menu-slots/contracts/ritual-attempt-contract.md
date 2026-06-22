# Contract: Ritual Attempt

**Branch**: `022-ritual-menu-slots` | **Date**: 2026-06-22

## Purpose

Define the deterministic contract for previewing and confirming rituals.

## Input

```gdscript
{
	"slot_keys": Array[String],       # up to 3 non-empty identity keys
	"context": Dictionary,           # optional; empty for basic rituals
	"confirm": bool                  # false for preview, true for commit
}
```

## Output

```gdscript
{
	"outcome": StringName,
	"feedback_key": StringName,
	"guidance": String,
	"ritual_id": StringName,
	"result_kind": StringName,
	"result_id": StringName,
	"consumed_input_keys": Array[String],
	"discovered_id": StringName
}
```

## Required Outcomes

- `success`
- `empty_input`
- `duplicate_input`
- `missing_essence`
- `locked_input`
- `no_match`
- `inventory_full`
- `context_blocked`

## Invariants

- Ritual slots are order-insensitive.
- No input identity may appear more than once.
- At least one input must be an essence.
- Preview never mutates inventory, charges, discoveries or world state.
- Confirm mutates state only after output insertion succeeds.
- Failure never consumes essence, materials, components or spirit availability.
- Spirits are never consumed, even when they are present in `consumed_input_keys` by mistake; implementation must filter them out or fail validation.
- Duplicate-token legacy building recipes are invalid and must return `duplicate_input` or `no_match`, not `success`.

## Initial Acceptance Fixtures

| Input Keys | Context | Expected |
|------------|---------|----------|
| `essence:wind` | empty | Meadow Seed |
| `essence:fire` | empty | Hearth Seed |
| `essence:wind`, `essence:fire` | empty | Sungrass Seed |
| `material:living_wood`, `essence:fire` | empty | Warm Hollow |
| `essence:earth`, `essence:earth`, `essence:wind` | empty | duplicate/failure |
| `material:living_wood` | empty | missing essence |

## Placement Contract for Warm Hollow

Warm Hollow placement uses a second context resolution step:

```gdscript
{
	"form_id": "warm_hollow",
	"target_coord": Vector2i,
	"target_biome": int,
	"nearby_spirit_ids": Array[String]
}
```

The first implementation must support:

- Meadow target -> `meadow_dwelling`
- Fire/Hearth target -> `scorched_hollow`
- invalid or empty target -> blocked with no inventory consumption
