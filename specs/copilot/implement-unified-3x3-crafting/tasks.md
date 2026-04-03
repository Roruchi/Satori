# Tasks: Unified 3×3 Crafting and Explicit Ghost Placement

**Feature Branch**: `copilot/implement-unified-3x3-crafting`
**Input**: `specs/copilot/implement-unified-3x3-crafting/plan.md` + `spec.md`
**Engine**: Godot 4.6 · GDScript · GUT test framework

**Tests**: All crafting-logic and placement-logic classes MUST have GUT unit
coverage. Scene-heavy and input-routing changes MUST include explicit manual
validation tasks. Test tasks precede or accompany their implementation tasks
within each phase.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

---

## Phase 1: Setup (Directory Structure)

**Purpose**: Create the new `src/crafting/` module tree and test directory so
all subsequent tasks have unambiguous target paths.

- [ ] T001 Create `src/crafting/` directory (add a placeholder `.gitkeep` or open first source file directly in T004/T005/T006)
- [ ] T002 Create `src/crafting/recipes/` directory for `.tres` recipe data files
- [ ] T003 Create `tests/unit/crafting/` directory for GUT unit tests

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data types and pure-logic classes that every user story
depends on. All tasks here must complete before any user-story phase begins.

**⚠️ CRITICAL**: No user story implementation can begin until T004–T011 are complete.

- [ ] T004 [P] Create `RecipeDefinition` resource class in `src/crafting/RecipeDefinition.gd` — `class_name RecipeDefinition extends Resource`; export fields: `recipe_id: String`, `output_type: int` (TILE=0/STRUCTURE=1 enum), `output_id: String`, `shape: Array[Vector2i]` (normalised, sorted by row/col ASC), `elements: Array[int]` (parallel to shape, `GodaiElement.Value`), `display_name: String`, `icon_path: String`, `terrain_rules: Array[Dictionary]`, `min_element_count: int`
- [ ] T005 [P] Create `InventoryItem` resource class in `src/crafting/InventoryItem.gd` — `class_name InventoryItem extends Resource`; export fields: `recipe_id: String`, `item_type: int` (TILE=0/STRUCTURE=1 enum), `quantity: int`, `output_id: String`
- [ ] T006 [P] Create `PlacementRecord` resource class in `src/crafting/PlacementRecord.gd` — `class_name PlacementRecord extends Resource`; export fields: `recipe_id: String`, `anchor_cell: Vector2i`, `rotation_steps: int` (0–3); implement `serialize() -> Dictionary` and `static func deserialize(d: Dictionary) -> PlacementRecord`
- [ ] T007 Create `RecipeRegistry` class in `src/crafting/RecipeRegistry.gd` — `class_name RecipeRegistry extends RefCounted`; `_init()` loads all `.tres` files from `res://src/crafting/recipes/` via `DirAccess`; `lookup(shape, elements) -> RecipeDefinition` using a deterministic string key `"row,col:element|..."` sorted by shape order; `get_by_id(recipe_id) -> RecipeDefinition`; `add_for_testing(recipe)` bypass for unit tests; `assert` on duplicate key at registration (depends on T004)
- [ ] T008 Create `CraftingGrid` class in `src/crafting/CraftingGrid.gd` — `class_name CraftingGrid extends RefCounted`; flat 9-cell `Array` of `GodaiElement.Value | EMPTY (-1)`; `set_cell(row, col, element)`, `clear_cell(row, col)`, `clear_all()`; `is_contiguous() -> bool` using 8-directional BFS; `normalize() -> Array` returning `[Array[Vector2i], Array[int]]` (translate to min_row=0/min_col=0, sort by row then col ASC); `get_cell`, `occupied_count()`; emit `signal grid_changed(matched_recipe: RecipeDefinition)` on every mutation (depends on T007)
- [ ] T009 Create `PlayerInventory` class in `src/crafting/PlayerInventory.gd` — `class_name PlayerInventory extends RefCounted`; `add_item(item)` stacks same `recipe_id`; `consume(recipe_id) -> bool` decrements quantity, removes at zero; `has_item(recipe_id) -> bool`; `get_items() -> Array[InventoryItem]`; `serialize() -> Array`; `static func deserialize(data: Array) -> PlayerInventory` (old saves pass `[]`, returns empty inventory); emit `signal item_added(item)`, `signal item_removed(recipe_id)` (depends on T005)
- [ ] T010 Create `TerrainValidator` class in `src/crafting/TerrainValidator.gd` — `class_name TerrainValidator extends RefCounted`; `static func apply_rotation(offsets: Array[Vector2i], rotation_steps: int) -> Array[Vector2i]` — 90° CW per step: `(r,c)→(c,-r)`, renormalise to min_row=min_col=0 after each step; `func validate(recipe, anchor, rotation_steps, grid) -> Array[Dictionary]` — one entry per shape cell: `{world_coord, valid, error}`; checks: out-of-bounds (|x|>500 or |y|>500), cell already occupied (`grid.has_tile`), terrain rule per `recipe.terrain_rules[i].required_biome`; `static func all_valid(results) -> bool` (depends on T004)
- [ ] T011 Create `BuildMode` controller in `src/crafting/BuildMode.gd` — `class_name BuildMode extends RefCounted`; holds `recipe: RecipeDefinition`, `rotation_steps: int`, `anchor_cell: Vector2i`, `_validator: TerrainValidator`, `_grid`; `rotate_cw()` increments rotation mod 4; `set_anchor(cell)` triggers `_revalidate()`; `can_confirm() -> bool` via `TerrainValidator.all_valid`; `confirm() -> PlacementRecord` (null if invalid, emits `signal placement_confirmed(record)`); `cancel()` emits `signal placement_cancelled(recipe_id)`; `get_footprint_cells() -> Array[Vector2i]`; `get_last_validation() -> Array[Dictionary]`; emit `signal validation_updated(results)` on every revalidation (depends on T010, T004, T006)

