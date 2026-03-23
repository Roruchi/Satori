# Data Model: Tier 1 Biome Discoveries (MVP)

**Branch**: `006-tier1-biome-discoveries` | **Date**: 2026-03-23

## Entities

### DiscoveryDefinition (Metadata)

Purpose: Presentation metadata keyed by discovery ID.

Fields:
- `discovery_id: String` (stable key, matches `PatternDefinition.discovery_id`)
- `display_name: String`
- `flavor_text: String`
- `audio_key: String`
- `tier: int` (fixed to `1` for this feature)

Validation:
- `discovery_id` must be non-empty and unique across Tier 1 set.
- `audio_key` must resolve to a loaded audio asset.
- Exactly 12 Tier 1 definitions must exist for MVP completion criteria.

Relationships:
- One-to-one with Tier 1 `PatternDefinition` via `discovery_id`.

### DiscoverySignal (Runtime Event)

Purpose: Matching engine output from scan pass.

Fields (existing core):
- `discovery_id: String`
- `triggering_coords: Array[Vector2i]`

Validation:
- `discovery_id` must map to a known `DiscoveryDefinition`.
- `triggering_coords` must be non-empty for Tier 1 emissions.

Relationships:
- Produced by `PatternMatcher`; consumed by UI notification queue and persistence recorder.

### DiscoveryLogEntry (Persistent Record)

Purpose: Immutable record of first-time discovery trigger in a garden.

Fields:
- `discovery_id: String`
- `display_name: String`
- `trigger_timestamp: int` (Unix epoch)
- `triggering_coords: Array[Vector2i]`

Validation:
- One entry per `discovery_id` per garden.
- `trigger_timestamp` is recorded at first trigger and never rewritten.

Relationships:
- Belongs to `DiscoveryLog` collection.

### DiscoveryLog (Aggregate)

Purpose: Ordered persistent history + duplicate suppression source of truth.

Fields:
- `entries: Array[DiscoveryLogEntry]` (append-only in trigger order)
- `discovered_ids: Dictionary` (`String -> bool` fast lookup)

Validation:
- `entries` and `discovered_ids` must be consistent.
- On load, `discovered_ids` rebuilt or validated from entries.

Relationships:
- Hydrates `DiscoveryRegistry` at startup.
- Serialized into garden save payload.

### DiscoveryNotificationQueueItem (UI Runtime)

Purpose: Queue payload for serialized visual/audio feedback.

Fields:
- `discovery_id: String`
- `display_name: String`
- `flavor_text: String`
- `audio_key: String`
- `duration_seconds: float` (4.0 target)

Validation:
- Queue must process strictly one active item at a time.
- Enqueued order must match deterministic discovery emission order.

Relationships:
- Built from `DiscoverySignal + DiscoveryDefinition`.

## State Transitions

### Discovery Trigger Lifecycle

1. `PatternScanService` requests scan after tile placement.
2. `PatternMatcher.scan_and_emit()` emits ordered `DiscoverySignal` values for newly discovered IDs only.
3. Each signal is recorded to `DiscoveryLog` (if first occurrence).
4. Matching queue item is enqueued for notification/audio playback.
5. Item is displayed for 4 seconds, then queue advances.

### Session Restore Lifecycle

1. Garden save data is loaded.
2. `DiscoveryLog` entries are restored.
3. `DiscoveryRegistry` is hydrated with persisted IDs before the first scan.
4. Existing pattern matches do not re-trigger already logged discoveries.

## Persistence Shape (MVP)

```gdscript
{
  "discoveries": {
    "entries": [
      {
        "discovery_id": "disc_deep_stand",
        "display_name": "The Deep Stand",
        "trigger_timestamp": 1774224000,
        "triggering_coords": [Vector2i(0,0), Vector2i(1,0)]
      }
    ]
  }
}
```

Notes:
- Exact save container may include additional garden keys.
- Discovery payload must remain backward-compatible with future tiers.
