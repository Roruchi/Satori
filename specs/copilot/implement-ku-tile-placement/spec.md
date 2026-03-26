# Feature Specification: Ku Tile Placement (Abyss Biome + Island System)

**Feature Branch**: `copilot/implement-ku-tile-placement`  
**Created**: 2026-03-26  
**Status**: Draft  
**Input**: User description: "implement a singular ku tile placement the ku tile is the abyss region. it is a special biome that can separate islands. each island is isolated and gets an island id. per island each spirit can spawn again even already unlocked."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Place a Ku (Abyss) Tile (Priority: P1)

A player who has unlocked the Ku element can select the Ku abyss tile from the tile selector and place it on the garden grid. The Ku tile visually represents the void or abyss — a boundary that separates landmasses.

**Why this priority**: This is the fundamental building block. Without the ability to place a Ku tile, no island separation or per-island spirit mechanics can exist.

**Independent Test**: Place a Ku tile adjacent to an existing tile and confirm it appears on the grid with the correct biome value. GUT unit coverage on GridMap; manual verification in the editor.

**Acceptance Scenarios**:

1. **Given** the Ku element is unlocked and the player is in Plant mode, **When** the player selects the Ku tile and taps a valid empty hex, **Then** a KU-biome tile is placed at that coordinate.
2. **Given** a Ku tile is placed, **When** another Ku tile is placed adjacent to it, **Then** both Ku tiles exist on the grid and are treated as abyss (not as land).
3. **Given** a non-Ku tile exists adjacent to a Ku tile, **When** the player inspects the grid, **Then** the Ku tile does not contribute to any island's land mass — it acts as a void separator.

---

### User Story 2 - Islands Are Identified and Isolated (Priority: P2)

When a Ku tile separates two groups of non-Ku tiles, each group becomes a distinct island and receives a unique island ID. Players can build two separate islands that are independent of each other.

**Why this priority**: Island isolation is the core mechanic that makes per-island spirit spawning possible. Without reliable island IDs, the spirit re-spawn system cannot function.

**Independent Test**: Place tiles to create two groups separated by Ku tiles; verify each group gets a different island ID via GUT unit tests on the island-labelling algorithm.

**Acceptance Scenarios**:

1. **Given** a contiguous cluster of non-Ku tiles, **When** island IDs are computed, **Then** all tiles in the cluster share the same island ID.
2. **Given** a Ku tile placed between two previously connected clusters, **When** island IDs are recomputed, **Then** each cluster receives a distinct island ID.
3. **Given** two isolated groups that are subsequently bridged by a new non-Ku tile, **When** island IDs are recomputed, **Then** both groups merge into a single island ID.
4. **Given** a Ku tile on the grid, **When** island IDs are queried, **Then** the Ku tile itself is excluded from all island assignments (it has no island ID).

---

### User Story 3 - Spirits Respawn Per Island (Priority: P3)

A spirit that has already been summoned globally can appear again on a new, isolated island. Each island maintains its own spirit-summoning ledger, so once a spirit's discovery pattern is matched on a given island, it spawns there — even if it already wandered a different island.

**Why this priority**: This unlocks long-term replayability. Players can deliberately create multiple isolated islands to re-experience spirit encounters.

**Independent Test**: Simulate a spirit discovery on Island 1, then create Island 2 with matching pattern; verify the spirit spawns on Island 2. GUT unit test covering SpiritPersistence island-keyed lookup.

**Acceptance Scenarios**:

1. **Given** spirit_X was summoned on Island 1, **When** the same discovery pattern is matched on Island 2, **Then** spirit_X spawns on Island 2 as a separate instance.
2. **Given** spirit_X is active on Island 1, **When** the same discovery pattern is matched again on Island 1, **Then** spirit_X does not spawn a second instance on that island.
3. **Given** an island is later connected to another island (Ku tile removed), **When** spirit summoning is checked, **Then** the merged island uses the ID of whichever component was established first (deterministic merge rule).

---

### Edge Cases

- What happens when Ku tiles are placed at the origin (0,0)? The origin tile is always STONE at game start; Ku tiles may be placed adjacent but the origin island always has ID "0".
- What happens if a player encircles an island entirely with Ku tiles? The encircled group is still a valid island with its own ID.
- What happens if all non-Ku tiles are removed (hypothetical future mechanic)? The island map becomes empty; no IDs are assigned.
- How does the system handle very large grids with many Ku separators? The flood-fill must complete in a single frame without freezing; bounded by total non-Ku tile count.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST add a standalone `KU` biome value to the BiomeType enum that represents the abyss and is distinct from the four Ku-pair biomes already defined.
- **FR-002**: System MUST allow the Ku tile to be placed on the grid through the same tile-placement flow as other biomes, subject to Ku unlock status.
- **FR-003**: System MUST NOT treat Ku tiles as landmass — a Ku tile breaks adjacency for island-connectivity purposes.
- **FR-004**: System MUST compute an island ID for every non-Ku tile on the grid using connected-component labelling (BFS/DFS flood-fill, treating Ku tiles as walls).
- **FR-005**: Island IDs MUST be recomputed after every tile placement so that the island map is always current.
- **FR-006**: System MUST store each tile's island ID in the tile's metadata bag under the key `"island_id"`.
- **FR-007**: Spirit summoning MUST be scoped per island: the system checks whether a spirit has already been summoned on the *same island* rather than globally.
- **FR-008**: SpiritPersistence MUST track summoning records keyed by `"island_{id}:spirit_{spirit_id}"` so the same spirit can be summoned on multiple distinct islands.
- **FR-009**: SpiritInstance MUST carry an `island_id` field so that persistence serialisation and restoration respects island scope.
- **FR-010**: The tile selector UI MUST expose the Ku biome for selection when the Ku element is unlocked (consistent with how other unlocked biomes are shown).

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: The Ku tile MUST respect the permanent-placement rule — once placed it cannot be mixed into another biome (locked = true immediately, or no mix recipes target KU).
- **EX-002**: No change to mobile input or thumb-zone UI layout is required beyond adding the Ku tile to the existing tile selector; accessibility settings are unaffected.
- **EX-003**: Island ID recomputation runs every tile placement. The flood-fill is bounded by the number of tiles in the grid; for typical garden sizes (< 500 tiles) this must complete in under 1 ms to avoid perceptible frame drop.

### Key Entities *(include if feature involves data)*

- **KU Biome Tile**: A placed GardenTile with `biome == BiomeType.Value.KU`. Acts as a void separator; has no island ID; cannot be mixed.
- **Island**: A maximal set of non-Ku tiles that are all reachable from each other without crossing a Ku tile. Identified by a string island ID (e.g., `"0"`, `"1"`, …).
- **IslandMap**: The mapping from tile coordinate to island ID, recomputed on every placement. Lives in GridMap and is queried by SpiritService.
- **Per-Island Spirit Record**: A summoning record keyed by `"island_{id}:spirit_{spirit_id}"` in SpiritPersistence, preventing duplicate spawns on the same island while permitting them on different islands.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can place a Ku tile on the grid and visually observe it appearing as the abyss biome within the same interaction frame.
- **SC-002**: Placing a Ku tile between two previously-connected tile groups results in two distinct island IDs being assigned within the same frame as the placement.
- **SC-003**: A spirit that was summoned on Island 1 is able to be triggered again on Island 2 with a matching pattern, confirmed by a GUT unit test.
- **SC-004**: No existing spirit-summon behaviour is broken on a single-island garden (regression-free): all existing GUT tests continue to pass.
- **SC-005**: Island ID recomputation completes without causing a visible frame stutter for gardens of up to 200 tiles.
