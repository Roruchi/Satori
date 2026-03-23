# Feature Specification: Tier 3 — Spirit Animal System

**Feature Branch**: `008-spirit-animal-system`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Tier 3 spirit animal autonomous entity system with multi-variable summon conditions"

## User Scenarios & Testing *(mandatory)*

### Spirit Catalogue

All 30 spirits and their summon conditions are listed below for reference during testing.

| # | Spirit | Summon Condition |
|---|--------|-----------------|
| 1 | Red Fox | 3 Forest tiles in a triangle |
| 2 | Mist Stag | Deep Stand cluster completed |
| 3 | Emerald Snake | 7 Forest tiles in a straight line |
| 4 | Owl of Silence | Forest tile adjacent to Monk's Rest landmark |
| 5 | Tree Frog | Forest tile bordering a Swamp tile |
| 6 | White Heron | 5 Water tiles in a line |
| 7 | Koi Fish | 2×2 square of pure Water |
| 8 | River Otter | 10 Water tiles in a curvy line |
| 9 | Blue Kingfisher | Forest mixed with Water tile (hybrid biome) |
| 10 | Dragonfly | 1 Water tile surrounded by 4 Sand tiles |
| 11 | Mountain Goat | Stone tile touching a 10+ Mountain cluster |
| 12 | Stone Golem | 3×3 solid block of pure Stone |
| 13 | Granite Ram | Granite Range cluster completed |
| 14 | Sun-Lizard | Stone tile adjacent to 4 Sand tiles |
| 15 | Rock Badger | Stone tile at the very edge of the garden |
| 16 | Golden Bee | 10+ connected Savannah tiles |
| 17 | Jade Beetle | 15+ connected Forest/Meadow tiles |
| 18 | Meadow Lark | Verdant Valley cluster completed |
| 19 | Field Mouse | Tile adjacent to 3 different macro-biome types |
| 20 | Hare | 4 Savannah tiles in a straight line |
| 21 | Marsh Frog | 7 Swamp tiles in a contiguous line |
| 22 | Peat Salamander | Exact centre of a Peat Bog discovery |
| 23 | Swamp Crane | Swamp tile adjacent to a River and Forest |
| 24 | Murk Crocodile | Swamp tiles enclosing a Water tile |
| 25 | Mud Crab | Mudflat tile adjacent to a Great Reef |
| 26 | Frost Owl | Roosts in a Boreal Forest biome |
| 27 | Boreal Wolf | 10 Tundra tiles bordering a Forest |
| 28 | Tundra Lynx | River intersecting a Tundra biome |
| 29 | Ice Cavern Bat | Enclosed Ice Cavern landmark |
| 30 | Sky-Whale | 1,000 total tiles with balanced biome ratios (global check) |

---

### User Story 1 - Riddle Hint and Spirit Summon (Priority: P1)

When a player's tile placements partially satisfy a spirit's compound conditions, a riddle hint surfaces in the garden UI — teasing the player toward the final placement. When the last condition is met, the spirit entity spawns at the triggering location and begins wandering.

**Why this priority**: This is the core discovery loop of Tier 3. Without it the spirit system delivers no gameplay value whatsoever — nothing appears, nothing rewards the player.

**Independent Test**: Seed a garden with the prerequisites for the Red Fox (two Forest tiles in an L arrangement). Verify the riddle hint appears. Place the third Forest tile to complete the triangle. Verify the Red Fox entity spawns at the cluster centroid.

**Acceptance Scenarios**:

1. **Given** a garden where the Red Fox pattern is partially satisfied (2 of 3 triangle tiles placed), **When** the second tile is placed, **Then** the riddle hint "Three forest corners, a triangle of green…" appears in the discovery tray.
2. **Given** the riddle hint is visible, **When** the player places the third Forest tile to complete the triangle, **Then** the Red Fox entity spawns at the cluster centroid within the same frame and the riddle hint is dismissed.
3. **Given** the Red Fox has already been summoned once, **When** a second triangle of Forest tiles is formed in a different area, **Then** no second Red Fox spawns and no riddle hint is shown (each spirit is discoverable at most once per garden).

---

### User Story 2 - Spirit Wandering within Bounding Region (Priority: P1)

After a spirit spawns it moves autonomously inside the bounding area derived from the tiles that triggered it. The spirit is always visible and animate — it is a living presence in the garden, not a static icon.

**Why this priority**: The wandering behaviour is what distinguishes a spirit from a simple discovery badge. Without it spirits feel inert and the Tier 3 reward feels flat.

**Independent Test**: Spawn the Stone Golem by placing a 3×3 block of Stone tiles. Observe for 30 seconds that the Golem moves within that 3×3 region and never leaves it.

**Acceptance Scenarios**:

1. **Given** the Stone Golem has spawned on a 3×3 Stone block, **When** 30 seconds elapse, **Then** the Golem has visibly changed position at least twice and has not moved outside the 3×3 bounding box.
2. **Given** the Koi Fish has spawned on a 2×2 Water square, **When** additional Water tiles are placed adjacent to the cluster, **Then** the Koi Fish's wander bounding box expands to encompass the enlarged cluster within one frame.
3. **Given** a spirit is wandering, **When** the player pans the camera away and back, **Then** the spirit is in the same relative position it would have reached had the camera never moved (no position reset on camera return).

---

### User Story 3 - Spirit Persistence across App Restarts (Priority: P2)

All active spirits and their wander state are saved with the garden and restored on the next launch. The player should find their spirits exactly where they left them.

