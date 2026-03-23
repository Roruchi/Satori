# Feature Specification: Infinite Grid Engine

**Feature Branch**: `002-infinite-grid-engine`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Infinite coordinate-based tile grid with chunk-based world partitioning"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Arbitrary-Coordinate Tile Storage and Retrieval (Priority: P1)

As a system component, I need to store a tile at any integer coordinate — including negative coordinates and coordinates far from the origin — and retrieve that exact tile data back in constant time, regardless of how large the garden grows.

**Why this priority**: This is the foundational capability of the entire game. Every other feature (placement, alchemy, pattern matching) depends on being able to write and read tile data by coordinate. Without O(1) lookup the game cannot meet its 60fps target on mobile.

**Independent Test**: Seed a grid with tiles at coordinates including `(0,0)`, `(-500, 300)`, `(9999, -9999)`, and a cluster of 10,000 random positions. Confirm every retrieval returns the correct tile type and that retrieval time does not grow with garden size.

**Acceptance Scenarios**:

1. **Given** an empty grid, **When** a Forest tile is stored at `(0, 0)`, **Then** querying `(0, 0)` returns a Forest tile with the correct metadata.
2. **Given** tiles placed at positive and negative coordinates spanning multiple chunks, **When** each coordinate is queried, **Then** every query returns the correct tile with no cross-coordinate contamination.
3. **Given** a coordinate that has never had a tile placed, **When** the grid is queried at that coordinate, **Then** the system returns the defined null/empty sentinel value (not an error or crash).
4. **Given** a garden of 10,000+ placed tiles, **When** a random tile coordinate is looked up, **Then** the lookup completes in constant time (no measurable degradation vs. a 10-tile garden).

---

### User Story 2 - Chunk Loading and Unloading Around the Camera (Priority: P1)

As the chunk manager, I need to automatically load the tile chunks that are visible or adjacent to the player's camera viewport, and unload chunks that have moved beyond the configured load radius, so that memory usage stays bounded even in large gardens.

**Why this priority**: Without chunk management the game would accumulate memory linearly with garden size and fail the <200MB RAM target on mobile hardware. This is equally critical to F02 as a foundation for all other features.

**Independent Test**: Create a garden that spans 200×200 tiles (spanning many chunks). Move the simulated camera across the garden and confirm: (a) only chunks within the load radius are held in memory, (b) chunks outside the radius are released within one second of the camera moving away, (c) chunk loading/unloading does not cause a frame drop.

**Acceptance Scenarios**:

1. **Given** a camera positioned at the garden origin, **When** the scene initialises, **Then** all chunks overlapping or adjacent to the viewport are loaded and all others remain unloaded.
2. **Given** a loaded chunk that was previously within the viewport, **When** the camera moves so that chunk exceeds the configured unload distance, **Then** that chunk is released from active memory within 1 second.
3. **Given** a camera panning continuously over a 10,000-tile garden, **When** chunk loading and unloading are active, **Then** the frame rate remains at or above 60fps throughout.
4. **Given** two tiles placed in the same chunk simultaneously (e.g. during a rapid-fire test), **When** the chunk is next accessed, **Then** both tiles are present and neither write is lost.

---

### User Story 3 - Garden Bounding Box and Tile Count Tracking (Priority: P2)

As a developer and as future UI features, I need the grid to always report the exact total number of placed tiles and the current axis-aligned bounding box of all tiles, updated synchronously after every placement.

**Why this priority**: The bounding box drives camera framing, minimap rendering, and share/export features. Tile count is used for progression metrics. These are derived values that must always be accurate; computing them on-demand over a large grid would be too expensive.

**Independent Test**: Place tiles in a scripted sequence that extends the garden in all four compass directions, including diagonal sequences that do not affect the bounding box. After each placement assert that `tile_count` equals the number of placements made and that `bounding_box` matches the expected min/max coordinates exactly.

**Acceptance Scenarios**:

1. **Given** an empty grid, **When** the first tile is placed at `(0,0)`, **Then** tile count is 1 and the bounding box is `(0,0)→(0,0)`.
2. **Given** an existing garden with bounding box `(-2,-2)→(3,3)`, **When** a tile is placed at `(5, -4)`, **Then** the bounding box updates to `(-2,-4)→(5,3)` and tile count increments by 1.
3. **Given** a garden of 500 tiles, **When** the tile count is read, **Then** it equals exactly 500 with no off-by-one errors.

