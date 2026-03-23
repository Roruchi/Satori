# Feature Specification: Tier 2 — Structural Landmark Discoveries

**Feature Branch**: `007-tier2-structural-landmarks`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Tier 2 structural landmark discoveries triggered by geometric shape recipes"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Landmark Discovery Notification When Geometric Recipe Completes (Priority: P1)

As a player, I want to see a discovery notification the moment I place the tile that completes one of the 10 geometric landmark recipes, so that I know I have built something special and feel rewarded for intentional construction.

**Why this priority**: The notification is the player-facing payoff for the landmark system. Without it, completed landmarks exist only in data and the player never experiences the discovery moment. All other landmark features (visual overlays, log persistence) are enhancements to this core beat.

**Independent Test**: Build the "Origin Shrine" recipe manually — a cross (+) shape of Water tiles with Stone at `(0,0)`. Confirm: (a) the "Origin Shrine" notification fires when the final tile completes the cross, (b) the notification shows the landmark name and flavor text, (c) placing additional tiles nearby does NOT re-trigger the notification.

**Acceptance Scenarios**:

1. **Given** a partial cross of Water tiles with Stone at `(0,0)`, **When** the final Water tile completing the cross is placed, **Then** the "Origin Shrine" notification appears with name and flavor text.
2. **Given** the "Bridge of Sighs" pattern requires a 3-tile Stone line spanning across Water tiles, **When** the 3rd Stone tile is placed completing the span, **Then** the "Bridge of Sighs" notification fires.
3. **Given** "Origin Shrine" has already been discovered, **When** the player builds an identical cross shape at a different location, **Then** no second notification fires.
4. **Given** a geometric recipe with the correct shape but wrong biome types (e.g. Forest tiles instead of Water in the Origin Shrine cross), **When** the shape is completed, **Then** no landmark notification fires for Origin Shrine — biome types must match the recipe exactly.

---

### User Story 2 - Landmark Once Per Garden, Idempotent (Priority: P1)

As a player, I want each landmark to be discoverable exactly once per garden, so that the discovery log is a reliable historical record and I am not distracted by repeated notifications for shapes I have already completed.

**Why this priority**: Idempotency is a correctness requirement that shares the same priority as firing the landmark in the first place. A duplicate notification for a landmark would be more confusing than no notification at all, and would undermine the "once-per-garden" permanence philosophy.

**Independent Test**: Trigger "Lotus Pagoda" (2×2 Swamp square) once. Record the discovery log entry. Build a second 2×2 Swamp square elsewhere in the garden. Confirm the discovery log still has exactly one entry for "Lotus Pagoda" and no second notification appears.

**Acceptance Scenarios**:

1. **Given** "Lotus Pagoda" has been triggered once, **When** a second 2×2 Swamp configuration is constructed, **Then** no second signal or notification fires.
2. **Given** any of the 10 landmarks has been discovered, **When** the garden is saved, closed, and reopened, **Then** the landmark is still in the discovery log and will not re-fire on subsequent placements.
3. **Given** the landmark "Monk's Rest" is in the discovery log, **When** the pattern engine scans after any new placement, **Then** the Monk's Rest pattern ID is suppressed in all future scan passes.

---

### User Story 3 - Placeholder Visual Overlay on Completed Landmark Tiles (Priority: P2)

As a player, I want the tiles that form a completed landmark to display a subtle visual overlay or marking, so that I can see at a glance where my landmarks are without consulting the discovery log.

**Why this priority**: Visual overlays provide spatial context for the player's achievements and make the garden feel inhabited. They are independently deliverable as a rendering layer and do not affect gameplay logic — placeholder visuals are explicitly acceptable at this stage.

**Independent Test**: Trigger the "Echoing Cavern" landmark (3×3 Stone ring with empty centre). Confirm each of the 8 contributing Stone tiles displays a distinct visual overlay or tinting that differentiates them from non-landmark Stone tiles. Confirm the overlay is visible at both default and zoomed-out camera distances.

**Acceptance Scenarios**:

1. **Given** the "Echoing Cavern" landmark has been discovered, **When** the contributing Stone tiles are rendered, **Then** each tile has a visual overlay (placeholder acceptable) distinguishing it from non-landmark tiles.
2. **Given** a landmark overlay is applied, **When** the camera zooms out, **Then** the overlay remains visible (does not disappear at reduced scale) at all supported zoom levels.
3. **Given** a tile contributes to two different landmark shapes (if applicable), **When** both landmarks are discovered, **Then** the tile's overlay represents both — or at minimum the most recently discovered — without visual corruption.

---

### User Story 4 - Discovered Landmarks Visible in Discovery Log (Priority: P3)

As a player, I want to browse all landmarks I have discovered in a dedicated section of the discovery log, so that I can see my collection and re-read the flavor text for each landmark I have built.

**Why this priority**: The discovery log is a secondary screen that requires prior discovery to have any content. It is P3 because the core discovery moment (P1) delivers the primary value; the log is a reference feature.

**Independent Test**: Trigger 5 landmarks in a test session. Open the discovery log. Confirm all 5 appear with their names, flavor text, and trigger coordinates. Close and reopen the app. Confirm all 5 are still listed.

**Acceptance Scenarios**:

1. **Given** 5 landmarks have been discovered, **When** the player opens the discovery log, **Then** all 5 landmark entries are listed with display name and flavor text.
2. **Given** the discovery log is open, **When** the player taps a landmark entry, **Then** the camera navigates to the grid coordinates of the first discovered instance (or a representative coordinate from the triggering coords).
3. **Given** no landmarks have been discovered, **When** the player opens the landmark section of the discovery log, **Then** an appropriate empty-state message is shown (not a blank or error screen).

