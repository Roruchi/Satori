# Feature Specification: Craft Mode Building Placement

**Feature Branch**: `020-craft-mode-buildings`  
**Created**: 2026-04-03  
**Status**: Draft  
**Input**: User description: "Now that 019 is in place we need to do the following: Remove the build mode, update the crafting system so that you can now craft buildings in the craft mode each recipe takes 3+ slots. When crafting a building place it in the inventory. Selecting a building in your inventory should allow you to place it on top of tiles. Small buildings taking one tile and bigger buildings can take multiple tiles. When placing a building the user can explicit confirm / cancel it (Which is the way building currently work.) And then since we have one inventory we should update the inventory to 8 slots."

## Clarifications

### Session 2026-04-03

- Q: After discovery, how are building recipes crafted? -> A: Crafting always resolves directly from the current ingredient pattern in the grid; discovery is informational/progression only.
- Q: Does full-inventory craft failure still grant first-time discovery? -> A: No. Discovery is only recorded on successful craft output; failed crafts due to full inventory do not unlock discovery.
- Q: How do crafted building items stack in inventory? -> A: Building items stack only when they are the exact same building type; different building types never stack together.
- Q: What is the stack cap for same-type building items? -> A: Same-type building stacks are capped at 99.
- Q: What happens when a matching same-type stack is already at 99? -> A: If another inventory slot is free, crafting creates a new same-type stack in that free slot.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Craft Buildings in Craft Mode (Priority: P1)

As a player, I can craft buildings by arranging ingredients in craft mode patterns, and successful pattern discoveries unlock progression without switching to any recipe-list selection flow.

**Why this priority**: This is the core behavior change requested and unlocks all later placement interactions.

**Independent Test**: Can be validated with GUT coverage for pattern recognition and discovery state transitions, plus manual in-editor verification that discovered patterns produce building items inside craft mode without any separate build mode.

**Acceptance Scenarios**:

1. **Given** a player is in craft mode with a valid building pattern, **When** they place the required ingredients in the correct arrangement and confirm, **Then** the craft succeeds and produces one building inventory item.
2. **Given** a player creates a new valid building pattern for the first time with available inventory space, **When** crafting succeeds, **Then** that recipe is marked discovered and remains available for future attempts.
3. **Given** an existing world where build mode was previously available, **When** the player accesses construction flow, **Then** building crafting is only available through craft mode and no separate build mode entry point is shown.
4. **Given** a craft would create a building item of an exact type already present in inventory, **When** crafting succeeds, **Then** that item stacks into the matching building-type stack instead of creating a mixed-type stack, up to a cap of 99 per stack.
5. **Given** a matching same-type stack is at 99 and at least one other slot is free, **When** crafting succeeds, **Then** the output is placed into a new stack of that same building type in a free slot.

---

### User Story 2 - Place Buildings from Inventory (Priority: P2)

As a player, I can select a crafted building from inventory and place it onto tiles, including both single-tile and multi-tile footprints.

**Why this priority**: Crafted buildings have no gameplay value unless they can be placed back into the world.

**Independent Test**: Can be validated with GUT placement-rule tests for occupancy and footprint validation, plus manual verification of tile preview behavior for both one-tile and larger buildings.

**Acceptance Scenarios**:

1. **Given** a building item exists in inventory, **When** the player selects it, **Then** placement preview starts and valid target tiles are placeable.
2. **Given** a one-tile building is selected, **When** the player confirms on an empty tile, **Then** the building is placed on that tile.
3. **Given** a multi-tile building is selected, **When** part of its footprint overlaps blocked or occupied tiles, **Then** confirmation is prevented until a fully valid footprint is targeted.

---

### User Story 3 - Confirm or Cancel Building Placement (Priority: P3)

As a player, I can explicitly confirm or cancel placement after selecting a building, preserving the current confirmation flow and preventing accidental placement.

**Why this priority**: Explicit confirmation is already expected behavior and protects user intent during the new inventory-driven placement flow.

**Independent Test**: Can be validated via GUT tests for confirm/cancel state transitions and inventory consumption rules, plus manual in-editor checks of user prompts and cancellation outcomes.

**Acceptance Scenarios**:

1. **Given** a player is previewing a valid placement, **When** they confirm, **Then** the building is placed and one matching building item is removed from inventory.
2. **Given** a player is previewing a placement, **When** they cancel, **Then** no building is placed and the building item remains in inventory.
3. **Given** inventory is full, **When** a building craft would produce a new building item, **Then** the craft fails and no ingredients are consumed.

### Edge Cases

