# Feature Specification: Voxel Rendering and Mesh Merging

**Feature Branch**: `009-voxel-rendering-merging`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Voxel tile rendering with bitmask autotiling and cluster mesh merging"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bitmask Autotiling on Tile Placement (Priority: P1)

Every time a tile is placed, the tile itself and all of its immediate neighbours refresh their displayed mesh to reflect the updated neighbour bitmask. The player sees seamless edge and corner blending appear instantly — the garden looks coherent, not like isolated disconnected squares.

**Why this priority**: Visual coherence is the first impression of the game. Autotiling is the lowest-level rendering primitive that all other visual features (Mountain merging, LOD, colorblind palette) build upon. Without it the garden looks broken from the very first tile.

**Independent Test**: Place a single Forest tile on an empty grid. Verify it shows the "isolated" mesh variant. Place a second Forest tile adjacent to the first. Verify both tiles update their mesh variants to show the correct edge-connected variant within the same frame. No restart or manual refresh should be required.

**Acceptance Scenarios**:

1. **Given** an empty grid, **When** a Forest tile is placed at (0,0), **Then** the tile displays the isolated (no-neighbour) mesh variant for Forest.
2. **Given** a Forest tile at (0,0), **When** a second Forest tile is placed at (1,0) (directly to the right), **Then** both tiles update their mesh variants within the same frame to show the correct east/west edge-connected variants.
3. **Given** a Forest tile surrounded by Forest tiles on all 4 cardinal sides, **When** a diagonal (corner) Forest tile is added, **Then** the centre tile updates its bitmask to include the corner neighbour and switches to the correct 8-bit variant within the same frame.
4. **Given** a tile of biome type A adjacent to a tile of biome type B, **When** both are rendered, **Then** the edge between them uses a blended transition mesh variant appropriate to those two biome types rather than a hard cut.

---

### User Story 2 - Mountain Mesh Merging at 10+ Stone Tiles (Priority: P1)

When a contiguous cluster of Stone tiles reaches exactly 10 tiles, all 10 individual tile meshes are replaced in the same frame by a single unified Mountain mesh that spans the cluster. Further Stone tiles added to the cluster cause the Mountain mesh to re-merge and expand to include the new shape.

**Why this priority**: Mountain merging is the signature visual event for Stone biomes. It is the most dramatic moment in the rendering system and acts as a visual milestone that the player learns to anticipate. It also validates the cluster-detection pipeline used by other systems.

**Independent Test**: Place 9 Stone tiles in a straight line. Verify they each show individual tile meshes. Place the 10th Stone tile connected to the line. Verify all 10 individual meshes are replaced by a single Mountain mesh within the same frame.

**Acceptance Scenarios**:

1. **Given** 9 connected Stone tiles each showing individual voxel meshes, **When** a 10th Stone tile is placed connected to the cluster, **Then** all 10 individual meshes are replaced by a single Mountain mesh within the same render frame.
2. **Given** an existing Mountain mesh spanning 10 Stone tiles, **When** an 11th Stone tile is placed adjacent to the cluster, **Then** the Mountain mesh re-merges within the same frame to span all 11 tiles.
3. **Given** two separate clusters of Stone tiles each with 8 tiles, **When** a bridging Stone tile is placed connecting them (creating a 17-tile cluster), **Then** both separate meshes and the bridging tile are replaced by a single merged Mountain mesh within the same frame.
4. **Given** two independent Stone clusters each with 10+ tiles, **When** each is viewed independently, **Then** each cluster has its own distinct Mountain mesh and neither mesh overlaps or references tiles from the other cluster.

---

### User Story 3 - 60fps Performance on Mid-Range Mobile with Instanced Rendering (Priority: P2)

A garden containing up to 5,000 placed tiles maintains 60fps on mid-range mobile hardware. Tiles within loaded chunks are rendered using instanced mesh calls; tiles in distant chunks are rendered at a reduced LOD. No individual mesh draw call is issued per tile.

**Why this priority**: Performance is a hard constraint for a mobile-first product. If the garden stutters at a few hundred tiles the game becomes unplayable for the majority of the target audience long before they reach interesting content.

**Independent Test**: Load a pre-built 5,000-tile garden on a reference mid-range Android device (e.g., Snapdragon 778G class). Measure sustained frame time over 60 seconds of slow panning. Verify frame time stays at or below 16.7ms throughout.

**Acceptance Scenarios**:

1. **Given** a garden with 5,000 placed tiles, **When** the player pans slowly across the entire garden over 60 seconds, **Then** the frame rate remains at or above 60fps on the reference mid-range mobile device.
2. **Given** tiles in a chunk that is far from the camera viewport, **When** those tiles are rendered, **Then** they use the reduced-LOD mesh variant and contribute fewer vertices than their full-detail counterparts.
3. **Given** a chunk containing 64 Forest tiles of the same mesh variant, **When** those tiles are rendered, **Then** they are submitted as a single instanced draw call rather than 64 individual calls.

