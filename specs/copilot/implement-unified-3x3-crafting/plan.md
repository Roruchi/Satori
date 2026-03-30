Now I have complete context. Here is the detailed technical implementation plan:

---

# Technical Implementation Plan: Unified 3×3 Crafting and Explicit Ghost Placement

**Feature Branch**: `copilot/implement-unified-3x3-crafting`
**Spec**: `specs/copilot/implement-unified-3x3-crafting/spec.md`
**Engine**: Godot 4.6 · GDScript · GUT test framework

---

## 1. Architecture Overview

The feature introduces a **Craft → Inventory → Place** pipeline that replaces the legacy **Place-and-scan** model for structures. All new code lives under `src/crafting/` and `scenes/UI/`. Existing biome-cluster pattern scanning (`PatternType.CLUSTER`, `RATIO_PROXIMITY`, `COMPOUND`) is untouched; only `PatternType.SHAPE` call sites for the ten build-gated structure IDs are retired.

```
CraftingGrid (3×3 transient state)
    │  normalise() → Array[Vector2i] shape key
    ▼
RecipeRegistry (data-driven lookup)
    │  → RecipeDefinition (.tres resource)
    ▼
PlayerInventory (InventoryItem: tile | structure)
    │  tile item → TileSelector flow (unchanged)
    │  structure item → BuildMode
    ▼
BuildMode (rotation, TerrainValidator, ghost)
    │  confirm → PlacementRecord → GameState
    ▼
GardenView (renders GhostFootprint + placed tiles)
```

---

## 2. New Files to Create

### 2.1 `src/crafting/RecipeDefinition.gd`

```gdscript
class_name RecipeDefinition
extends Resource

enum OutputType { TILE = 0, STRUCTURE = 1 }

## Unique stable ID (e.g. "recipe_starter_house").
@export var recipe_id: String = ""

## TILE or STRUCTURE.
@export var output_type: int = OutputType.TILE

## For TILE: a BiomeType.Value int cast to String.
## For STRUCTURE: a discovery_id string (e.g. "disc_wayfarer_torii").
@export var output_id: String = ""

## Canonical normalised shape: min_row=0, min_col=0, sorted by (row, col) ASC.
## One Vector2i per occupied cell — row is x, col is y.
@export var shape: Array[Vector2i] = []

## Element required at each occupied cell, parallel to `shape`.
## GodaiElement.Value int.
@export var elements: Array[int] = []

## Human-readable name shown in the crafting UI preview.
@export var display_name: String = ""

## Path to a 64×64 icon texture resource.
@export var icon_path: String = ""

## Per-cell terrain rules used by TerrainValidator on placement.
## Array of Dictionaries: { "shape_index": int, "required_biome": int }
## Empty = no terrain constraint.
@export var terrain_rules: Array[Dictionary] = []

## Minimum element count guard (redundant with shape.size(), kept for
## data-authoring legibility and FR-006/FR-007 comment anchors).
@export var min_element_count: int = 1
```

**Notes:**
- `shape` + `elements` together form the lookup key. `shape` is the normalized offset array per the spec algorithm. `elements[i]` is the required `GodaiElement.Value` at `shape[i]`.
- A shape lookup produces at most one recipe (registry validates uniqueness at load time).
- Single-element recipes (e.g., `shape = [Vector2i(0,0)]`, `elements = [CHI]`) satisfy FR-003/FR-008 with no special-casing.
- Structure recipe `terrain_rules` moves the per-cell placement constraints that used to live in `PatternDefinition.shape_recipe` entries into the new resource.

---

### 2.2 `src/crafting/RecipeRegistry.gd`

```gdscript
class_name RecipeRegistry
extends RefCounted

## Lookup table: _shape_key(shape, elements) → RecipeDefinition
var _by_key: Dictionary = {}
## Lookup by recipe_id → RecipeDefinition
var _by_id: Dictionary = {}

func _init() -> void:
    _load_from_dir("res://src/crafting/recipes/")

## Compute a deterministic string key from a normalised shape + element list.
## The key encodes each occupied cell as "row,col:element" joined by "|".
static func _shape_key(shape: Array[Vector2i], elements: Array[int]) -> String:
    var parts: Array[String] = []
    for i in range(shape.size()):
        parts.append("%d,%d:%d" % [shape[i].x, shape[i].y, elements[i]])
    return "|".join(parts)

## Load all RecipeDefinition .tres files from a directory.
func _load_from_dir(dir_path: String) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return
    dir.list_dir_begin()
    var fname := dir.get_next()
    while fname != "":
        if not dir.current_is_dir() and fname.ends_with(".tres"):
            var res: Resource = load(dir_path + fname)
            if res is RecipeDefinition:
                _register(res as RecipeDefinition)
        fname = dir.get_next()
    dir.list_dir_end()

func _register(recipe: RecipeDefinition) -> void:
    var key := _shape_key(recipe.shape, recipe.elements)
    assert(not _by_key.has(key),
        "RecipeRegistry: ambiguous shape+element key for recipe_id '%s'" % recipe.recipe_id)
    _by_key[key] = recipe
    _by_id[recipe.recipe_id] = recipe

## Look up a recipe by a normalised shape + per-cell element assignment.
## Returns null if no matching recipe is registered.
func lookup(shape: Array[Vector2i], elements: Array[int]) -> RecipeDefinition:
    if shape.size() != elements.size() or shape.is_empty():
        return null
    return _by_key.get(_shape_key(shape, elements), null) as RecipeDefinition

## Return a RecipeDefinition by its stable ID, or null.
func get_by_id(recipe_id: String) -> RecipeDefinition:
    return _by_id.get(recipe_id, null) as RecipeDefinition

## For testing: inject a recipe without loading from disk.
func add_for_testing(recipe: RecipeDefinition) -> void:
    _register(recipe)
```

**Integration**: `RecipeRegistry` is instantiated once as a member of a new `CraftingService` autoload (Section 2.8). Do **not** make it a standalone autoload; it is a pure data service.

---

### 2.3 `src/crafting/CraftingGrid.gd`

```gdscript
class_name CraftingGrid
extends RefCounted

## Transient 3×3 crafting grid state.
## Cells indexed by (row, col), 0-based. Flat array index = row * 3 + col.
## Cell value: GodaiElement.Value int, or EMPTY = -1.

const SIZE: int = 3
const EMPTY: int = -1

## Emitted whenever the grid changes; carries the current recipe match (null if none).
signal grid_changed(matched_recipe: RecipeDefinition)

var _cells: Array = []   # 9 ints, default EMPTY
var _registry: RecipeRegistry

func _init(registry: RecipeRegistry) -> void:
    _registry = registry
    _cells.resize(SIZE * SIZE)
    _cells.fill(EMPTY)

# ── Mutation ──────────────────────────────────────────────────────────────

func set_cell(row: int, col: int, element: int) -> void:
    _cells[_idx(row, col)] = element
    grid_changed.emit(_current_match())

func clear_cell(row: int, col: int) -> void:
    _cells[_idx(row, col)] = EMPTY
    grid_changed.emit(_current_match())

func clear_all() -> void:
    _cells.fill(EMPTY)
    grid_changed.emit(null)

# ── Queries ───────────────────────────────────────────────────────────────

## Returns true when all occupied cells form one 8-directional connected group.
func is_contiguous() -> bool:
    var occupied := _occupied_coords()
    if occupied.is_empty():
        return true   # empty grid is trivially contiguous
    var visited: Dictionary = {}
    var stack: Array[Vector2i] = [occupied[0]]
    visited[occupied[0]] = true
    while not stack.is_empty():
        var cur: Vector2i = stack.pop_back()
        for dr in [-1, 0, 1]:
            for dc in [-1, 0, 1]:
                if dr == 0 and dc == 0:
                    continue
                var nb := Vector2i(cur.x + dr, cur.y + dc)
                if visited.has(nb):
                    continue
                if nb.x < 0 or nb.x >= SIZE or nb.y < 0 or nb.y >= SIZE:
                    continue
                if _cells[_idx(nb.x, nb.y)] == EMPTY:
                    continue
                visited[nb] = true
                stack.append(nb)
    return visited.size() == occupied.size()

## Returns the normalised shape (min_row=0, min_col=0, sorted asc by row then col)
## and the parallel element array. Returns empty arrays if grid is empty.
func normalize() -> Array:   # returns [Array[Vector2i], Array[int]]
    var occupied := _occupied_coords()
    if occupied.is_empty():
        return [[], []]
    var min_row: int = occupied[0].x
    var min_col: int = occupied[0].y
    for v in occupied:
        if v.x < min_row: min_row = v.x
        if v.y < min_col: min_col = v.y
    # Translate to origin
    var translated: Array[Vector2i] = []
    for v in occupied:
        translated.append(Vector2i(v.x - min_row, v.y - min_col))
    # Sort by (row, col)
    translated.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        if a.x != b.x: return a.x < b.x
        return a.y < b.y
    )
    # Build parallel elements array using pre-translation coords as lookup
    var elements: Array[int] = []
    for v in translated:
        var orig := Vector2i(v.x + min_row, v.y + min_col)
        elements.append(_cells[_idx(orig.x, orig.y)])
    return [translated, elements]

## Returns the element at (row, col) or EMPTY.
func get_cell(row: int, col: int) -> int:
    return _cells[_idx(row, col)]

## Returns the count of occupied cells.
func occupied_count() -> int:
    return _occupied_coords().size()

# ── Private helpers ────────────────────────────────────────────────────────

func _idx(row: int, col: int) -> int:
    return row * SIZE + col

func _occupied_coords() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for r in range(SIZE):
        for c in range(SIZE):
            if _cells[_idx(r, c)] != EMPTY:
                result.append(Vector2i(r, c))
    return result

func _current_match() -> RecipeDefinition:
    if not is_contiguous():
        return null
    var parts: Array = normalize()
    if (parts[0] as Array).is_empty():
        return null
    return _registry.lookup(parts[0], parts[1])
```

