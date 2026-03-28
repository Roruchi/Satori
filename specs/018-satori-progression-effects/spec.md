# Feature Specification: Satori Progression & Architectural Effects

**Feature Branch**: `018-satori-progression-effects`  
**Created**: 2026-03-28  
**Status**: Draft  
**Input**: User description: "RFC: Satori Progression & Architectural Effects (v1.0)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Balance Spirit Housing to Maintain Positive Growth (Priority: P1)

As a player, I need the Satori meter to increase from housed spirits and decrease from unhoused spirits so that expansion without infrastructure has meaningful consequences.

**Why this priority**: This is the core progression loop; all later unlocking and structure value depend on this economic pressure.

**Independent Test**: Validate with GUT coverage of per-minute Satori delta, floor/ceiling clamps, and housed/unhoused combinations; manually verify in-editor meter updates over multiple ticks.

**Acceptance Scenarios**:

1. **Given** current Satori is 100 with 6 housed and 2 unhoused spirits, **When** one minute passes, **Then** Satori changes by +2 (6 - 4) and becomes 102.
2. **Given** current Satori is 3 with 0 housed and 2 unhoused spirits, **When** one minute passes, **Then** Satori is clamped to 0 and never becomes negative.
3. **Given** current Satori is 248 and current cap is 250 with positive net generation, **When** one minute passes, **Then** Satori is clamped to 250 and does not exceed cap.

---

### User Story 2 - Expand Capacity Through Structures (Priority: P1)

As a player, I need structures to increase Satori cap by tier-specific amounts so I can continue progressing into higher Eras.

**Why this priority**: Without cap growth, the progression loop stalls and Era gating cannot be reached.

**Independent Test**: Validate with GUT coverage of cap increases for Tier 1 (+50), Tier 2 (+250), and Tier 3 (+1000), including cumulative effects from multiple allowed structures.

**Acceptance Scenarios**:

1. **Given** a new game with cap 250, **When** the player manifests one Tier 1 dwelling, **Then** cap becomes 300.
2. **Given** existing cap and structures, **When** the player manifests a Tier 2 resonance pavilion, **Then** cap increases by 250 from the previous value.
3. **Given** a game with no monument yet, **When** the player manifests a Tier 3 monument, **Then** cap increases by 1000 and monument uniqueness rules activate.

---

### User Story 3 - Unlock and Lose Era-Based Progression Gates (Priority: P2)

As a player, I need Era thresholds tied to Satori so that higher-tier spirit opportunities unlock when harmony is maintained and close when harmony drops.

**Why this priority**: Era gating defines mid/late-game pacing and creates risk for over-expansion.

**Independent Test**: Validate with GUT coverage of threshold crossings and fallback behavior; manually verify era-dependent UI/gameplay indicators react to changes.

**Acceptance Scenarios**:

1. **Given** Satori rises from 499 to 500, **When** the value updates, **Then** Era changes from Stillness to Awakening and Lesser Kami gate opens.
2. **Given** Satori drops from 1510 to 1490, **When** the value updates, **Then** Era changes from Flow to Awakening and Major Kami gate closes.
3. **Given** Satori reaches 5000 or higher, **When** the value updates, **Then** Era changes to Satori and the prestige-era trigger conditions are met.

---

### User Story 4 - Receive Tier-Specific Structure Effects and Monument Uniqueness Enforcement (Priority: P2)

As a player, I need each structure to apply its cataloged effect and unique monuments to be build-once so architecture decisions remain strategic and meaningful.

**Why this priority**: Structure identity and uniqueness are central to the RFC theme of mindful expansion.

**Independent Test**: Validate with GUT coverage of each structure effect and uniqueness checks; manually verify blocked unique builds are clearly indicated and cannot be confirmed.

**Acceptance Scenarios**:

1. **Given** a monument marked unique already exists, **When** the player completes a matching monument blueprint again, **Then** confirmation is blocked and the placement attempt fails/dissolves as defined.
2. **Given** a guidance lantern is active locally, **When** up to 3 unhoused spirits are in range, **Then** their per-minute penalty is reduced to -1 each.
3. **Given** a pagoda of the five exists, **When** passive generation is evaluated each minute, **Then** it contributes +5 Satori per minute and can house up to 4 spirits of any type.

---

### Edge Cases

