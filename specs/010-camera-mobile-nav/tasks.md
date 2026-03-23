# Tasks: Camera and Mobile Navigation

**Input**: Design documents from `/specs/010-camera-mobile-nav/`
**Prerequisites**: spec.md
**Feature Branch**: `010-camera-mobile-nav`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Paths are relative to the repository root (`C:\Repo\Personal\Games\Satori\`)

---

## Phase 1: Setup

**Purpose**: Prepare the camera controller file and scene wiring.

- [x] T001 Create `src/camera/CameraPanController.gd` as an empty Node2D script with exported pan parameters and a comment header

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Connect the CameraPanController into the main scene so it has access to Camera2D before any user story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Add CameraPanController as a child node of the main scene root in `scenes/Main.tscn`, positioned as a sibling of GardenView, and export-link its `_camera` reference to the existing `Camera2D` node
- [x] T003 Remove the keyboard-panning `_process` block from `src/grid/GardenView.gd` and re-implement it inside `src/camera/CameraPanController.gd` so keyboard panning still works via the new controller

**Checkpoint**: Launch the game — keyboard panning (WASD / arrow keys) still works via CameraPanController; GardenView no longer handles input.

---

## Phase 3: User Story 1 — Basic Drag Panning (Priority: P1) 🎯 MVP

**Goal**: Drag with a mouse button or single finger to pan the camera. Camera stops immediately on release. Tile placement is not triggered by drags.

**Independent Test**: Open the game. Drag the mouse across the viewport — the camera follows the pointer. Release — camera stops immediately. Pan until tiles placed off-screen are visible. Verify that clicking (no drag) still places a tile normally.

### Implementation for User Story 1

- [x] T004 [US1] Add drag-state tracking fields (`_dragging: bool`, `_last_drag_pos: Vector2`) to `src/camera/CameraPanController.gd`
- [x] T005 [US1] Implement `_unhandled_input` in `src/camera/CameraPanController.gd` to handle `InputEventMouseButton` (left button press/release) and set `_dragging` and `_last_drag_pos` accordingly
- [x] T006 [US1] Handle `InputEventMouseMotion` in `_unhandled_input` in `src/camera/CameraPanController.gd`: when `_dragging` is true, compute the world-space delta from `event.relative / _camera.zoom` and subtract it from `_camera.position`
- [x] T007 [US1] Handle `InputEventScreenTouch` (touch press/release) in `_unhandled_input` in `src/camera/CameraPanController.gd` using the same drag-state logic as mouse
- [x] T008 [US1] Handle `InputEventScreenDrag` (single-finger drag) in `_unhandled_input` in `src/camera/CameraPanController.gd`: apply `event.relative / _camera.zoom` delta to `_camera.position`
- [x] T009 [US1] Add a `drag_threshold_px: float = 8.0` exported parameter to `src/camera/CameraPanController.gd` and track cumulative drag distance; expose a `is_drag_gesture() -> bool` method that returns true when the pointer has moved beyond the threshold since press
- [x] T010 [US1] Update `src/grid/PlacementController.gd` to call `_camera_pan.is_drag_gesture()` (via a reference set in the scene) before confirming a tile-placement tap — suppress placement if a drag was in progress

**Checkpoint**: Drag to pan works on desktop and touch. Releasing the pointer/finger stops the camera immediately. Tapping (no drag) still places tiles; dragging does not.

---

## Phase 4: User Story 2 — Momentum Panning (Priority: P2)

**Goal**: After a fast swipe the camera drifts and decelerates to a stop organically.

**Independent Test**: Fast swipe and lift — camera continues moving and decelerates over ~0.5–1.5 s. Slow drag then release — minimal drift. Touch during drift — drift stops immediately.

### Implementation for User Story 2

- [ ] T011 [P] [US2] Add exported momentum parameters to `src/camera/CameraPanController.gd`: `friction: float = 8.0` (deceleration multiplier), `max_velocity: float = 2000.0`
- [ ] T012 [P] [US2] Add `_pan_velocity: Vector2` field to `src/camera/CameraPanController.gd` and compute a rolling average drag velocity during active drags by sampling `event.relative / delta` each `InputEventScreenDrag` / `InputEventMouseMotion` frame
- [ ] T013 [US2] On drag release in `src/camera/CameraPanController.gd`, assign the rolling average velocity to `_pan_velocity` (clamped to `max_velocity`)
- [ ] T014 [US2] In `_process` in `src/camera/CameraPanController.gd`, apply `_pan_velocity` to `_camera.position` and decay `_pan_velocity` by `friction * delta` each frame; zero out when magnitude drops below 1.0
- [ ] T015 [US2] Zero out `_pan_velocity` on new drag press in `src/camera/CameraPanController.gd`

**Checkpoint**: Momentum panning feels fluid. Deceleration curve is tunable via exported parameters in the Godot inspector.

---

## Phase 5: User Story 3 — Pinch-to-Zoom (Priority: P2)

**Goal**: Two-finger pinch to zoom in/out with hard clamping at configurable limits.

**Independent Test**: Pinch out — tiles grow. Pinch in — tiles shrink. Pinch past the maximum — zoom stops at the limit with no overshoot. Simultaneous pan and pinch — system transitions to pinch mode correctly.

### Implementation for User Story 3

- [ ] T016 [P] [US3] Add exported zoom parameters to `src/camera/CameraPanController.gd`: `zoom_min: float = 0.5`, `zoom_max: float = 4.0`
- [ ] T017 [P] [US3] Add pinch-state tracking fields (`_touch_points: Dictionary`, `_pinch_initial_distance: float`, `_pinch_initial_zoom: float`) to `src/camera/CameraPanController.gd`
- [ ] T018 [US3] Handle second finger touch-down (`InputEventScreenTouch` with index > 0) in `src/camera/CameraPanController.gd`: record second touch point, store initial pinch distance, discard any active pan velocity
- [ ] T019 [US3] Handle `InputEventScreenDrag` for the second finger in `src/camera/CameraPanController.gd`: compute current distance between two touch points, derive zoom scale factor, apply to `_camera.zoom` clamped to `[zoom_min, zoom_max]`
- [ ] T020 [US3] Handle second finger touch-up in `src/camera/CameraPanController.gd`: exit pinch mode, re-enter single-finger pan mode with zero initial velocity

**Checkpoint**: Pinch-to-zoom works reliably. Zoom never exceeds limits regardless of pinch speed.

---

## Phase 6: User Story 4 — Double-Tap Re-Centre (Priority: P2)

**Goal**: Double-tap anywhere snaps camera back to (0,0) instantly and cancels any active drift.

**Independent Test**: Pan far away — double-tap — camera snaps to origin in one frame. Slow taps separated by > 300 ms do not trigger re-centre.

### Implementation for User Story 4

- [ ] T021 [P] [US4] Add double-tap state fields (`_last_tap_time: float`, `_last_tap_pos: Vector2`, `double_tap_threshold_ms: float = 300.0`, `double_tap_radius_px: float = 40.0`) to `src/camera/CameraPanController.gd`
- [ ] T022 [US4] In the press handler in `src/camera/CameraPanController.gd`, check if current press is within `double_tap_threshold_ms` and `double_tap_radius_px` of the previous press; if so, snap `_camera.position` to `Vector2.ZERO`, zero out `_pan_velocity`, and consume the event
- [ ] T023 [US4] Update `_last_tap_time` and `_last_tap_pos` on every press in `src/camera/CameraPanController.gd` (used by the double-tap check in T022)

**Checkpoint**: Double-tap re-centres reliably. Slow taps and tile-placement taps are not mis-identified.

---

## Phase 7: User Story 5 — Thumb-Zone UI Layout (Priority: P3)

**Goal**: Tile selector and settings button sit in the bottom 30% of the viewport in portrait mode.

**Independent Test**: Run on a 6.1-inch portrait phone — all interactive UI is reachable with a thumb without grip adjustment.

### Implementation for User Story 5

- [ ] T024 [US5] Open `scenes/Main.tscn` and move the TileSelector CanvasLayer / Control root to anchor bottom-left/bottom-right with a margin so its top edge sits at 70% of the screen height
- [ ] T025 [US5] Ensure the settings button (if present) is anchored within the same bottom-30% strip in `scenes/Main.tscn`
- [ ] T026 [US5] Run the game in 1080×2340 (portrait) window size and visually confirm all interactive elements are below the 70% height line

**Checkpoint**: UI is within thumb reach on a standard tall-aspect phone.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T027 [P] Add soft-boundary resistance: in `_process` of `src/camera/CameraPanController.gd`, read `GameState.grid.garden_bounds`, compute a padded boundary (exported `boundary_padding_tiles: int = 20`), and scale pan velocity down exponentially as the camera moves beyond that boundary
- [ ] T028 [P] Add spring-back: when the camera is beyond the soft boundary and `_pan_velocity` is near zero, apply a gentle spring force toward the nearest in-bounds position in `src/camera/CameraPanController.gd`
- [ ] T029 Verify drag-vs-tap threshold prevents accidental tile placement during fast panning in `src/grid/PlacementController.gd`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Stories (Phases 3–7)**: All depend on Phase 2; stories can proceed in priority order
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependencies on other stories
- **US2 (P2)**: Depends on US1 (momentum builds on top of drag infrastructure)
- **US3 (P2)**: Can start after Phase 2 — independent of US1/US2
- **US4 (P2)**: Can start after Phase 2 — independent of US1/US2/US3
- **US5 (P3)**: Can start after Phase 2 — fully independent UI change

### Parallel Opportunities

- T011 + T012 (US2 setup fields) can run in parallel
- T016 + T017 (US3 setup fields) can run in parallel
- T021 (US4 double-tap fields) can run in parallel with T016/T017
- T027 + T028 (polish) can run in parallel

---

## Parallel Example: User Story 1

```
# All independent setup tasks within US1:
T004  Add drag-state tracking fields
T005  Implement mouse button handler     ← depends on T004
T007  Implement touch press/release      ← depends on T004 (different events, parallel with T005)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — keyboard panning migrated)
3. Complete Phase 3: User Story 1 (basic drag panning)
4. **STOP and VALIDATE**: Drag to pan works; tiles still place on tap; camera stops on release
5. Ship / demo

### Incremental Delivery

1. Phase 1 + 2 → keyboard panning migrated to CameraPanController
2. Phase 3 (US1) → basic drag panning — **MVP**
3. Phase 4 (US2) → momentum added
4. Phase 5 (US3) → pinch-to-zoom added
5. Phase 6 (US4) → double-tap re-centre added
6. Phase 7 (US5) → thumb-zone UI layout
7. Phase 8 → soft boundary + spring-back polish

---

## Notes

- `[P]` tasks = different fields/files, no dependencies between them
- `[Story]` label maps task to specific user story for traceability
- All tasks in Phases 1–3 are the **minimum** needed to ship a playable improvement
- Do not implement momentum (US2) until basic drag (US1) is validated
- Drag threshold (T009–T010) is critical — without it, every pan will suppress tile placement
