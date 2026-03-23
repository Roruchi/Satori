# Tasks: Biome Alchemy — Mixing and Locking

**Input**: Design documents from `/specs/004-biome-alchemy-mixing/`
**Prerequisites**: spec.md (user stories), codebase exploration

**Scope Note**: Only Forest and Water tiles are currently available in the TileSelector UI. The engine will support all 6 hybrid combinations, but player-facing testing of US1 is limited to Forest+Water=Swamp until additional tile types are added to the UI (out of scope for this feature).

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm existing foundations before building the mixing engine on top of them.

- [x] T001 Review `src/biomes/BiomeType.gd` and `src/grid/TileData.gd` — verify BiomeType.mix() covers all 6 valid base-pair combinations with commutative normalization (sorted input before lookup), and GardenTile has `locked: bool` defaulting to false; fix any gaps

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: New infrastructure that MUST exist before any user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Add long-press input state tracking to `src/grid/PlacementController.gd` — add `const LONG_PRESS_THRESHOLD_MS: float = 500.0`, `_press_start_time: int`, `_press_coord: Vector2i`, `_press_on_occupied: bool`; on `_input` MOUSE_BUTTON_LEFT pressed, record time and whether target coord is occupied; on each `_process` frame while pressed, check if threshold exceeded and coord is occupied, then call internal `_on_long_press(_press_coord)`; cancel on drag or early release before threshold
- [x] T003 Add `replace_tile(coord: Vector2i, new_biome: int)` method to `src/grid/GridMap.gd` — assert tile exists at coord, update `tiles[coord].biome = new_biome`, set `tiles[coord].locked = true`; update `garden_bounds` if needed
- [x] T004 Add `tile_mixed` and `mix_rejected` signals and `try_mix_tile(coord: Vector2i) -> bool` stub to `src/autoloads/GameState.gd` — declare `signal tile_mixed(coord: Vector2i, tile: GardenTile)` and `signal mix_rejected(coord: Vector2i, reason: String)`; stub returns false

**Checkpoint**: Long-press detection plumbed, grid mutation method ready, GameState signals declared — user story implementation can now begin.

---

## Phase 3: User Story 1 — Mix Two Unlocked Base Tiles to Create a Hybrid Biome (Priority: P1) 🎯 MVP

**Goal**: A player long-pressing a different selected base tile onto an existing unlocked base tile triggers the correct hybrid replacement and locks the result.

**Independent Test**: Place a Forest tile at `(1,0)`. Select Water. Hold the mouse button over `(1,0)` for 500ms. Confirm the tile becomes a Swamp tile, `locked == true`, and a distinct merge visual plays.

### Implementation for User Story 1

- [x] T005 [US1] Wire `_on_long_press(coord)` to `GameState.try_mix_tile(coord)` in `src/grid/PlacementController.gd` — in `_on_long_press`, call `GameState.try_mix_tile(coord)` only if the camera pan controller reports no drag gesture
- [x] T006 [US1] Implement mix validation and application in `try_mix_tile()` in `src/autoloads/GameState.gd` — get target tile via `grid.get_tile(coord)`; if tile is null or not occupied, return false; look up `BiomeType.mix(selected_biome, tile.biome)`; if result is a valid hybrid, call `grid.replace_tile(coord, result)`, emit `tile_mixed(coord, grid.get_tile(coord))`, return true
- [x] T007 [US1] Add mix success animation to `src/grid/GardenView.gd` — on `tile_mixed` signal, store `_mixing_coord = coord` and `_mix_timer = 0.4`; in `_process`, decrement timer; in `_draw`, if `_mix_timer > 0`, render a semi-transparent white shimmer rect expanding outward over the tile at `_mixing_coord` (alpha fades from 0.8 to 0 over 0.4s using `_mix_timer / 0.4`); call `queue_redraw()` each frame while timer active

**Checkpoint**: Forest+Water long-press produces a locked Swamp tile with shimmer animation. (Only this pair is player-testable until more tiles are added to TileSelector.)

---

## Phase 4: User Story 2 — Locked Tile Rejects Further Mixing (Priority: P1)

**Goal**: Long-pressing any tile onto a locked tile produces immediate, distinct rejection feedback and no tile change.

**Independent Test**: Create a Swamp tile at `(1,0)` (now locked). Select any tile. Long-press `(1,0)`. Confirm tile stays Swamp, a rejection flash plays, and `locked` remains true.

### Implementation for User Story 2

- [x] T008 [US2] Add locked-tile rejection path in `try_mix_tile()` in `src/autoloads/GameState.gd` — check `tile.locked` first (before any other validation); if true, emit `mix_rejected(coord, "locked")` and return false
- [x] T009 [US2] Implement rejection flash animation in `src/grid/GardenView.gd` — on `mix_rejected` signal, store `_rejected_coord = coord`, `_reject_reason = reason`, `_reject_timer = 0.3`; in `_draw`, if `_reject_timer > 0`, render a red overlay rect on the tile with alpha `0.6 * (_reject_timer / 0.3)` — visually distinct from the white shimmer of a successful mix; call `queue_redraw()` each frame while timer active
- [x] T010 [US2] Add persistent locked indicator rendering to `src/grid/GardenView.gd` — in `_draw`, for every tile where `locked == true`, draw a small filled circle (radius 4px) in the top-right corner of the tile rect using `Color(1.0, 0.85, 0.0)` (gold); ensure indicator is always drawn on top of the biome color rect so it remains legible at Camera2D zoom levels 1× through 4×

**Checkpoint**: Locked tiles show gold indicator dot. Long-pressing a locked tile flashes red without changing the tile.

---

