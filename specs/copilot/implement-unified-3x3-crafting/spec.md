# Feature Specification: Unified 3×3 Crafting and Explicit Placement

**Feature Branch**: `copilot/implement-unified-3x3-crafting`
**Created**: 2026-07-17
**Status**: Draft
**Author**: Roel van Bergen (RFC) / Speckit
**Input**: RFC — Migration to Unified 3×3 Crafting and Explicit Ghost Placement

---

## Overview

Satori currently detects structures by scanning the live game board for spatial tile arrangements at runtime. This pattern-inference approach is fragile, hard to extend, and creates accidental structure creation for players who are simply placing biome tiles. This feature replaces that approach with a **two-phase model**:

1. **Craft** — A 3×3 grid UI where the player arranges elemental charges into a recognised recipe shape and receives a discrete inventory item.
2. **Place** — The player selects that item from inventory, sees a ghost footprint on the map, optionally rotates it, and confirms an atomic placement.

Structure-related runtime pattern scanning is fully retired. Biome cluster discoveries (river, deep stand, etc.) are explicitly **out of scope** and continue to use the existing pattern-matching pipeline.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Craft a Single-Tile Biome from the Grid (Priority: P1)

The player opens the crafting grid, places a single elemental charge (e.g. Chi) in any slot, and confirms. They receive a Chi/Stone tile in their inventory and then tap to place it on any valid adjacent cell, identical to the existing tile-placement flow.

**Why this priority**: Tile crafting is the most frequent action in the game. The 3×3 grid must handle the 1- and 2-element tile cases without regression before any structure work is validated. Proving this story proves the grid input model and the recipe-lookup logic work end-to-end.

**Independent Test**: Open the crafting grid in the debug harness, place one Chi charge in the centre slot, and confirm. Verify a Stone tile item appears in inventory. Place it on a valid adjacent cell. Confirm the tile appears on the board with the correct biome type and that no pattern scan is triggered for structure detection.

**Acceptance Scenarios**:

1. **Given** an empty crafting grid, **When** the player places a single Chi charge in any slot and confirms, **Then** a Stone (Chi) tile item is added to inventory and the grid resets to empty.
2. **Given** a single Chi charge in any grid slot, **When** the player places a single Sui charge in any other slot that is not adjacent to the Chi slot, **Then** the confirm button is disabled (contiguity rule violated).
3. **Given** two adjacent charges (Chi and Sui) anywhere in the grid, **When** the player confirms, **Then** a Wetlands tile item is added to inventory regardless of which corner the pair starts in (floating shape).
4. **Given** a valid 2-element tile recipe, **When** the player places the resulting tile item on the board, **Then** the tile appears at the correct cell with the correct biome and the legacy in-world structure scanner is not triggered.

---

### User Story 2 — Craft a Structure from the Grid (Priority: P1)

The player opens the crafting grid, places 3 or more connected elemental charges that match a known structure recipe (e.g. a 3-tile L-shape of Chi charges to craft a Torii gate), and confirms. They receive a discrete "Wayfarer Torii" structure item in their inventory.

**Why this priority**: Structure crafting is the core new capability this RFC introduces. It must work correctly before ghost placement can be validated. All existing structure content must produce the same end result via this new path.

**Independent Test**: In the debug harness, open the crafting grid, place the correct shape for the Wayfarer Torii recipe, and confirm. Verify the correct structure item (not a tile) appears in inventory. Verify no in-world structure tile-scan event is emitted.

**Acceptance Scenarios**:

1. **Given** a 3-element L-shaped arrangement of Chi charges in the crafting grid, **When** the arrangement matches a known structure recipe, **Then** the corresponding structure item is added to inventory.
2. **Given** the same L-shape mirrored (flipped horizontally), **When** the player confirms, **Then** the confirm button is disabled because strict orientation is enforced — a mirror does not match the recipe.
3. **Given** the same valid L-shape shifted to a different area of the 3×3 grid (floating), **When** the player confirms, **Then** the structure item is produced correctly.
4. **Given** a 3-element arrangement that is not contiguous (e.g. one charge isolated diagonally), **When** the arrangement is shown in the grid, **Then** the UI visually marks the isolated charge as invalid and disables confirm.
5. **Given** a valid recipe shape, **When** the player opens the Codex for that structure, **Then** the recipe shape is illustrated in the Codex entry.

