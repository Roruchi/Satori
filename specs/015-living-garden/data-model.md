# Data Model: Living Garden — Satori v2 Core Loop

**Branch**: `015-living-garden` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)

---

## New Resources & Classes

---

### GodaiElement *(new enum — `src/seeds/GodaiElement.gd`)*

**Purpose**: Typed identifiers for the five Japanese classical elements. Used as mixing UI input and recipe lookup keys.

```gdscript
class_name GodaiElement
extends RefCounted

enum Value {
    CHI = 0,   # 地 Earth
    SUI = 1,   # 水 Water
    KA  = 2,   # 火 Fire
    FU  = 3,   # 風 Wind
    KU  = 4,   # 空 Void (locked by default)
}

const DISPLAY_NAMES: Dictionary = {
    Value.CHI: "Chi (地)",
    Value.SUI: "Sui (水)",
    Value.KA:  "Ka (火)",
    Value.FU:  "Fū (風)",
    Value.KU:  "Kū (空)",
}

const LOCKED_BY_DEFAULT: Array[int] = [Value.KU]
```

**Validation**: KU cannot appear as a solo element in a recipe (FR-012). Duplicate elements in a recipe are rejected by the mixing UI before confirm.

---

### SeedRecipe *(new Resource — `src/seeds/SeedRecipe.gd`)*

**Purpose**: Defines one seed crafting recipe — the element combination and the biome it produces. Stored as `.tres` files in `res://src/seeds/recipes/`.

```gdscript
class_name SeedRecipe
extends Resource

@export var recipe_id: StringName = &""
@export var elements: Array[int] = []          # GodaiElement.Value[], stored sorted ascending
@export var tier: int = 1                       # 1, 2, or 3
@export var produces_biome: int = BiomeType.Value.NONE   # BiomeType.Value
@export var spirit_unlock_id: StringName = &""  # empty for Tier 1/2; spirit ID for Tier 3
@export var codex_hint: String = ""             # shown in Codex before discovery
```

**Validation**: `elements` must be sorted and deduplicated. `tier` must equal `elements.size()`. `spirit_unlock_id` must be non-empty iff `tier == 3`.

**Identity**: `recipe_id` is the canonical key. Recipe lookup by elements uses a sorted-join key: `"chi_sui"`, `"chi"`, `"chi_ka_fu"`.

---

### SeedRecipeRegistry *(new class — `src/seeds/SeedRecipeRegistry.gd`)*

**Purpose**: Loads all `SeedRecipe` .tres files at startup. Provides lookup by element set and tracks per-recipe unlock state.

```gdscript
class_name SeedRecipeRegistry
extends RefCounted

# _recipes: Dictionary[String → SeedRecipe]  (key = sorted element join)
# _unlocked_tier3: Dictionary[StringName → bool]

func lookup(elements: Array[int]) -> SeedRecipe   # returns null if no match or locked
func unlock_recipe(recipe_id: StringName) -> void
func is_recipe_known(recipe_id: StringName) -> bool
func all_known_recipes() -> Array[SeedRecipe]
```

---

### SeedState *(new enum — `src/seeds/SeedState.gd`)*

```gdscript
class_name SeedState
extends RefCounted

enum Value {
    GROWING = 0,
    READY   = 1,
    BLOOMED = 2,
}
```

---

### SeedInstance *(new class — `src/seeds/SeedInstance.gd`)*

**Purpose**: Represents one planted seed in the ground. Not a Godot Resource — plain RefCounted for performance.

```gdscript
class_name SeedInstance
extends RefCounted

var recipe_id: StringName = &""
var hex_coord: Vector2i = Vector2i.ZERO
var planted_at: float = 0.0       # Unix timestamp
var growth_duration: float = 0.0  # seconds; 0 in INSTANT mode
var state: int = SeedState.Value.GROWING  # SeedState.Value

static func create(rid: StringName, coord: Vector2i, duration: float) -> SeedInstance
func is_ready() -> bool:
    return state == SeedState.Value.READY or state == SeedState.Value.BLOOMED
func evaluate_growth() -> bool:  # returns true if newly transitioned to READY
    if state != SeedState.Value.GROWING: return false
    if growth_duration <= 0.0:
        state = SeedState.Value.READY
        return true
    if Time.get_unix_time_from_system() - planted_at >= growth_duration:
        state = SeedState.Value.READY
        return true
    return false

func serialize() -> Dictionary
static func deserialize(data: Dictionary) -> SeedInstance
```

**State transitions**: GROWING → READY (automatic, via `evaluate_growth()`), READY → BLOOMED (explicit player tap).

---

