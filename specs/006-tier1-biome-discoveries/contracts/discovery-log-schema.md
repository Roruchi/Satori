# Contract: Discovery Log Persistence Schema (MVP)

## Scope

Defines the serialized discovery payload saved to `user://garden_discoveries.json` for Tier 1 discoveries.

## Save File

**Location**: `user://garden_discoveries.json`  
**Format**: UTF-8 JSON, written on every new discovery, read once on startup.

## Schema

```json
{
  "entries": [
    {
      "discovery_id": "disc_deep_stand",
      "display_name": "The Deep Stand",
      "trigger_timestamp": 1774224000,
      "triggering_coords": [[0, 0], [1, 0], [2, 0]]
    }
  ]
}
```

## Field Rules

- `entries`: ordered array in first-trigger order.
- `discovery_id`: stable string identifier; unique within the array.
- `display_name`: player-facing title captured at trigger time.
- `trigger_timestamp`: unix epoch seconds (integer) when first triggered.
- `triggering_coords`: array of `[x, y]` integer coordinate pairs.

## Load Contract

On startup (`DiscoveryPersistence._ready()`):
1. Read `user://garden_discoveries.json` if it exists.
2. Deserialize `entries` array into `DiscoveryLog`.
3. `PatternScanService` hydrates its `DiscoveryRegistry` with all persisted IDs before the first scan.
4. Existing pattern matches do not re-trigger already-logged discoveries.
5. Stored timestamps and coordinate history are preserved unchanged.

## Backward/Forward Compatibility

- If the file is absent (new garden), treat as empty discovery log.
- Unknown extra fields in entries should be ignored.
- Invalid entries should be skipped with a warning, without failing the whole load.