## Phase 5: User Story 3 — Full Catalogue: All 6 Combinations Valid, All Others Invalid (Priority: P3)

**Goal**: Every possible biome-on-biome combination either produces the correct hybrid or is cleanly rejected — no silent failures, no engine errors, no undefined biome types.

**Scope Note**: Player can only exercise Forest+Water (and Swamp-locked rejection) until additional tile types are wired into TileSelector. The engine-level rejection paths below are fully functional regardless.

**Independent Test**: Via code inspection and the `try_mix_tile()` return values, confirm that: same-type placement returns false with reason "same_type"; NONE result from BiomeType.mix() returns false with reason "no_recipe"; all 6 valid pairs return true with correct hybrid.

### Implementation for User Story 3

- [x] T011 [P] [US3] Add same-type rejection path in `src/autoloads/GameState.gd` — in `try_mix_tile()`, after the locked check, if `selected_biome == tile.biome`, emit `mix_rejected(coord, "same_type")` and return false
- [x] T012 [P] [US3] Add no-recipe rejection path in `src/autoloads/GameState.gd` — after computing `BiomeType.mix(selected_biome, tile.biome)`, if result equals `BiomeType.Value.NONE` (or equivalent sentinel), emit `mix_rejected(coord, "no_recipe")` and return false; this guards against any unlocked non-same-type pair that has no entry in the table
- [x] T013 [US3] Add distinct same-type feedback in `src/grid/GardenView.gd` — on `mix_rejected` with reason "same_type", play a yellow pulse overlay (alpha 0.5, duration 0.25s) instead of the red flash used for "locked"; this communicates "invalid mix" rather than "permanently locked"
- [x] T014 [US3] Verify commutative normalization in `src/biomes/BiomeType.gd` — confirm `mix()` sorts the two biome IDs (e.g. `var a = min(biome_a, biome_b)`, `var b = max(biome_a, biome_b)`) before the lookup; if not present, add the sort so Forest+Water and Water+Forest both return Swamp

**Checkpoint**: All rejection paths are distinct and exhaustive. No mix attempt produces an undefined tile type.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Visual completeness and scene wiring across all user stories.

- [x] T015 Add distinct colors for all 6 hybrid biomes in `src/grid/GardenView.gd` — replace the placeholder `Color(0.502, 0.502, 0.502)` (#808080) with unique per-hybrid colors in the biome color lookup: SWAMP `Color(0.25, 0.40, 0.20)` (dark olive), TUNDRA `Color(0.75, 0.88, 0.95)` (pale ice blue), MUDFLAT `Color(0.42, 0.28, 0.15)` (dark mud brown), MOSSY_CRAG `Color(0.45, 0.52, 0.35)` (grey-green), SAVANNAH `Color(0.78, 0.65, 0.25)` (golden straw), CANYON `Color(0.72, 0.35, 0.18)` (burnt orange)
- [x] T016 Connect `GameState.tile_mixed` and `GameState.mix_rejected` signals to `GardenView` in `scenes/Garden.tscn` — in the Garden scene, wire the two GameState autoload signals to the GardenView node so animations trigger correctly without requiring `get_node` calls inside GardenView

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2
- **US2 (Phase 4)**: Depends on Phase 2; integrates with US1 (locked tiles created by US1)
- **US3 (Phase 5)**: Depends on Phase 2; rejection paths build on US1+US2 logic
- **Polish (Phase 6)**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — no cross-story dependencies
- **US2 (P1)**: Can start after Foundational — depends on locked tiles existing (created by US1 mixing, but the rejection path itself is independent)
- **US3 (P3)**: Can start after Foundational — extends the same `try_mix_tile()` function

### Within Each User Story

- Foundational tasks (T002–T004) before story tasks
- GameState logic (try_mix_tile validation) before GardenView animations
- Signals declared before any listener wires to them

### Parallel Opportunities

- T002, T003, T004 in Phase 2 touch different files — can run in parallel
- T011 and T012 in Phase 5 both modify GameState but are separate if-branches — best done sequentially to avoid merge conflicts
- T015 and T016 in Phase 6 touch different files — can run in parallel

---

## Parallel Example: Phase 2 (Foundational)

```
# All three foundational tasks touch different files — launch together:
Task T002: Add long-press tracking to src/grid/PlacementController.gd
Task T003: Add replace_tile() to src/grid/GridMap.gd
Task T004: Add signals and try_mix_tile stub to src/autoloads/GameState.gd
```

---

## Implementation Strategy

### MVP First (US1 Only — Forest+Water pair)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T004)
3. Complete Phase 3: US1 (T005–T007)
4. **STOP AND VALIDATE**: Long-press Forest tile with Water selected → Swamp tile with shimmer animation
5. Demo this single pair as proof of the engine

### Incremental Delivery

1. Setup + Foundational → mixing engine plumbed
2. US1 → first hybrid works, locked state active
3. US2 → rejection feedback complete, locked indicator visible
4. US3 → all edge cases handled, catalogue trustworthy
5. Polish → all hybrids visually distinct, scene wiring clean

---

## Notes

- [P] tasks operate on different files with no cross-task dependencies
- US3 player testing is partially blocked: only Forest+Water is selectable in TileSelector until Stone and Earth tile buttons are added (separate feature)
- The long-press threshold (500ms) in T002 is a starting point — adjust in LONG_PRESS_THRESHOLD_MS constant after playtesting
- `BiomeType.Value.NONE` sentinel used in T012 assumes BiomeType.mix() returns a sentinel for invalid combos — verify the actual return value during T001
- Avoid touching `class_name` declarations in new files per project convention (see memory: Godot 4 class_name scan order causes type-not-found errors on non-leaf types)