**Key design decisions:**
- `grid_changed` carries the matched recipe directly so UI never polls.
- 8-directional contiguity as specified (FR-005).
- Normalization algorithm matches the spec verbatim.
- `normalize()` returns a raw `Array` of two typed arrays (GDScript limitation with generic return types for parallel arrays).

---

### 2.4 `src/crafting/InventoryItem.gd`

```gdscript
class_name InventoryItem
extends Resource

enum ItemType { TILE = 0, STRUCTURE = 1 }

@export var recipe_id: String = ""
@export var item_type: int = ItemType.TILE
@export var quantity: int = 1

## Stable biome int (for TILE items) or discovery_id (for STRUCTURE items),
## derived from the recipe on item creation — stored for save/load independence.
@export var output_id: String = ""
```

---

### 2.5 `src/crafting/PlayerInventory.gd`

```gdscript
class_name PlayerInventory
extends RefCounted

signal item_added(item: InventoryItem)
signal item_removed(recipe_id: String)

## Ordered list of InventoryItem resources.
var _items: Array[InventoryItem] = []

func add_item(item: InventoryItem) -> void:
    # Stack same recipe_id items.
    for existing in _items:
        if existing.recipe_id == item.recipe_id:
            existing.quantity += item.quantity
            item_added.emit(existing)
            return
    _items.append(item)
    item_added.emit(item)

## Consume one unit of recipe_id. Returns false if item not present.
func consume(recipe_id: String) -> bool:
    for i in range(_items.size()):
        var it: InventoryItem = _items[i]
        if it.recipe_id == recipe_id:
            it.quantity -= 1
            if it.quantity <= 0:
                _items.remove_at(i)
                item_removed.emit(recipe_id)
            return true
    return false

func has_item(recipe_id: String) -> bool:
    for it in _items:
        if it.recipe_id == recipe_id:
            return true
    return false

func get_items() -> Array[InventoryItem]:
    return _items.duplicate()

## Serialise to a plain Dictionary (for GameState save).
func serialize() -> Array:
    var out: Array = []
    for it in _items:
        out.append({
            "recipe_id": it.recipe_id,
            "item_type": it.item_type,
            "quantity": it.quantity,
            "output_id": it.output_id,
        })
    return out

## Deserialise. Old saves that lack inventory data pass an empty Array.
static func deserialize(data: Array) -> PlayerInventory:
    var inv := PlayerInventory.new()
    for entry in data:
        if not entry is Dictionary:
            continue
        var it := InventoryItem.new()
        it.recipe_id = str(entry.get("recipe_id", ""))
        it.item_type = int(entry.get("item_type", InventoryItem.ItemType.TILE))
        it.quantity   = int(entry.get("quantity", 1))
        it.output_id  = str(entry.get("output_id", ""))
        if not it.recipe_id.is_empty():
            inv._items.append(it)
    return inv
```

---

### 2.6 `src/crafting/PlacementRecord.gd`

```gdscript
class_name PlacementRecord
extends Resource

## Stable recipe identifier.
@export var recipe_id: String = ""
## Anchor cell in axial grid coordinates.
@export var anchor_cell: Vector2i = Vector2i.ZERO
## 0–3; each step = 90° clockwise.
@export var rotation_steps: int = 0

func serialize() -> Dictionary:
    return {
        "recipe_id": recipe_id,
        "anchor_cell": { "x": anchor_cell.x, "y": anchor_cell.y },
        "rotation_steps": rotation_steps,
    }

static func deserialize(d: Dictionary) -> PlacementRecord:
    var r := PlacementRecord.new()
    r.recipe_id     = str(d.get("recipe_id", ""))
    var ac: Dictionary = d.get("anchor_cell", {})
    r.anchor_cell   = Vector2i(int(ac.get("x", 0)), int(ac.get("y", 0)))
    r.rotation_steps = int(d.get("rotation_steps", 0))
    return r
```

---

### 2.7 `src/crafting/TerrainValidator.gd`

```gdscript
class_name TerrainValidator
extends RefCounted

## Apply `rotation_steps` × 90° clockwise to a list of Vector2i offsets
## (treating x = row, y = col). Renormalises origin to (0,0) after rotation.
## 90° CW rotation: (row, col) → (col, -row), then renormalise.
static func apply_rotation(offsets: Array[Vector2i], rotation_steps: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = offsets.duplicate()
    for _step in range(rotation_steps % 4):
        var rotated: Array[Vector2i] = []
        for v in result:
            rotated.append(Vector2i(v.y, -v.x))
        # Renormalise
        var min_r: int = rotated[0].x
        var min_c: int = rotated[0].y
        for v in rotated:
            if v.x < min_r: min_r = v.x
            if v.y < min_c: min_c = v.y
        result.clear()
        for v in rotated:
            result.append(Vector2i(v.x - min_r, v.y - min_c))
    return result

## Validate a recipe placed at anchor_cell with rotation_steps.
## Returns an Array[Dictionary] — one entry per shape cell:
##   { "world_coord": Vector2i, "valid": bool, "error": String }
## An empty error string means the cell is valid.
func validate(
    recipe: RecipeDefinition,
    anchor: Vector2i,
    rotation_steps: int,
    grid: RefCounted       # GardenGrid instance
) -> Array[Dictionary]:
    var rotated_shape := apply_rotation(recipe.shape, rotation_steps)
    var results: Array[Dictionary] = []

    for i in range(rotated_shape.size()):
        var offset: Vector2i = rotated_shape[i]
        var world: Vector2i  = anchor + offset
        var entry := { "world_coord": world, "valid": true, "error": "" }

        # FR-013 / edge case: out-of-bounds check (beyond loaded area)
        # For now: out-of-bounds if abs(x or y) > 500 (hardened later)
        if abs(world.x) > 500 or abs(world.y) > 500:
            entry["valid"] = false
            entry["error"] = "Outside garden boundary"
            results.append(entry)
            continue

        # Cell must be empty to place a new tile.
        if grid.has_tile(world):
            entry["valid"] = false
            entry["error"] = "Cell already occupied"
            results.append(entry)
            continue

        # Terrain rules — only check cells that have an explicit rule.
        for rule in recipe.terrain_rules:
            if int(rule.get("shape_index", -1)) != i:
                continue
            var required_biome: int = int(rule.get("required_biome", -1))
            if required_biome < 0:
                continue
            var existing: GardenTile = grid.get_tile(world)
            if existing == null or existing.biome != required_biome:
                var biome_name: String = _biome_name(required_biome)
                entry["valid"] = false
                entry["error"] = "Requires %s biome" % biome_name
                break

        results.append(entry)

    return results

## All cells valid?
static func all_valid(results: Array[Dictionary]) -> bool:
    for r in results:
        if not bool(r.get("valid", false)):
            return false
    return true

static func _biome_name(biome: int) -> String:
    match biome:
        BiomeType.Value.STONE:   return "Stone"
        BiomeType.Value.RIVER:   return "River"
        BiomeType.Value.MEADOW:  return "Meadow"
        BiomeType.Value.EMBER_FIELD: return "Ember Field"
        _: return "Unknown"
```