**Checkpoint**: All core data types and logic classes are in place — user story phases can begin.

---

## Phase 3: User Story 1 — Craft a Single-Tile Biome (Priority: P1) 🎯 MVP

**Goal**: Player opens crafting grid, places a single (or pair of adjacent) elemental
charge(s), confirms, receives a tile item in inventory, and places it on the board
via the existing tile-placement flow.

**Independent Test**: Open the crafting grid in the debug harness. Place one Chi charge
in the centre slot (row 1, col 1) and confirm. Verify a Stone tile item appears in
inventory. Place it on a valid adjacent cell. Confirm the tile appears on the board
with the correct biome. Verify no structure pattern scan event is emitted.

### Tests for User Story 1

- [ ] T012 [P] [US1] Write GUT test file `tests/unit/crafting/test_crafting_grid.gd` — `extends GutTest`; cover: single cell normalises to `Vector2i(0,0)`; two adjacent cells normalise to `[(0,0),(0,1)]`; 2×2 block normalises identically regardless of grid position (translation invariance); empty grid is contiguous; single cell is contiguous; orthogonally adjacent cells are contiguous; diagonally adjacent cells are contiguous; two cells at (0,0) and (2,2) are NOT contiguous; `grid_changed` emits `null` for non-contiguous shape; Starter House 2×2 matches in all four corners; mirrored L-shape does NOT match canonical L recipe (FR-004)
- [ ] T013 [P] [US1] Write GUT test file `tests/unit/crafting/test_recipe_registry.gd` — cover: `lookup` returns null for unknown shape; `lookup` returns null for empty arrays; single-Fu tile recipe is registered and returns `output_type == TILE`; Starter House recipe is registered with 4-cell shape and `output_type == STRUCTURE`; Chi+Fu pair produces TILE (Whistling Canyons), NOT STRUCTURE (FR-016); registering a duplicate shape key triggers an assert
- [ ] T014 [P] [US1] Write GUT test file `tests/unit/crafting/test_player_inventory.gd` — cover: `add_item` and `has_item`; `consume` removes item at zero quantity; `consume` returns false for missing item; adding same `recipe_id` twice stacks `quantity` to 2; `serialize/deserialize` round-trip preserves `recipe_id`, `item_type`, `output_id`, `quantity`; `deserialize([])` returns empty inventory (old-save compat)

### Implementation for User Story 1