- Multiple cap-changing structures are created or removed in short succession; cap and current Satori remain consistent and correctly clamped after each change.
- Era thresholds are crossed multiple times in either direction during consecutive minute ticks; era change notifications fire only when the era value actually changes.
- Restless spirit penalties would reduce Satori below zero while monument bonus generation also applies in the same tick; final Satori is deterministic and clamped.
- Monument instant grant (+500) is attempted when current Satori is near cap; only up to cap is applied.
- Unique monument blueprint is valid in shape but rejected due to existing instance; rejection feedback is visible before final confirmation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST maintain a global integer Satori value for the current game state.
- **FR-002**: System MUST start new games with a Satori cap of 250.
- **FR-003**: System MUST apply per-minute Satori generation of +1 for each housed spirit.
- **FR-004**: System MUST apply per-minute Satori penalty of -2 for each unhoused spirit, before local modifiers are applied.
- **FR-005**: System MUST process Satori change on a 60-second cadence using net delta from housed and unhoused spirit counts.
- **FR-006**: System MUST clamp Satori to a minimum of 0.
- **FR-007**: System MUST clamp Satori to the current Satori cap maximum.
- **FR-008**: System MUST increase Satori cap by +50 for each Tier 1 dwelling created.
- **FR-009**: System MUST increase Satori cap by +250 for each Tier 2 resonance pavilion created.
- **FR-010**: System MUST increase Satori cap by +1000 for each Tier 3 monument created.
- **FR-011**: System MUST classify Satori into Eras using these ranges: Stillness (0-499), Awakening (500-1499), Flow (1500-4999), Satori (5000+).
- **FR-012**: System MUST evaluate era transitions whenever Satori changes and emit an era-changed event only when the era value changes.
- **FR-013**: System MUST open or close Kami spawn gates based on whether current Satori is at or above the relevant era threshold.
- **FR-014**: System MUST treat dropping below an era threshold as immediate loss of that era’s Kami gate access.
- **FR-015**: System MUST support all Tier 1 dwellings from the catalog, each housing exactly one qualifying spirit and contributing the Tier 1 cap increase.
- **FR-016**: System MUST support all Tier 2 structures from the catalog with their defined effects (storage increase, island movement speed increase, secondary drop-off behavior, tending boost improvement, and localized penalty pacification).
- **FR-017**: System MUST support all Tier 3 monuments from the catalog with their defined effects (instant Satori grant, passive generation and universal housing, island generation multiplier).
- **FR-018**: System MUST mark monument definitions with a uniqueness property that enforces maximum one instance per game for each unique monument definition.
- **FR-019**: System MUST prevent confirmation of a unique structure pattern when an instance of that structure already exists.
- **FR-020**: System MUST provide clear pre-confirmation rejection feedback for blocked unique monument attempts.
- **FR-021**: System MUST apply Great Torii instant +500 Satori grant only up to current cap.
- **FR-022**: System MUST apply Pagoda of the Five passive +5 Satori per minute regardless of housed spirit count, while respecting global cap clamping.
- **FR-023**: System MUST apply Void Mirror island multiplier to housed-spirit Satori generation on its island.
- **FR-024**: System MUST preserve baseline game behavior for non-progression systems not described by this RFC.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Feature MUST preserve the permanent-emergence rule set, with no debug-only bypass in standard gameplay flow.
- **EX-002**: Feature MUST expose progression and gate changes in a way that is understandable without requiring hidden developer diagnostics.
- **EX-003**: Feature MUST keep minute-tick progression deterministic so repeated runs with the same state produce the same Satori outcomes.
- **EX-004**: Feature MUST keep progression-state transitions responsive enough that players can perceive era and cap updates immediately after relevant events.

### Key Entities *(include if feature involves data)*

- **Satori State**: Global progression state containing current Satori, current cap, and derived current era.
- **Spirit Housing State**: Per-spirit housed/unhoused status and local context used to compute generation and penalties.
- **Era Definition**: Named progression band with minimum/maximum threshold and associated gate/unlock behavior.
- **Structure Definition**: Buildable catalog entry with tier, recipe/shape identity, cap contribution, unique flag, and effect definition.
- **Structure Instance**: In-world manifested structure record used for uniqueness checks and active effect application.
- **Kami Gate State**: Availability state for Lesser and Major Kami spawn eligibility tied to current era.

### Assumptions

- Existing spirit and biome pattern systems remain the authority for validating pattern shape and biome eligibility.
- Existing game events and UI channels are used for communicating progression changes unless replaced by equivalent user-visible behavior.
- Tier 3 uniqueness applies per monument definition (one of each unique monument), not a single total monument across all Tier 3 entries.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation runs, Satori minute-tick outcomes exactly match expected results for at least 20 distinct housed/unhoused/cap scenarios including floor and ceiling boundaries.
- **SC-002**: Era transitions are detected correctly at all six boundary crossings (upward and downward at 500, 1500, and 5000) with 100% correct gate state updates.
- **SC-003**: Each listed structure effect in the RFC is demonstrably active in at least one acceptance test scenario, with expected quantitative impact.
- **SC-004**: Attempting to build a second instance of any unique monument is blocked in 100% of attempts and provides visible rejection feedback.
- **SC-005**: Players can progress from base cap (250) to at least Era III thresholds through structure-driven cap growth and spirit management without manual debugging controls.