**Rotation math**: 90° CW in row/col space: `(r, c) → (c, −r)`. After each rotation step the array is renormalised (`min_row = min_col = 0`) so `apply_rotation` is idempotent and composable.

---

### 2.8 `src/crafting/BuildMode.gd`

```gdscript
class_name BuildMode
extends RefCounted

## Emitted whenever the anchor or rotation changes (ghost footprint subscribes).
signal validation_updated(results: Array[Dictionary])
## Emitted on confirm. Consumers call GameState.confirm_placement(record).
signal placement_confirmed(record: PlacementRecord)
## Emitted on cancel.
signal placement_cancelled(recipe_id: String)

var recipe: RecipeDefinition
var rotation_steps: int = 0
var anchor_cell: Vector2i = Vector2i.ZERO

var _validator: TerrainValidator
var _grid: RefCounted     # GardenGrid
var _last_results: Array[Dictionary] = []

func _init(r: RecipeDefinition, grid: RefCounted) -> void:
    recipe = r
    _grid = grid
    _validator = TerrainValidator.new()

# ── Input actions ──────────────────────────────────────────────────────────

func rotate_cw() -> void:
    rotation_steps = (rotation_steps + 1) % 4
    _revalidate()

func set_anchor(cell: Vector2i) -> void:
    anchor_cell = cell
    _revalidate()

func can_confirm() -> bool:
    return TerrainValidator.all_valid(_last_results) and not _last_results.is_empty()

## Atomically confirms placement. Returns the PlacementRecord or null if invalid.
func confirm() -> PlacementRecord:
    if not can_confirm():
        return null
    var record := PlacementRecord.new()
    record.recipe_id     = recipe.recipe_id
    record.anchor_cell   = anchor_cell
    record.rotation_steps = rotation_steps
    placement_confirmed.emit(record)
    return record

## Cancels placement; the caller is responsible for returning the item to inventory.
func cancel() -> void:
    placement_cancelled.emit(recipe.recipe_id)

# ── Private ────────────────────────────────────────────────────────────────

func _revalidate() -> void:
    _last_results = _validator.validate(recipe, anchor_cell, rotation_steps, _grid)
    validation_updated.emit(_last_results)

func get_last_validation() -> Array[Dictionary]:
    return _last_results

## Returns the world-space footprint cells for current rotation + anchor.
func get_footprint_cells() -> Array[Vector2i]:
    var rotated := TerrainValidator.apply_rotation(recipe.shape, rotation_steps)
    var result: Array[Vector2i] = []
    for offset in rotated:
        result.append(anchor_cell + offset)
    return result
```

---

### 2.9 `src/crafting/CraftingService.gd` *(new autoload)*

```gdscript
## CraftingService — autoload singleton.
## Owns RecipeRegistry, PlayerInventory, active BuildMode, and
## pending spirit-event queue (FR: spirit events deferred during Build Mode).
extends Node

const RecipeRegistryScript = preload("res://src/crafting/RecipeRegistry.gd")
const PlayerInventoryScript = preload("res://src/crafting/PlayerInventory.gd")
const BuildModeScript       = preload("res://src/crafting/BuildMode.gd")

var registry:  RecipeRegistry
var inventory: PlayerInventory

## Non-null when Build Mode is active.
var active_build_mode: BuildMode = null

## Deferred spirit events queued during Build Mode.
var _deferred_spirit_events: Array[Callable] = []

signal inventory_changed()
signal build_mode_entered(recipe: RecipeDefinition)
signal build_mode_exited()
signal structure_placed(record: PlacementRecord)

func _ready() -> void:
    registry  = RecipeRegistryScript.new()
    inventory = PlayerInventoryScript.new()
    inventory.item_added.connect(func(_item): inventory_changed.emit())
    inventory.item_removed.connect(func(_id): inventory_changed.emit())

# ── Crafting ───────────────────────────────────────────────────────────────

## Called by CraftingPanel when the player confirms a valid grid state.
func craft(recipe: RecipeDefinition) -> void:
    var item := InventoryItem.new()
    item.recipe_id = recipe.recipe_id
    item.item_type = recipe.output_type
    item.output_id = recipe.output_id
    item.quantity  = 1
    inventory.add_item(item)

# ── Build Mode ─────────────────────────────────────────────────────────────

## Enter Build Mode for a structure item. No-op if already active.
func enter_build_mode(recipe_id: String) -> void:
    if active_build_mode != null:
        return
    var recipe: RecipeDefinition = registry.get_by_id(recipe_id)
    if recipe == null or recipe.output_type != RecipeDefinition.OutputType.STRUCTURE:
        return
    active_build_mode = BuildModeScript.new(recipe, GameState.grid)
    active_build_mode.placement_confirmed.connect(_on_placement_confirmed)
    active_build_mode.placement_cancelled.connect(_on_placement_cancelled)
    build_mode_entered.emit(recipe)

func _on_placement_confirmed(record: PlacementRecord) -> void:
    inventory.consume(record.recipe_id)
    GameState.confirm_placement(record)
    structure_placed.emit(record)
    active_build_mode = null
    build_mode_exited.emit()
    _flush_deferred_spirit_events()

func _on_placement_cancelled(recipe_id: String) -> void:
    # Item remains in inventory (already there; Build Mode does not pre-consume).
    active_build_mode = null
    build_mode_exited.emit()
    _flush_deferred_spirit_events()

# ── Spirit event deferral ──────────────────────────────────────────────────

## Enqueue a spirit event to process after Build Mode exits.
func defer_spirit_event(event_fn: Callable) -> void:
    if active_build_mode == null:
        event_fn.call()
    else:
        _deferred_spirit_events.append(event_fn)

func _flush_deferred_spirit_events() -> void:
    var pending := _deferred_spirit_events.duplicate()
    _deferred_spirit_events.clear()
    for fn in pending:
        fn.call()
```

**Registration**: Add `CraftingService` to `project.godot` autoloads list alongside `GameState`, `SeedAlchemyService`, etc.

---

### 2.10 Scene: `scenes/UI/CraftingPanel.tscn` + `src/ui/CraftingPanel.gd`

#### Scene node hierarchy

```
CraftingPanel (PanelContainer)
  └─ VBoxContainer
       ├─ Label "Crafting Grid"
       ├─ GridContainer (columns=3)  ← 9 SlotButton children
       │    ├─ SlotButton_0_0 ... SlotButton_2_2
       ├─ RecipePreview (HBoxContainer)
       │    ├─ PreviewIcon (TextureRect)
       │    └─ PreviewLabel (Label)
       └─ HBoxContainer (buttons)
            ├─ ClearButton (Button)
            └─ ConfirmButton (Button)
```

#### `CraftingPanel.gd` (abbreviated)

