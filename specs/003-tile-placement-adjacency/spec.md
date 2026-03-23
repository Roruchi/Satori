# Feature Specification: Tile Placement and Organic Adjacency

**Feature Branch**: `003-tile-placement-adjacency`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Tile placement with organic adjacency rules and long-press interaction"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Long-Press to Place a Base Tile on an Adjacent Coordinate (Priority: P1)

As a player building my garden, I want to touch and hold an empty coordinate that is directly adjacent to an existing tile and have my chosen base tile (Forest, Water, Stone, or Earth) appear there when the long-press threshold is crossed, so that garden growth feels intentional and deliberate.

**Why this priority**: This is the core interaction loop of the entire game. Every other feature depends on tile placement working correctly. Without it nothing else can be demonstrated or tested.

**Independent Test**: Open the game with a garden containing only the Origin tile at `(0,0)`. Select the Forest tile type from the selector. Long-press the coordinate `(1,0)` for 350ms. Confirm a Forest tile appears at `(1,0)` in the same frame the threshold is crossed. Confirm no tile appears when pressing for only 200ms. Confirms FR-001, FR-002, FR-008.

**Acceptance Scenarios**:

1. **Given** a garden with the Origin tile at `(0,0)` and Forest selected, **When** the player long-presses coordinate `(0,1)` for 350ms, **Then** a Forest tile appears at `(0,1)` within the same frame the 300–400ms threshold is crossed.
2. **Given** the same setup, **When** the player releases the touch at 200ms (before threshold), **Then** no tile is placed and no permanent state changes.
3. **Given** a Forest tile at `(0,1)`, **When** the player long-presses `(0,2)` (adjacent to `(0,1)`) for 350ms, **Then** a tile of the currently selected type is placed at `(0,2)`.
4. **Given** any placed tile, **When** the player long-presses a diagonal coordinate such as `(1,1)` (not 4-directionally adjacent to any tile), **Then** the placement is rejected with visible feedback.

---

### User Story 2 - Origin Tile Auto-Placed at Session Start (Priority: P1)

As a new player opening the game for the first time (or starting a new garden), I want the first tile — my chosen biome type — to be automatically placed at coordinate `(0,0)` before I interact with the grid, so that I always have a starting anchor and understand where the garden begins.

**Why this priority**: The Origin tile is the mandatory seed for adjacency validation. Without it the first-placement rule (FR-002 exempts the very first tile) would have no anchor, and the garden session would have no defined starting state.

**Independent Test**: Start a fresh garden session with no saved data. Before any touch input, confirm `(0,0)` is occupied with the player's initial base tile choice (or the default biome if no choice is presented yet). Confirm the tile is shown on screen.

**Acceptance Scenarios**:

1. **Given** a new garden session starting, **When** the game initialises the garden, **Then** coordinate `(0,0)` is occupied by the Origin tile before any player input is processed.
2. **Given** the Origin tile at `(0,0)`, **When** the player long-presses `(1,0)`, **Then** the placement is accepted because `(1,0)` is adjacent to the Origin — confirming the Origin acts as a valid adjacency anchor.

---

### User Story 3 - Valid Placement Zone Highlight on Long-Press Start (Priority: P2)

As a player, I want all eligible placement coordinates to be visually highlighted as soon as I begin a long-press gesture anywhere on the grid, so that I can see at a glance where I am allowed to plant my next tile.

**Why this priority**: This is a usability enhancement that prevents frustration from failed placements. It is independently deliverable as a visual overlay and does not block core placement logic.

**Independent Test**: With a garden of 5 tiles in an L-shape, initiate a long-press anywhere. Within one frame confirm a highlight overlay appears on exactly the valid adjacent empty coordinates (those 4-directionally adjacent to an existing tile and currently unoccupied). Confirm the highlight disappears on finger lift.

**Acceptance Scenarios**:

1. **Given** a garden with tiles at `(0,0)` and `(1,0)`, **When** the player initiates a long-press gesture anywhere, **Then** highlights appear on `(0,-1)`, `(0,1)`, `(1,-1)`, `(1,1)`, `(2,0)`, and `(-1,0)` within one frame.
2. **Given** the highlights are displayed, **When** the player lifts their finger before the threshold, **Then** all highlights are removed immediately.
3. **Given** a non-adjacent coordinate is highlighted as invalid, **When** the player completes a long-press on it, **Then** a rejection animation or shake plays and no tile is placed.

---

