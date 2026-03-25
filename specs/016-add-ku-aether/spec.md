# Feature Specification: Mixable Ku Recipes

**Feature Branch**: `[016-add-ku-aether]`  
**Created**: 2026-03-25  
**Status**: Draft  
**Input**: User description: "allow mixable ku recipes. Please add combinations for ku using the godai philosophy as ku being heavenly/spirtual/occult. or https://en.wikipedia.org/wiki/Aether_(classical_element) This should grant 4 new tiles (since ku cant be mixed by itself.) These 4 new tiles grant new spirits, new structures and new biomes. Ku being the heavenly/element and aether these spirits are not simply animals but may bring about (japanese) deities. and fantasy biomes and places of worship. There should be a hint to unlock the ku element in the codex."

## Clarifications

### Session 2026-03-25

- Q: Which progression event should unlock Ku for this feature? → A: Keep current Ku unlock trigger: summoning Mist Stag (existing spirit gift path), with codex hints pointing players toward this path.
- Q: What content scope should be required for Ku-linked spirits/deities and structures? → A: Balanced scope: 4 new Ku biomes, 4 new spirits/deities (one per Ku biome), and 4 new structures (one per Ku biome).
- Q: Should this feature add new persistence guarantees for Ku unlock/discovery state? → A: Keep current behavior unchanged; no new persistence guarantees are added by this feature.
- Q: Should Ku deity content use direct real-world Shinto deity references or only inspired originals? → A: Use direct real-world Shinto deity names and lore references for the 4 Ku spirits/deities.
- Q: How explicit should codex hints be for Ku unlock progression? → A: Guided in-world hint that names Mist Stag and indicates discovery direction without exact numeric thresholds.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently

  For this project, every story's Independent Test should name the validation
  path: GUT coverage, manual in-editor verification, debug-harness flow, or the
  combination required to prove the story is complete.
-->

### User Story 1 - Unlock and Mix Ku Pairings (Priority: P1)

As a player, I want to unlock Ku and mix it with each base element so I can craft new heavenly seeds instead of seeing Ku as unusable.

**Why this priority**: The feature's core value is making Ku meaningfully playable. Without mixable Ku pairings, the rest of the content cannot be reached.

**Independent Test**: Can be fully tested by following the Ku unlock flow, opening Mix mode, and crafting all four Ku pair seeds via manual in-editor verification and debug-harness checks.

**Acceptance Scenarios**:

1. **Given** Ku is locked, **When** the player summons Mist Stag through normal progression, **Then** Ku becomes selectable in Mix mode immediately.
2. **Given** Ku is unlocked, **When** the player mixes Ku with Chi, Sui, Ka, or Fu, **Then** each pairing previews a valid craft result and can be added to the pouch.
3. **Given** Ku is unlocked, **When** the player attempts to mix Ku by itself, **Then** crafting remains unavailable and clear feedback is shown.

---

### User Story 2 - Discover Aether-Themed World Content (Priority: P2)

As a player, I want each Ku pairing to lead to distinct spiritual world outcomes so Ku feels like a heavenly/aether progression tier with deities, sacred places, and fantasy biomes.

**Why this priority**: New Ku recipes should produce meaningful exploration goals, not only color-swapped tiles.

**Independent Test**: Can be tested by crafting and blooming each Ku pairing outcome, then verifying each new outcome has associated biome identity, exactly one discoverable spirit/deity per Ku biome, and exactly one discoverable structure/place-of-worship per Ku biome.

**Acceptance Scenarios**:

1. **Given** the player blooms each Ku pairing result at least once, **When** discoveries are evaluated, **Then** four distinct Ku-aligned biome outcomes are discoverable.
2. **Given** each Ku biome is discovered, **When** the player continues pattern-driven exploration, **Then** new Ku-themed spirits/deities using direct Shinto deity references become summonable and codex-visible.
3. **Given** Ku-themed spirits/deities are discovered, **When** related landmarks are formed, **Then** new spiritual structure discoveries become available.

---

### User Story 3 - Codex Guidance for Ku Progression (Priority: P3)

As a player, I want the Codex to hint how Ku is unlocked so I can progress without external guides.

**Why this priority**: Progression clarity prevents confusion where players unlock Ku once but cannot reproduce the unlock in later runs.

**Independent Test**: Can be tested by starting from a fresh profile, checking codex guidance before Ku unlock, then confirming the hint updates once Ku and Ku outcomes are discovered.

**Acceptance Scenarios**:

1. **Given** Ku is still locked, **When** the player opens relevant codex entries, **Then** they see a guided in-world hint that names Mist Stag and points to the required discovery direction without exact numeric thresholds.
2. **Given** Ku has been unlocked, **When** the player revisits codex entries, **Then** the hint is replaced or supplemented by discovered-state information.

---

### Edge Cases

