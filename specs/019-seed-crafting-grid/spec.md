# Feature Specification: Phase 1 Seed Crafting in 3x3 Grid

**Feature Branch**: `019-seed-crafting-grid`  
**Created**: 2026-03-31  
**Status**: Draft  
**Input**: User description: "Based on proposal.md, start a first specification focused on changing the crafting menu to use a 3x3 grid. The crafting grid creates items in the plant inventory. Start with only the first phase being seed recipes. Migration of structures and builds will happen in a later request and must be explicitly out of scope for this spec."

## Clarifications

### Session 2026-03-31

- Q: What recipe domain is included in this phase? -> A: Seed recipes only in Phase 1.
- Q: Where do successful crafting outputs go in this phase? -> A: Plant inventory.
- Q: Are structure/build migrations part of this specification? -> A: No, explicitly out of scope.
- Q: When are elemental tokens consumed? -> A: Tokens are consumed only on successful craft.
- Q: What happens when inventory is full for a valid recipe? -> A: Craft completion is blocked; tokens remain in grid; inventory-full message is shown.
- Q: What happens to grid slots after successful craft? -> A: Consumed slots are cleared.
- Q: What is the minimum mobile touch target for grid slots? -> A: 48x48 px minimum per slot.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Craft Single-Element Seeds from a 3x3 Grid (Priority: P1)

As a player, I want to place one elemental token in a 3x3 crafting grid and craft the corresponding seed so seed creation matches the new crafting interaction model.

**Why this priority**: This is the smallest playable slice of the new grid crafting loop and validates the new menu interaction without requiring structure migration.

**Independent Test**: Validate with GUT coverage for each single-element seed output and manual in-editor verification that crafted output is added to plant inventory.

**Acceptance Scenarios**:

1. **Given** the crafting menu is open and the player places `CHI` in any one grid slot, **When** the player confirms craft, **Then** one Stone Seed is added to plant inventory.
2. **Given** the crafting menu is open and the player places `KU` in any one grid slot without Ku unlocked, **When** the player confirms craft, **Then** no seed is created and the player receives a clear unlock-required message.

---

### User Story 2 - Craft Dual-Element Seeds with Position-Insensitive Matching (Priority: P1)

As a player, I want two-token seed recipes to resolve regardless of where the tokens are placed in the 3x3 grid so crafting is readable and forgiving.

**Why this priority**: Dual-element seeds are core progression content and must remain intuitive under the new grid.

**Independent Test**: Validate with GUT coverage for all dual-element seed mappings using multiple slot arrangements per recipe, plus manual in-editor verification.

**Acceptance Scenarios**:

1. **Given** the player places `CHI` and `SUI` in any two grid slots, **When** the player confirms craft, **Then** one Wetlands Seed is added to plant inventory.
2. **Given** the player places `FU` and `KA` in any two grid slots, **When** the player confirms craft, **Then** one The Ashfall Seed is added to plant inventory.

---

### User Story 3 - Receive Clear Failure Feedback for Non-Seed Inputs (Priority: P2)

As a player, I want clear feedback when grid contents do not match a Phase 1 seed recipe so I can correct my inputs without confusion.

**Why this priority**: The new grid introduces more input permutations; clear failure behavior reduces friction and onboarding issues.

**Independent Test**: Validate with GUT coverage and manual checks for invalid combinations, overfilled inputs, and locked-element conditions.

**Acceptance Scenarios**:

1. **Given** the player places three or more tokens in the 3x3 grid, **When** the player confirms craft, **Then** no output item is created and a "no matching seed recipe" message is shown.
2. **Given** the player places a token combination with no seed mapping, **When** the player confirms craft, **Then** no output item is created and the player receives corrective feedback.

### Edge Cases