---

### User Story 3 — Place a Crafted Structure via Ghost Footprint (Priority: P1)

The player selects a structure item from inventory. A ghost footprint (a translucent multi-tile preview) follows the cursor/finger on the map. The player moves it to a valid location, optionally rotates it, and confirms. The structure spawns atomically — all tiles appear in a single frame.

**Why this priority**: Ghost placement is the second half of the two-phase model and the primary UX win over the old system. Until it works, the feature is incomplete. It also provides the first user-visible evidence that accidental structure creation is eliminated.

**Independent Test**: Craft a 3-tile structure item. Select it from inventory. Drag the ghost footprint over an invalid cell (wrong terrain type) and verify the blocked cells are highlighted red with error text. Move to a valid location and confirm placement. Verify all tiles of the structure appear simultaneously on the board in one frame, and the item is consumed from inventory.

**Acceptance Scenarios**:

1. **Given** a structure item in inventory, **When** the player selects it, **Then** the map enters Build Mode and a ghost footprint that matches the structure's shape follows the cursor.
2. **Given** the ghost footprint is over a cell where placement would violate terrain rules, **Then** the blocked cell(s) within the footprint are visually highlighted and human-readable error text is shown (e.g. "Requires Stone biome").
3. **Given** the ghost footprint is over a fully valid placement location, **When** the player confirms, **Then** all structure tiles are placed simultaneously in one frame and the structure item is removed from inventory.
4. **Given** the ghost footprint is on the map, **When** the player triggers a rotate action, **Then** the footprint rotates 90° in place and terrain validation re-runs for the new orientation.
5. **Given** the player is in Build Mode, **When** they press Cancel or tap outside the footprint zone, **Then** Build Mode exits and the structure item is returned to inventory.
6. **Given** a placement is confirmed, **When** the garden state is inspected, **Then** no intermediate partial-structure state exists — either all tiles are present or none are.

---

### User Story 4 — New 4-Element Starter House (Priority: P1)

The player uses the crafting grid to produce the new Starter House: a solid 2×2 block of Fu charges. This replaces the legacy 2-element (Chi + Fu) house recipe. Post-tutorial, the player receives enough elemental charges to craft one Starter House without additional grinding.

**Why this priority**: The Starter House is the first structure new players build. If the recipe cost is unplayable or the tutorial does not teach the new grid UX, onboarding is broken. This must be validated before any other story.

**Independent Test**: Run the new-player tutorial flow in the debug harness. Verify the player ends the tutorial with enough Fu charges to fill a 2×2 block (4 charges). Craft the Starter House from the grid. Confirm the structure item appears. Place it and verify a spirit can bind to it. Verify the legacy Chi+Fu 2-tile recipe no longer produces a house item.

**Acceptance Scenarios**:

1. **Given** the player has 4 Fu elemental charges, **When** they arrange them as a 2×2 solid block anywhere in the 3×3 grid and confirm, **Then** a Starter House structure item is added to inventory.
2. **Given** the player arranges 2 Fu charges in any adjacent pair, **When** they confirm, **Then** they receive a Meadow tile item — not a house — because 2-element recipes produce tiles.
3. **Given** the post-tutorial starter inventory, **When** the player opens the crafting grid, **Then** they have sufficient Fu charges to fill a 2×2 block without additional farming.
4. **Given** a placed Starter House structure on the board, **When** a spirit-binding event is evaluated, **Then** the structure is recognised as a valid dwelling with correct housing capacity.
5. **Given** the legacy Chi+Fu recipe is looked up in the recipe registry, **Then** it produces only a Meadow tile (the normal 2-element tile result) and no house item is produced by that combination.

---

### User Story 5 — Legacy Structure Pattern-Matching Retired (Priority: P2)

All runtime scanning for structure footprints on the game board is removed from the codebase. Existing structures in saved gardens continue to render correctly via stored placement data; they are never re-inferred from tile proximity at load time.

**Why this priority**: Code health and regression prevention. The legacy scanner is the root cause of the edge-case bugs described in the RFC. Retiring it prevents future regressions and reduces maintenance cost, but it does not block the new UX — it can be done in parallel or immediately after the new placement path is validated.