### User Story 4 - Garden Growth Extends in Any Direction (Priority: P3)

As a player, I want to be able to expand my garden in any compass direction indefinitely by placing tiles at the edges of my current garden, so that the garden feels truly open-ended and exploration is rewarded.

**Why this priority**: This validates that the adjacency and grid systems together support unbounded growth, not just growth within a fixed region.

**Independent Test**: Build a scripted garden that extends in all four cardinal directions from the origin by 50 tiles each. Confirm each new tile is accepted by the adjacency rule and the grid stores and renders all 200+ tiles correctly.

**Acceptance Scenarios**:

1. **Given** tiles extending to coordinate `(50, 0)`, **When** the player long-presses `(51, 0)`, **Then** the placement is accepted as valid (adjacent to existing tile at `(50,0)`).
2. **Given** tiles extending in the negative direction to `(-50, 0)`, **When** the player long-presses `(-51, 0)`, **Then** the placement is accepted with no coordinate-boundary error.

---

### Edge Cases

- **Long-press on a non-adjacent coordinate**: The system must reject the placement and provide visible feedback (e.g. a brief shake or "invalid" indicator on the target coordinate). No tile is placed. The valid-zone highlights remain active so the player can reorient.
- **Finger lifted before the 300ms threshold**: The placement intent is cancelled silently. No tile is placed, no feedback animation plays, and no state is written to the grid. The long-press timer resets cleanly.
- **Long-press on an already-occupied coordinate**: If the target tile is an unlocked base tile, the attempt is routed to the alchemy system (F04). If the target tile is locked or if alchemy is not applicable, a distinct rejection feedback plays and no change occurs.
- **Simultaneous long-press on two valid coordinates** (e.g. two-finger input): Only the first resolved long-press is honoured. The second is ignored or treated as a zoom/pan gesture depending on the input system's gesture priority.
- **Tile selector obscures valid zones**: The valid-zone highlight calculation must account for the UI overlay footprint so that coordinates hidden behind the tile selector panel are not shown as interactive targets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST require a sustained touch or click of 300–400ms to register a placement intent; contacts shorter than 300ms MUST be ignored for placement purposes.
- **FR-002**: System MUST accept new tile placements only on coordinates that are 4-directionally adjacent (up, down, left, right) to an already-placed tile, with the sole exception of the very first tile in a new garden.
- **FR-003**: System MUST auto-place the Origin tile at `(0,0)` when a new garden session begins, before processing any player input.
- **FR-004**: System MUST compute and display highlights on all currently valid placement coordinates within one frame of the player initiating a long-press gesture.
- **FR-005**: System MUST reject placement attempts on non-adjacent coordinates and display a visible rejection indicator (animation, colour flash, or haptic) at the attempted coordinate.
- **FR-006**: System MUST reject placement on already-occupied coordinates (base-tile-on-base-tile overwriting is the domain of alchemy in F04, not this system).
- **FR-007**: System MUST NOT expose any undo, clear, or reset capability for placed tiles in the production build; tile placement is permanent.
- **FR-008**: Player MUST be able to select from the 4 base tile types (Forest, Water, Stone, Earth) via a tile selector UI element accessible from the bottom corners of the screen without obscuring the centre of the garden view.

### Key Entities

- **PlacementIntent**: Represents the in-progress placement gesture. Attributes: `target_coord` (Vector2i), `chosen_biome` (enum), `press_duration_ms` (float), `state` (pending | confirmed | cancelled). Created on long-press start; resolved or cancelled on finger lift or threshold crossing.
- **ValidZone**: A coordinate that is currently eligible for placement — 4-directionally adjacent to at least one existing tile and currently unoccupied. Recomputed each time a tile is placed or a long-press gesture begins. Displayed as a visual overlay during an active gesture.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A tile placed via a valid long-press appears at the correct coordinate within the same frame the 300–400ms threshold is crossed, verified across 50 placements in an automated input replay test.
- **SC-002**: 100% of invalid placement attempts — non-adjacent coordinate, occupied coordinate, or press duration below threshold — are rejected and produce a visible feedback response, verified by an automated test suite covering all three rejection categories.
- **SC-003**: Valid placement zone highlights appear within one frame (≤16.7ms) of the player initiating a long-press gesture, measured on the target mid-range mobile device.
- **SC-004**: The tile selector is reachable with a single thumb-reach from the bottom corners of a 375pt-wide portrait screen without the player needing to reposition their grip, verified by a thumb-reach ergonomics check against standard phone form factors.
