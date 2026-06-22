# Feature Specification: Ritual Menu and Slot-Based Creation

**Feature Branch**: `022-ritual-menu-slots`
**Created**: 2026-06-22
**Status**: Draft
**Input**: User description: "Replace the crafting grid with a ritual menu / slots, using the new master plan and recipes. Ritual slots must never allow duplicates."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Perform Simple Rituals (Priority: P1)

As a player, I want to combine a small number of meaningful ritual inputs in clear slots so I can discover seeds and early forms without understanding a 3x3 crafting grid.

**Why this priority**: The new direction depends on rituals replacing grid recipes. Without this, materials, Warm Hollow, placement context and later spirit assistants have no player-facing home.

**Independent Test**: Can be validated with GUT coverage for order-insensitive ritual resolution and manual in-editor verification of the ritual menu. The story is complete when a player can create a Meadow Seed with Wind Essence and Warm Hollow with Living Wood + Fire Essence from the new menu.

**Acceptance Scenarios**:

1. **Given** the player opens the ritual menu, **When** they select Wind Essence and confirm, **Then** the game creates a Meadow Seed using the same inventory pathway as current seed creation.
2. **Given** the player has Living Wood and Fire Essence, **When** they place both in unique ritual slots and confirm, **Then** Warm Hollow is discovered and added as a placeable form.
3. **Given** the player changes input order, **When** they confirm the same unique input set, **Then** the same ritual result is produced.
4. **Given** an input has already been placed in a slot, **When** the player tries to place the same input identity again, **Then** the UI blocks the duplicate before confirm.

---

### User Story 2 - Replace Crafting Grid Language (Priority: P2)

As a player, I want the creation UI and feedback to talk about rituals, forms and intent instead of grid crafting so the game language matches the Codex and master plan.

**Why this priority**: The previous grid UI teaches positional recipe thinking. The new game direction teaches material meaning, elemental intent and context.

**Independent Test**: Can be validated through manual HUD and panel review plus string-level checks for removed player-facing "craft grid" copy in the affected UI.

**Acceptance Scenarios**:

1. **Given** the player opens the former Mix/Craft surface, **When** the panel appears, **Then** it shows up to three ritual slots rather than nine grid cells.
2. **Given** a ritual cannot resolve, **When** feedback is shown, **Then** it gives a ritual-style reason or hint rather than saying "No matching grid recipe."
3. **Given** a seed ritual succeeds, **When** feedback is shown, **Then** it says the seed or form was shaped/discovered and does not use shop or grid language.

---

### User Story 3 - Place Ritual Forms by Context (Priority: P3)

As a player, I want a ritual-created form to become its final role when placed so that Warm Hollow can become Meadow Dwelling on Meadow or a different form in Fire context.

**Why this priority**: The master plan's key consistency decision is that rituals create forms while placement and context give those forms their final role.

**Independent Test**: Can be validated with GUT coverage for placement context resolution and manual in-editor checks for Warm Hollow placement on Meadow and Hearth/Fire biomes.

**Acceptance Scenarios**:

1. **Given** Warm Hollow is in the place inventory, **When** it is placed on a Meadow tile, **Then** the placed structure records or displays Meadow Dwelling and can house Meadow-preferred spirits.
2. **Given** Warm Hollow is placed on a Fire/Hearth biome, **When** placement resolves, **Then** the placed structure becomes Scorched Hollow or the documented Fire-context variant.
3. **Given** a placement target has no valid tile, **When** the player previews placement, **Then** the form cannot be confirmed and no inventory is consumed.

### Edge Cases