- [ ] T015 [P] [US1] Author 5 single-element tile recipe `.tres` files in `src/crafting/recipes/`: `recipe_chi_tile.tres` (shape=[(0,0)], elements=[CHI=0], output_id="0" STONE), `recipe_sui_tile.tres` (SUI=1, output_id="1" RIVER), `recipe_ka_tile.tres` (KA=2, output_id="2" EMBER_FIELD), `recipe_fu_tile.tres` (FU=3, output_id="3" MEADOW), `recipe_ku_tile.tres` (KU=4, output_id="14" KU) — all `output_type=TILE`, `display_name` set to the tile's biome name, `min_element_count=1`
- [ ] T016 [P] [US1] Author 10 two-element tile recipe `.tres` files in `src/crafting/recipes/` — one per Godai pair combination; shape=`[(0,0),(0,1)]` (adjacent horizontal pair) for each; `output_type=TILE`; `output_id` maps to the combined biome int from `BiomeType`; **critical**: `recipe_chi_fu_tile.tres` → `output_id="6"` (WHISTLING_CANYONS), NOT a structure (FR-016); file names follow `recipe_{element_a}_{element_b}_tile.tres` convention
- [ ] T017 [US1] Create `CraftingService` autoload in `src/crafting/CraftingService.gd` — `extends Node`; owns `var registry: RecipeRegistry` and `var inventory: PlayerInventory` (initialised in `_ready()`); connect `inventory.item_added/item_removed` → emit `signal inventory_changed()`; implement `func craft(recipe: RecipeDefinition)` — creates `InventoryItem` from recipe, calls `inventory.add_item(item)`; stub `enter_build_mode(recipe_id)` as no-op for this phase (extended in T029); declare signals: `inventory_changed`, `build_mode_entered(recipe)`, `build_mode_exited`, `structure_placed(record)` (depends on T007, T009, T004)
- [ ] T018 [US1] Register `CraftingService` autoload in `project.godot` — add entry `autoload/CraftingService="*res://src/crafting/CraftingService.gd"` alongside existing autoloads (`GameState`, `SeedAlchemyService`, etc.)
- [ ] T019 [US1] Create `CraftingPanel` scene in `scenes/UI/CraftingPanel.tscn` — root: `PanelContainer`; child `VBoxContainer` containing: `Label` ("Crafting Grid"), `GridContainer` (columns=3) with exactly 9 `Button` children named `SlotButton_0_0` through `SlotButton_2_2`, `HBoxContainer` "RecipePreview" containing `TextureRect` "PreviewIcon" and `Label` "PreviewLabel", `HBoxContainer` "Buttons" containing `Button` "ClearButton" and `Button` "ConfirmButton" (ConfirmButton disabled by default)
- [ ] T020 [US1] Implement `CraftingPanel` controller in `src/ui/CraftingPanel.gd` — `extends PanelContainer`; `_ready()` instantiates `CraftingGrid.new(CraftingService.registry)`, connects `grid_changed` → `_on_grid_changed`, wires all 9 slot buttons → `_on_slot_pressed(row, col)`, wires ClearButton → `_grid.clear_all()`, ConfirmButton → `_on_confirm()`; `_on_grid_changed(matched_recipe)` updates ConfirmButton.disabled (disable when recipe null, grid empty, or non-contiguous) and shows/hides PreviewIcon+PreviewLabel (FR-020); `_on_confirm()` calls `CraftingService.craft(recipe)`, clears grid; for STRUCTURE output_type: hide panel and call `CraftingService.enter_build_mode(recipe.recipe_id)` (depends on T017, T019, T008)
- [ ] T021 [US1] Add Craft button to `src/ui/HUDController.gd` — add `@onready` reference to a new `Button` "CraftButton" in `scenes/UI/HUD.tscn` (place in bottom-left thumb zone per EX-002); connect pressed signal → toggle `CraftingPanel.visible`; add `@onready var _crafting_panel: CraftingPanel` node reference via `add_child(preload("res://scenes/UI/CraftingPanel.tscn").instantiate())` in `_ready()` (depends on T019, T020)
- [ ] T022 [US1] **Manual validation** — In Godot editor debug harness: open the crafting grid, place a single Chi charge in any slot, confirm; assert Stone tile item appears in `CraftingService.inventory`; place it on a valid adjacent cell; assert tile renders with STONE biome; check Godot Output panel confirms no `PatternMatcher.scan_and_emit` call fires for SHAPE patterns

**Checkpoint**: US1 — Single-tile crafting is fully functional and independently testable

---

## Phase 4: User Story 2 — Craft a Structure from the Grid (Priority: P1)

**Goal**: Player arranges 3+ connected elemental charges matching a known structure
recipe, confirms, and receives a discrete structure inventory item. Mirrored or
non-contiguous arrangements are rejected.

**Independent Test**: Open the crafting grid in the debug harness. Place the correct
shape for Wayfarer Torii (extract canonical shape from plan.md § 2.12). Confirm.
Verify the structure item (not a tile) appears in `CraftingService.inventory`. Verify
no in-world structure tile-scan event is emitted.

### Tests for User Story 2

- [ ] T023 [P] [US2] Extend `tests/unit/crafting/test_recipe_registry.gd` — add: all 11 Tier-2 landmark recipes are registered after registry init; each returns `output_type == STRUCTURE`; a 3-element L-shape in canonical orientation matches its recipe; the same L-shape mirrored does NOT match (strict orientation, FR-004)

### Implementation for User Story 2

- [ ] T024 [P] [US2] Author 11 Tier-2 landmark structure recipe `.tres` files in `src/crafting/recipes/` — one per structure in `_RETIRED_SHAPE_IDS`: `recipe_wayfarer_torii.tres`, `recipe_origin_shrine.tres`, `recipe_bridge_of_sighs.tres`, `recipe_lotus_pagoda.tres`, `recipe_monks_rest.tres`, `recipe_star_gazing_deck.tres`, `recipe_sun_dial.tres`, `recipe_whale_bone_arch.tres`, `recipe_echoing_cavern.tres`, `recipe_bamboo_chime.tres`, `recipe_floating_pavilion.tres`; extract canonical shape + elements from corresponding `.tres` files under `src/biomes/patterns/tier3/` (great_torii → wayfarer_torii, etc.); migrate per-cell biome requirements from `shape_recipe[i].biome` → `terrain_rules[{shape_index: i, required_biome: …}]`; `output_type=STRUCTURE`, `output_id` = the `disc_*` discovery ID string
- [ ] T025 [US2] Update `CraftingPanel._on_confirm()` in `src/ui/CraftingPanel.gd` to handle STRUCTURE output type — after `CraftingService.craft(recipe)`: if `recipe.output_type == RecipeDefinition.OutputType.STRUCTURE`, call `hide()` then `CraftingService.enter_build_mode(recipe.recipe_id)` (Build Mode entry implemented fully in T029; this task ensures the UI side of the transition is wired)
- [ ] T026 [US2] **Manual validation** — Place the Wayfarer Torii shape (3-element L of Chi) in the crafting grid; confirm; assert structure item appears in inventory via `CraftingService.inventory.has_item("recipe_wayfarer_torii")`; assert mirrored arrangement leaves Confirm button disabled; check Output panel for absence of SHAPE scan events

