# Feature Specification: The Godai Sandbox Core (v6.0)

**Feature Branch**: `017-short-name-godai`  
**Created**: 2026-03-28  
**Status**: Draft  
**Input**: User description: "Implement the Godai Sandbox Core v6.0 loop with permanent placement, Kusho economy, spirit FSM, replenishment cycle, edge constraints, and audio/HUD resonance behavior."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Permanent Intent Sandbox Loop (Priority: P1)

As a player, I can spend element-specific Kusho to place seeds or blocks in a world where placements are permanent, so I stay in a creative flow without delete/undo anxiety and keep adapting to emergent outcomes.

**Why this priority**: This is the primary game loop and emotional design goal; without it, the Zen/anti-doom-scroll experience does not exist.

**Independent Test**: Validate with focused GUT coverage for resource spend, mode behavior, and no-delete invariants plus manual in-editor verification that no undo/delete input path exists and placements persist.

**Acceptance Scenarios**:

1. **Given** a player has at least 1 Kusho charge for an element, **When** the player confirms a placement in plant or build mode, **Then** exactly 1 charge of that element is consumed and the placement remains permanent.
2. **Given** a player attempts to remove or undo a prior seed/block placement, **When** they use available controls, **Then** the game offers no delete/undo action and existing placements remain unchanged.
3. **Given** an element counter is at 1/3 or 0/3, **When** the HUD updates, **Then** the corresponding icon visibly pulses at low charge and dims at depletion.

---

### User Story 2 - Living Garden Growth and Blueprint Confirmation (Priority: P1)

As a player, I can plant sprouts that bloom over time and discover build patterns on bloomed tiles, then intentionally finalize structures by striking a bell.

**Why this priority**: Growth pacing and explicit confirmation provide the core “Form is Emptiness” cadence of pause, observation, and commitment.

**Independent Test**: Validate with GUT tests for sprout lifecycle, spirit tending acceleration multiplier, blueprint overlap gating, and bell confirmation behavior; manually verify bell prompt and audiovisual feedback.

**Acceptance Scenarios**:

1. **Given** a newly planted seed, **When** no spirit assists it, **Then** it appears as a translucent sprout and auto-grows to a bloomed tile over time.
2. **Given** a spirit is tending a sprout, **When** growth time is measured, **Then** growth proceeds at 300% of baseline speed.
3. **Given** a valid recipe appears on fully bloomed tiles, **When** the player enters build intent, **Then** a bell confirmation affordance appears.
4. **Given** a proposed blueprint overlaps an existing structure, non-bloomed tile, incompatible biome, or invalid recipe, **When** the player attempts to strike the bell, **Then** confirmation is prevented and no Kusho is consumed.

---

### User Story 3 - Autonomous Spirits with Manual Harvest Rhythm (Priority: P1)

As a player, I experience spirits as autonomous helpers that build, tend, and replenish energy, while I must manually harvest stored gifts to restore actionable potential.

**Why this priority**: This creates the intended interaction rhythm between autonomous world activity and mindful player intervention.

**Independent Test**: Validate with GUT tests for spirit state transitions (BUILD, REPLENISH, TEND, WANDER, MEDITATING), repository capacity handling, and manual pickup transfer; manually verify spirit behavior in-editor.

**Acceptance Scenarios**:

1. **Given** a confirmed structure blueprint exists, **When** a spirit chooses its next task, **Then** BUILD is prioritized over lower-priority states.
2. **Given** a spirit carries a gift and a repository has capacity, **When** pathing succeeds, **Then** the spirit deposits the gift and repository stored energy increases.
3. **Given** a repository stores uncollected energy, **When** the player clicks the glowing/vibrating repository, **Then** stored charges transfer to the HUD counters and matching element icons flash/chime.
4. **Given** a repository is full at 3 uncollected charges, **When** another spirit arrives with a gift, **Then** that spirit waits nearby in a meditating state until space is cleared.

---

### User Story 4 - Resilience During Depletion and Path Failure (Priority: P2)

As a player, I can recover from full depletion and blocked logistics without hard failure, preserving a calm loop even when systems stall.

**Why this priority**: These safeguards prevent dead-end frustration while preserving intentional pauses.

**Independent Test**: Validate with GUT tests for deep-breath recovery timing and blocked-path fallback drop behavior; manually verify recovery after long idle simulation.

**Acceptance Scenarios**:

1. **Given** all five element counters are at 0 and no spirits carry gifts, **When** exactly 10 minutes elapse, **Then** the Shrine of Origin grants 1 charge to a random element and exits deep-breath waiting.
2. **Given** a spirit with a gift cannot path to any valid repository, **When** retry/path resolution fails, **Then** the spirit emits a cloudy indicator and drops a temporary pickup on the ground.

### Edge Cases