- Player confirms craft with an empty grid; no item is created and a clear prompt is shown.
- Player uses duplicate tokens in two slots for a dual-token attempt; only explicitly defined seed recipes are craftable.
- Player repeatedly confirms the same valid recipe; each successful craft adds exactly one seed item per confirmation.
- Player attempts a Ku-based recipe before Ku is unlocked; output is blocked with unlock guidance.
- Plant inventory is full when a valid recipe is confirmed; craft completion is blocked, no seed is created, recipe tokens remain in the grid, and an inventory-full message is shown.
- Player enters a legacy structure/build combination in the 3x3 grid; craft resolves as no matching seed recipe with corrective feedback.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present seed crafting through a 3x3 craft grid in this phase.
- **FR-002**: Each grid slot MUST accept either zero or one elemental token.
- **FR-003**: System MUST resolve single-element seed recipes from one token placed in any slot.
- **FR-004**: System MUST resolve dual-element seed recipes from two tokens regardless of slot position.
- **FR-005**: System MUST support these single-token outputs: `CHI -> Stone Seed`, `SUI -> River Seed`, `KA -> Ember Field Seed`, `FU -> Meadow Seed`, `KU -> Ku Seed`.
- **FR-006**: System MUST support these dual-token outputs: `CHI+SUI -> Wetlands Seed`, `CHI+KA -> Badlands Seed`, `CHI+FU -> Whistling Canyons Seed`, `SUI+KA -> Prismatic Terraces Seed`, `SUI+FU -> Frostlands Seed`, `KA+FU -> The Ashfall Seed`, `CHI+KU -> Sacred Stone Seed`, `SUI+KU -> Moonlit Pool Seed`, `KA+KU -> Ember Shrine Seed`, `FU+KU -> Cloud Ridge Seed`.
- **FR-007**: System MUST enforce unlock gating for Ku-based recipes and block craft output when Ku is not unlocked.
- **FR-008**: Successful craft MUST create exactly one seed output item and add it to plant inventory.
- **FR-009**: Elemental tokens in the recipe MUST be consumed only when craft completes successfully.
- **FR-010**: After successful craft completion, grid slots used by the consumed recipe tokens MUST be cleared.
- **FR-011**: If a valid recipe is confirmed while plant inventory is full, craft completion MUST be blocked, no output item is created, recipe tokens MUST remain in their current grid slots, and an inventory-full message MUST be shown.
- **FR-012**: Craft attempts with non-matching seed inputs MUST not create output and MUST provide clear user-facing feedback.
- **FR-013**: This phase MUST exclude structure recipes, house recipes, and structure placement outputs.
- **FR-014**: This phase MUST exclude migration of legacy structure/build systems and grouped build-confirm behavior.
- **FR-015**: Existing non-seed gameplay flows not explicitly changed by this phase MUST remain functionally unchanged.
- **FR-016**: Recipe resolution in this phase MUST evaluate only the Phase 1 seed recipe set; non-seed/legacy structure recipes MUST be treated as non-matching inputs.
- **FR-017**: User-facing craft feedback MUST emit one deterministic outcome key per attempt (`success`, `empty_input`, `no_matching_seed_recipe`, `locked_element`, `inventory_full`) and each non-success outcome MUST include a corrective guidance phrase.
- **FR-018**: Grouped build-confirm behavior MUST remain unchanged in this phase and MUST be covered by explicit regression validation.
- **FR-019**: At least one representative non-seed gameplay flow MUST be regression-validated as unchanged in this phase.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Feature MUST preserve the craft-to-place mental model direction while limiting this phase to seed crafting only.
- **EX-002**: Feature MUST provide clear, readable feedback for success, invalid recipe inputs, locked-element inputs, and inventory-capacity failures, where readability is validated by presence of an outcome-specific message and one actionable corrective hint for non-success outcomes.
- **EX-003**: On mobile, each interactive 3x3 grid slot touch target MUST be at least 48x48 px.
- **EX-004**: Craft outcome resolution MUST remain deterministic: identical grid inputs and unlock state produce identical results.

### Key Entities *(include if feature involves data)*

- **Craft Grid Input**: A 3x3 set of up to nine slot values where each slot is empty or contains one element token.
- **Seed Recipe Definition**: A mapping from valid one-token or two-token input sets to a single seed output item.
- **Craft Attempt Result**: Outcome record containing success/failure state, output item (if any), and user-visible feedback reason.
- **Plant Inventory Item**: Inventory entry representing a crafted seed that can be used in downstream planting flows.
- **Unlock State**: Player progression state controlling whether Ku token recipes are eligible.

### Assumptions

- Existing elemental token identities (`CHI`, `SUI`, `KA`, `FU`, `KU`) remain unchanged.
- Plant inventory remains the destination for crafted seed outputs in this phase.
- Existing unlock rules for Ku are already defined elsewhere and can be referenced by this feature.

### Out of Scope

- Structure recipe crafting, including house kits and multi-tile structures.
- Unified placement inventory migration for structures/builds.
- Migration or retirement of legacy structure inference, grouped build-confirm paths, or structure metadata flows.
- Changes to structure placement validation behaviors (footprints, occupancy checks, terrain-specific rules).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of defined single-token and dual-token Phase 1 seed mappings produce the expected output item across automated validation cases.
- **SC-002**: For at least 3 slot arrangements per dual-token recipe, crafting output remains identical, confirming position-insensitive matching.
- **SC-003**: 100% of invalid or out-of-scope craft attempts produce no output item and show user-facing corrective feedback.
- **SC-004**: In playtest validation, testers complete a seed craft from first interaction with an already-open crafting menu to seeing the item in plant inventory in 30 seconds or less on first attempt.
- **SC-005**: No structure/build migration behavior changes are observed in regression checks for this phase.
- **SC-006**: 100% of craft attempts emit the expected outcome key, and 100% of non-success outcomes include a corrective guidance phrase.

### SC-004 Test Protocol

- Run on desktop using mouse/keyboard in a fresh play session with no tutorial overlay active.
- Use the single-token `CHI` craft path as the first attempted craft in the session.
- Start timing at first interaction with an already-open crafting menu.
- Stop timing when the crafted seed is visible in plant inventory.
- Record pass/fail evidence for at least 5 testers.