**Checkpoint**: US2 — Structure crafting produces correct inventory items and rejects mirrors/non-contiguous arrangements

---

## Phase 5: User Story 3 — Place a Crafted Structure via Ghost Footprint (Priority: P1)

**Goal**: Player selects a structure item, enters Build Mode, drags a translucent
ghost footprint over the map, optionally rotates it, sees blocked cells highlighted
red with error text, and confirms atomic placement (all tiles appear in one frame).
Cancel returns the item to inventory.

**Independent Test**: Craft a 3-tile structure item. Select it from inventory. Drag
the ghost footprint over an invalid cell and verify red highlight + error text. Move
to a valid location and confirm placement. Verify all tiles of the structure appear
simultaneously on the board in one frame. Verify the structure item is consumed from
inventory. Verify cancel returns the item.

### Tests for User Story 3

- [ ] T027 [P] [US3] Write GUT test file `tests/unit/crafting/test_terrain_validator.gd` — `extends GutTest`; cover: `apply_rotation(shape, 0)` returns original; `apply_rotation(shape, 4)` returns same shape as 0 rotations; 90° CW on L-shape `[(0,0),(1,0),(1,1)]` produces a rotated+normalised result containing `Vector2i(0,0)`; empty cell validates as valid; occupied cell fails validation with non-empty error string; terrain rule failure returns error string containing the biome name (e.g. "River"); `all_valid` returns true when all entries valid; `all_valid` returns false when any entry invalid; 2×2 footprint with one pre-occupied cell: `all_valid` returns false (FR-013 atomic rejection)
- [ ] T028 [P] [US3] Write GUT test file `tests/unit/crafting/test_build_mode.gd` — `extends GutTest`; cover: initial `rotation_steps == 0`; `rotate_cw()` increments to 1; four `rotate_cw()` calls cycle back to 0; `set_anchor()` emits `validation_updated` signal; `confirm()` returns valid `PlacementRecord` with correct `recipe_id`, `anchor_cell`, `rotation_steps` when all cells empty; `confirm()` returns null when a footprint cell is pre-occupied; `cancel()` emits `placement_cancelled` signal with `recipe_id`; `placement_confirmed` signal emits correct record on valid confirm; `get_footprint_cells().size() == recipe.shape.size()`

### Implementation for User Story 3