- Player attempts bell confirmation repeatedly while blueprint is invalid; confirmation remains blocked each attempt and no resource drains occur.
- Multiple sprouts finish bloom while one spirit is tending; spirit re-targets nearest unfinished sprout, and if none remain, transitions to WANDER.
- Player harvests from repository while spirits are queued in meditating state; queue clears in order as capacity becomes available.
- Deep-breath timer conditions are interrupted by any new incoming gift or restored charge; emergency regeneration does not trigger while recovery conditions are false.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST not provide any player-facing undo or delete capability for placed seeds, placed blocks, or confirmed structures.
- **FR-002**: The system MUST track five independent Kusho counters (Chi, Sui, Ka, Fu, Ku) with a maximum capacity of 3 charges each.
- **FR-003**: The HUD MUST show each element counter state and visually signal low charge at 1/3 and depletion at 0/3.
- **FR-004**: Plant mode MUST consume exactly 1 matching element charge per placed seed.
- **FR-005**: Newly planted seeds MUST enter a sprout phase represented as an unbloomed/translucent state before blooming.
- **FR-006**: Sprouts MUST bloom automatically over time without requiring direct player maintenance.
- **FR-007**: When a spirit tends a sprout, the sprout’s remaining growth progression MUST accelerate to 300% of baseline growth speed.
- **FR-008**: Build mode MUST reserve 1 matching element charge per placed building block intent and finalize consumption only on bell confirmation.
- **FR-009**: The system MUST surface a bell confirmation affordance when a valid pattern is present on bloomed tiles.
- **FR-010**: Bell confirmation MUST fail when any blueprint tile overlaps an existing structure, a non-bloomed tile, an incompatible biome, or an invalid recipe.
- **FR-011**: Spirit behavior MUST follow dynamic priority ordering: BUILD highest, then REPLENISH when carrying gift, then TEND nearby sprouts, else WANDER.
- **FR-012**: Spirits in TEND behavior MUST seek the next closest unfinished sprout upon completion and return to WANDER when no nearby sprout remains.
- **FR-013**: Spirits MUST generate gifts after sufficient time in their preferred biome and carry one gift at a time.
- **FR-014**: Spirits carrying gifts MUST attempt deposit at Shrine of Origin or a valid localized repository.
- **FR-015**: Repositories MUST visually indicate when they contain uncollected energy and allow player-initiated harvest interaction.
- **FR-016**: Harvest interaction MUST transfer stored charges from repository to corresponding HUD counters up to counter caps.
- **FR-017**: Repository storage MUST cap at 3 uncollected charges; spirits arriving when full MUST enter a meditating wait state nearby.
- **FR-018**: When all element counters are zero and no spirits carry gifts, the Shrine of Origin MUST enter deep-breath mode and restore exactly 1 random element charge after 10 minutes.
- **FR-019**: If a gift-carrying spirit cannot path to any repository, it MUST emit a cloudy indicator and drop a temporary ground pickup.
- **FR-020**: Bell confirmation MUST trigger a resonant sound event with a 5-second decay and this decay period MUST influence background procedural music pitch.
- **FR-021**: Repository harvest MUST trigger corresponding element HUD flash and a soft element-linked chime.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: The permanent-emergence rule set is non-negotiable in normal play; any debug overrides must remain inaccessible during standard gameplay.
- **EX-002**: Interactions required for core loop completion are limited to mode selection, placement intent, bell confirmation, and repository click harvest so the loop remains low-friction on pointer/touch input.
- **EX-003**: Spirit behavior updates and growth checks must support sustained play without visible stutter when multiple spirits, sprouts, and repositories are active concurrently.
- **EX-004**: Deep-breath recovery must be exact and deterministic from condition entry so intentional pause timing is predictable to players.

### Key Entities *(include if feature involves data)*

- **KushoCounter**: Per-element potential tracker with current charge, cap, HUD state (normal/low/depleted), and last-harvest feedback trigger.
- **SeedSproutTile**: Tile lifecycle entity with states (sprout, blooming, bloomed), growth progress, and tending acceleration state.
- **BlueprintIntent**: Pending structure confirmation record containing shape footprint, biome validity checks, bloom eligibility checks, and confirmation status.
- **SpiritWorker**: Autonomous actor with current FSM state, gift-carrying status, biome affinity, task target, and fallback response state.
- **RepositoryNode**: Deposit target with storage count, capacity, glow/vibration status, and harvest interaction surface.
- **GroundGiftPickup**: Temporary world pickup spawned from failed repository pathing that can later be collected or resolved by system rules.
- **DeepBreathCycle**: Shrine emergency recovery state holding condition start time, eligibility state, and random-element restoration result.
- **ResonanceEvent**: Timed audio influence event for bell decay affecting background music pitch and tied HUD chime reactions.

### Assumptions

- The Shrine of Origin remains fixed at grid coordinate (0,0) for this feature.
- “Nearby sprout” and “nearby repository” use current project pathing/proximity rules unless otherwise redefined later.
- Temporary ground gift pickups persist long enough for gameplay recovery and are considered valid replenishment opportunities.
- Repository harvest transfers only to the relevant element counters represented by stored energy type.

### Dependencies

- Existing spirit spawning and movement systems must expose state transitions required by the new priority logic.
- Existing pattern detection and structure validation systems must provide blueprint overlap and compatibility checks before confirmation.
- Existing procedural audio layer must accept temporary pitch influence from bell resonance events.
- Existing HUD icon system must support per-element flash/chime feedback and low/depleted visual states.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In playtests, 100% of placement actions remain present for the full session with no player-accessible delete/undo path.
- **SC-002**: At least 90% of players can complete one full loop (place → spirit activity → deposit → manual harvest → place again) within 8 minutes in a fresh session.
- **SC-003**: In controlled scenario tests, sprout completion time while tended is consistently 3× faster than untended baseline.
- **SC-004**: Bell confirmation is blocked with zero false-accepts across all overlap/invalidity edge scenarios defined in this spec.
- **SC-005**: Deep-breath recovery triggers exactly once at 10 minutes (±1 second) when depletion conditions are continuously true, and does not trigger when conditions are broken early.
- **SC-006**: During harvest interactions, corresponding element HUD feedback (flash + chime) is observed in 100% of successful repository pickups.