---

### User Story 4 - Colorblind High-Contrast Palette (Priority: P3)

When the player enables the colorblind-friendly palette in settings, all rendered tile meshes immediately switch to a high-contrast colour scheme that distinguishes every biome without relying on hue alone (using distinct shapes, patterns, or luminance differences as secondary cues).

**Why this priority**: This is an accessibility requirement that must be designed in from the start, not retrofitted. Without it the game is inaccessible to a significant portion of players. It is P3 because the core rendering pipeline must be stable first.

**Independent Test**: With at least one tile of each major biome type visible on screen, enable the colorblind palette from settings. Verify all tile colours change to their high-contrast variants within the same frame, with no tiles retaining the standard palette.

**Acceptance Scenarios**:

1. **Given** standard palette is active and tiles of Forest, Water, Stone, and Earth are visible, **When** the colorblind palette is toggled on, **Then** all four tile types visibly change colour within the same frame and none retain their original standard-palette colour.
2. **Given** the colorblind palette is active, **When** a new tile is placed, **Then** the new tile renders immediately in the high-contrast variant without a one-frame flash of the standard colour.
3. **Given** the colorblind palette is active, **When** the app is restarted (settings persistence handled by spec 013), **Then** all tiles render in the high-contrast palette from the first rendered frame after load.

---

### Edge Cases

- **Mountain cluster grows beyond merged mesh**: When new Stone tiles are added to a Mountain cluster, the entire cluster re-merges into a new unified mesh covering all tiles. The old mesh is destroyed in the same frame; there is no frame where both the old mesh and individual tile meshes are visible simultaneously.
- **Disconnected Stone clusters each reaching 10**: Each contiguous cluster is evaluated independently. A cluster of 10 forms its own Mountain mesh; a separate cluster of 10 forms a separate Mountain mesh. They do not merge until a Stone tile bridges them.
- **Stone tile removed from a Mountain cluster**: Tile placements are permanent in Satori (no undo), so a Mountain cluster can only grow, never shrink. Mesh re-merge on removal is therefore out of scope.
- **Bitmask update performance spike**: When a large contiguous region of the same biome is filled rapidly (e.g., flood-fill via a hypothetical tool), many tiles need simultaneous bitmask updates. The system must batch these into a single deferred update pass per frame to avoid per-tile frame stalls.
- **Hybrid biome tiles and bitmask**: A hybrid biome tile (e.g., Forest+Water) contributes to the bitmask of both parent biome types for neighbouring tiles; the correct blended edge variant must be selected for each neighbour pair.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST instantiate a biome-appropriate voxel mesh for each placed tile using the tile's biome type as the mesh selector
- **FR-002**: System MUST update a tile's mesh variant when any of its neighbours changes, using a bitmask autotiling algorithm (minimum 4-bit cardinal; 8-bit including diagonals preferred)
- **FR-003**: System MUST monitor contiguous Stone tile clusters; when a cluster reaches 10 tiles, replace all individual tile meshes with a single unified Mountain mesh within the same render frame
- **FR-004**: System MUST re-evaluate and re-merge Mountain meshes when additional Stone tiles are added to or bridge an existing Mountain cluster, completing the re-merge within the same render frame
- **FR-005**: System MUST use instanced mesh rendering within each chunk so that tiles sharing the same mesh variant are submitted as a single draw call
- **FR-006**: System MUST apply level-of-detail (LOD) reduction to tiles in chunks beyond a configurable distance from the camera viewport
- **FR-007**: System MUST provide a high-contrast colorblind-friendly colour palette for all biome meshes, toggled via the settings system (spec 013); the palette switch MUST apply to all currently rendered tiles within the same frame
- **FR-008**: Mesh updates triggered by tile placement or biome alchemy changes MUST complete within one render frame (≤16.7ms at 60fps target)

### Key Entities

- **TileMeshVariant**: a specific mesh asset selected by the 4-bit or 8-bit bitmask value for a given tile's neighbour configuration; keyed by (biome type, bitmask value)
- **MountainCluster**: a contiguous group of 10+ Stone tiles whose individual TileMeshVariant instances have been retired and replaced by a single unified Mountain mesh node; tracks member tile coordinates and cluster bounding box

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Placing a tile causes that tile's and all its neighbours' mesh variants to update visibly within the same rendered frame — verified by frame-by-frame capture showing no stale variants on frame N+1
- **SC-002**: Placing the 10th connected Stone tile causes the cluster to visually merge into a Mountain mesh within one render frame, with no intermediate frame showing a mix of individual tile meshes and the Mountain mesh
- **SC-003**: A garden with 5,000 placed tiles renders at a sustained ≥60fps on a reference mid-range mobile device (Snapdragon 778G class or equivalent) during a 60-second continuous pan across the full garden
- **SC-004**: Enabling the colorblind palette causes all currently visible tile colours to switch to the high-contrast variant within one render frame, with no tile retaining the standard-palette colour on that frame or any subsequent frame while the setting is active