- [ ] T029 [US3] Extend `CraftingService.gd` with full Build Mode lifecycle — `var active_build_mode: BuildMode = null`; `var _deferred_spirit_events: Array[Callable] = []`; implement `enter_build_mode(recipe_id)` — no-op if already active, fetches recipe via `registry.get_by_id`, validates `output_type == STRUCTURE`, creates `BuildMode.new(recipe, GameState.grid)`, connects `placement_confirmed` → `_on_placement_confirmed`, `placement_cancelled` → `_on_placement_cancelled`, emits `build_mode_entered`; `_on_placement_confirmed(record)` — `inventory.consume`, `GameState.confirm_placement(record)`, emits `structure_placed`, sets `active_build_mode = null`, emits `build_mode_exited`, flushes deferred events; `_on_placement_cancelled` — sets `active_build_mode = null`, emits `build_mode_exited`, flushes deferred events; `defer_spirit_event(fn)` — call immediately if not in Build Mode, else enqueue; `_flush_deferred_spirit_events()` drains and calls all pending callables (depends on T011, T017)
- [ ] T030 [US3] Create `GhostFootprint` scene in `scenes/UI/GhostFootprint.tscn` — root: `Node2D`; attach `src/ui/GhostFootprint.gd`; no child nodes required (renders procedurally via `_draw`)
- [ ] T031 [US3] Implement `GhostFootprint` renderer in `src/ui/GhostFootprint.gd` — `extends Node2D`; `var _validation: Array[Dictionary]`; `func update_from_validation(results)` stores and calls `queue_redraw()`; `_draw()` iterates each result entry: compute pixel centre via `HexUtils.axial_to_pixel(world_coord, TILE_RADIUS)` (TILE_RADIUS must match `GardenView.TILE_RADIUS`); draw filled hex polygon in green (0.2,0.8,0.2,0.45) when valid, red (0.9,0.1,0.1,0.45) when blocked; for blocked cells draw error string using `draw_string(ThemeDB.fallback_font, …)` (depends on T030, `src/grid/hex_utils.gd`)
- [ ] T032 [US3] Extend `GameState.gd` with placement support — add `var placement_records: Array[PlacementRecord] = []`; implement `func confirm_placement(record: PlacementRecord)` — fetch recipe via `CraftingService.registry.get_by_id`; call `TerrainValidator.apply_rotation(recipe.shape, record.rotation_steps)`; compute `to_place: Array[Dictionary]` with `{coord, biome}` per cell using `_element_to_biome(element)`; validate atomicity (all cells empty, abort with `push_error` on first conflict); write all tiles in a single `for` loop calling `grid.place_tile(coord, biome)` and setting `tile.metadata["placement_record_id"]` and emitting `tile_placed`; append `record` to `placement_records`; implement `static func _element_to_biome(element) -> int` mapping CHI→STONE, SUI→RIVER, KA→EMBER_FIELD, FU→MEADOW (depends on T006, T010, T004)
- [ ] T033 [US3] Integrate `GhostFootprint` into `GardenView.gd` — add `var _ghost: GhostFootprint = null`; in `_ready()` connect `CraftingService.build_mode_entered` → `_on_build_mode_entered(_recipe)` and `CraftingService.build_mode_exited` → `_on_build_mode_exited()`; `_on_build_mode_entered` instantiates `preload("res://scenes/UI/GhostFootprint.tscn")`, adds as child, connects `CraftingService.active_build_mode.validation_updated` → `_ghost.update_from_validation`; `_on_build_mode_exited` calls `_ghost.queue_free(); _ghost = null` (depends on T031, T029)
- [ ] T034 [US3] Update `PlacementController.gd` with Build Mode input routing — in `_unhandled_input(event)`: add guard for `CraftingService.active_build_mode != null`; left mouse button release → `set_anchor(_world_to_tile(get_global_mouse_position()))` then `active_build_mode.confirm()`; right mouse button release → `active_build_mode.cancel(); return`; in `_process(_delta)`: if `CraftingService.active_build_mode != null`, call `active_build_mode.set_anchor(_world_to_tile(get_global_mouse_position()))` and `return` to suppress normal hover highlight (depends on T011, T029)
- [ ] T035 [US3] Add Build Mode controls to `HUD.tscn` and `HUDController.gd` — add three `Button` nodes to bottom thumb zone (EX-002): "RotateCWButton" (🔄 icon), "CancelBuildButton" (✕), "ConfirmBuildButton" (✓); in `HUDController.gd._ready()` connect RotateCW pressed → `CraftingService.active_build_mode.rotate_cw()` (guard null); CancelBuild pressed → `CraftingService.active_build_mode.cancel()`; ConfirmBuild pressed → `CraftingService.active_build_mode.confirm()`; connect `CraftingService.build_mode_entered` → show these three buttons; `CraftingService.build_mode_exited` → hide them; hide by default (depends on T029)
- [ ] T036 [US3] **Manual validation** — Craft a structure item (e.g. Wayfarer Torii). Select it from inventory via HUD. Drag ghost footprint over an invalid cell (pre-occupied or wrong biome) → verify blocked cell highlights red and error text is displayed. Move to a valid location → all cells green → confirm via thumb-zone button → verify all structure tiles appear on the board simultaneously in one frame (no intermediate partial state visible). Verify structure item is consumed from `CraftingService.inventory`. Press Cancel on a second attempt → verify item is returned to inventory and Build Mode exits.

**Checkpoint**: US3 — Ghost placement with validation, rotation, atomic confirm, and cancel is fully functional

---

## Phase 6: User Story 4 — New 4-Element Starter House (Priority: P1)

**Goal**: A 2×2 solid block of Fu charges produces the Starter House structure. The
post-tutorial starter grant includes ≥ 4 Fu charges. The legacy Chi+Fu 2-tile house
recipe is replaced by a Whistling Canyons tile (already done in T016 via FR-016).

**Independent Test**: In the debug harness, run new-player tutorial flow. Verify the
player ends with ≥ 4 Fu elemental charges. Open crafting grid, arrange Fu 2×2 in any
corner. Confirm → Starter House structure item in inventory. Place it → spirit-binding
event evaluates it as a valid dwelling. Verify Chi+Fu pair produces only a tile.

### Tests for User Story 4

- [ ] T037 [P] [US4] Extend `tests/unit/crafting/test_recipe_registry.gd` — add: `recipe_starter_house` is registered with `output_type == STRUCTURE`, `shape.size() == 4`, and all 4 elements are FU; `recipe_starter_house` 2×2 Fu shape normalises correctly (lookup succeeds from all four 3×3 grid positions); Chi+Fu pair returns a TILE (verifies FR-016 in data; reuses existing test if present)
- [ ] T038 [P] [US4] Extend `tests/unit/test_kusho_pool.gd` (existing file) — add: assert `KushoPool.CAPACITY_PER_ELEMENT == 10`; assert that a fresh KushoPool started via `SeedAlchemyService` initial grant results in `>=4` Fu charges available (FR-017)