### GrowthMode *(new enum — `src/seeds/GrowthMode.gd`)*

```gdscript
class_name GrowthMode
extends RefCounted

enum Value {
    INSTANT   = 0,
    REAL_TIME = 1,
}
```

---

### SeedPouch *(new class — `src/seeds/SeedPouch.gd`)*

**Purpose**: Holds unplanted seeds ready to be placed. Capacity starts at 3, expands via spirit gifts.

```gdscript
class_name SeedPouch
extends RefCounted

var seeds: Array[SeedRecipe] = []   # recipes ready to plant
var capacity: int = 3

func is_full() -> bool: return seeds.size() >= capacity
func add(recipe: SeedRecipe) -> bool  # returns false if full
func remove_at(index: int) -> SeedRecipe
func first() -> SeedRecipe  # peek at index 0; null if empty
```

---

### GrowthSlotTracker *(new class — `src/seeds/GrowthSlotTracker.gd`)*

**Purpose**: Tracks seeds currently in the ground (GROWING or READY state). Capacity starts at 3.

```gdscript
class_name GrowthSlotTracker
extends RefCounted

var active_seeds: Array[SeedInstance] = []
var capacity: int = 3

func available_slots() -> int: return capacity - active_seeds.size()
func is_full() -> bool: return active_seeds.size() >= capacity
func add(seed: SeedInstance) -> void
func remove_bloomed(coord: Vector2i) -> void
func get_at(coord: Vector2i) -> SeedInstance  # null if not found
func get_ready_seeds() -> Array[SeedInstance]
func serialize() -> Array[Dictionary]
static func deserialize(data: Array) -> GrowthSlotTracker
```

---

## Modified Existing Classes

---

### BiomeType *(modified — `src/biomes/BiomeType.gd`)*

**Change**: Replace existing enum values with Godai-aligned biome set. Deprecate static `mix()` function (still compiles, returns NONE for all inputs — redirect to SeedRecipeRegistry at call sites).

```gdscript
enum Value {
    NONE         = -1,
    # Tier 1 — Single Godai element
    STONE        = 0,   # Chi (地)
    RIVER        = 1,   # Sui (水)
    EMBER_FIELD  = 2,   # Ka  (火)
    MEADOW       = 3,   # Fū  (風)
    # Tier 2 — Two Godai elements
    CLAY         = 4,   # Chi + Sui
    DESERT       = 5,   # Chi + Ka
    DUNE         = 6,   # Chi + Fū
    HOT_SPRING   = 7,   # Sui + Ka
    BOG          = 8,   # Sui + Fū
    CINDER_HEATH = 9,   # Ka  + Fū
    SACRED_STONE = 10,  # Chi + Kū
    VEIL_MARSH   = 11,  # Sui + Kū
    EMBER_SHRINE = 12,  # Ka  + Kū
    CLOUD_RIDGE  = 13,  # Fū  + Kū
    # Tier 3 — Spirit-unlocked (indices 20+, added incrementally)
}

## Deprecated — do not call in new code. Returns NONE always.
static func mix(_a: Value, _b: Value) -> Value: return Value.NONE
```

---

### SpiritDefinition *(modified — `src/spirits/spirit_definition.gd`)*

**Change**: Add habitat profile and gift fields.

```gdscript
# Existing fields retained:
@export var spirit_id: String = ""
@export var display_name: String = ""
@export var riddle_text: String = ""
@export var pattern_id: String = ""
@export var wander_radius: int = 4
@export var wander_speed: float = 2.0
@export var color_hint: Color = Color.WHITE

# New fields:
@export var preferred_biomes: Array[int] = []    # BiomeType.Value[]
@export var disliked_biomes: Array[int] = []     # BiomeType.Value[]
@export var harmony_partner_id: StringName = &"" # spirit_id of harmony partner; empty = none
@export var tension_partner_id: StringName = &"" # spirit_id of tension partner; empty = none
@export var gift_type: int = SpiritGiftType.NONE # SpiritGiftType.Value
@export var gift_payload: StringName = &""       # recipe_id, spirit_id, or empty
```

---

### SpiritWanderer *(modified — `src/spirits/spirit_wanderer.gd`)*

**Changes**:
- Add `_disliked_biomes: Array[int]` field.
- In `setup()`: populate `_disliked_biomes` from `catalog_entry`.
- Add `moved_to` signal: `signal moved_to(spirit_id: String, coord: Vector2i)` — emitted when wanderer reaches its target (used by `SpiritEcologyService`).
- In `_process()`: when spirit arrives at target tile and that tile is in `_disliked_biomes`, immediately call `_pick_new_target()` without waiting.

---

