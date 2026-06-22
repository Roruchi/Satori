# Feature Specification: Biome Natural Materials and Harvesting

**Feature Branch**: `023-biome-natural-materials`
**Created**: 2026-06-22
**Status**: Draft
**Input**: User description: "Let biomes spawn natural materials, make it visually appealing, e.g. a meadow biome/cluster spawns a large tree that becomes harvestable."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Materials Grow from Biomes (Priority: P1)

As a player, I want biomes to visibly grow natural materials so that materials feel like gifts of the place rather than abstract inventory numbers.

**Why this priority**: Rituals require materials. The first ten minutes depend on Meadow generating Living Wood before the player can discover Warm Hollow.

**Independent Test**: Can be validated with GUT coverage for deterministic spawn timing and manual in-editor verification that Meadow tiles or clusters produce a visible Living Wood node.

**Acceptance Scenarios**:

1. **Given** a Meadow tile or Meadow cluster exists, **When** enough material-spawn time passes, **Then** a visible Living Wood node appears on or near that biome.
2. **Given** a material node is unharvested, **When** the player views the garden, **Then** the node is visually distinguishable from normal tile decoration.
3. **Given** the garden is saved and loaded, **When** a material node was present before save, **Then** it is restored deterministically and remains harvestable.

---

### User Story 2 - Harvest Materials Actively (Priority: P2)

As a player, I want to tap or click natural material nodes to harvest them so I can intentionally gather what rituals need.

**Why this priority**: The master plan says early harvesting is active. This gives the ritual menu meaningful inputs without turning early play into idle collection.

**Independent Test**: Can be validated with GUT coverage for harvest state mutation and manual in-editor verification of tap/click collection feedback.

**Acceptance Scenarios**:

1. **Given** a Living Wood node is ready, **When** the player taps it in Interact or default harvest context, **Then** Living Wood is added to material inventory.
2. **Given** a material node has been harvested, **When** the player taps the same location again, **Then** no duplicate material is awarded.
3. **Given** material inventory is full, **When** the player attempts to harvest, **Then** the node remains and the game gives one clear blocked reason.

---

### User Story 3 - Cluster Landmarks Feel Special (Priority: P3)

As a player, I want larger biome clusters to produce more expressive material landmarks, such as a large meadow tree, so the garden feels alive and visually rewarding.

**Why this priority**: The user explicitly wants visual appeal. Cluster anchors make material generation readable without cluttering every tile.

**Independent Test**: Can be validated with deterministic cluster selection tests and manual screenshot-style review in the editor.

**Acceptance Scenarios**:

1. **Given** a Meadow cluster reaches the configured size threshold, **When** material spawning evaluates, **Then** the cluster can spawn a large Living Wood tree anchor instead of many small nodes.
2. **Given** the cluster changes shape, **When** the anchor is recalculated, **Then** it stays deterministic and does not jump every frame.
3. **Given** multiple clusters exist, **When** spawn caps are reached, **Then** each cluster respects its own material-node cap.

### Edge Cases

- Material nodes must not spawn on empty tiles.
- Material nodes must not overlap completed structures in a way that prevents interaction.
- Harvesting must be deterministic across save/load and offline progression.
- Material spawning must avoid unbounded node growth in large gardens.
- If a biome is transformed after a material node appears, the node either remains as history or becomes harvestable memory according to the feature implementation decision; it must not crash.
- Automation structures from later features may harvest nodes, but manual harvesting remains the MVP.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST define material output rules per biome or biome family.
- **FR-002**: Meadow MUST generate Living Wood.
- **FR-003**: Pond/Water-family biomes SHOULD be ready to generate Reed Fiber when the Water material path is implemented.
- **FR-004**: Stonefield/Stone-family biomes SHOULD be ready to generate Spirit Stone.
- **FR-005**: Hearth/Fire-family biomes SHOULD be ready to generate Ember Clay.
- **FR-006**: Material nodes MUST be visible in the garden when ready to harvest.
- **FR-007**: A Meadow cluster at or above the configured threshold MUST be able to spawn a larger Living Wood landmark such as a harvestable tree.
- **FR-008**: The player MUST be able to harvest a ready material node through a clear click/tap interaction.
- **FR-009**: Harvesting MUST add the corresponding material to a material inventory or equivalent resource store.
- **FR-010**: Harvesting MUST mark the node as collected and prevent duplicate collection.
- **FR-011**: Material spawn state MUST persist across save/load.
- **FR-012**: Material spawn evaluation MUST cap the number of active material nodes per biome cluster or island.
- **FR-013**: Root Network effects MUST be able to increase material generation speed for nearby Meadow tiles after that structure exists.
- **FR-014**: Wind Chime effects MUST be able to auto-harvest nearby Living Wood after that structure exists.
- **FR-015**: The implementation MUST keep `specs/master/recipes.md` synchronized if any material IDs, display names or unlock behavior changes.
- **FR-016**: The Living Wood spawn and harvest path MUST be fast enough, with debug acceleration if needed, to support a 10-minute first-session playtest.
- **FR-017**: Adding material nodes MUST NOT break existing spirit discovery, housing assignment, Mist Stag discovery, Ku unlock or island creation flows.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Material visuals MUST be readable at normal gameplay zoom and not hide spirit or placement feedback.
- **EX-002**: Spawn evaluation MUST be incremental or bounded so it does not block the frame on large gardens.
- **EX-003**: Harvest interaction MUST be reachable on mobile and must not require tiny precision taps.
- **EX-004**: Material node and landmark visuals MUST respect accessibility contrast settings where applicable.

### Key Entities *(include if feature involves data)*

- **BiomeMaterialDefinition**: Data mapping a biome or biome tag to material output, spawn interval, node cap and visual profile.
- **MaterialNode**: Persistent harvestable world object with material ID, amount, coord, visual state and collected flag.
- **MaterialInventory**: Store for harvested materials used by rituals.
- **MaterialSpawnCluster**: Deterministic grouping of biome tiles used to cap and place material nodes.
- **MaterialVisualProfile**: Data describing small node vs cluster landmark presentation and interaction bounds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a fresh garden, Meadow can produce at least one harvestable Living Wood node before the Warm Hollow ritual is needed.
- **SC-002**: 100% of material harvest tests prevent duplicate collection from the same node.
- **SC-003**: Material nodes persist through save/load in automated or debug-harness validation.
- **SC-004**: Spawn evaluation respects configured caps in large-cluster tests.
- **SC-005**: Manual mobile-layout validation confirms material nodes are readable and tappable at standard zoom.
- **SC-006**: After this feature lands, a fresh playtest can create Meadow, harvest Living Wood, shape Warm Hollow, place Meadow Dwelling and house a Meadow spirit without debug-only steps.