- Player unlocks Ku, leaves/reloads, and expects behavior to remain consistent with current save/load systems (no new persistence guarantees introduced by this feature).
- Player attempts invalid Ku mixes (duplicate element, third element, or solo Ku) and must receive consistent non-destructive feedback.
- Player discovers Ku biome outcomes before associated spirit/deity or structure content and codex must still present coherent progression breadcrumbs.
- Multiple unlock triggers fire in one session and Ku unlock should not duplicate rewards or break discovery state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST keep Ku unavailable by default and only make it selectable after the player summons Mist Stag through the existing spirit gift path.
- **FR-002**: System MUST provide exactly four valid Ku pairing recipes: Ku+Chi, Ku+Sui, Ku+Ka, and Ku+Fu.
- **FR-003**: System MUST reject solo Ku crafting attempts and any Ku combination outside the four defined pairings.
- **FR-004**: System MUST let each Ku pairing produce a distinct biome outcome with unique player-facing identity.
- **FR-005**: System MUST introduce exactly 4 new Ku-themed spirits/deities, mapped one-to-one with the 4 new Ku biomes.
- **FR-006**: System MUST introduce exactly 4 new Ku-themed structures or places of worship, mapped one-to-one with the 4 new Ku biomes.
- **FR-007**: System MUST define the 4 Ku spirits/deities using direct Shinto deity names and lore references in player-facing content.
- **FR-008**: System MUST expose codex entries for Ku unlock guidance before Ku is unlocked, explicitly naming Mist Stag and the required discovery direction.
- **FR-009**: System MUST update codex presentation after Ku unlock so players can distinguish hinted vs discovered Ku progression.
- **FR-010**: System MUST ensure recipe preview, craftability feedback, and discovery updates remain consistent across all four Ku pairings.
- **FR-011**: System MUST avoid granting duplicate progression rewards when Ku unlock or Ku-linked discoveries are triggered more than once.
- **FR-012**: System MUST preserve compatibility with existing non-Ku recipes and discovery progression.
- **FR-013**: System MUST define player-facing naming and flavor text for each Ku biome, spirit/deity, and structure in a coherent aether-heavenly tone.
- **FR-014**: System MUST keep Ku progression discoverable through play and codex hints without requiring external documentation.
- **FR-015**: System MUST not introduce new save/load persistence behavior for Ku unlock or Ku-linked discovery state as part of this feature.
- **FR-016**: System MUST present direct Shinto deity references respectfully and consistently across naming, flavor text, and codex descriptions.
- **FR-017**: System MUST keep Ku codex guidance non-checklist in style by avoiding exact numeric requirement thresholds in pre-unlock hints.

### Experience & Runtime Constraints *(mandatory when applicable)*

- **EX-001**: Feature MUST preserve the permanent-emergence rule set, or justify
  any debug-only exception explicitly.
- **EX-002**: Feature MUST state any impact on mobile input, thumb-zone UI, or
  accessibility settings when player interaction changes.
- **EX-003**: Feature MUST state performance, scan-time, startup, or save/load
  expectations when the feature touches runtime-critical systems.

- **EX-004**: Feature MUST keep mix interaction parity with existing element mixing (same tap-count expectations and no extra mandatory UI steps).
- **EX-005**: Feature MUST keep discovery scanning behavior within existing play-session responsiveness expectations.

### Key Entities *(include if feature involves data)*

- **Ku Pairing Recipe**: A two-element recipe where one element is Ku and the other is one base element; includes unlock visibility, preview name, and resulting biome.
- **Ku Biome Outcome**: A heavenly/aether-themed biome generated by a Ku pairing; includes display name, codex flavor, and links to related discoveries.
- **Ku Spirit/Deity Discovery**: A summonable spiritual entity tied to one or more Ku biomes; includes codex text, unlock conditions, and thematic alignment.
- **Ku Structure Discovery**: A landmark or place-of-worship discovery tied to Ku biomes and/or Ku spirits; includes discovery trigger and codex presentation.
- **Ku Codex Hint Entry**: Player-facing hint content that explains the Ku unlock direction before completion and transitions to discovered-state guidance after completion.

## Assumptions

- Ku remains a non-solo element and always requires one partner element.
- Existing four base elements and current non-Ku recipes remain available and unchanged in player-facing behavior.
- Existing discovery pipelines can be extended with new themed content without replacing prior spirit or structure content.
- The codex is the primary in-game surface for progression hints.

## Dependencies

- Existing Mist Stag summon progression and its Ku unlock gift path remain available and can trigger codex state transitions.
- Existing recipe discovery and biome discovery systems support adding four new outcomes.
- Existing spirit/deity and structure discovery pipelines support adding Ku-linked content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In feature validation runs, players can craft all four Ku pairing outcomes after Ku unlock with a 100% successful recipe preview-to-craft match rate.
- **SC-002**: In feature validation runs, 100% of Ku pairing outcomes map to four distinct biome entries with non-overlapping player-facing names and descriptions.
- **SC-003**: In first-time playtest checks, at least 80% of players identify the Ku unlock path using only codex hints and in-game feedback.
- **SC-004**: In content validation, the feature provides exactly 4 new Ku-themed spirits/deities and exactly 4 new Ku-themed structures, with one spirit/deity and one structure mapped to each Ku biome.
- **SC-005**: Invalid Ku crafting attempts (solo Ku or undefined Ku combinations) are rejected in 100% of test cases with clear player feedback and no progression loss.