- Player crafts a building while all 8 inventory slots are occupied.
- Player matches a new valid undiscovered pattern while inventory is full; craft fails and discovery remains locked.
- Player enters a nearly-correct pattern (right ingredients, wrong positions) and attempts crafting.
- Player discovers the same building pattern again after it was already discovered.
- Player crafts a wood house while inventory has a stone/water house stack; the new item does not merge into the different-type stack.
- Player crafts a building whose exact-type stack is already at 99.
- Player crafts a building whose exact-type stack is at 99 with one free slot available; crafting creates a second same-type stack.
- Player starts placement and then changes selected inventory slot before confirming.
- Player attempts to place a multi-tile building partly outside the playable grid bounds.
- Player attempts to place onto tiles containing incompatible existing objects.
- Player cancels placement repeatedly across different buildings without losing inventory items.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST remove standalone build mode as a separate player mode for creating new buildings.
- **FR-002**: The game MUST allow buildings to be crafted from ingredient arrangement patterns in craft mode, with no building recipe-list selection step.
- **FR-003**: Every building recipe pattern MUST use at least 3 occupied input slots.
- **FR-004**: The game MUST treat a valid first-time building pattern completion as a recipe discovery event.
- **FR-005**: A successful building craft MUST produce a building item in the shared player inventory.
- **FR-006**: If inventory has no free slot, building crafting MUST fail and MUST NOT consume ingredients or grant first-time discovery.
- **FR-007**: The shared inventory MUST provide exactly 8 slots.
- **FR-008**: Building inventory items MUST stack only with items of the exact same building type, and MUST NOT stack with different building types.
- **FR-009**: Same-type building stacks MUST have a hard cap of 99 items per stack, and if that cap is reached while another inventory slot is free, crafting MUST place output into a new same-type stack in a free slot.
- **FR-010**: Players MUST be able to select a building item from inventory to initiate building placement.
- **FR-011**: The placement system MUST support both one-tile and multi-tile building footprints.
- **FR-012**: The placement flow MUST require explicit player confirm or cancel input before finalizing.
- **FR-013**: Confirmed placement MUST consume one matching building item from inventory.
- **FR-014**: Canceled placement MUST leave the building item in inventory and leave the world unchanged.
- **FR-015**: Placement MUST be blocked when any tile in the selected footprint is invalid, occupied, or out of bounds.
- **FR-016**: The system MUST provide clear player feedback for blocked crafting or blocked placement attempts, including full-inventory craft failure.
- **FR-017**: Non-building tile placement behavior MUST remain immediate and MUST NOT require an explicit confirm step.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Feature MUST preserve permanent-emergence progression by ensuring building creation continues to require recipe-based crafting rather than free placement.
- **EX-002**: Feature MUST preserve accessible confirm/cancel interactions across input methods, including mobile-touch pathways and existing accessibility settings.
- **EX-003**: Entering placement preview and validating a candidate footprint MUST feel immediate during normal play and not introduce noticeable interaction delay.

### Key Entities *(include if feature involves data)*

- **Building Recipe Pattern**: A craftable arrangement definition with three or more occupied ingredient slots that outputs a building item.
- **Recipe Discovery State**: The player-visible record of which valid building patterns have been discovered.
- **Building Inventory Item**: A storable item record representing one placeable building instance.
- **Building Type Key**: The canonical identifier used to determine whether two building items are the exact same type for stacking.
- **Building Stack Count**: The per-slot quantity value for a stacked building type, capped at 99.
- **Shared Inventory Slot**: One of 8 unified player-held slots that can contain materials, crafted outputs, or building items.
- **Building Footprint**: A tile occupancy pattern defining how many and which tiles a building requires to be validly placed.
- **Placement Session**: A temporary player interaction state from building-item selection through explicit confirm or cancel.

### Assumptions

- Building crafting is pattern-driven, including arrangements such as a 2x2 pattern with Chi at the bottom and Fu at the top for a house outcome.
- Recipe discovery does not replace pattern crafting with a separate craft-from-list interaction.
- Existing non-building crafting behavior remains available within craft mode and is not removed by this feature.
- Existing placement confirmation language and interaction style are retained unless a separate UX update is requested.
- Existing save data migrates to the unified 8-slot inventory model without deleting previously owned items.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation sessions, 95% of players can craft a building and place it successfully in under 90 seconds without external instruction.
- **SC-002**: In acceptance testing, 100% of valid first-time building patterns with successful output trigger a discovery record exactly once.
- **SC-003**: In acceptance testing, 100% of confirmed placements consume exactly one building item and place exactly one building instance.
- **SC-004**: In acceptance testing, 100% of canceled placements leave world state and inventory counts unchanged.
- **SC-005**: In acceptance testing, 100% of invalid footprint placements are blocked with clear user-facing feedback.
- **SC-006**: In acceptance testing, 100% of full-inventory building craft attempts fail with no ingredient loss.
- **SC-007**: In acceptance testing, 100% of same-type building stacks enforce the 99-item cap and roll over into a new same-type stack when a free slot exists.
- **SC-008**: The in-game inventory UI consistently displays 8 usable slots in all contexts where inventory is shown.