**Why this priority**: Persistence is table stakes for a garden that the player returns to daily. Losing spirits on restart would feel like a punishment and undermine the value of discovery.

**Independent Test**: Summon the White Heron, note its position, close the app, reopen the app, and confirm the White Heron is present at the expected location.

**Acceptance Scenarios**:

1. **Given** the White Heron is wandering near grid coordinate (10, 5), **When** the app is closed and relaunched, **Then** the White Heron entity is present and wandering within its original bounding region.
2. **Given** 5 spirits have been summoned, **When** the app is relaunched, **Then** all 5 spirits are restored with no duplicates and no missing spirits.
3. **Given** a spirit's triggering cluster has not changed, **When** the app restarts, **Then** the spirit's wander bounding box is identical to the box saved at close time.

---

### User Story 4 - Sky-Whale Global Event (Priority: P3)

When the garden reaches 1,000 placed tiles and the biome distribution is sufficiently balanced, the Sky-Whale manifests in a full-screen event before taking up residence in the garden.

**Why this priority**: The Sky-Whale is the prestige capstone of the entire spirit system. It rewards players who build diverse, balanced gardens rather than spamming a single biome, making it a long-term goal.

**Independent Test**: Build a 1,000-tile garden with roughly equal proportions of each macro-biome. Verify the full-screen Sky-Whale event fires. Then build a 1,000-tile garden composed of 95% Forest tiles. Verify the event does NOT fire.

**Acceptance Scenarios**:

1. **Given** a garden of exactly 1,000 tiles with biome ratios each within ±15% of an even distribution, **When** the 1,000th tile is placed, **Then** the full-screen Sky-Whale event plays and the Sky-Whale entity appears in the garden.
2. **Given** a garden of 1,000 tiles dominated by one biome (e.g., 800 Forest tiles), **When** the 1,000th tile is placed, **Then** no Sky-Whale event fires; the discovery hint "A great balance is still missing…" is shown instead.
3. **Given** the Sky-Whale has already appeared, **When** the garden grows beyond 1,000 tiles, **Then** the event does not replay and the Sky-Whale continues wandering its existing bounding region.

---

### Edge Cases

- **Overlapping spirit conditions**: Two spirits may have conditions that occupy the same tiles (e.g., a straight line of 7 Forest tiles satisfies the Emerald Snake and could be part of a Jade Beetle cluster). Both spirits evaluate independently; satisfying one does not block the other.
- **Cluster expansion after spawn**: If the triggering cluster for a spirit grows (more tiles added), the spirit's wander bounding box expands to encompass the new tiles. The spirit does not re-spawn; it inherits the updated bounds.
- **Sky-Whale with poor biome balance**: Reaching 1,000 tiles but failing the balance check blocks the Sky-Whale. If the player later adds tiles that bring ratios into balance and total tiles remain at or above 1,000, the balance check re-evaluates and may trigger the event at that point.
- **Simultaneous condition completion**: If a single tile placement satisfies conditions for multiple spirits at once, all spirits queue to spawn sequentially (one per frame) with their individual riddle sequences skipped for already-completed spirits.
- **Spirit condition met before riddle is shown**: If the player places all required tiles in a single session without any intermediate partial state (e.g., a script or fast play), the riddle is displayed briefly at spawn time rather than skipped entirely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register all 30 spirit definitions as compound pattern definitions in the pattern engine
- **FR-002**: System MUST reveal a riddle hint to the player before a spirit's full summon condition is met (when the condition is partially satisfied)
- **FR-003**: System MUST spawn an autonomous spirit entity at the triggering cluster centroid when all conditions for that spirit are satisfied
- **FR-004**: Spirit entities MUST wander within a bounding area derived from their triggering tile cluster; the bounding area MUST update if the cluster expands
- **FR-005**: System MUST store all active spirit instances in the garden save data so they survive app restarts
- **FR-006**: Each spirit MUST be discoverable at most once per garden; a second satisfaction of the same conditions MUST be silently ignored
- **FR-007**: All 30 spirit definitions MUST be stored as data resources (not hard-coded logic), allowing additions without engine code changes
- **FR-008**: The Sky-Whale trigger MUST perform a global garden biome-balance check (not a local pattern scan) and MUST fire the full-screen event only when both the 1,000-tile count AND the balance threshold are met simultaneously
- **FR-009**: System MUST append a discovery log entry for each summoned spirit, recording spirit name, summon coordinate, and UTC timestamp

### Key Entities

- **SpiritDefinition**: ID, display name, riddle text, wander radius (tiles), summon conditions expressed as a compound pattern descriptor; stored as a data resource file
- **SpiritInstance**: reference to SpiritDefinition ID, spawn coordinate (grid), current wander bounding box (min/max grid coords), active state (bool); serialised into garden save data

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 30 spirit conditions can be seeded in a controlled test environment and each spirit spawns exactly once upon condition completion, with zero duplicate spawns across a full test run
- **SC-002**: A spawned spirit entity moves visibly within its wander bounds over a 30-second observation window and does not leave the bounding area on any observed frame
- **SC-003**: Spirits are still visible and positioned within their correct bounding regions after an app close and relaunch (persistence verified by automated save-load test)
- **SC-004**: The Sky-Whale full-screen event triggers when and only when both the 1,000-tile count AND the biome-balance conditions are met simultaneously; it does not trigger for unbalanced 1,000-tile gardens and does not replay once triggered