- Duplicate inputs of any type are blocked: duplicate essence, duplicate material, duplicate component and duplicate spirit assistant.
- If a duplicate somehow reaches the resolver through debug or save data, the ritual attempt fails non-destructively.
- If the place inventory is full, a successful ritual result is not committed and inputs are not consumed.
- If Ku is locked, Ku inputs remain unavailable in the menu and Ku rituals return a locked feedback state.
- Existing duplicate-token building recipes remain migration inputs only; they must not become valid rituals.
- Duplicate-token building recipes must not be removed from the playable flow until their no-duplicate ritual replacement can create a valid housing path.
- Legacy save data with grid state may be ignored or migrated to an empty ritual state; it must not crash load.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide a player-facing ritual menu with up to three input slots.
- **FR-002**: The ritual menu MUST replace the current 9-slot crafting-grid presentation for seed and structure creation.
- **FR-003**: The ritual resolver MUST treat inputs as order-insensitive.
- **FR-004**: The ritual resolver MUST require every input identity in one ritual to be unique.
- **FR-005**: The UI MUST prevent duplicate input identities before confirmation.
- **FR-006**: The resolver MUST reject duplicate input identities non-destructively if duplicates are submitted through non-UI paths.
- **FR-007**: A valid ritual MUST include at least one essence.
- **FR-008**: One-essence rituals MUST continue to create basic biome seeds.
- **FR-009**: Two-essence rituals MUST continue to create hybrid biome seeds when both elements are unlocked.
- **FR-010**: Living Wood + Fire Essence MUST discover Warm Hollow, not Fox Den or Meadow Dwelling directly.
- **FR-011**: Warm Hollow placement on Meadow MUST resolve to Meadow Dwelling.
- **FR-012**: Warm Hollow placement on Fire/Hearth context MUST resolve to Scorched Hollow or an equivalent Fire-context shelter variant.
- **FR-013**: Ritual success MUST consume only the inputs required by the resolved result and MUST only consume them after output insertion succeeds.
- **FR-014**: Ritual failure MUST preserve inputs, inventory and discovery state.
- **FR-015**: Player-facing copy in the affected menu MUST use ritual, form, seed, essence and material language instead of crafting-grid language.
- **FR-016**: The implementation MUST keep `specs/master/recipes.md` synchronized if any unlock ID, display name or recipe mapping changes during implementation.
- **FR-017**: The feature MUST preserve a playable first-session path for seed creation, spirit invitation and spirit housing during migration.
- **FR-018**: The implementation MUST NOT retire an existing house-building path until Warm Hollow -> Meadow Dwelling or an explicit no-duplicate compatibility recipe can replace it.
- **FR-019**: The feature MUST keep existing spirit discovery triggers reachable unless a replacement trigger is implemented in the same change.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: The menu MUST remain usable on mobile and show all available ritual slots without horizontal scrolling.
- **EX-002**: The feature MUST preserve deterministic discovery and no-undo world rules.
- **EX-003**: Ritual preview and confirmation MUST stay responsive within the current 60 fps interaction budget.
- **EX-004**: Accessibility settings for contrast and readable text MUST remain effective for ritual slot labels and feedback.

### Key Entities *(include if feature involves data)*

- **RitualSlot**: One of up to three ritual inputs, containing one essence, material, component or spirit assistant identity.
- **RitualInputIdentity**: Canonical key used to enforce no duplicates across all slot types.
- **RitualAttempt**: Snapshot of selected slots, unlock state, inventory capacity and placement or spirit context if available.
- **RitualRecipeDefinition**: Data-driven mapping from unique input identities plus optional context to a result.
- **RitualResult**: Seed, form, component, hint, memory or blocked state produced by a ritual attempt.
- **RitualFormPlacementRule**: Context rule that turns a placeable form such as Warm Hollow into a final placed structure such as Meadow Dwelling.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of ritual resolver tests reject duplicate inputs without consuming resources.
- **SC-002**: A fresh player can create Meadow Seed and Warm Hollow from the ritual menu without using the old 9-slot grid.
- **SC-003**: Warm Hollow placed on Meadow resolves to Meadow Dwelling in automated or debug-harness validation.
- **SC-004**: Warm Hollow placed on Fire/Hearth context resolves to the documented Fire-context variant in automated or debug-harness validation.
- **SC-005**: No current duplicate-token building recipe is accepted as a valid ritual after this feature lands.
- **SC-006**: After this feature lands, a fresh playtest can still create Meadow, invite at least one Meadow spirit and place a valid spirit house through either the new ritual path or a documented temporary compatibility path.
