# Feature Specification: Dev Tooling and Test Harness

**Feature Branch**: `001-dev-tooling-harness`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Dev tooling and debug test harness for in-editor game testing"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Instant Garden Seeding (Priority: P1)

A developer needs to quickly populate the garden with many tiles to test pattern detection, rendering, and performance without manually long-pressing tiles one by one.

**Why this priority**: Without rapid seeding, testing every other feature takes prohibitively long. This is the highest-leverage development capability.

**Independent Test**: Open the debug scene, trigger flood-fill, verify tiles appear at the specified coordinates with the correct biome assignments.

**Acceptance Scenarios**:

1. **Given** the debug scene is open and the garden is empty, **When** the developer triggers flood-fill with a count and biome type, **Then** that many valid adjacent tiles are placed instantly without any long-press flow.
2. **Given** a flood-fill has been triggered, **When** the developer inspects the tile data, **Then** all placed tiles obey adjacency rules and carry correct biome assignments.

---

### User Story 2 — Debug Overlay (Priority: P1)

A developer wants to see tile coordinates, chunk boundaries, and biome labels overlaid on the garden to understand the spatial data during testing.

**Why this priority**: Without coordinate and chunk visibility, diagnosing placement or pattern-matching bugs is nearly impossible.

**Independent Test**: Enable the overlay toggle; verify coordinate labels appear on tiles and chunk grid lines render aligned to 16×16 boundaries.

**Acceptance Scenarios**:

1. **Given** the debug overlay is enabled, **When** the developer looks at any tile, **Then** its grid coordinate and biome type are displayed as a readable label.
2. **Given** the debug overlay is enabled and the camera pans, **When** the view moves, **Then** chunk boundary lines track with the world and remain aligned to the 16×16 tile grid.

---

### User Story 3 — Discovery Event Log (Priority: P2)

A developer needs a visible log of discovery trigger events to confirm the pattern engine fires correctly during testing.

**Why this priority**: Discovery bugs are silent without a log — the only symptom is "nothing happened". The log surfaces signal firings immediately.

**Independent Test**: Seed a configuration that triggers a known discovery; confirm the event appears in the log panel with the correct discovery ID and coordinates.

**Acceptance Scenarios**:

1. **Given** the debug scene is running, **When** a discovery-triggering tile configuration is created, **Then** the discovery ID and triggering coordinates appear in the log panel within the same frame.
2. **Given** multiple discoveries fire in sequence, **When** the developer reads the log, **Then** events are listed in chronological order with frame timestamps.

---

### User Story 4 — Instant Placement Mode (Priority: P2)

A developer can bypass the 300–400 ms long-press timer to place tiles with a single tap, enabling rapid iteration.

**Why this priority**: Long-press is essential for players but is an obstacle during development and automated testing.

**Independent Test**: Enable instant-placement mode; single-tap a valid adjacent coordinate; verify the tile is placed without any hold delay.

**Acceptance Scenarios**:

1. **Given** instant-placement mode is enabled, **When** the developer taps a valid adjacent position, **Then** the tile is placed immediately with no hold delay.
2. **Given** instant-placement mode is disabled, **When** the developer taps without holding, **Then** no tile is placed.

---

### User Story 5 — Pattern Visualizer (Priority: P3)

A developer can highlight tiles currently participating in any active discovery evaluation to debug pattern conditions.

**Why this priority**: Complex multi-variable conditions (Tier 2 and Tier 3) are nearly impossible to debug without spatial visualisation.

**Independent Test**: Enable the visualizer; seed a partial pattern (e.g., 8 of 10 required Stone tiles); verify those tiles highlight differently from unrelated tiles.

**Acceptance Scenarios**:

1. **Given** the visualizer is enabled, **When** tiles form a partial match for a discovery, **Then** those tiles are highlighted in a "partial" colour distinct from neutral tiles.
2. **Given** a discovery triggers, **When** the developer views the visualizer, **Then** the tiles that satisfied the condition switch to a "completed" highlight colour.

---

### Edge Cases

- What happens if the debug scene is accidentally included in a release export? The export preset must filter it out via a feature flag — the scene must be provably absent from the release package.
- What if flood-fill is triggered on a completely empty garden (no Origin tile yet)? The tool auto-places the Origin tile at (0,0) first, then seeds outward.
- What if the overlay label zoom is too small to read? Labels should suppress rendering below a minimum zoom threshold.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a dedicated debug scene that is fully excluded from release export builds.
- **FR-002**: System MUST provide a toggleable coordinate and biome-type overlay on all placed tiles.
- **FR-003**: System MUST render chunk boundary lines aligned to the 16×16 tile grid when the overlay is active.
- **FR-004**: System MUST provide a flood-fill tool that places N tiles of a chosen biome instantly from a given origin, respecting adjacency rules.
- **FR-005**: System MUST provide an instant-placement mode that allows single-tap tile placement without the long-press timer.
- **FR-006**: System MUST display a scrolling event log showing discovery signals with discovery ID, frame timestamp, and triggering tile coordinates.
- **FR-007**: System MUST provide a pattern visualizer highlighting tiles in partial-match and completed-match states.
- **FR-008**: All debug tools MUST be activatable via dedicated keyboard shortcuts documented in an in-scene help overlay.
- **FR-009**: The event log MUST be clearable during a session via a dedicated shortcut.
- **FR-010**: Debug tools MUST NOT affect game logic outcomes — they are purely observational except for flood-fill and instant-placement which respect all game rules.

### Key Entities

- **DebugSession**: Runtime flags for which tools are active (overlay, instant-placement, visualizer).
- **DiscoveryLogEntry**: Discovery ID, frame timestamp, array of triggering tile coordinates.
- **FloodFillRequest**: Biome type, starting coordinate, tile count.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can seed a 100-tile garden in under 5 seconds using the flood-fill tool.
- **SC-002**: The coordinate and chunk overlay activates within one frame of the toggle keypress with no visible lag.
- **SC-003**: Discovery events appear in the log in the same frame they are emitted — zero frame delay.
- **SC-004**: A release export provably does not include the debug scene file.
- **SC-005**: All debug tool shortcuts are visible in an in-scene help overlay without navigating any menu.