---

### User Story 4 - Origin Coordinate Reservation (Priority: P3)

As the game system, I need coordinate `(0,0)` to be permanently reserved as the Origin — the anchor point for every new garden — so that the origin tile is always at a known location regardless of how the garden grows.

**Why this priority**: The Origin is a game design anchor referenced by structural landmark patterns (e.g. the Origin Shrine). It is a low-risk, low-effort guarantee with high downstream value.

**Independent Test**: Start a new garden session. Confirm the Origin tile is at `(0,0)`. Attempt to programmatically place a second tile directly at `(0,0)` and confirm the system rejects or ignores the overwrite. Query `(0,0)` and confirm it returns the Origin tile, not empty.

**Acceptance Scenarios**:

1. **Given** a brand-new garden session, **When** the grid is initialised, **Then** coordinate `(0,0)` is occupied by the Origin tile before any player input.
2. **Given** the Origin tile exists at `(0,0)`, **When** a placement is attempted at `(0,0)`, **Then** the placement is rejected (the Origin cannot be overwritten by a normal placement).

---

### Edge Cases

- **Simultaneous writes to the same chunk**: If two tiles are placed within the same chunk in the same frame (e.g. via scripted automation or future multiplayer), both writes must be applied atomically — the second write must not silently discard the first. The chunk's internal data structure must handle concurrent-write safety at the GDScript level.
- **Query at an unoccupied coordinate**: The grid must return a defined sentinel value (e.g. `null` or a typed `EMPTY` constant) — never an engine error or an out-of-bounds crash — when queried at any coordinate that has no tile.
- **Chunk at the coordinate-space boundary**: The chunk partitioning algorithm must correctly assign tiles at coordinates like `(-1, -1)`, `(-16, 0)`, and `(15, -1)` to the right chunk without off-by-one errors in the chunk key calculation for negative values.
- **Garden with a single tile**: Bounding box, tile count, and chunk load logic must all behave correctly for a minimal one-tile garden.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store placed tile data addressable by an integer coordinate pair with no upper or lower coordinate boundary.
- **FR-002**: System MUST retrieve any tile's data in O(1) constant time regardless of total garden size.
- **FR-003**: System MUST partition tiles into 16×16 tile chunks identified by a chunk coordinate derived from the tile coordinate.
- **FR-004**: System MUST load all chunks that overlap or are adjacent to the current camera viewport.
- **FR-005**: System MUST unload chunks that are beyond a configurable distance (load radius) from the camera viewport within 1 second of the camera moving away.
- **FR-006**: System MUST track the total count of placed tiles and the axis-aligned bounding box of the garden, updated synchronously after every placement.
- **FR-007**: System MUST reserve coordinate `(0,0)` as the Origin — auto-placed when a new garden session begins — and reject any attempt to overwrite it via normal placement.
- **FR-008**: System MUST return a null/empty sentinel value (not an error) when queried at any unoccupied coordinate.

### Key Entities

- **TileData**: Represents a single placed tile. Attributes: `coord` (Vector2i), `biome_type` (enum), `locked` (bool), `metadata` (Dictionary — extensible for future use). No coordinate boundary. Immutable once placed except for the `locked` transition applied by alchemy.
- **Chunk**: A 16×16 group of tiles identified by a `chunk_coord` (Vector2i, derived by integer-dividing the tile coord by 16 with correct negative-number handling). Has a `loaded` flag and a sparse dictionary of `TileData` keyed by local coordinate within the chunk.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Placing and retrieving a tile at any coordinate — including negative values, coordinates spanning chunk boundaries, and coordinates at ±10,000 — always returns the correct tile data with zero retrieval errors.
- **SC-002**: A garden with 10,000+ placed tiles maintains a sustained 60fps on a mid-range mobile device with chunk loading and unloading active during camera movement.
- **SC-003**: Chunks outside the camera's configured load radius are released from active memory within 1 second of the camera moving away, as measured by a memory profiling test.
- **SC-004**: The bounding box and tile count are exactly correct after every placement in a scripted 1,000-placement stress test, with zero off-by-one or missed-update errors.