### Implementation for User Story 4

- [ ] T039 [P] [US4] Author `src/crafting/recipes/recipe_starter_house.tres` — `recipe_id = "recipe_starter_house"`, `output_type = STRUCTURE (1)`, `output_id = "disc_starter_house"`, `shape = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]` (2×2 solid block, normalised), `elements = [FU, FU, FU, FU]` (all index 3), `display_name = "Starter House"`, `terrain_rules = []`, `min_element_count = 4`
- [ ] T040 [US4] Change `CAPACITY_PER_ELEMENT` from `3` to `10` in `src/autoloads/kusho_pool.gd` — single-line change: `const CAPACITY_PER_ELEMENT: int = 10`; the existing `SeedAlchemyService._ready()` call `_kusho_pool.set_charge(element, KushoPoolScript.CAPACITY_PER_ELEMENT)` automatically grants 10 of each element — more than enough for one 2×2 Starter House (4 × Fu) plus exploratory crafting (FR-017)
- [ ] T041 [US4] Verify starter injection path in `src/autoloads/seed_alchemy_service.gd` — confirm the `_ready()` loop that calls `set_charge(element, CAPACITY_PER_ELEMENT)` covers FU; add inline comment `# FR-017: ≥ 4 Fu required for Starter House; CAPACITY_PER_ELEMENT is now 10`; no code change required if the loop already sets all elements uniformly (depends on T040)
- [ ] T042 [US4] **Manual validation** — Start a new-player session in the debug harness. Confirm Fu charge count ≥ 4 after initial grant. Open crafting grid, fill a 2×2 block with Fu in any corner. Confirm → Starter House item in inventory. Place it on the map. Confirm a spirit-binding event recognises it as a valid dwelling (check Output panel for correct discovery ID `disc_starter_house`). Attempt Chi+Fu arrangement → confirm only Whistling Canyons tile item is produced.

**Checkpoint**: US4 — Starter House recipe works end-to-end; legacy Chi+Fu house recipe is gone; starter grant is sufficient

---

## Phase 7: User Story 5 — Legacy Structure Pattern-Matching Retired (Priority: P2)

**Goal**: Remove all runtime structure shape-scanning from active code paths. Existing
structures in saved gardens continue to render from stored coordinates. Biome cluster
patterns (CLUSTER, RATIO_PROXIMITY, COMPOUND) remain completely unaffected (EX-001).

**Independent Test**: In a seeded garden with all previously-discovered structure types,
load the garden — verify no `PatternMatcher.scan_and_emit` call fires for any
`_RETIRED_SHAPE_IDS`. Confirm all structures are visible at stored coordinates. Place
new tiles adjacent to a structure footprint → no re-detection. Grep the codebase for
structure-scanning call sites → zero active results.

### Tests for User Story 5

- [ ] T043 [P] [US5] Extend `tests/unit/test_build_mode_regressions.gd` (existing file) — add assertions: after `PatternMatcher.reload_patterns()`, none of the 12 `disc_*` IDs in `_RETIRED_SHAPE_IDS` appear in the active `_patterns` array with `pattern_type == SHAPE`; biome CLUSTER and RATIO_PROXIMITY patterns are still present and active (EX-001 guard); placing tiles matching a retired structure shape triggers no discovery signal for that structure
- [ ] T044 [P] [US5] Extend `tests/unit/test_tier2_landmark_discoveries.gd` (existing file) — add: attempting to trigger a Tier-2 structure discovery via the old tile-placement scan path returns no discovery event; the structure item must instead come via `CraftingService.craft()` → verify `registry.get_by_id("recipe_wayfarer_torii")` is not null

### Implementation for User Story 5