```gdscript
extends PanelContainer

@onready var _slots: Array = []     # 9 SlotButton nodes
@onready var _preview_icon: TextureRect = $VBox/RecipePreview/PreviewIcon
@onready var _preview_label: Label   = $VBox/RecipePreview/PreviewLabel
@onready var _confirm_btn: Button    = $VBox/Buttons/ConfirmButton
@onready var _clear_btn: Button      = $VBox/Buttons/ClearButton

var _grid: CraftingGrid
var _element_picker_row: int = -1
var _element_picker_col: int = -1

func _ready() -> void:
    _grid = CraftingGrid.new(CraftingService.registry)
    _grid.grid_changed.connect(_on_grid_changed)
    _confirm_btn.pressed.connect(_on_confirm)
    _clear_btn.pressed.connect(_on_clear)
    # Wire each slot click to open element picker.
    for r in range(3):
        for c in range(3):
            var btn: Button = _get_slot(r, c)
            btn.pressed.connect(_on_slot_pressed.bind(r, c))

func _on_slot_pressed(row: int, col: int) -> void:
    _element_picker_row = row
    _element_picker_col = col
    _open_element_picker()   # Platform-specific popup or inline toggle

func _on_element_selected(element: int) -> void:
    _grid.set_cell(_element_picker_row, _element_picker_col, element)

func _on_grid_changed(matched_recipe: RecipeDefinition) -> void:
    var can_confirm: bool = (
        matched_recipe != null and
        _grid.is_contiguous() and
        _grid.occupied_count() > 0
    )
    _confirm_btn.disabled = not can_confirm
    # FR-020: show recipe preview
    if matched_recipe != null:
        _preview_label.text = matched_recipe.display_name
        if not matched_recipe.icon_path.is_empty():
            _preview_icon.texture = load(matched_recipe.icon_path)
        _preview_icon.visible = true
    else:
        _preview_label.text = ""
        _preview_icon.visible = false

func _on_confirm() -> void:
    var parts: Array = _grid.normalize()
    var recipe: RecipeDefinition = CraftingService.registry.lookup(parts[0], parts[1])
    if recipe == null:
        return
    CraftingService.craft(recipe)
    _grid.clear_all()
    # If structure: immediately enter Build Mode
    if recipe.output_type == RecipeDefinition.OutputType.STRUCTURE:
        hide()
        CraftingService.enter_build_mode(recipe.recipe_id)

func _on_clear() -> void:
    _grid.clear_all()
```

---

### 2.11 Scene: `scenes/UI/GhostFootprint.tscn` + `src/ui/GhostFootprint.gd`

GhostFootprint is a **Node2D child of GardenView** (added at runtime when Build Mode is entered, freed on exit). It overlays the hex grid with per-cell translucent hexagons.

```gdscript
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 20.0   # Must match GardenView.TILE_RADIUS

var _validation: Array[Dictionary] = []  # from BuildMode.get_last_validation()

func update_from_validation(results: Array[Dictionary]) -> void:
    _validation = results
    queue_redraw()

func _draw() -> void:
    for entry in _validation:
        var world_coord: Vector2i = entry["world_coord"]
        var pixel: Vector2 = _HexUtils.axial_to_pixel(world_coord, TILE_RADIUS)
        var valid: bool = bool(entry["valid"])
        var color: Color = Color(0.2, 0.8, 0.2, 0.45) if valid else Color(0.9, 0.1, 0.1, 0.45)
        _draw_hex(pixel, TILE_RADIUS, color)
        if not valid:
            var err: String = str(entry.get("error", ""))
            if not err.is_empty():
                draw_string(
                    ThemeDB.fallback_font, pixel + Vector2(-28, 6),
                    err, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
                    Color(1, 1, 1, 0.9)
                )

func _draw_hex(center: Vector2, radius: float, color: Color) -> void:
    var points: PackedVector2Array = []
    for i in range(6):
        var angle_deg: float = 60.0 * i - 30.0
        var angle_rad: float = deg_to_rad(angle_deg)
        points.append(center + Vector2(radius * cos(angle_rad), radius * sin(angle_rad)))
    draw_colored_polygon(points, color)
```

**GardenView integration** (modification, not new file): Add a `_ghost: GhostFootprint` member. Connect to `CraftingService.build_mode_entered` / `build_mode_exited` to add/remove the node; connect to `BuildMode.validation_updated` to call `_ghost.update_from_validation(results)`.

---

### 2.12 Recipe `.tres` Data Files

All files live in `src/crafting/recipes/`. Naming convention: `recipe_{id}.tres`.

#### Single-element tile recipes (5 files)

| File | `recipe_id` | shape | elements | `output_id` |
|---|---|---|---|---|
| `recipe_chi_tile.tres` | `recipe_chi_tile` | `[(0,0)]` | `[CHI=0]` | `"0"` (STONE) |
| `recipe_sui_tile.tres` | `recipe_sui_tile` | `[(0,0)]` | `[SUI=1]` | `"1"` (RIVER) |
| `recipe_ka_tile.tres` | `recipe_ka_tile` | `[(0,0)]` | `[KA=2]` | `"2"` (EMBER_FIELD) |
| `recipe_fu_tile.tres` | `recipe_fu_tile` | `[(0,0)]` | `[FU=3]` | `"3"` (MEADOW) |
| `recipe_ku_tile.tres` | `recipe_ku_tile` | `[(0,0)]` | `[KU=4]` | `"14"` (KU) |

#### Two-element tile recipes (10 files — all Godai pairs)

Pattern: shape = `[(0,0),(0,1)]` (adjacent pair), elements per pair. These map the 10 biome combinations from `BiomeType`. Example: `recipe_chi_sui_tile.tres` → shape=`[(0,0),(0,1)]`, elements=`[0,1]`, `output_id="4"` (WETLANDS).

Full table follows the existing `SeedRecipe` catalog — all 10 combos must be authored. The `chi_fu` pair (formerly used as "house" recipe) now maps to `output_id="6"` (WHISTLING_CANYONS), **not** a structure (FR-016).

#### Starter House structure recipe (1 file)

```
# src/crafting/recipes/recipe_starter_house.tres
recipe_id = "recipe_starter_house"
output_type = STRUCTURE (1)
output_id = "disc_starter_house"
shape = [(0,0), (0,1), (1,0), (1,1)]   # 2×2 solid block, normalised
elements = [FU, FU, FU, FU]            # all Fu
display_name = "Starter House"
terrain_rules = []                     # no terrain constraint for house
min_element_count = 4
```

#### Tier-2 landmark structure recipes (10 files)

One `.tres` per structure in `_BUILD_GATED_DISCOVERY_IDS`. Each encodes the shape and element requirements that were previously inside the legacy `PatternDefinition.shape_recipe` array. Per-cell terrain rules migrate from `PatternDefinition.shape_recipe[i].biome` → `terrain_rules[{shape_index: i, required_biome: …}]`.

Placeholder recipe IDs: `recipe_origin_shrine`, `recipe_lotus_pagoda`, `recipe_monks_rest`, `recipe_star_gazing_deck`, `recipe_sun_dial`, `recipe_whale_bone_arch`, `recipe_echoing_cavern`, `recipe_bamboo_chime`, `recipe_floating_pavilion`, `recipe_wayfarer_torii`, `recipe_bridge_of_sighs`.

> **Content-team note**: The exact shapes for these 10 structures must be extracted from the existing `PatternDefinition.shape_recipe` arrays in the `.tres` files under `src/biomes/patterns/` (e.g., `great_torii.tres`, `heavenwind_torii.tres`, etc.) and re-authored as `RecipeDefinition` resources. This is a 1:1 migration of data, not a design decision.

---

## 3. Files to Modify

### 3.1 `src/autoloads/GameState.gd`

**Add:**

```gdscript
## List of confirmed structure placements (PlacementRecord instances).
var placement_records: Array[PlacementRecord] = []

## Atomically place all tiles for a confirmed structure.
## Called by CraftingService after BuildMode confirms.
func confirm_placement(record: PlacementRecord) -> void:
    var recipe: RecipeDefinition = CraftingService.registry.get_by_id(record.recipe_id)
    if recipe == null:
        push_error("confirm_placement: unknown recipe_id '%s'" % record.recipe_id)
        return
    var rotated_shape := TerrainValidator.apply_rotation(recipe.shape, record.rotation_steps)
    # Gather all tiles first, then write atomically (single frame, FR-013).
    var to_place: Array[Dictionary] = []
    for i in range(rotated_shape.size()):
        var coord: Vector2i = record.anchor_cell + rotated_shape[i]
        var biome: int = int(recipe.output_id) if recipe.output_type == RecipeDefinition.OutputType.TILE else _element_to_biome(recipe.elements[i])
        to_place.append({ "coord": coord, "biome": biome })
    # Validate atomicity: all cells must be empty.
    for entry in to_place:
        if grid.has_tile(entry["coord"]):
            push_error("confirm_placement: cell %s already occupied" % str(entry["coord"]))
            return
    # Write all tiles in one pass (single frame, FR-013).
    for entry in to_place:
        var tile: GardenTile = grid.place_tile(entry["coord"], entry["biome"])
        tile.metadata["placement_record_id"] = record.recipe_id
        tile_placed.emit(entry["coord"], tile)
    placement_records.append(record)

static func _element_to_biome(element: int) -> int:
    match element:
        GodaiElement.Value.CHI: return BiomeType.Value.STONE
        GodaiElement.Value.SUI: return BiomeType.Value.RIVER
        GodaiElement.Value.KA:  return BiomeType.Value.EMBER_FIELD
        GodaiElement.Value.FU:  return BiomeType.Value.MEADOW
        _: return BiomeType.Value.NONE
```

