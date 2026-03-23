# Feature Specification: Pattern Matching Engine

**Feature Branch**: `005-pattern-matching-engine`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Background pattern matching engine for spatial discovery detection"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Background Pattern Scan After Every Tile Placement (Priority: P1)

As a player placing tiles, I want the game to silently check for completed discovery patterns after each placement and notify me immediately if one is found — without any lag or stutter in the game — so that discoveries feel magical and instantaneous.

**Why this priority**: The pattern matching engine is the signal pipeline for all discovery features (F06, F07, and any future tiers). If it blocks the render loop the game fails its 60fps mobile target. If it does not fire correctly, no discovery ever triggers. It is the most critical infrastructure piece after the grid itself.

**Independent Test**: Load a garden of 1,000 tiles that contains one incomplete known pattern (e.g. a cluster of 9 Forest tiles, needing 10 for "The Deep Stand"). Place the 10th Forest tile. Confirm: (a) a `discovery_triggered` signal is emitted with the correct discovery ID and coordinates, (b) frame time during the scan does not exceed 16ms, (c) the signal fires within the same update cycle as the placement.

**Acceptance Scenarios**:

1. **Given** a garden with 9 contiguous Forest tiles and a cluster pattern that requires 10, **When** the 10th Forest tile is placed, **Then** a `discovery_triggered` signal fires with the correct discovery ID before the next render frame.
2. **Given** a placement that does not complete any known pattern, **When** the scan completes, **Then** no discovery signal is emitted and no frame-time spike above 16ms is recorded.
3. **Given** a 1,000-tile garden, **When** any tile is placed and a full scan runs, **Then** the scan completes within 16ms on the target mid-range mobile device.
4. **Given** a placement that simultaneously satisfies two distinct patterns, **When** the scan completes, **Then** both discovery signals are emitted in the same scan pass, each with their own discovery ID and coordinate list.
5. **Given** a discovery signal is emitted, **When** the UI receives that signal, **Then** the game displays an on-screen discovery notification containing the discovery ID within the same update cycle.

---

### User Story 2 - No Duplicate Discovery Signals (Priority: P1)

As a player, I want each discovery to fire exactly once — when I first achieve it — so that the discovery system feels meaningful and the log is an accurate record of my garden's unique history.

**Why this priority**: Duplicate signals would flood the discovery log, trigger repeated audio stingers, and break compound pattern prerequisites that rely on a discovery being "already logged". This is equally critical to the engine's correctness as the scan itself.

**Independent Test**: Configure a cluster pattern with a known discovery ID. Construct the triggering configuration in a test garden. Confirm the signal fires once. Then add another tile adjacent to the cluster (extending it). Confirm the signal does NOT fire a second time for the same discovery ID.

**Acceptance Scenarios**:

1. **Given** a discovery pattern that has already been logged, **When** the exact same pattern is evaluated again (e.g. after the next placement), **Then** no second signal is emitted for that discovery ID.
2. **Given** a discovery ID in the discovery log, **When** the scan runs any number of subsequent times, **Then** that discovery ID is never emitted again.
3. **Given** two different discovery IDs that are independently triggered, **When** both fire in the same scan pass, **Then** each fires exactly once — duplication suppression does not suppress distinct discoveries.

---

### User Story 3 - Data-Driven Pattern Definitions (Priority: P1)

As a developer adding new content, I want to add a new discovery by creating a data resource file — not by modifying the engine scanning code — so that the catalogue can grow without risking regressions in existing patterns.

**Why this priority**: The pattern engine has no value if adding content requires engine code changes. Data-driven definitions are an architectural constraint that must be established from the first build; retrofitting it later would require rewriting the engine.

**Independent Test**: With no code changes to the scanning engine, create a new `PatternDefinition` resource file describing a simple 3-tile cluster. Run the game. Confirm the new pattern is detected and triggers a signal when the test configuration is built in-garden.

**Acceptance Scenarios**:

1. **Given** a new `PatternDefinition` resource file placed in the patterns directory, **When** the game loads, **Then** the engine includes that pattern in all subsequent scans without any code change.
2. **Given** the new pattern's trigger conditions are met in the garden, **When** the scan runs, **Then** the engine emits a `discovery_triggered` signal with the new pattern's ID.
3. **Given** an invalid or malformed `PatternDefinition` resource, **When** the game loads, **Then** the engine logs a warning and skips that pattern without crashing or affecting other patterns.

---

### User Story 4 - All Four Pattern Types Evaluate Correctly (Priority: P3)

As a developer, I want the engine to correctly evaluate cluster, shape, ratio/proximity, and compound patterns, so that the full range of Tier 1 and Tier 2 discoveries can be expressed using the data definition format.

**Why this priority**: This is a completeness requirement. P1 covers the scan infrastructure; P3 covers the full breadth of pattern type support. Each type can be added and tested incrementally without blocking the core signal pipeline.

**Independent Test**: Create one test `PatternDefinition` for each of the four types. Build each trigger configuration in a test garden. Confirm each type fires its signal exactly once at the correct moment.

**Acceptance Scenarios**:

1. **Given** a cluster pattern requiring 10 contiguous same-biome tiles, **When** the 10th tile is placed, **Then** the signal fires.
2. **Given** a shape pattern described by 5 relative coordinate offsets each with a specific biome, **When** all 5 positions are filled correctly, **Then** the signal fires.
3. **Given** a ratio/proximity pattern requiring a centre tile with 4 specific neighbour biomes, **When** all 4 neighbours are in place, **Then** the signal fires.
4. **Given** a compound pattern with prerequisite discovery ID "disc_001", **When** "disc_001" has NOT yet been logged, **Then** the compound pattern does NOT fire even if its spatial conditions are met.
5. **Given** the same compound pattern and "disc_001" IS in the discovery log, **When** the spatial conditions are met, **Then** the compound pattern fires.

---

### Edge Cases

- **Two patterns trigger simultaneously**: A single tile placement may satisfy multiple patterns at once. The engine must evaluate all patterns in the same scan pass and emit all resulting signals. Signal ordering should be deterministic (e.g. ordered by discovery ID or pattern priority) to ensure consistent sequencing in the notification queue.
- **Scan still running when the next tile is placed**: If pattern evaluation is dispatched to a background thread and a second placement arrives before the first scan completes, the second placement must be queued. The engine must not start a second concurrent scan that reads partially-written grid state. The discovery log check must see the state after both placements, not interleaved.
- **Pattern partially satisfied (9 of 10 required tiles)**: The engine must correctly report "no match" for incomplete conditions. No signal is emitted, no partial-discovery state is stored, and the incomplete state is silently discarded until a future placement completes it.
- **Compound pattern prerequisites form a chain**: Pattern C requires pattern B, which requires pattern A. The engine must resolve the dependency chain in the correct order within a single scan pass if all three trigger simultaneously.
- **Garden with zero tiles**: The engine must handle a scan call on an empty garden without error, emitting no signals.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST dispatch pattern evaluation to a background process (thread or deferred call) after every tile placement, never blocking on the result before returning control to the render loop.
- **FR-002**: System MUST NOT block the game render loop during pattern evaluation; frame time must remain below 16ms on mid-range mobile hardware during a scan of a 1,000-tile garden.
- **FR-003**: System MUST emit a `discovery_triggered` signal containing the discovery ID and the array of triggering tile coordinates when a pattern evaluation finds a complete match.
- **FR-004**: System MUST support cluster patterns: contiguous same-biome regions of ≥ N tiles, with optional purity constraints (forbidden biomes within or adjacent to the cluster).
- **FR-005**: System MUST support shape patterns: specific geometric tile arrangements described by an array of relative coordinate offsets, each with a required biome type.
- **FR-006**: System MUST support ratio/proximity patterns: a centre tile surrounded by required counts of specified neighbouring biome types within a defined radius.
- **FR-007**: System MUST support compound patterns: patterns that have one or more prerequisite discovery IDs that must already be present in the discovery log before the pattern can fire.
- **FR-008**: System MUST prevent duplicate discovery signals — a pattern whose ID is already in the discovery log MUST NOT emit a signal regardless of how many times its conditions are re-evaluated.
- **FR-009**: Pattern definitions MUST be stored as data resources (external files or inline resources), not hard-coded logic within the scanning engine. Adding a new pattern MUST require no changes to scanning code.
- **FR-010**: System MUST complete a full scan of a 1,000-tile garden in under 16ms on the target mid-range mobile hardware.
- **FR-011**: System MUST surface each emitted `discovery_triggered` event to the player via an on-screen notification that includes the matched discovery ID.

### Key Entities

- **PatternDefinition**: A data resource describing a single discovery pattern. Attributes: `discovery_id` (String), `pattern_type` (enum: cluster | shape | ratio_proximity | compound), `required_biomes` (Array[BiomeType]), `forbidden_biomes` (Array[BiomeType]), `size_threshold` (int, for cluster type), `shape_recipe` (Array[{offset: Vector2i, biome: BiomeType}], for shape type), `neighbour_requirements` (Dictionary, for ratio/proximity type), `prerequisite_ids` (Array[String], for compound type).
- **DiscoverySignal**: The payload emitted when a pattern completes. Attributes: `discovery_id` (String), `triggering_coords` (Array[Vector2i]). Consumed by the discovery log and the notification/audio systems.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every discovery pattern in the full catalogue fires exactly once when its conditions are first met, verified by an automated test that constructs each trigger configuration and asserts a single signal emission with the correct ID.
- **SC-002**: No pattern evaluation introduces a frame time spike above 16ms on a 1,000-tile garden on the target mid-range mobile device, verified by performance profiling during a scripted placement sequence.
- **SC-003**: Placing a tile that simultaneously satisfies two discovery patterns causes both signals to fire within the same scan pass (same frame budget), verified by a test that constructs a dual-trigger configuration.
- **SC-004**: Adding a new `PatternDefinition` resource to the patterns directory causes the engine to detect and fire the new pattern with zero changes to engine scanning code, verified by a content-addition integration test.
- **SC-005**: For every emitted `discovery_triggered` signal, the UI renders a visible notification with the corresponding discovery ID, verified by an integration test that triggers a known pattern.