- [ ] T045 [US5] Add `_RETIRED_SHAPE_IDS` filter to `PatternMatcher.reload_patterns()` in `src/biomes/pattern_matcher.gd` — add constant `const _RETIRED_SHAPE_IDS: Dictionary = { "disc_wayfarer_torii": true, "disc_origin_shrine": true, "disc_bridge_of_sighs": true, "disc_lotus_pagoda": true, "disc_monks_rest": true, "disc_star_gazing_deck": true, "disc_sun_dial": true, "disc_whale_bone_arch": true, "disc_echoing_cavern": true, "disc_bamboo_chime": true, "disc_floating_pavilion": true, "disc_starter_house": true }`; in `reload_patterns()` filter loaded patterns: `_patterns = all.filter(func(p) -> bool: if p.pattern_type == PatternDefinition.PatternType.SHAPE: return not _RETIRED_SHAPE_IDS.has(p.discovery_id); return true)`; also remove the `satori_service.can_build_structure` / `block_structure_build` guard block from `scan_and_emit` (FR-018)
- [ ] T046 [P] [US5] Remove `_BUILD_GATED_DISCOVERY_IDS` from `src/grid/GardenView.gd` — delete the `const _BUILD_GATED_DISCOVERY_IDS: Dictionary = { … }` block (line ~78); remove the `if _BUILD_GATED_DISCOVERY_IDS.has(discovery_id) and not _is_any_build_tile_built(disc_coords):` condition and its `_draw_build_block_icon(…)` call body; remove the `is_build_block` metadata read at line ~208 and all `under_construction` rendering logic that depends on it; keep all other rendering paths untouched (depends on T045)
- [ ] T047 [P] [US5] Deprecate `can_build_structure()` and `block_structure_build()` in `src/autoloads/satori_service.gd` — add `## @deprecated: Structure creation now goes exclusively through CraftingService. Remove in follow-up cleanup PR.` doc comment above each method; do NOT delete the methods yet (editor tooling safety net); mark with `push_warning("satori_service: deprecated method called — migrate to CraftingService")` inside each
- [ ] T048 [US5] Delete retired structure pattern files — remove: `src/biomes/patterns/sample_shape_pattern.tres`, `src/biomes/patterns/tier3/great_torii.tres`, `src/biomes/patterns/tier3/heavenwind_torii.tres`, `src/biomes/patterns/tier3/pagoda_of_the_five.tres`, `src/biomes/patterns/tier3/void_mirror.tres`; also delete their `.uid` companion files; the `_RETIRED_SHAPE_IDS` filter in T045 provides safety during the transition (depends on T045)
- [ ] T049 [US5] **Manual validation** — Load a seeded garden containing all previously-discovered structures (Torii, Pagoda, etc.). In the Godot Output panel, confirm no SHAPE pattern scan fires on load. Place biome tiles adjacent to each structure footprint one by one. Confirm no re-detection events appear. Run `grep -r "scan_and_emit\|SHAPE\|can_build_structure\|build_block" src/` and confirm all remaining hits are either in comments, deprecated stubs, or non-structure contexts.

**Checkpoint**: US5 — All runtime structure shape-scanning retired; biome cluster discovery unaffected; saved structures render correctly

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Save/load round-trip fidelity, Codex recipe illustration, EX-003
performance validation, and final integration smoke test across all stories.

- [ ] T050 [P] Extend `GameState.gd` save/load serialisation — in `serialize()` output: add `"placement_records": placement_records.map(func(r): return r.serialize())` and `"inventory": CraftingService.inventory.serialize()`; in `deserialize(data)`: reconstruct `placement_records` via `PlacementRecord.deserialize(d)` for each entry (default `[]` if key absent); reconstruct `CraftingService.inventory` via `PlayerInventory.deserialize(data.get("inventory", []))` (default empty for old saves, FR backward-compat per clarification session); do NOT re-run structure scans on load (FR-019)
- [ ] T051 [P] Add `.uid` companion resource files for all new GDScript files in `src/crafting/` — Godot 4.6 generates `.uid` files automatically on first import; ensure `RecipeDefinition.gd.uid`, `RecipeRegistry.gd.uid`, `CraftingGrid.gd.uid`, `InventoryItem.gd.uid`, `PlayerInventory.gd.uid`, `PlacementRecord.gd.uid`, `TerrainValidator.gd.uid`, `BuildMode.gd.uid`, `CraftingService.gd.uid` are committed; same for `src/ui/CraftingPanel.gd.uid`, `src/ui/GhostFootprint.gd.uid`
- [ ] T052 Extend `CodexPanel.gd` (`src/ui/CodexPanel.gd`) to render a recipe-grid illustration for structure Codex entries — when the displayed entry has a matching `RecipeDefinition` (look up via `CraftingService.registry.get_by_id`), render a 3×3 mini-grid with highlighted cells at `recipe.shape` positions and element colour coding; place below the discovery description text; no-op for biome-cluster discoveries that have no recipe
- [ ] T053 Save/load integration smoke test — craft a tile item (Chi → Stone), craft the Starter House structure, confirm placement, save game; reload; assert: Stone tile item quantity in `CraftingService.inventory` is preserved; placed Starter House tiles are visible at stored coordinates; `GameState.placement_records` contains one record with `recipe_id = "recipe_starter_house"`; no structure scan fires during load (SC-006)
- [ ] T054 Run full GUT test suite — execute `gut -gdir=tests/unit/crafting/ -gexit` (or via Godot editor GUT panel); confirm 0 failing tests across `test_crafting_grid.gd`, `test_recipe_registry.gd`, `test_player_inventory.gd`, `test_terrain_validator.gd`, `test_build_mode.gd`; also run the full `tests/unit/` suite to confirm no regressions in existing tests
- [ ] T055 EX-003 performance spot-check — in the Godot editor profiler, load a medium-size garden and enter Build Mode with the Starter House footprint; drag the ghost footprint across the garden rapidly; confirm frame time stays below 16 ms during ghost position updates; confirm `GameState.confirm_placement` completes within a single `_process` frame (EX-003); record profiler screenshot in `specs/copilot/implement-unified-3x3-crafting/checklists/` if frame spikes are found

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
    └─ Phase 2 (Foundational) — BLOCKS all user story phases
            ├─ Phase 3 (US1: Single-Tile Crafting) — independent P1 story
            ├─ Phase 4 (US2: Structure Crafting) — builds on Phase 3 CraftingService
            ├─ Phase 5 (US3: Ghost Placement) — builds on Phase 4 structure items
            ├─ Phase 6 (US4: Starter House) — independent; only needs Phase 2 + T017
            └─ Phase 7 (US5: Retire Legacy) — can start after Phase 4 Tier-2 recipes done
                    └─ Phase 8 (Polish) — after all desired stories complete