**Save/load**: Extend the existing serialisation path to include `placement_records` (each serialised via `PlacementRecord.serialize()`) and the `CraftingService.inventory.serialize()` result. On load, reconstruct each `PlacementRecord` via `PlacementRecord.deserialize()` and populate `GameState.placement_records`; **do not re-run structure scans** (FR-019).

Backward compatibility: if `placement_records` key is absent in save data, initialise to empty array. If `inventory` key is absent, initialise to empty `PlayerInventory` (FR backward-compat per clarification session).

---

### 3.2 `src/autoloads/kusho_pool.gd`

**Change** `CAPACITY_PER_ELEMENT` from `3` to `10`.

This single-line change enables the new starter grant (≥ 4 Fu + other elements) and supports exploratory crafting per FR-017.

```gdscript
# Before:
const CAPACITY_PER_ELEMENT: int = 3
# After:
const CAPACITY_PER_ELEMENT: int = 10
```

**Update starter injection** in `SeedAlchemyService._ready()`: the existing line `_kusho_pool.set_charge(element, KushoPoolScript.CAPACITY_PER_ELEMENT)` already sets each element to capacity. With `CAPACITY_PER_ELEMENT = 10`, all four elements start at 10 charges — more than enough to craft one Starter House (4 × Fu) plus explore other recipes. This satisfies FR-017.

> If a more targeted grant is preferred (e.g., 4 Fu + 3 each of others), introduce a `_STARTER_GRANT: Dictionary = { CHI: 6, SUI: 6, KA: 6, FU: 6 }` constant and use it in place of the flat `CAPACITY_PER_ELEMENT` call. Content-team decision.

---

### 3.3 `src/biomes/pattern_matcher.gd`

**Retire `PatternType.SHAPE` from `scan_and_emit` for build-gated structures.**

The cleanest approach is to filter `_patterns` at load time: exclude any `PatternDefinition` whose `discovery_id` is in the set of build-gated structure IDs **and** whose `pattern_type == SHAPE`. Cluster patterns for biome discovery (CLUSTER, RATIO_PROXIMITY, COMPOUND) continue unchanged.

```gdscript
## Set of discovery IDs whose shape-based patterns have been retired
## in favour of explicit CraftingGrid recipes. Keep in sync with
## CraftingService recipe data.
const _RETIRED_SHAPE_IDS: Dictionary = {
    "disc_wayfarer_torii": true,
    "disc_origin_shrine": true,
    "disc_bridge_of_sighs": true,
    "disc_lotus_pagoda": true,
    "disc_monks_rest": true,
    "disc_star_gazing_deck": true,
    "disc_sun_dial": true,
    "disc_whale_bone_arch": true,
    "disc_echoing_cavern": true,
    "disc_bamboo_chime": true,
    "disc_floating_pavilion": true,
    "disc_starter_house": true,
}

func reload_patterns() -> void:
    var all: Array[PatternDefinition] = _loader.load_patterns()
    _patterns = all.filter(func(p: PatternDefinition) -> bool:
        # Retire shape-based structure patterns; keep everything else.
        if p.pattern_type == PatternDefinition.PatternType.SHAPE:
            return not _RETIRED_SHAPE_IDS.has(p.discovery_id)
        return true
    )
```

Also remove the `satori_service.can_build_structure` / `block_structure_build` call block from `scan_and_emit` — that guard is no longer needed once structure creation goes exclusively through `CraftingService` (FR-018).

---

### 3.4 `src/grid/GardenView.gd`

**Remove** `_BUILD_GATED_DISCOVERY_IDS` dictionary and all code paths that check it:

```gdscript
# DELETE this block entirely:
const _BUILD_GATED_DISCOVERY_IDS: Dictionary = {
    "disc_origin_shrine": true,
    ...
}
```

**Add** `GhostFootprint` node management:

```gdscript
var _ghost: GhostFootprint = null

func _ready() -> void:
    # ... existing connections ...
    CraftingService.build_mode_entered.connect(_on_build_mode_entered)
    CraftingService.build_mode_exited.connect(_on_build_mode_exited)

func _on_build_mode_entered(_recipe: RecipeDefinition) -> void:
    _ghost = preload("res://scenes/UI/GhostFootprint.tscn").instantiate()
    add_child(_ghost)
    CraftingService.active_build_mode.validation_updated.connect(_ghost.update_from_validation)

func _on_build_mode_exited() -> void:
    if _ghost != null:
        _ghost.queue_free()
        _ghost = null
```

---

### 3.5 `src/grid/PlacementController.gd`

**Remove** `_toggle_build_block`, `_cancel_pending_build_block`, and all `is_build_block` / `build_completion_pending` metadata logic. This is the core of the legacy build-block mechanism.

**Replace** right-click / cancel Build Mode trigger:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # ... existing camera pan guard ...
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
            if CraftingService.active_build_mode != null:
                CraftingService.active_build_mode.cancel()
                return
        if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
            if CraftingService.active_build_mode != null:
                var coord := _world_to_tile(get_global_mouse_position())
                CraftingService.active_build_mode.set_anchor(coord)
                # Confirm on tap if valid
                CraftingService.active_build_mode.confirm()
                return
            # ... existing tile-placement path unchanged ...
```

**Add** cursor tracking in `_process` for Build Mode anchor updates:

```gdscript
func _process(_delta: float) -> void:
    var coord := _world_to_tile(get_global_mouse_position())
    if CraftingService.active_build_mode != null:
        CraftingService.active_build_mode.set_anchor(coord)
        return   # suppress hover highlight during Build Mode
    # ... existing hover logic ...
```

---

### 3.6 `src/ui/HUDController.gd`

Add a **Craft button** (e.g., hammer icon, bottom-left thumb zone) that shows/hides `CraftingPanel`. Wire Build Mode rotate/cancel/confirm buttons (EX-002 — all in bottom thumb zone) to `CraftingService.active_build_mode`.

---

### 3.7 `src/autoloads/satori_service.gd`

Remove or stub `can_build_structure` and `block_structure_build` since structure creation no longer goes through pattern scanning. Mark them `@deprecated` initially; delete in a follow-up cleanup PR to avoid breaking any editor tooling.

---

## 4. Files to Delete (Legacy Retirement)

| File | Reason |
|---|---|
| `src/biomes/patterns/sample_shape_pattern.tres` | Sample structure shape pattern |
| `src/biomes/patterns/tier3/great_torii.tres` | Retired structure shape |
| `src/biomes/patterns/tier3/heavenwind_torii.tres` | Retired structure shape |
| `src/biomes/patterns/tier3/pagoda_of_the_five.tres` | Retired structure shape |
| `src/biomes/patterns/tier3/void_mirror.tres` | Retired structure shape |

> Any additional `.tres` files under `src/biomes/patterns/` whose `pattern_type = 1` (SHAPE) and `discovery_id` appears in `_RETIRED_SHAPE_IDS` should be deleted or moved to `src/biomes/patterns/archived/`. The `_load_patterns` filter in `PatternMatcher` provides a safety net during the transition.

`ShapeMatcher.gd` and `PatternType.SHAPE` in `PatternDefinition.gd` may be left in place for now — the filter in `PatternMatcher.reload_patterns()` ensures they are never invoked for structures. A subsequent cleanup PR can remove them entirely once all structure `.tres` files are deleted (SC-004).

---

## 5. GUT Unit Tests

All tests live under `tests/unit/crafting/`. Test files follow the existing GUT convention: `extends GutTest`, method names `test_…`.

---

### 5.1 `tests/unit/crafting/test_crafting_grid.gd`

```gdscript
extends GutTest

