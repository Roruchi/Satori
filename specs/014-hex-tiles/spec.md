# Feature Specification: Hexagonal Tile System

**Feature Branch**: `014-hex-tiles`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "satori is a tile based game. It currently works using square tiles however since this would make discoveries more complex we should move to hexagonal tiles that would support more options and make it visually more pleasing"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate a Hexagonal Grid (Priority: P1)

The player explores the game world on a hexagonal tile grid. Every tile has up to six neighboring tiles (versus four in the previous square system). The player can move or interact in six directions, making navigation feel more organic and offering richer spatial choices.

**Why this priority**: This is the core of the feature. All discovery mechanics, visual improvements, and downstream gameplay depend on the hex grid being correctly laid out and navigable.

**Independent Test**: Load a map scene. Verify that tiles are arranged in a recognisable hex grid and that the player can move or cursor-select in six distinct directions. Delivers a functional hex world even before discovery logic is wired up. Can be verified by manual in-editor play or a debug harness that logs neighbor counts per tile.

**Acceptance Scenarios**:

1. **Given** a new game session is started, **When** the map is loaded, **Then** all tiles are rendered in a hexagonal grid layout with no gaps or misaligned tiles.
2. **Given** any non-edge tile on the map, **When** its neighbors are queried, **Then** exactly six neighbors are returned.
3. **Given** the player selects a tile, **When** valid move destinations are highlighted, **Then** only the six hex-adjacent tiles are shown as reachable (subject to game rules).

---

### User Story 2 - Discover Neighboring Hex Tiles (Priority: P2)

As the player explores, previously hidden tiles are revealed one by one through the six-direction adjacency system. Each revealed hex tile may trigger discovery events — resources, biomes, clues, or hazards — making exploration feel more branching and varied than the previous four-directional square system.

**Why this priority**: The richer discovery space (6 neighbors vs 4) is the primary gameplay motivation for switching to hexagons. This story delivers the tangible player benefit.

**Independent Test**: Start a map with only a central tile revealed. Interact with it to trigger discovery. Confirm that up to six new tiles become candidates for reveal, and that at least one discovery event fires correctly. Verifiable through manual play or a GUT test that simulates a reveal action on a known tile configuration.

**Acceptance Scenarios**:

1. **Given** a revealed tile with unrevealed hex neighbors, **When** the player triggers a discovery action, **Then** one or more of the six neighboring tiles are revealed, each potentially carrying a distinct discovery outcome.
2. **Given** a corner or edge tile with fewer than six physical neighbors, **When** discovery is triggered, **Then** only valid in-bounds neighbors are considered and no out-of-bounds error occurs.
3. **Given** all six neighbors of a tile are already revealed, **When** the player attempts another discovery action on that tile, **Then** the game communicates that no new neighbors remain to discover.

---

### User Story 3 - Visually Appealing Hex Map Presentation (Priority: P3)

The hex grid is rendered with clear hexagonal tile shapes, well-defined borders, and smooth visual transitions between biomes or terrain types. Tiles read clearly at a glance and the overall map looks more polished than the previous square grid.

**Why this priority**: Visual quality was an explicit motivation for this change. A broken or unappealing hex render undermines player trust even if the logic is correct.

**Independent Test**: Open the map in the editor and press Play. Visually inspect that tiles are hexagonal, borders do not overlap awkwardly, and biome colour gradients (if any) transition smoothly across hex edges. Can also be validated by screenshot comparison if a reference image exists.

**Acceptance Scenarios**:

1. **Given** a map with multiple biome regions, **When** the map is rendered, **Then** each tile displays a hexagonal shape with clearly visible borders and its correct biome colour or texture.
2. **Given** adjacent tiles of different biomes, **When** the map is rendered, **Then** the visual transition at shared hex edges looks intentional and not broken.
3. **Given** any screen resolution supported by the game, **When** the hex map is displayed, **Then** tiles remain readable without overlapping text or icons.

---

### User Story 4 - Save and Configuration Compatibility (Priority: P4)

If the game currently saves map data or player progress, the transition to hex tiles either migrates existing data gracefully or provides a clear reset/new-game path, so players are not left with a broken save state after the update.

**Why this priority**: Data integrity matters but is lower priority than core gameplay; the game is in early development so a clean break is acceptable as long as it is communicated clearly.

**Independent Test**: Run the game with a pre-existing save file (if any). Verify either that it loads correctly on the new hex grid, or that the player receives a clear notice that a new game must be started. Verifiable through a manual smoke-test with a backed-up save file.

**Acceptance Scenarios**:

1. **Given** the game has no prior save data, **When** a new game is started after the hex transition, **Then** a fresh hex map loads without errors.
2. **Given** the game has existing save data incompatible with hex tiles, **When** the player loads the game, **Then** a user-friendly message explains the data cannot be loaded and offers to start a new game.

---

### Edge Cases

- What happens when a tile is at the edge of the map and has fewer than six neighbors? — boundary neighbors must be treated as non-existent, not as a crash or undefined behavior.
- How does the discovery system behave if a tile has zero unrevealed neighbors? — must communicate "fully explored" without errors.
- What happens if two tiles visually overlap due to an incorrect hex layout calculation? — must not occur; layout must be validated on map generation.
- How does the game handle very large maps where rendering all hex tiles simultaneously may affect frame rate? — performance must remain acceptable at the target map sizes (see EX-003).
- What happens when the player clicks between two hex tiles in the gap area? — no tile must be selected and no error must fire.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game map MUST be laid out as a hexagonal grid where each interior tile has exactly six adjacent neighbors.
- **FR-002**: All player interactions that previously operated on four-directional adjacency MUST be updated to operate on six-directional hex adjacency.
- **FR-003**: The discovery system MUST evaluate up to six candidate neighbor tiles when a discovery action is triggered on a hex tile.
- **FR-004**: Edge and corner tiles MUST correctly report only their valid in-bounds neighbors without triggering errors for missing neighbors.
- **FR-005**: Every tile MUST be rendered as a hexagonal shape; no square or diamond tile shapes may appear on the map.
- **FR-006**: Biome and terrain visual transitions MUST be computed and rendered along hex edges, not along cardinal edges.
- **FR-007**: The game MUST handle the absence of compatible save data gracefully, offering a new-game option rather than crashing or displaying corrupt state.
- **FR-008**: Map coordinates MUST use a single consistent hex coordinate system throughout all systems so that neighbor look-up, rendering, and save/load operate on the same coordinate space.
- **FR-009**: Input hit-detection (mouse click or touch tap) MUST resolve to the correct hexagonal tile that is visually under the cursor or finger.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: The hex tile system MUST preserve the permanent-emergence rule set; any tile reveal or discovery rule that was part of core gameplay on the square grid must have an equivalent or improved hex counterpart.
- **EX-002**: If the game supports mouse or touch input for tile selection, the hit-detection regions MUST match the visible hexagonal shapes so that players select the tile they can see, not an invisible square bounding box.
- **EX-003**: Map generation and initial render of a full hex map MUST complete without a noticeable stall. Neighbor look-up per tile MUST complete in constant time regardless of map size.

### Key Entities *(include if feature involves data)*

- **Hex Tile**: A single unit of the game map with a hexagonal shape. Has a coordinate position in the hex grid, a revealed/hidden state, a biome or terrain type, and references to up to six neighboring tiles.
- **Hex Grid / Map**: The collection of all hex tiles forming the game world. Responsible for spatial layout, coordinate translation, and neighbor resolution.
- **Discovery Event**: An outcome triggered when a hidden tile is revealed. Associated with a specific hex tile; may carry resource, hazard, biome, or narrative data.
- **Tile Coordinate**: A value object representing a tile's position in the hex coordinate system. Used consistently across rendering, neighbor look-up, input mapping, and persistence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of tiles on any generated map are hexagonal in shape — zero square, diamond, or malformed tiles are present.
- **SC-002**: Every interior tile returns exactly six neighbors; every edge/corner tile returns the correct reduced count with zero errors or exceptions across all map sizes tested.
- **SC-003**: Discovery actions expose up to six candidate neighbor tiles per action, representing at least a 50% increase in per-action discovery options compared to the previous four-directional system.
- **SC-004**: The map loads and renders fully with no regression in load time compared to the previous square-tile system.
- **SC-005**: Players can complete at least one full discovery loop (reveal tile → receive discovery event → act on outcome) without encountering any layout errors, coordinate mismatches, or visual artefacts.
- **SC-006**: Click and touch input resolves to the correct tile in 100% of on-tile interactions — no visible misalignment between selectable area and rendered hex shape.

## Assumptions

- The game is in active development and does not yet have a stable saved-game format that must be preserved; a new-game requirement after this change is acceptable if communicated clearly.
- Hexagons will use a **pointy-top** orientation (a vertex pointing up), which is conventional for exploration/strategy games and aligns naturally with vertical map scrolling. If a flat-top orientation is preferred, this should be confirmed before planning.
- The current map size and generation approach will be reused as a baseline; the hex grid will match or approximate the same navigable area.
- Biome and terrain data attached to tiles is tile-local and does not depend on cardinal-direction assumptions, making it straightforward to re-associate with hex tiles.
- Performance targets are based on the existing game's hardware targets; no new minimum hardware specification is introduced by this change.