---

### Landmark Catalogue Reference

| # | Name | Shape Recipe Summary |
|---|------|---------------------|
| 1 | Origin Shrine | Cross (+) of Water tiles with Stone at `(0,0)` |
| 2 | Bridge of Sighs | 3-tile Stone line spanning across Water tiles |
| 3 | Lotus Pagoda | 2×2 square of Swamp (mixed) tiles |
| 4 | Monk's Rest | 1 Earth tile fully enclosed by 6 surrounding Forest tiles |
| 5 | Star-Gazing Deck | 1 Stone tile placed on top of a 20+ Mountain (Stone) cluster |
| 6 | Sun-Dial | 5 Sand tiles in a ring with Stone at the centre |
| 7 | Whale-Bone Arch | U-shape of 5 Sand+Stone mixed tiles |
| 8 | Echoing Cavern | 3×3 Stone ring with an empty (no tile) centre |
| 9 | Bamboo Chime | 5-tile straight line of Forest+Sand mixed tiles |
| 10 | Floating Pavilion | Water+Forest mixed tile with no adjacent land tiles |

---

### Edge Cases

- **Correct shape, wrong biome types**: A player assembles the exact geometric layout of "Origin Shrine" using Forest tiles instead of Water. The shape scan must check biome types at every position in the recipe, not just the geometric form. No landmark fires for a type-mismatched shape.
- **Partial shape (e.g. 4 of 5 tiles in a ring)**: The engine evaluates each shape recipe against the current grid state after every placement. An incomplete shape must not fire — the engine must only emit a signal when all positions in the recipe are occupied with the correct biome type.
- **Origin Shrine is coordinate-specific**: Unlike other landmarks, Origin Shrine requires Stone at `(0,0)` specifically. The recipe must include an absolute coordinate constraint for the centre tile in addition to the relative offsets for the Water cross arms. The shape pattern system must support at least one position being anchored to an absolute coordinate.
- **Floating Pavilion (isolated tile)**: This pattern requires a specific mixed tile with no adjacent land tiles — it is a "negative neighbour" constraint. The pattern engine must support forbidden-neighbour conditions at the shape recipe level for this landmark.
- **Echoing Cavern (empty centre)**: The 3×3 Stone ring requires the centre coordinate `(0,0)` of the ring to have no tile. The pattern engine must support "must be empty" constraints for specific positions in a shape recipe.
- **Star-Gazing Deck (cluster prerequisite)**: This landmark requires a 20+ Stone cluster to already exist before the capping tile triggers the discovery. This should be modelled as a compound pattern whose prerequisite is a cluster pattern ("Mountain Peak cluster ≥ 20"), not as an ad-hoc special case.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register all 10 landmark shapes as `LandmarkDefinition` resources using relative coordinate offsets and required biome types per position.
- **FR-002**: System MUST evaluate all registered shape patterns after every tile placement by delegating to the pattern matching engine (F05).
- **FR-003**: System MUST display a discovery notification (name + flavor text) for each newly completed landmark via the same notification system used by Tier 1 discoveries.
- **FR-004**: System MUST record each triggered landmark in the persistent discovery log with discovery ID, display name, trigger timestamp, and triggering coordinates.
- **FR-005**: Each landmark discovery MUST fire at most once per garden; subsequent matching configurations do not re-trigger the notification (idempotent, enforced by the pattern engine's duplicate-suppression in F05 FR-008).
- **FR-006**: System MUST support the following shape constraint types at minimum: straight line, ring, cross, U-shape, enclosed-centre (empty interior), isolated tile (no adjacent land), and absolute-coordinate anchor (required for Origin Shrine's Stone at `(0,0)`).
- **FR-007**: Completed landmark tiles SHOULD display a placeholder visual overlay on the contributing tile positions to visually distinguish them from non-landmark tiles at all supported zoom levels.

### Key Entities

- **LandmarkDefinition**: A data resource defining a single Tier 2 landmark. Attributes: `discovery_id` (String), `display_name` (String), `flavor_text` (String), `shape_recipe` (Array of position descriptors, each containing: `offset` (Vector2i), `required_biome` (BiomeType or ANY), `must_be_empty` (bool), `absolute_anchor` (bool — if true, offset is treated as an absolute grid coordinate)). Extends the `PatternDefinition` schema from F05.
- **ShapeMatch**: The resolved result of a successful shape evaluation. Attributes: `landmark_id` (String), `anchor_coord` (Vector2i — the grid coordinate that served as the shape's origin/anchor), `matched_coords` (Array[Vector2i] — the absolute grid coordinates of all tiles contributing to the match). Passed as the payload of the discovery signal.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 10 landmark configurations, when constructed in a test garden with the exact required biome types, trigger their notification exactly once — verified by an automated test covering all 10 landmark recipes.
- **SC-002**: Constructing the same geometric shape in a second location after the first discovery does not re-trigger the notification for that landmark — verified by a post-discovery duplicate-construction test for at least 3 landmark types.
- **SC-003**: All 10 landmarks appear in the discovery log after being triggered in a test session and all 10 remain present after the app is terminated and relaunched — verified by a persistence integration test.
- **SC-004**: Shape detection for all 10 landmark recipes completes without any perceptible frame lag (frame time remains below 16ms) on mid-range mobile hardware during a scripted placement sequence, measured by performance profiling.