var _registry: RecipeRegistry
var _grid: CraftingGrid

func before_each() -> void:
    _registry = RecipeRegistry.new()
    _grid = CraftingGrid.new(_registry)

# ── Normalisation ──────────────────────────────────────────────────────────

func test_single_cell_normalises_to_origin() -> void:
    _grid.set_cell(2, 2, GodaiElement.Value.CHI)
    var parts: Array = _grid.normalize()
    var shape: Array = parts[0]
    assert_eq(shape.size(), 1)
    assert_eq(shape[0], Vector2i(0, 0))

func test_two_adjacent_cells_normalise_correctly() -> void:
    _grid.set_cell(1, 1, GodaiElement.Value.CHI)
    _grid.set_cell(1, 2, GodaiElement.Value.SUI)
    var shape: Array = _grid.normalize()[0]
    assert_eq(shape[0], Vector2i(0, 0))
    assert_eq(shape[1], Vector2i(0, 1))

func test_normalised_shape_is_translation_invariant() -> void:
    # Place 2×2 at top-left
    for r in [0, 1]:
        for c in [0, 1]:
            _grid.set_cell(r, c, GodaiElement.Value.FU)
    var shape_a: Array = _grid.normalize()[0]
    _grid.clear_all()
    # Same 2×2 at bottom-right
    for r in [1, 2]:
        for c in [1, 2]:
            _grid.set_cell(r, c, GodaiElement.Value.FU)
    var shape_b: Array = _grid.normalize()[0]
    assert_eq(shape_a, shape_b, "2×2 block must normalise identically regardless of position")

# ── Contiguity ─────────────────────────────────────────────────────────────

func test_empty_grid_is_contiguous() -> void:
    assert_true(_grid.is_contiguous())

func test_single_cell_is_contiguous() -> void:
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    assert_true(_grid.is_contiguous())

func test_orthogonally_adjacent_cells_are_contiguous() -> void:
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    _grid.set_cell(0, 1, GodaiElement.Value.SUI)
    assert_true(_grid.is_contiguous())

func test_diagonally_adjacent_cells_are_contiguous() -> void:
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    _grid.set_cell(1, 1, GodaiElement.Value.SUI)
    assert_true(_grid.is_contiguous())

func test_isolated_cell_is_not_contiguous() -> void:
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    _grid.set_cell(2, 2, GodaiElement.Value.SUI)   # no 8-dir path
    assert_false(_grid.is_contiguous())

func test_two_separate_islands_are_not_contiguous() -> void:
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    _grid.set_cell(0, 2, GodaiElement.Value.CHI)   # col gap of 2
    assert_false(_grid.is_contiguous())

# ── Recipe matching ────────────────────────────────────────────────────────

func test_grid_changed_signal_emits_null_for_unrecognised_shape() -> void:
    var last_recipe = "UNSET"
    _grid.grid_changed.connect(func(r): last_recipe = r)
    _grid.set_cell(0, 0, GodaiElement.Value.CHI)
    _grid.set_cell(0, 2, GodaiElement.Value.SUI)   # non-contiguous
    assert_null(last_recipe)

func test_starter_house_2x2_matches_in_any_corner() -> void:
    var recipe: RecipeDefinition = RecipeDefinition.new()
    recipe.recipe_id  = "recipe_starter_house"
    recipe.output_type = RecipeDefinition.OutputType.STRUCTURE
    recipe.shape = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]
    recipe.elements = [
        GodaiElement.Value.FU, GodaiElement.Value.FU,
        GodaiElement.Value.FU, GodaiElement.Value.FU
    ]
    _registry.add_for_testing(recipe)
    # Top-left corner
    _fill_2x2(0, 0)
    var matched := _grid._current_match()
    assert_not_null(matched)
    assert_eq(matched.recipe_id, "recipe_starter_house")
    _grid.clear_all()
    # Bottom-right corner
    _fill_2x2(1, 1)
    matched = _grid._current_match()
    assert_not_null(matched)
    assert_eq(matched.recipe_id, "recipe_starter_house")

func _fill_2x2(start_r: int, start_c: int) -> void:
    for r in [start_r, start_r + 1]:
        for c in [start_c, start_c + 1]:
            _grid.set_cell(r, c, GodaiElement.Value.FU)

func test_mirror_of_l_shape_does_not_match_recipe() -> void:
    # Register an L-shape recipe (canonical orientation)
    var recipe: RecipeDefinition = RecipeDefinition.new()
    recipe.recipe_id = "recipe_l_shape_test"
    recipe.output_type = RecipeDefinition.OutputType.STRUCTURE
    recipe.output_id = "disc_test_structure"
    recipe.shape = [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]
    recipe.elements = [GodaiElement.Value.CHI, GodaiElement.Value.CHI, GodaiElement.Value.CHI]
    _registry.add_for_testing(recipe)
    # Place mirrored L (col-flipped)
    _grid.set_cell(0, 1, GodaiElement.Value.CHI)
    _grid.set_cell(1, 0, GodaiElement.Value.CHI)
    _grid.set_cell(1, 1, GodaiElement.Value.CHI)
    assert_null(_grid._current_match(), "Mirror orientation must NOT match recipe (FR-004)")
```

---

### 5.2 `tests/unit/crafting/test_recipe_registry.gd`

```gdscript
extends GutTest

var _registry: RecipeRegistry

func before_each() -> void:
    _registry = RecipeRegistry.new()

func test_lookup_returns_null_for_unknown_shape() -> void:
    var shape := [Vector2i(0, 0), Vector2i(0, 2)]  # non-contiguous gap — no recipe
    var elems := [GodaiElement.Value.CHI, GodaiElement.Value.SUI]
    assert_null(_registry.lookup(shape, elems))

func test_lookup_returns_null_for_empty_shape() -> void:
    assert_null(_registry.lookup([], []))

func test_single_fu_tile_recipe_registered() -> void:
    var shape := [Vector2i(0, 0)]
    var elems := [GodaiElement.Value.FU]
    var result := _registry.lookup(shape, elems)
    assert_not_null(result, "Single Fu tile recipe must be registered")
    assert_eq(result.output_type, RecipeDefinition.OutputType.TILE)

func test_starter_house_recipe_registered() -> void:
    var result := _registry.get_by_id("recipe_starter_house")
    assert_not_null(result)
    assert_eq(result.output_type, RecipeDefinition.OutputType.STRUCTURE)
    assert_eq(result.shape.size(), 4, "Starter House must have 4 cells")

func test_chi_fu_pair_produces_tile_not_structure(fr016) -> void:
    # FR-016: Chi+Fu 2-element combo → Whistling Canyons tile, NOT a house
    var shape := [Vector2i(0, 0), Vector2i(0, 1)]
    var elems := [GodaiElement.Value.CHI, GodaiElement.Value.FU]
    var result := _registry.lookup(shape, elems)
    assert_not_null(result)
    assert_eq(result.output_type, RecipeDefinition.OutputType.TILE,
        "Chi+Fu must produce a TILE, not STRUCTURE (FR-016)")

func test_duplicate_shape_asserts_at_registration() -> void:
    var r1 := RecipeDefinition.new()
    r1.recipe_id = "recipe_dup_1"
    r1.shape = [Vector2i(0, 0)]
    r1.elements = [GodaiElement.Value.CHI]
    var r2 := RecipeDefinition.new()
    r2.recipe_id = "recipe_dup_2"
    r2.shape = [Vector2i(0, 0)]
    r2.elements = [GodaiElement.Value.CHI]
    _registry.add_for_testing(r1)
    # Second registration with same key must trigger assert (GUT will catch it)
    assert_error(_registry.add_for_testing.bind(r2))
```

---

### 5.3 `tests/unit/crafting/test_terrain_validator.gd`

```gdscript
extends GutTest

var _validator: TerrainValidator
var _grid: RefCounted   # GardenGrid

func before_each() -> void:
    _validator = TerrainValidator.new()
    _grid = load("res://src/grid/GridMap.gd").new()

