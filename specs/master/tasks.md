# Tasks: Satori — F02 + F03 Minimal Playable Grid

**Input**: Design documents from `specs/master/`
**Features**: F02 · Infinite Grid Engine + F03 · Tile Placement & Organic Adjacency
**Date**: 2026-03-23
**Scope**: Minimal playable game — Grass (Forest) and Water tiles can be placed on an infinite grid with adjacency rules.

> **Scope note**: Chunk management (16×16 partitioning), long-press timing, and mobile haptics are deferred to the full F02/F03 pass. This task set delivers: a flat Dictionary grid, click-to-place input, adjacency validation, Origin auto-placement, and a two-tile selector UI — enough to be a playable game.

> **Implementation note**: T006 (TileSet resource + PNG assets) was replaced by programmatic `draw_rect()` rendering in `GardenView.gd`. This avoids binary resource creation complexity and is fully equivalent for the minimal MVP. The TileMap node is not used; rendering is done via Node2D `_draw()`.

**Prerequisites**: `src/biomes/BiomeType.gd` and `src/grid/TileData.gd` already exist from F01.

**Organization**: Tasks grouped by user story — each story is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no inter-task dependencies)
- **[Story]**: Which user story this task belongs to (US1–US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Wire the Godot project so the game launches from a playable garden scene and the GameState autoload is available globally.

- [x] T001 Set `scenes/Garden.tscn` as the main scene in `project.godot`: in the `[application]` section change (or add) `run/main_scene="res://scenes/Garden.tscn"`
- [x] T002 Register `src/autoloads/GameState.gd` as an autoload singleton in `project.godot`: in the `[autoload]` section add `GameState="*res://src/autoloads/GameState.gd"` so it is available globally without an explicit preload

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Grid data structures and the GameState singleton that all user stories depend on. `TileData` and `BiomeType` already exist (F01) — do not recreate them.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 [P] Create `src/grid/GridMap.gd` — `class_name GridMap`; fields: `var tiles: Dictionary` (Vector2i → TileData), `var total_tile_count: int = 0`, `var garden_bounds: Rect2i`; methods: `func place_tile(coord: Vector2i, biome: BiomeType.Value) -> TileData` — creates a TileData via `TileData.create(coord, biome)`, stores it in `tiles[coord]`, increments `total_tile_count`, expands `garden_bounds`; `func get_tile(coord: Vector2i) -> TileData` — returns `tiles.get(coord, null)`; `func has_tile(coord: Vector2i) -> bool` — returns `tiles.has(coord)`; `func is_placement_valid(coord: Vector2i) -> bool` — returns `true` if `coord == Vector2i.ZERO` (Origin) OR (`not has_tile(coord)` AND at least one of the four cardinal neighbours `[coord + Vector2i(1,0), coord + Vector2i(-1,0), coord + Vector2i(0,1), coord + Vector2i(0,-1)]` is in `tiles`)
- [x] T004 [P] Create `src/autoloads/GameState.gd` — `extends Node`; `var grid: GridMap`; `var selected_biome: BiomeType.Value = BiomeType.Value.FOREST`; `signal tile_placed(coord: Vector2i, tile: TileData)`; in `_ready()`: `grid = GridMap.new()`, then call `grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)` to auto-place the Origin Grass tile and emit `tile_placed.emit(Vector2i.ZERO, grid.get_tile(Vector2i.ZERO))`; expose `func try_place_tile(coord: Vector2i) -> bool` — calls `grid.is_placement_valid(coord)`, if valid calls `grid.place_tile(coord, selected_biome)`, emits `tile_placed`, returns `true`; returns `false` if invalid

**Checkpoint**: `GridMap` and `GameState` exist; Origin tile is placed on game start — user stories can now build on top.

---

## Phase 3: US1 — Grid Visualization (Priority: P1) 🎯 MVP

**Goal**: The player can see the garden — placed tiles appear as colored squares: green for Grass, blue for Water.

**Independent Test**: Press F5 to launch `scenes/Garden.tscn`; a green square is visible at the center of the screen (the Origin tile); no errors in the Output panel.

### Implementation for US1

- [x] T005 [US1] Create `scenes/Garden.tscn` — a root `Node2D` scene with: `Camera2D` (zoom 2×), `GardenView` Node2D (rendering script), `PlacementController` Node2D (input script), and an instanced `TileSelector` CanvasLayer
- [x] T006 [US1] ~~Create TileSet resource and PNG assets~~ — **replaced**: rendering uses `draw_rect()` in GardenView.gd; no TileSet or image assets needed for the minimal MVP
- [x] T007 [US1] Create `src/grid/GardenView.gd` — `class_name GardenView extends Node2D`; renders tiles via `_draw()` using `draw_rect()`; color map: FOREST=#4CAF50, WATER=#2196F3; handles camera pan in `_process()`; exposes `set_hover(coord, valid)` called by PlacementController; draws white dot at origin; draws semi-transparent highlight on valid hover cell
- [x] T008 [US1] Attach `GardenView.gd` as the script on the `GardenView` Node2D in `scenes/Garden.tscn` — done via the `.tscn` file

**Checkpoint**: Press F5 — one green tile visible at center; Output panel clean.

---

## Phase 4: US2 — Tile Placement Input (Priority: P1)

**Goal**: The player can left-click any cell adjacent to an existing tile to place the currently selected tile type. Invalid clicks are silently ignored.

**Independent Test**: Launch `scenes/Garden.tscn`; click a cell directly next to the green Origin tile — a tile of the selected biome appears; clicking a non-adjacent empty cell does nothing; clicking an already-occupied cell does nothing.

### Implementation for US2

- [x] T009 [US2] Create `src/grid/PlacementController.gd` — `class_name PlacementController extends Node2D`; converts mouse position to tile coord via `roundi(world_pos / TILE_SIZE)`; on left-click release calls `GameState.try_place_tile(coord)`; each `_process()` frame calls `_garden_view.set_hover(coord, valid)` for the hover highlight
- [x] T010 [US2] Attach `PlacementController.gd` to a `Node2D` in `scenes/Garden.tscn` — done via the `.tscn` file
- [x] T011 [US2] Hover highlight for valid placement cells — implemented in `PlacementController._process()` updating `GardenView._hover_coord`; GardenView draws a semi-transparent white rect + white border on the hovered cell when valid

**Checkpoint**: Clicking adjacent cells places tiles; valid cells show a white highlight on hover; non-adjacent clicks do nothing.

---

## Phase 5: US3 — Tile Selector UI (Priority: P2)

**Goal**: A visible on-screen panel with "Grass" and "Water" buttons lets the player switch which tile type is placed.

**Independent Test**: Launch `scenes/Garden.tscn`; a panel with two labeled buttons is visible at the bottom of the screen; clicking "Water" changes `GameState.selected_biome` so the next placed tile is blue; clicking "Grass" switches back to green.

### Implementation for US3

- [x] T012 [US3] Create `scenes/UI/TileSelector.tscn` — a `CanvasLayer` (layer 1) with an `HBoxContainer` anchored to bottom-center (anchor_left/right=0.5, anchor_top/bottom=1.0, offsets -100/-64/100/-16); two `Button` children: `GrassButton` and `WaterButton` (96×48 each)
- [x] T013 [US3] Create `src/ui/TileSelector.gd` — `class_name TileSelector extends CanvasLayer`; connects button presses to set `GameState.selected_biome`; highlights the active button (full white) and dims the inactive one (0.6 gray)
- [x] T014 [US3] Add `TileSelector.tscn` as a child instance in `scenes/Garden.tscn` — done via the `.tscn` ext_resource and node instance declaration

**Checkpoint**: Two buttons visible at bottom of screen; clicking each changes the selected tile type; active button is brighter.

---

## Phase 6: Polish & Integration

**Purpose**: Ensure the game is coherent as a minimal playable whole.

- [x] T015 [P] Camera panning with arrow keys — implemented in `GardenView._process()`: reads `Input.get_vector("ui_left","ui_right","ui_up","ui_down")` and moves `_camera.position` at 300 px/s
- [x] T016 [P] Origin marker — implemented in `GardenView._draw()`: `draw_circle(Vector2.ZERO, 3.0, Color.WHITE)` draws a small white dot at the world origin, visible on top of the Grass tile

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Requires Phase 1 (autoload registered before GameState can be used); T003 and T004 can run in parallel
- **Phase 3 (US1 — Visualization)**: Requires Phase 2 complete; T005–T008 are sequential within the story
- **Phase 4 (US2 — Placement)**: Requires Phase 3 complete (PlacementController needs the TileMap node)
- **Phase 5 (US3 — UI)**: Requires Phase 2 (needs GameState.selected_biome); can start after Phase 2 but needs Phase 3 for the scene to exist
- **Phase 6 (Polish)**: Requires Phases 3–5 complete

### User Story Dependencies

- **US1 (Visualization)**: Depends on Foundational (GameState, GridMap)
- **US2 (Placement)**: Depends on US1 (shares scene node references)
- **US3 (Tile Selector)**: Depends on Foundational; independent of US2 but integrated via GameState.selected_biome
- **Polish**: Depends on US1–US3

### Parallel Opportunities

- **Phase 2**: T003 (GridMap.gd) and T004 (GameState.gd) touch different files — run in parallel
- **Phase 6**: T015 (camera pan) and T016 (origin marker) touch different concerns — run in parallel

---

## Parallel Example: Phase 2

```
# Run in parallel — different files, no dependencies:
Task T003: Create src/grid/GridMap.gd
Task T004: Create src/autoloads/GameState.gd
```

---

## Implementation Strategy

### MVP (Phases 1–4)

1. Complete Phase 1: Wire project.godot
2. Complete Phase 2: GridMap + GameState (with Origin tile)
3. Complete Phase 3 (US1): Garden scene + tile visualization
4. Complete Phase 4 (US2): Click-to-place with adjacency
5. **STOP and VALIDATE**: A green tile is visible; clicking adjacent cells places tiles
6. Add Phase 5 (US3) for tile switching when ready

### Full Minimal Playable Delivery

1. Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
2. Each phase adds independently testable value
3. The result: a Godot 4.6 scene where you start with a green Origin tile and can expand the garden with Grass and Water tiles by clicking adjacent cells, using a bottom panel to switch tile type, and arrow keys to pan the camera

---

## Notes

- `BiomeType.gd` and `TileData.gd` were created in F01 (T006/T007) — do not recreate
- GUT tests are NOT included here; add them if TDD is requested for this feature
- `GardenView` uses Node2D `_draw()` + `queue_redraw()` instead of a TileMap node (simpler, no TileSet resource file needed)
- Tiles are drawn *centred* at `coord * TILE_SIZE` in world space; `PlacementController` uses `roundi()` for coordinate conversion
- `GameState` is an autoload singleton — access globally as `GameState.grid` and `GameState.selected_biome`
- `PlacementController` uses `_unhandled_input` (not `_input`) so it does not interfere with UI button clicks
- Full F02 chunking (16×16 chunk load/unload) and F03 long-press timing are out of scope for this minimal delivery