### GameState *(modified — `src/autoloads/GameState.gd`)*

**Changes**: The direct-placement and mixing API is superseded by the seed system. Retain signals for backward compatibility with PatternScanService.

```gdscript
# Retained signals (emitted at bloom time by SeedGrowthService):
signal tile_placed(coord: Vector2i, tile: GardenTile)

# Deprecated signals (kept for test compatibility, no longer emitted in gameplay):
signal tile_mixed(coord: Vector2i, tile: GardenTile)
signal mix_rejected(coord: Vector2i, reason: String)

# Removed: try_mix_tile() — callers must use SeedAlchemyService
# Modified: try_place_tile() renamed to place_tile_from_seed(coord, biome) — called only by SeedGrowthService on bloom
```

---

## New Services

---

### SeedAlchemyService *(new autoload — `src/autoloads/seed_alchemy_service.gd`)*

**Purpose**: Manages element unlock state, recipe lookup, and pouch lifecycle.

```gdscript
# Autoload key: SeedAlchemyService (class_name: SeedAlchemyServiceNode)
signal element_unlocked(element_id: int)       # GodaiElement.Value
signal recipe_discovered(recipe_id: StringName)
signal seed_added_to_pouch(recipe: SeedRecipe)

var _pouch: SeedPouch
var _registry: SeedRecipeRegistry
var _unlocked_elements: Array[int]

func is_element_unlocked(element: int) -> bool
func unlock_element(element: int) -> void      # called by gift processor
func lookup_recipe(elements: Array[int]) -> SeedRecipe  # null if locked/unknown
func craft_seed(elements: Array[int]) -> bool  # adds to pouch; false if pouch full or no recipe
func get_pouch() -> SeedPouch
```

---

### SeedGrowthService *(new autoload — `src/autoloads/seed_growth_service.gd`)*

**Purpose**: Manages the GrowthSlotTracker, timer evaluation, mode switching, and bloom confirmation.

```gdscript
# Autoload key: SeedGrowthService (class_name: SeedGrowthServiceNode)
signal seed_planted(seed: SeedInstance)
signal seed_ready(seed: SeedInstance)        # transitions GROWING → READY
signal bloom_confirmed(coord: Vector2i, biome: int)  # player tapped READY seed

var _tracker: GrowthSlotTracker
var _mode: int = GrowthMode.Value.REAL_TIME

func set_mode(mode: int) -> void             # switches INSTANT/REAL_TIME; promotes all GROWING → READY if INSTANT
func get_mode() -> int
func try_plant(coord: Vector2i, recipe: SeedRecipe) -> bool  # false if slots full
func try_bloom(coord: Vector2i) -> bool      # false if seed not READY at coord
func available_slots() -> int
func get_ready_seeds() -> Array[SeedInstance]
func _evaluate_all() -> void                 # called on focus return and timer tick
```

**Timer**: 60-second `Timer` node child. On `_notification(NOTIFICATION_APPLICATION_FOCUS_IN)`: call `_evaluate_all()`.

---

### SpiritEcologyService *(new autoload — `src/autoloads/spirit_ecology_service.gd`)*

**Purpose**: Monitors active spirit positions for tension proximity and harmony accumulation.

```gdscript
# Autoload key: SpiritEcologyService (class_name: SpiritEcologyServiceNode)
signal tension_active(spirit_a_id: String, spirit_b_id: String)
signal tension_cleared(spirit_a_id: String, spirit_b_id: String)
signal harmony_event_fired(spirit_a_id: String, spirit_b_id: String, overlap_hexes: Array[Vector2i])

var _harmony_ticks: Dictionary   # "a|b" → int (accumulated ticks)
var _harmony_fired: Dictionary   # "a|b" → bool (permanent flag)
var _tension_active: Dictionary  # "a|b" → bool

func on_spirit_moved(spirit_id: String, coord: Vector2i) -> void  # called by SpiritWanderer.moved_to
func harmony_count() -> int     # number of fired harmony events
```

---

### SatoriService *(new autoload — `src/autoloads/satori_service.gd`)*

**Purpose**: Loads SatoriConditionSet resources, evaluates after blooms and summons, fires the Satori sequence.

```gdscript
# Autoload key: SatoriService (class_name: SatoriServiceNode)
signal satori_moment_fired(condition_id: StringName, unlock_type: int, unlock_payload: StringName)

func evaluate() -> void    # checks all unfired condition sets
func _apply_unlock(unlock_type: int, payload: StringName) -> void
func trigger_debug() -> void   # instant mode debug panel hook
```

---

### CodexService *(new autoload — `src/autoloads/codex_service.gd`)*