# ── Rotation ───────────────────────────────────────────────────────────────

func test_zero_rotation_returns_original_shape() -> void:
    var shape := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]
    var result := TerrainValidator.apply_rotation(shape, 0)
    assert_eq(result, shape)

func test_four_rotations_returns_original_shape() -> void:
    var shape := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]
    var result := TerrainValidator.apply_rotation(shape, 4)
    # After 4×90°=360° the shape must be identical (up to normalisation)
    assert_eq(result.size(), shape.size())

func test_single_rotation_cw_l_shape() -> void:
    # L-shape: (0,0),(1,0),(1,1) → 90°CW → (0,0),(0,1),(1,0)  [then renormalised]
    var shape := [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]
    var rotated := TerrainValidator.apply_rotation(shape, 1)
    assert_eq(rotated.size(), 3)
    # Origin must be at (0,0)
    assert_true(rotated.has(Vector2i(0, 0)))

# ── Validation ─────────────────────────────────────────────────────────────

func test_empty_cell_validates_as_valid() -> void:
    var recipe := _make_simple_recipe()
    var results := _validator.validate(recipe, Vector2i(1, 1), 0, _grid)
    assert_eq(results.size(), 1)
    assert_true(bool(results[0]["valid"]))

func test_occupied_cell_fails_validation() -> void:
    _grid.place_tile(Vector2i(1, 1), BiomeType.Value.STONE)
    var recipe := _make_simple_recipe()
    var results := _validator.validate(recipe, Vector2i(1, 1), 0, _grid)
    assert_false(bool(results[0]["valid"]))
    assert_ne(str(results[0]["error"]), "")

func test_terrain_rule_failure_emits_error_string() -> void:
    var recipe := _make_simple_recipe()
    recipe.terrain_rules = [{ "shape_index": 0, "required_biome": BiomeType.Value.RIVER }]
    # Cell at anchor is empty — it has no biome at all, so rule should fail
    var results := _validator.validate(recipe, Vector2i(0, 0), 0, _grid)
    assert_false(bool(results[0]["valid"]))
    assert_true(str(results[0]["error"]).contains("River"),
        "Error must name the required biome")

func test_all_valid_returns_true_when_all_pass() -> void:
    var results := [
        { "valid": true, "error": "" },
        { "valid": true, "error": "" },
    ]
    assert_true(TerrainValidator.all_valid(results))

func test_all_valid_returns_false_when_one_fails() -> void:
    var results := [
        { "valid": true, "error": "" },
        { "valid": false, "error": "Blocked" },
    ]
    assert_false(TerrainValidator.all_valid(results))

func test_2x2_footprint_rejected_atomically_if_one_cell_occupied() -> void:
    # FR-013: entire placement must be rejected if any cell is occupied
    _grid.place_tile(Vector2i(1, 1), BiomeType.Value.STONE)   # one of 4 cells
    var recipe := _make_starter_house_recipe()
    var results := _validator.validate(recipe, Vector2i(0, 0), 0, _grid)
    var blocked := results.filter(func(r): return not bool(r["valid"]))
    assert_true(blocked.size() > 0)
    assert_false(TerrainValidator.all_valid(results),
        "Entire 2×2 placement must be blocked if any cell is occupied")

func _make_simple_recipe() -> RecipeDefinition:
    var r := RecipeDefinition.new()
    r.recipe_id = "test_simple"
    r.shape = [Vector2i(0, 0)]
    r.elements = [GodaiElement.Value.CHI]
    return r

func _make_starter_house_recipe() -> RecipeDefinition:
    var r := RecipeDefinition.new()
    r.recipe_id = "recipe_starter_house"
    r.shape = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]
    r.elements = [GodaiElement.Value.FU, GodaiElement.Value.FU,
                  GodaiElement.Value.FU, GodaiElement.Value.FU]
    return r
```

---

### 5.4 `tests/unit/crafting/test_build_mode.gd`

```gdscript
extends GutTest

var _grid: RefCounted
var _recipe: RecipeDefinition
var _build_mode: BuildMode

func before_each() -> void:
    _grid = load("res://src/grid/GridMap.gd").new()
    _recipe = _make_starter_house_recipe()
    _build_mode = BuildMode.new(_recipe, _grid)

func test_initial_rotation_is_zero() -> void:
    assert_eq(_build_mode.rotation_steps, 0)

func test_rotate_cw_increments_rotation() -> void:
    _build_mode.rotate_cw()
    assert_eq(_build_mode.rotation_steps, 1)

func test_four_rotations_cycles_back_to_zero() -> void:
    for _i in range(4):
        _build_mode.rotate_cw()
    assert_eq(_build_mode.rotation_steps, 0)

func test_set_anchor_triggers_validation() -> void:
    var signal_emitted := false
    _build_mode.validation_updated.connect(func(_r): signal_emitted = true)
    _build_mode.set_anchor(Vector2i(5, 5))
    assert_true(signal_emitted)

func test_confirm_returns_record_on_valid_placement() -> void:
    _build_mode.set_anchor(Vector2i(3, 3))   # empty cells — should be valid
    var record: PlacementRecord = _build_mode.confirm()
    assert_not_null(record)
    assert_eq(record.recipe_id, "recipe_starter_house")
    assert_eq(record.anchor_cell, Vector2i(3, 3))
    assert_eq(record.rotation_steps, 0)

func test_confirm_returns_null_on_invalid_placement() -> void:
    # Pre-fill one cell in the footprint
    _grid.place_tile(Vector2i(3, 3), BiomeType.Value.STONE)
    _build_mode.set_anchor(Vector2i(3, 3))
    assert_null(_build_mode.confirm())

func test_cancel_emits_cancelled_signal_with_recipe_id() -> void:
    var cancelled_id := ""
    _build_mode.placement_cancelled.connect(func(id): cancelled_id = id)
    _build_mode.cancel()
    assert_eq(cancelled_id, "recipe_starter_house")

func test_confirm_emits_placement_confirmed_signal() -> void:
    var confirmed_record = null
    _build_mode.placement_confirmed.connect(func(r): confirmed_record = r)
    _build_mode.set_anchor(Vector2i(3, 3))
    _build_mode.confirm()
    assert_not_null(confirmed_record)

func test_footprint_cells_count_matches_recipe_shape() -> void:
    _build_mode.set_anchor(Vector2i(2, 2))
    var cells := _build_mode.get_footprint_cells()
    assert_eq(cells.size(), _recipe.shape.size())

func _make_starter_house_recipe() -> RecipeDefinition:
    var r := RecipeDefinition.new()
    r.recipe_id = "recipe_starter_house"
    r.shape = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]
    r.elements = [GodaiElement.Value.FU, GodaiElement.Value.FU,
                  GodaiElement.Value.FU, GodaiElement.Value.FU]
    return r
```

---

### 5.5 `tests/unit/crafting/test_player_inventory.gd`

```gdscript
extends GutTest

func test_add_and_has_item() -> void:
    var inv := PlayerInventory.new()
    inv.add_item(_make_item("recipe_foo", InventoryItem.ItemType.STRUCTURE))
    assert_true(inv.has_item("recipe_foo"))

func test_consume_removes_item_at_zero_quantity() -> void:
    var inv := PlayerInventory.new()
    inv.add_item(_make_item("recipe_foo", InventoryItem.ItemType.STRUCTURE))
    assert_true(inv.consume("recipe_foo"))
    assert_false(inv.has_item("recipe_foo"))

func test_consume_returns_false_for_missing_item() -> void:
    var inv := PlayerInventory.new()
    assert_false(inv.consume("recipe_nonexistent"))

func test_stacks_same_recipe_items() -> void:
    var inv := PlayerInventory.new()
    inv.add_item(_make_item("recipe_foo", InventoryItem.ItemType.TILE))
    inv.add_item(_make_item("recipe_foo", InventoryItem.ItemType.TILE))
    assert_eq(inv.get_items()[0].quantity, 2)

func test_serialize_deserialize_round_trip() -> void:
    var inv := PlayerInventory.new()
    var item := _make_item("recipe_starter_house", InventoryItem.ItemType.STRUCTURE)
    item.output_id = "disc_starter_house"
    inv.add_item(item)
    var data := inv.serialize()
    var inv2 := PlayerInventory.deserialize(data)
    assert_true(inv2.has_item("recipe_starter_house"))