**Independent Test**: In a seeded garden with all previously-discovered structure types present, load the garden and verify no structure-detection scan runs. Confirm all existing structures are visible. Place new tiles adjacent to a structure footprint and confirm no spurious re-detection occurs. Grep the codebase for structure-scanning call sites and confirm they are gone.

**Acceptance Scenarios**:

1. **Given** a saved garden containing all structure types, **When** it is loaded, **Then** all structures are visible at their stored coordinates and no pattern scan for structures runs on load.
2. **Given** the codebase, **When** searching for structure pattern-matching call sites, **Then** no active code paths trigger a structure shape scan on the game board.
3. **Given** a player placing biome tiles adjacent to an existing structure, **When** placement completes, **Then** no in-world structure detection event is emitted and the structure does not change or duplicate.
4. **Given** all existing biome cluster discoveries (river, deep stand, etc.), **When** the pattern engine runs, **Then** it continues to fire as before — only structure-specific scanning is retired.

---

### Edge Cases

- What happens when the player has a structure item in inventory and exits the app? The item must survive save/load and be usable on next launch.
- What happens when the player rotates the ghost footprint to an orientation that leaves the footprint partially off the edge of the currently loaded area? Footprint must clamp or show an error rather than creating an out-of-bounds placement.
- What happens if two elemental charges of the same type are placed in the grid but are not contiguous? Each isolated island must be flagged individually; the confirm button must remain disabled.
- What happens if a recipe shape matches more than one recipe (ambiguous)? The recipe registry must be designed such that ambiguity is not possible — validated at data-authoring time.
- What happens if the player is in Build Mode and receives a spirit event? Spirit events must queue or pause; Build Mode should not be interrupted unexpectedly.
- What happens if a 4-element (2×2) Starter House footprint is placed and one of the 4 cells is already occupied? The entire placement is rejected atomically — no partial placement occurs.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide a 3×3 crafting grid UI accessible during normal play from the main screen.
- **FR-002**: Each slot in the crafting grid MUST accept at most one elemental charge.
- **FR-003**: A recipe is valid anywhere within the 3×3 grid, provided the relative shape of placed charges matches the recipe's defined shape (floating/anchorless matching).
- **FR-004**: The crafting grid MUST NOT auto-rotate or mirror shapes. A player-placed orientation must exactly match the recipe's canonical orientation to confirm.
- **FR-005**: A recipe arrangement is only confirmable when all charges in the grid form a single contiguous group, where orthogonal and diagonal adjacency both count as connections.
- **FR-006**: An arrangement of 1 or 2 elemental charges that matches a known recipe MUST produce a Tile item (basic or combined biome).
- **FR-007**: An arrangement of 3 or more elemental charges that matches a known structure recipe MUST produce a Structure item.
- **FR-008**: Confirming any unrecognised arrangement (valid shape, no matching recipe) MUST be disallowed — the confirm button remains disabled and a hint is shown.
- **FR-009**: Confirming a valid recipe MUST add one discrete inventory item of the corresponding type and reset the crafting grid to empty.
- **FR-010**: Selecting a Structure item from inventory MUST enter Build Mode: the map view becomes interactive and a ghost footprint matching the structure's tile layout follows the cursor/touch point.
- **FR-011**: While in Build Mode, the player MUST be able to rotate the ghost footprint in 90° increments before confirming placement.
- **FR-012**: The ghost footprint MUST perform terrain validation in real time: cells that violate terrain rules are highlighted as blocked, and human-readable error text is displayed per violated rule.
- **FR-013**: Confirming a placement MUST be atomic — all tiles of the structure appear on the game board simultaneously in a single frame or transaction; no intermediate partial state is observable.
- **FR-014**: The player MUST be able to cancel Build Mode at any time; the structure item MUST be returned to inventory on cancel.
- **FR-015**: The Starter House recipe MUST require a 2×2 solid block of 4 Fu (Wind) elemental charges arranged anywhere in the 3×3 grid.
- **FR-016**: The legacy 2-element (Chi + Fu) house recipe MUST be removed. A Chi + Fu arrangement in the crafting grid produces only a Meadow tile.
- **FR-017**: The post-tutorial "Starter Seed Injection" grant MUST include at least 4 Fu charges so a first-time player can craft the Starter House without additional farming.
- **FR-018**: All runtime structure detection by spatial pattern scanning on the game board MUST be removed from the active code paths.
- **FR-019**: Existing structures stored in saved gardens MUST continue to render correctly using stored placement coordinates, never re-inferred from tile proximity.
- **FR-020**: The crafting grid UI MUST display a visual preview of a recipe's output (name and icon) when a valid recipe is detected in the grid.

