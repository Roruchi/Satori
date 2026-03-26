# Data Model: Ku Tile Placement (Abyss Biome + Island System)

**Feature**: Ku Tile Placement  
**Branch**: `copilot/implement-ku-tile-placement`  
**Date**: 2026-03-26

## Entities

### BiomeType.Value.KU

| Field | Value |
|-------|-------|
| Enum name | `KU` |
| Integer value | `14` |
| Semantic | Abyss — void separator; not land |
| Mixing | Cannot be mixed (no recipes target standalone KU) |
| Island membership | Excluded — Ku tiles are BFS walls |

---

### GardenTile (extended)

Existing class `GardenTile` (`src/grid/TileData.gd`). No new fields; the `metadata` dictionary is extended:

| Metadata key | Type | Description |
|---|---|---|
| `"island_id"` | `String` | ID of the island this tile belongs to. Empty string `""` for KU tiles. Set by `GridMap.compute_island_ids()` after every placement. |
| `"discovery_ids"` | `Array[String]` | Existing — unchanged |
| `"spirit_id"` | `String` | Existing — unchanged |

---

### IslandMap (logical, lives in GridMap)

Computed in-memory after every tile placement. Not persisted (fully derived from grid state).

| Property | Type | Description |
|---|---|---|
| `_island_map` | `Dictionary` (Vector2i → String) | Maps each non-Ku tile coord to its island ID |
| Key format | `Vector2i` | Axial hex coordinate |
| Value format | `String` | `"q,r"` of the canonical (lowest-coord) tile in the component |

Methods added to `GridMap`:

| Method | Signature | Description |
|---|---|---|
| `compute_island_ids()` | `() → void` | Full BFS flood-fill; populates `_island_map` and writes `tile.metadata["island_id"]` |
| `get_island_id(coord)` | `(Vector2i) → String` | Returns island ID for coord, or `""` if Ku/unknown |

---

### SpiritInstance (extended)

| Field | Type | Default | Description |
|---|---|---|---|
| `spirit_id` | `String` | `""` | Existing — unchanged |
| `spawn_coord` | `Vector2i` | `(0,0)` | Existing — unchanged |
| `wander_bounds` | `Rect2i` | `Rect2i()` | Existing — unchanged |
| `is_active` | `bool` | `false` | Existing — unchanged |
| `summoned_at` | `int` | `0` | Existing — unchanged |
| `island_id` | `String` | `""` | **NEW** — island on which this spirit was summoned |

Serialisation adds `"island_id"` key; deserialisation reads it with `""` default (backward compatible).

---

### SpiritPersistence (extended)

| Property | Type | Description |
|---|---|---|
| `_summoned_ids` | `Dictionary` | **Changed** — keyed by `"island_{island_id}\|spirit_{spirit_id}"` |

New / changed methods:

| Method | Signature | Description |
|---|---|---|
| `record_instance(instance)` | `(SpiritInstance) → void` | Uses `_island_spirit_key(instance)` as dedup key; backward compat: falls back to `spirit_id` key when `island_id` is empty |
| `is_summoned_on_island(spirit_id, island_id)` | `(String, String) → bool` | Returns true if the compound key exists; used by SpiritService |
| `_island_spirit_key(instance)` | `(SpiritInstance) → String` | Private helper: `"island_{island_id}\|spirit_{spirit_id}"` |

---

### SpiritService (changed logic)

`_active_instances` dictionary key changes:

| Before | After |
|---|---|
| `spirit_id` (String) | `"island_{island_id}\|spirit_{spirit_id}"` (String) when island_id known; falls back to `spirit_id` for Sky Whale and island-less cases |

New helper in SpiritService:

| Method | Signature | Description |
|---|---|---|
| `_spirit_key(spirit_id, island_id)` | `(String, String) → String` | Returns compound key when island_id non-empty, else spirit_id |
| `_island_for_coords(coords)` | `(Array[Vector2i]) → String` | Looks up island_id of the first valid triggering coord via GameState.grid |

## State Transitions

```
tile_placed signal
    → GridMap.compute_island_ids()         [all tiles get fresh island_id]
    → PatternScanService scans
        → discovery_triggered(id, coords)
            → SpiritService._on_discovery_triggered(id, coords)
                → island_id = _island_for_coords(coords)
                → key = _spirit_key(id, island_id)
                → if _active_instances.has(key): return
                → _summon_spirit(id, coords, island_id)
                    → SpiritInstance.island_id = island_id
                    → SpiritPersistence.record_instance(instance)
```

## Backward Compatibility

- `SpiritInstance.island_id` deserialises with `""` default → old saves load cleanly.
- `SpiritPersistence._summoned_ids` keys from previous runs that used bare `spirit_id` are NOT present in the new key namespace, so old spirits will not block new island-scoped spawning. This is intentional: the feature effectively resets spirits for the current session when the feature is first deployed.
- Single-island gardens (no Ku tiles placed) behave identically to pre-feature behaviour: every tile shares island_id `"0,0"` (the origin's canonical coord), so compound keys are unique per spirit and no duplicates occur.
