# Data Model: Spirit Animal System

## Entities

### SpiritDefinition (Resource — `src/spirits/spirit_definition.gd`)
Static definition of a spirit animal, stored as @export resource fields.
Currently instantiated from `SpiritCatalogData` dictionaries, not from .tres files.

| Field | Type | Description |
|-------|------|-------------|
| `spirit_id` | String | Unique identifier (e.g. `spirit_red_fox`) |
| `display_name` | String | Human-readable name (e.g. `Red Fox`) |
| `riddle_text` | String | Hint shown during partial condition satisfaction |
| `pattern_id` | String | Matches the `discovery_id` in the corresponding `.tres` |
| `wander_radius` | int | Tile radius for wander-bounds expansion |
| `wander_speed` | float | World units per second during wandering |
| `color_hint` | Color | Placeholder visual colour for the sphere mesh |

### SpiritInstance (RefCounted — `src/spirits/spirit_instance.gd`)
Runtime state of a summoned spirit. Serialised into `SpiritPersistence`.

| Field | Type | Description |
|-------|------|-------------|
| `spirit_id` | String | References a `SpiritDefinition.spirit_id` |
| `spawn_coord` | Vector2i | Centroid of triggering tile cluster (axial coords) |
| `wander_bounds` | Rect2i | Tile-coord bounding region for wander movement |
| `is_active` | bool | True after summoning |
| `summoned_at` | int | UTC Unix timestamp of summoning event |

**State transitions**: `create()` → `is_active = true`. Persisted via `serialize()` / `deserialize()`.

### PatternDefinition (.tres — `src/biomes/patterns/spirits/*.tres`)
One `.tres` file per spirit (29 files; Sky Whale has no pattern file).
Fields defined by the existing `PatternDefinition` resource. Spirit patterns share the
same `discovery_id` as the spirit they summon (e.g. `spirit_red_fox`).

### SpiritWanderer (Node3D — `src/spirits/spirit_wanderer.gd`)
Live scene node representing a spirit in the 3D garden world.

| Field | Type | Description |
|-------|------|-------------|
| `spirit_id` | String | Tracks which spirit this node represents |
| `wander_bounds` | Rect2i | Current wander region in tile coords |
| `_target_world` | Vector3 | Current movement target in world space |
| `_speed` | float | Movement speed (world units/sec) |
| `_wait_time` | float | Countdown before picking next waypoint |

Children created in `_ready()`: `MeshInstance3D` (SphereMesh placeholder) + `Label3D` (display name).

## Relationships

```
SpiritCatalogData ──provides──▶ SpiritCatalog
SpiritCatalog ──lookup──▶ Dictionary (entry)
PatternMatcher ──discovery_triggered──▶ SpiritService
SpiritService ──creates──▶ SpiritInstance
SpiritService ──calls──▶ SpiritSpawner.spawn()
SpiritSpawner ──add_child──▶ SpiritWanderer (under SpiritLayer Node3D)
SpiritService ──record_instance()──▶ SpiritPersistence
PatternScanScheduler._ready() ──hydrates──▶ SpiritPersistence.get_summoned_ids()
SpiritService._on_tile_placed() ──evaluates──▶ SkyWhaleEvaluator
SpiritService._evaluate_riddle_hints() ──checks──▶ SpiritRiddleEvaluator
```

## Persistence Format (user://spirit_instances.json)

```json
{
  "instances": [
    {
      "spirit_id": "spirit_red_fox",
      "spawn_coord": {"x": 3, "y": 2},
      "wander_bounds": {"x": -1, "y": -2, "w": 9, "h": 9},
      "is_active": true,
      "summoned_at": 1710000000
    }
  ]
}
```
_Save/load is currently disabled (pass) matching the DiscoveryPersistence pattern._