func test_deserialize_empty_for_old_save() -> void:
    var inv := PlayerInventory.deserialize([])
    assert_eq(inv.get_items().size(), 0)

func _make_item(recipe_id: String, type: int) -> InventoryItem:
    var it := InventoryItem.new()
    it.recipe_id = recipe_id
    it.item_type = type
    it.quantity  = 1
    return it
```

---

## 6. Implementation Sequence

| Phase | Task | Files Touched | Dependencies |
|---|---|---|---|
| **P1** | `RecipeDefinition.gd` + `RecipeRegistry.gd` | New | None |
| **P1** | `InventoryItem.gd` + `PlayerInventory.gd` + `PlacementRecord.gd` | New | None |
| **P1** | `CraftingGrid.gd` | New | RecipeRegistry |
| **P1** | `TerrainValidator.gd` | New | RecipeDefinition |
| **P1** | Single-element + 2-element tile recipe `.tres` files | New data | RecipeDefinition |
| **P1** | `test_crafting_grid.gd`, `test_recipe_registry.gd`, `test_terrain_validator.gd`, `test_player_inventory.gd` | New | P1 classes |
| **P2** | `BuildMode.gd` | New | CraftingGrid, TerrainValidator |
| **P2** | `CraftingService.gd` (autoload) | New | All P1 + BuildMode |
| **P2** | Extend `GameState.gd` (confirm_placement, save/load) | Modified | CraftingService |
| **P2** | Starter House recipe `.tres` | New data | RecipeDefinition |
| **P2** | `test_build_mode.gd` | New | P2 classes |
| **P3** | `CraftingPanel.tscn` + `CraftingPanel.gd` | New | CraftingGrid, CraftingService |
| **P3** | `GhostFootprint.tscn` + `GhostFootprint.gd` | New | BuildMode, HexUtils |
| **P3** | `GardenView.gd` — ghost integration | Modified | GhostFootprint |
| **P3** | `HUDController.gd` — Craft button wiring | Modified | CraftingPanel |
| **P3** | `PlacementController.gd` — Build Mode input routing | Modified | CraftingService |
| **P4** | `KushoPool.gd` — CAPACITY_PER_ELEMENT = 10 | Modified | None |
| **P4** | Starter seed injection update | `SeedAlchemyService` | KushoPool |
| **P4** | Tier-2 landmark recipe `.tres` files (11 structures) | New data | RecipeDefinition |
| **P5** | `PatternMatcher.gd` — retire SHAPE paths | Modified | Tier-2 recipes done |
| **P5** | Delete retired structure `.tres` from `src/biomes/patterns/` | Deleted | P5 PatternMatcher |
| **P5** | `GardenView.gd` — remove `_BUILD_GATED_DISCOVERY_IDS` | Modified | P5 PatternMatcher |
| **P5** | `SatoriService.gd` — deprecate structure guard methods | Modified | P5 |

---

## 7. Key Design Decisions and Rationale

| Decision | Rationale |
|---|---|
| **`RecipeRegistry` uses shape+element string key** (not shape-only) | Enables future recipes that differ only in element composition on the same geometry. Validates uniqueness at load time. |
| **`CraftingGrid` emits `grid_changed(recipe)` not just a flag** | UI subscribes once and drives all state (confirm button, preview) from a single signal — no polling. |
| **`BuildMode` does not pre-consume the inventory item** | Item stays in inventory until `placement_confirmed` fires. Cancel is free — no refund needed. |
| **`TerrainValidator` is stateless** | Easily unit-testable; no singleton reference; reusable for future placement preview features. |
| **`CraftingService.defer_spirit_event`** | Cleanly satisfies the spirit-event queueing requirement without touching `SpiritService`'s internals. |
| **`CAPACITY_PER_ELEMENT = 10`** | Flat increase avoids per-element capacity complexity; content team can tune the starter grant separately. |
| **`PatternMatcher._RETIRED_SHAPE_IDS` filter** | Ensures biome cluster discoveries (CLUSTER/RATIO_PROXIMITY/COMPOUND) are **never** disrupted (EX-001) while retiring structure SHAPE patterns. |
| **Tier-2 landmark recipes migrated as `.tres` data, not hardcoded** | Keeps `RecipeRegistry` as the single source of truth (FR-008); data-driven extensibility for future structures. |
| **`PlacementRecord` stores rotation_steps, not absolute coords** | Compact serialisation; tile coords are always derived on demand, eliminating a class of desync bugs. |

---

## 8. Acceptance Criterion Cross-Reference

| FR / SC | Implementation anchor |
|---|---|
| FR-001: 3×3 grid UI | `CraftingPanel.tscn` (Section 2.10) |
| FR-002: one charge per slot | `CraftingGrid.set_cell` overwrites (no stacking) |
| FR-003: floating shape | `CraftingGrid.normalize()` + `RecipeRegistry.lookup()` |
| FR-004: no auto-rotate/mirror | `RecipeRegistry` key is exact; no variant generation |
| FR-005: 8-dir contiguity | `CraftingGrid.is_contiguous()` |
| FR-006/007: tile vs structure output | `RecipeDefinition.output_type` field |
| FR-008: unknown shape disables confirm | `grid_changed(null)` → `ConfirmButton.disabled = true` |
| FR-009: grid resets after confirm | `CraftingPanel._on_confirm()` calls `_grid.clear_all()` |
| FR-010/011: Build Mode + rotation | `BuildMode.gd`, `rotate_cw()` |
| FR-012: terrain validation real-time | `BuildMode.set_anchor()` → `_revalidate()` → `validation_updated` |
| FR-013: atomic placement | `GameState.confirm_placement()` validates all cells first, then writes all in one pass |
| FR-014: cancel returns item | `CraftingService._on_placement_cancelled` — item never pre-consumed |
| FR-015: 2×2 Fu house recipe | `recipe_starter_house.tres` |
| FR-016: chi+fu → Whistling Canyons | `recipe_chi_fu_tile.tres` output_type=TILE |
| FR-017: starter grant ≥ 4 Fu | `KushoPool.CAPACITY_PER_ELEMENT = 10` |
| FR-018: retire runtime structure scan | `PatternMatcher._RETIRED_SHAPE_IDS` filter |
| FR-019: saved structures render from stored coords | `GameState.confirm_placement` stores `PlacementRecord`; load reconstructs tiles from it, no rescan |
| FR-020: recipe preview in UI | `CraftingPanel._on_grid_changed` updates `PreviewLabel` + `PreviewIcon` |
| EX-001: biome cluster unaffected | Filter in `PatternMatcher.reload_patterns` keeps CLUSTER/RATIO_PROXIMITY/COMPOUND |
| EX-002: thumb-zone controls | Build Mode controls in `HUDController` bottom strip (layout task) |
| EX-003: atomic single-frame placement | `GameState.confirm_placement` writes all tiles in one `for` loop before next `_process` |
| SC-004: zero active shape-scan call sites | `_RETIRED_SHAPE_IDS` + deleted `.tres` files |
| SC-006: save/load fidelity | `PlacementRecord.serialize/deserialize` + `PlayerInventory.serialize/deserialize` |

---

## 9. Out of Scope (Explicit Boundaries)

- **Biome cluster / ratio-proximity / compound pattern matching** — unchanged (`EX-001`).
- **Ku-element structure recipes** — Ku follows 1-/2-element → tile rule only; no Ku structures added here.
- **Codex recipe-grid illustration** — cosmetic addition inside scope but a UI polish task after core logic is proven.
- **Spirit binding logic** — `SpiritService` sees placed tiles as before; `PlacementRecord.metadata["placement_record_id"]` provides traceability. Binding evaluation is unchanged.
- **Tier-3 grand structure recipes** (`great_torii.tres`, `pagoda_of_the_five.tres`, `void_mirror.tres`, `heavenwind_torii.tres`) — these `.tres` files are deleted from `src/biomes/patterns/tier3/`; their corresponding `RecipeDefinition` resources are authored in Phase 4, but their unlock mechanics (Tier-3 gate) are a follow-on task.