```

### User Story Dependencies

| Story | Depends On | Can Parallelise With |
|---|---|---|
| **US1** (P1) | Phase 2 complete | US4 (independent data) |
| **US2** (P1) | US1 (CraftingService, CraftingPanel wired) | US4 |
| **US3** (P1) | US2 (structure items exist to place) | US4, US5 prep |
| **US4** (P1) | Phase 2 + T017 (CraftingService) | US1, US2, US5 prep |
| **US5** (P2) | US2 Tier-2 recipes (T024) complete | US3 ghost work |

### Within Each Phase

1. All `[P]`-marked tasks within a phase can run concurrently (different files)
2. RecipeDefinition (T004) must exist before RecipeRegistry (T007)
3. RecipeRegistry (T007) must exist before CraftingGrid (T008)
4. TerrainValidator (T010) must exist before BuildMode (T011)
5. CraftingService (T017) must be registered (T018) before UI scenes wire to it
6. GameState.confirm_placement (T032) must exist before CraftingService wires to it (T029)
7. PatternMatcher filter (T045) must exist before deleting `.tres` files (T048)

---

## Parallel Opportunities

### Phase 2 — Can run all in parallel (different files):
```
T004 RecipeDefinition.gd    T005 InventoryItem.gd    T006 PlacementRecord.gd
```
Then when complete:
```
T007 RecipeRegistry.gd    T009 PlayerInventory.gd    T010 TerrainValidator.gd
```
Then:
```
T008 CraftingGrid.gd    T011 BuildMode.gd
```

### Phase 3 — Tests and data can run in parallel with each other:
```
T012 test_crafting_grid.gd     T013 test_recipe_registry.gd    T014 test_player_inventory.gd
T015 single-element .tres ×5   T016 two-element .tres ×10
```

### Phase 5 — Tests can run in parallel with scene creation:
```
T027 test_terrain_validator.gd    T028 test_build_mode.gd
T030 GhostFootprint.tscn          T031 GhostFootprint.gd
```

### Phase 7 — All retirement tasks can run in parallel once T045 is done:
```
T046 GardenView cleanup    T047 SatoriService deprecation    T048 Delete .tres files
```

---

## Implementation Strategy

### MVP First (User Stories 1–4 Only — complete new Craft→Place pipeline)

1. Complete Phase 1: Setup (minutes)
2. Complete Phase 2: Foundational (T004–T011) — **CRITICAL BLOCKER**
3. Complete Phase 3: US1 (single-tile crafting + UI) — **STOP AND VALIDATE**
4. Complete Phase 4: US2 (structure crafting)
5. Complete Phase 5: US3 (ghost placement)
6. Complete Phase 6: US4 (Starter House + grant)
7. **DEMO**: Full Craft → Inventory → Place pipeline works end-to-end
8. Complete Phase 7: US5 (legacy retirement) — can be done as separate PR

### Incremental Delivery

| Milestone | Deliverable | Validates |
|---|---|---|
| After Phase 3 | Tile crafting works in game | US1 accepted |
| After Phase 4 | Structure crafting works | US2 accepted |
| After Phase 5 | Ghost placement works | US3 accepted |
| After Phase 6 | Starter House end-to-end | US4 accepted + tutorial path |
| After Phase 7 | Legacy scanner retired | US5 accepted + SC-004 |
| After Phase 8 | Save/load fidelity + perf | SC-006 + EX-003 |

---

## Notes

- `[P]` marks tasks that touch different files and have no intra-phase ordering dependency — safe to run concurrently
- `[USn]` label maps each task to the user story it satisfies for traceability against spec.md acceptance criteria
- All `.tres` recipe files must be saved as Godot `Resource` format with `RecipeDefinition` as the script class
- `GhostFootprint` uses `queue_redraw()` not `update()` — Godot 4 API
- Spirit events deferred during Build Mode via `CraftingService.defer_spirit_event()` — do not call spirit service directly during active `BuildMode`
- The `_RETIRED_SHAPE_IDS` filter in `PatternMatcher` is the safety net: delete `.tres` files (T048) AFTER the filter is merged (T045), never before
- Old save files: `placement_records` key absent → empty array; `inventory` key absent → empty `PlayerInventory` — forward-compat reads default `item_type` to TILE when field absent
- Commit after each phase checkpoint to enable clean rollback if needed