**Purpose**: Manages CodexEntry discovered state.

```gdscript
# Autoload key: CodexService (class_name: CodexServiceNode)
signal entry_discovered(entry_id: StringName)

func mark_discovered(entry_id: StringName) -> void
func is_discovered(entry_id: StringName) -> bool
func get_entries_by_category(category: int) -> Array[CodexEntry]  # CodexCategory.Value
func force_reveal(entry_id: StringName) -> void  # called by gift processor (CODEX_REVEAL)
```

---

### GardenSettings *(new autoload — `src/autoloads/garden_settings.gd`)*

**Purpose**: Persists `GrowthMode` and other device-level developer preferences.

```gdscript
# Autoload key: GardenSettings (class_name: GardenSettingsNode)
const SAVE_PATH: String = "user://garden_settings.json"

var growth_mode: int = GrowthMode.Value.REAL_TIME

func save() -> void
func load() -> void
```

---

## New Data Resources

---

### CodexEntry *(new Resource — `src/codex/CodexEntry.gd`)*

```gdscript
class_name CodexEntry
extends Resource

enum Category { SEED = 0, BIOME = 1, SPIRIT = 2, STRUCTURE = 3 }

@export var entry_id: StringName = &""
@export var category: int = Category.SEED
@export var hint_text: String = ""
@export var full_name: String = ""
@export var full_description: String = ""
@export var always_hidden: bool = false   # true for Kū-element seeds (no hint shown)
```

---

### SpiritGiftType *(new enum — `src/spirits/SpiritGiftType.gd`)*

```gdscript
class_name SpiritGiftType
extends RefCounted

enum Value {
    NONE               = 0,
    KU_UNLOCK          = 1,
    TIER3_RECIPE       = 2,
    POUCH_EXPAND       = 3,
    GROWING_SLOT_EXPAND = 4,
    CODEX_REVEAL       = 5,
}
```

---

### SatoriConditionSet *(new Resource — `src/satori/SatoriConditionSet.gd`)*

```gdscript
class_name SatoriConditionSet
extends Resource

@export var condition_id: StringName = &""
@export var requirements: Array[Dictionary] = []
# Requirement dictionary keys: "type", plus type-specific keys:
#   { "type": "biome_present", "biome": BiomeType.Value }
#   { "type": "spirit_count_gte", "count": int }
#   { "type": "harmony_count_gte", "count": int }
#   { "type": "tile_count_gte", "count": int }
@export var unlock_type: int = SpiritGiftType.Value.NONE  # reuses SpiritGiftType
@export var unlock_payload: StringName = &""
```

**First condition set file** (`res://src/satori/conditions/satori_first_awakening.tres`):
```
condition_id = "satori_first_awakening"
requirements = [
    { "type": "biome_present", "biome": 0 },   # STONE
    { "type": "biome_present", "biome": 1 },   # RIVER
    { "type": "biome_present", "biome": 2 },   # EMBER_FIELD
    { "type": "biome_present", "biome": 3 },   # MEADOW
    { "type": "spirit_count_gte", "count": 3 }
]
unlock_type = 4   # GROWING_SLOT_EXPAND
unlock_payload = ""
```

---

## Save File Summary

| File | Owner | Content |
|---|---|---|
| `user://garden_discoveries.json` | DiscoveryPersistence | Discovery log entries (existing, enable _save/_load) |
| `user://spirit_instances.json` | SpiritPersistence | Active spirit instances (existing, enable _save/_load) |
| `user://garden_seeds.json` | SeedGrowthService | GrowthSlotTracker + SeedPouch state |
| `user://garden_settings.json` | GardenSettings | GrowthMode and dev preferences |
| `user://codex_state.json` | CodexService | Discovered entry IDs (flat Dictionary) |
| `user://satori_state.json` | SatoriService | Fired condition set IDs |
| `user://spirit_gifts.json` | SpiritEcologyService | Applied gift IDs + harmony fired pairs |

---

## Autoload Registration (project.godot additions)

```
[autoload]
SeedAlchemyService="*res://src/autoloads/seed_alchemy_service.gd"
SeedGrowthService="*res://src/autoloads/seed_growth_service.gd"
SpiritEcologyService="*res://src/autoloads/spirit_ecology_service.gd"
SatoriService="*res://src/autoloads/satori_service.gd"
CodexService="*res://src/autoloads/codex_service.gd"
GardenSettings="*res://src/autoloads/garden_settings.gd"
```

**Guardrail check**: None of these autoload keys match any script `class_name`. Class names use the `Node` suffix pattern (e.g., `SeedAlchemyServiceNode`) to ensure no collision.