### Experience & Runtime Constraints *(mandatory)*

- **EX-001**: The removal of structure pattern scanning MUST NOT affect biome cluster discovery scanning (`disc_river`, `disc_deep_stand`, etc.). Those patterns run unchanged.
- **EX-002**: Ghost footprint cursor tracking and rotation MUST be responsive on the mobile touch target; the placement confirmation tap must be reachable from the thumb zone without repositioning the hand. Build Mode UI controls (rotate, cancel, confirm) MUST appear in the bottom thumb zone.
- **EX-003**: Atomic placement MUST complete within a single render frame on the minimum target device (mid-range mobile, iPhone 13 equivalent). Ghost footprint position updates MUST not introduce frame-time spikes above 16 ms.

### Key Entities

- **CraftingGrid**: Transient 3×3 state holding up to 9 elemental charge slots. Responsible for contiguity validation, floating-shape normalisation (canonical top-left alignment for lookup), and signalling recipe match state to the UI.
- **RecipeDefinition**: Data resource that describes a recipe by its canonical normalised shape (set of relative `Vector2i` offsets), required element types per cell, minimum element count, and output item type. Replaces the role structure shape-patterns played in the old `PatternDefinition` catalog.
- **InventoryItem**: A discrete crafted output record held in player inventory. Contains item type (tile or structure), associated recipe ID, and quantity. Must survive save/load.
- **BuildMode**: Transient runtime state active when the player is placing a structure item. Holds the ghost footprint shape, current rotation state, target anchor cell, and latest terrain-validation result.
- **GhostFootprint**: A visual scene node that renders the translucent multi-tile preview on the map and communicates valid/blocked cells per-cell using a colour overlay and text label.
- **TerrainValidator**: Stateless helper that accepts a structure recipe, a map anchor cell, and a rotation angle, then returns a per-cell pass/fail result with localised error strings.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero Ambiguity — every crafting action produces exactly one unambiguous outcome; no mixed-footprint or partial-structure results are observable in any test run.
- **SC-002**: Atomic Placement — multi-tile structures always appear fully on the board within a single frame; frame profiling of the confirmation event shows no intermediate partial-structure state.
- **SC-003**: UX Clarity — in a lightweight playtest (minimum 5 new players), every participant can describe the full build flow ("open grid → place elements → craft item → place on map") in one sentence without prompting.
- **SC-004**: Legacy Code Retired — a search of the active codebase finds zero call sites that trigger runtime structure pattern scanning on the game board; the shape-based structure matchers are deleted or isolated behind a deprecated-only compilation flag.
- **SC-005**: Tutorial Completion — new players complete the crafting-grid tutorial and successfully place their first Starter House without additional elemental farming; the post-tutorial seed grant is sufficient.
- **SC-006**: Save/Load Fidelity — structure inventory items survive a save/load round trip; placed structures from saves render correctly without re-running any structure scan.

---

## Assumptions

- Biome cluster and biome ratio/proximity discoveries (`disc_river`, `disc_deep_stand`, all Tier 1/2 biome discoveries) are **not** part of this migration. They continue to use the existing `PatternMatcher` pipeline.
- The existing elemental charge ("seed") inventory system is sufficient to hold the new discrete structure items, or a straightforward extension of it is used; no new persistence schema is required beyond adding an `item_type` field.
- Ku-element recipes (spec 016) continue to follow the same 1-/2-element → tile rule; no Ku-specific structure recipes are added in this feature.
- The Tier 2 structural landmark recipes (`disc_wayfarer_torii`, `disc_origin_shrine`, etc.) that previously relied on build-mode shape recognition will be migrated to the new 3×3 crafting grid recipe format. Their terrain placement rules move to the `TerrainValidator`.
- The Codex entry format can be extended to show a recipe-grid illustration without a separate feature spec; this is a cosmetic addition inside this feature's scope.
- "Strict orientation" means the player must match the recipe's canonical orientation exactly; the four 90° rotations available in Build Mode are for placement, not for crafting-grid recognition.
