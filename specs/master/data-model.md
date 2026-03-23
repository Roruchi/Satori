# Data Model: Satori — Full Game

**Branch**: `master` | **Date**: 2026-03-23

---

## Core Entities

### BiomeType (Enum)

```gdscript
enum BiomeType {
    # Base tiles (placeable by player)
    FOREST   = 0,
    WATER    = 1,
    STONE    = 2,
    EARTH    = 3,

    # Hybrid biomes (created by alchemy)
    SWAMP       = 4,   # Forest + Water
    TUNDRA      = 5,   # Stone + Water
    MUDFLAT     = 6,   # Earth + Water
    MOSSY_CRAG  = 7,   # Forest + Stone
    SAVANNAH    = 8,   # Forest + Earth
    CANYON      = 9,   # Stone + Earth

    NONE = -1
}
```

**Mixing matrix** (static, enforced in `BiomeType.mix(a, b) → BiomeType`):

| A        | B      | Result     |
|----------|--------|------------|
| FOREST   | WATER  | SWAMP      |
| STONE    | WATER  | TUNDRA     |
| EARTH    | WATER  | MUDFLAT    |
| FOREST   | STONE  | MOSSY_CRAG |
| FOREST   | EARTH  | SAVANNAH   |
| STONE    | EARTH  | CANYON     |

Mixing a base tile with itself, or mixing any hybrid tile: **invalid** (returns NONE, placement rejected).

---

### TileData (Value Type)

```gdscript
# Stored in GridMap.tiles: Dictionary[Vector2i, TileData]
class_name TileData

var coord:    Vector2i   # Axial grid coordinate
var biome:    BiomeType
var locked:   bool       # True after alchemy merge — no further mixing
var metadata: Dictionary # Extensible: { "discovery_ids": [], "spirit_id": "" }
```

---

### ChunkKey

```gdscript
# Derived: not stored explicitly
static func chunk_key(coord: Vector2i) -> Vector2i:
    return Vector2i(floori(coord.x / 16.0), floori(coord.y / 16.0))

static func local_coord(coord: Vector2i) -> Vector2i:
    return Vector2i(posmod(coord.x, 16), posmod(coord.y, 16))
```

---

### GridMap (Singleton — GameState)

```gdscript
# In-memory state
var tiles:  Dictionary  # Vector2i → TileData
var chunks: Dictionary  # Vector2i(chunk) → Dictionary[Vector2i(local) → TileData]
var total_tile_count: int
var garden_bounds: Rect2i  # Axis-aligned bounding box of placed tiles (updated on placement)
```

---

### DiscoveryDefinition (Resource)

```gdscript
class_name DiscoveryDefinition
extends Resource

@export var id:           String         # e.g. "tier1_river"
@export var display_name: String
@export var tier:         int            # 1, 2, or 3
@export var flavor_text:  String
@export var riddle_text:  String         # Used for Tier 3 spirits (empty for Tier 1/2)
@export var audio_key:    String         # Key into AudioManager bus map
@export var pattern:      PatternDefinition
```

---

### PatternDefinition (Resource)

```gdscript
class_name PatternDefinition
extends Resource

enum PatternType { CLUSTER, SHAPE, RATIO_PROXIMITY, COMPOUND }

@export var type:              PatternType
@export var required_biomes:   Array[BiomeType]   # Biomes that qualify
@export var forbidden_biomes:  Array[BiomeType]   # Biomes that disqualify nearby tiles
@export var min_size:          int                 # For CLUSTER: minimum contiguous count
@export var shape_recipe:      Array[Vector2i]    # For SHAPE: relative tile offsets
@export var center_biome:      BiomeType          # For RATIO_PROXIMITY: center tile type
@export var neighbor_biomes:   Dictionary         # BiomeType → required count
@export var sub_pattern_ids:   Array[String]      # For COMPOUND: prerequisite discoveries
```

---

### DiscoveryLog (Singleton — GameState)

```gdscript
var discovered:    Dictionary  # String(discovery_id) → { "timestamp": int, "tiles": Array[Vector2i] }
var total_count:   int

func is_discovered(id: String) -> bool
func record_discovery(id: String, tiles: Array[Vector2i]) -> void
```

---

### SpiritAnimalState

```gdscript
class_name SpiritAnimalState

var spirit_id:      String      # e.g. "spirit_red_fox"
var discovery_id:   String      # Triggering discovery
var spawn_coord:    Vector2i
var wander_bounds:  Rect2i      # Derived from triggering cluster bounding box
var active:         bool
```

---

### SaveData (Serialised to `user://garden.sav`)

```gdscript
# Structure written via var_to_bytes
{
    "version":      int,           # Save format version (increment on schema change)
    "tile_count":   int,
    "tiles": {
        # Encoded as Array of [x, y, biome_int, locked_bool] for compactness
        "data": Array
    },
    "discoveries":  Dictionary,    # id → { timestamp, tiles }
    "spirits":      Array,         # Array of SpiritAnimalState dicts
    "settings": {
        "haptic_level":        int,   # 0=off, 1=low, 2=full
        "colorblind_mode":     bool,
        "master_volume":       float,
        "ambient_enabled":     bool,
        "sfx_enabled":         bool,
    }
}
```

---

## State Transitions

### Tile Lifecycle

```
[Empty coord]
    │  Player long-presses valid adjacent coord
    ▼
[Base Tile: Forest | Water | Stone | Earth]
    │  Player long-presses this tile with different base type
    │  (only if NOT locked)
    ▼
[Hybrid Tile: locked=true]
    │  No further transitions (Permanent Emergence)
    ▼
[Locked Hybrid — immutable forever]
```

### Discovery Lifecycle

```
[Undiscovered]
    │  PatternEngine detects matching configuration
    ▼
[Triggered] → signal emitted → DiscoveryLog.record_discovery()
    │
    ▼
[Notified] → UI pop-in displayed → audio stinger played
    │
    ▼
[Logged — persists in SaveData.discoveries]
```

### Garden Session Lifecycle

```
App launch
    │
    ├─ SaveData exists → load → restore GridMap + DiscoveryLog + Spirits
    └─ No save → create Origin tile at (0,0) → new garden

Gameplay loop
    │
    ├─ Tile placed → ChunkManager.update() → PatternEngine.scan()
    └─ Every 10 placements / on background → SaveData written

App exit / background → auto-save
```

---

## Validation Rules

| Rule | Enforcement |
|------|-------------|
| No placement without adjacency (except Origin) | `GridMap.is_placement_valid(coord)` |
| No mixing a locked tile | `TileData.locked == false` check before mix |
| No mixing same biome type | `BiomeType.mix(a, b)` returns NONE if a==b |
| No mixing hybrid + anything | Hybrids have `locked=true` on creation |
| Discovery idempotent | `DiscoveryLog.is_discovered(id)` guard in PatternEngine |
| No undo/clear in production | `GameState` exposes no delete API; debug scene bypasses guard via feature flag |
