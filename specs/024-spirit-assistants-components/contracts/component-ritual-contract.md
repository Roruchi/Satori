# Contract: Component Ritual Input

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22

## Availability Input

```gdscript
{
	"component_id": StringName,
	"island_id": String,
	"context_coord": Vector2i
}
```

## Availability Output

```gdscript
{
	"available": bool,
	"blocked_reason": StringName,
	"input_key": String,
	"source_coord": Vector2i,
	"island_id": String
}
```

## Invariants

- Component input keys obey the same no-duplicate ritual slot rule as materials, essences and spirits.
- Discovery-based components require a recorded discovery.
- Placed-structure components require a matching placed structure when `requires_island_local` is true.
- Components are not consumed unless the component definition explicitly marks them inventory-based and consumable.
- Component availability is revalidated on confirm.
- Component rituals prefer context and state requirements over large material stack costs.

## Required Block Reasons

- `not_discovered`
- `not_placed`
- `wrong_island`
- `component_gate_locked`
- `duplicate_input`

## Initial Acceptance Fixtures

| Component | Source State | Expected |
|-----------|--------------|----------|
| Wind Chime | discovered, symbolic allowed | available |
| Tiny Shrine | not discovered | blocked `not_discovered` |
| Meadow Dwelling | placed on same island | available if placed requirement applies |
| Meadow Dwelling | placed on another island | blocked `wrong_island` |
| Component selected twice | confirm ritual | duplicate/failure |
