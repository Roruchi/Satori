# Contract: Discovery Log Persistence Schema (MVP)

## Scope

Defines the serialized discovery payload embedded in garden save data for Tier 1 discoveries.

## Schema

```json
{
  "discoveries": {
    "entries": [
      {
        "discovery_id": "disc_deep_stand",
        "display_name": "The Deep Stand",
        "trigger_timestamp": 1774224000,
        "triggering_coords": [[0, 0], [1, 0], [2, 0]]
      }
    ]
  }
}
```

## Field Rules

- `discoveries.entries`: ordered array in first-trigger order.
- `discovery_id`: stable string identifier; unique within the array.
- `display_name`: localized/player-facing title captured at trigger time.
- `trigger_timestamp`: unix epoch seconds when first triggered.
- `triggering_coords`: array of integer coordinate pairs `[x, y]`.

## Load Contract

On load:
1. Parse `discoveries.entries` if present.
2. Validate uniqueness by `discovery_id`.
3. Hydrate runtime discovery suppression set from parsed IDs before first scan.
4. Preserve stored timestamp and coordinate history unchanged.

## Backward/Forward Compatibility

- If `discoveries` key is absent (older saves), treat as empty discovery log.
- Unknown extra fields in entries should be ignored (forward compatibility).
- Invalid entries should be skipped with warning, without failing whole save load.
