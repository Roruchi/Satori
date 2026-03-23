# Feature Specification: Biome Alchemy — Mixing and Locking

**Feature Branch**: `004-biome-alchemy-mixing`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Biome alchemy mixing and locking system for hybrid biome creation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mix Two Unlocked Base Tiles to Create a Hybrid Biome (Priority: P1)

As a player, I want to long-press a different base tile type onto an existing unlocked base tile at the same coordinate, and see the correct hybrid biome replace both input tiles, so that I can intentionally craft the landscape I envision.

**Why this priority**: Alchemy is the primary creative mechanic that elevates the game beyond simple tile-painting. All 6 hybrid biomes, and many discoveries downstream, depend on this working correctly. It is the most impactful P1 feature after basic placement.

**Independent Test**: Place a Forest tile at `(1,0)`. Select Water. Long-press `(1,0)`. Confirm the tile at `(1,0)` is now a Swamp tile, is visually distinct from Forest and Water, shows a locked indicator, and rejects any further mixing attempt. Repeat for all 6 mixing pairs to confirm the full table.

**Acceptance Scenarios**:

1. **Given** an unlocked Forest tile at `(1,0)` and Water selected, **When** the player long-presses `(1,0)` past the threshold, **Then** the tile becomes a locked Swamp tile and the Forest tile no longer exists at that coordinate.
2. **Given** an unlocked Stone tile at `(2,0)` and Water selected, **When** the player mixes them, **Then** the result is a locked Tundra tile.
3. **Given** an unlocked Earth tile and Water selected, **When** mixed, **Then** the result is a locked Mudflat tile.
4. **Given** an unlocked Forest tile and Stone selected, **When** mixed, **Then** the result is a locked Mossy Crag tile.
5. **Given** an unlocked Forest tile and Earth selected, **When** mixed, **Then** the result is a locked Savannah tile.
6. **Given** an unlocked Stone tile and Earth selected, **When** mixed, **Then** the result is a locked Canyon tile.
7. **Given** the mixing succeeds, **When** the hybrid tile is created, **Then** it displays a differentiated visual effect (e.g. merge animation or shimmer) distinct from a normal placement animation.

---

### User Story 2 - Locked Tile Rejects Further Mixing (Priority: P1)

As a player, I want a clear, immediate signal when I try to mix into an already-locked tile, so that I understand the action is not permitted and I am not confused about why nothing happened.

**Why this priority**: The lock state is permanent and irreversible — the game has no undo. If a player unknowingly tries to mix a locked tile and receives no feedback, it will feel like a bug. This rejection feedback is essential to the "permanent choices" design philosophy.

**Independent Test**: Create a Swamp tile (Forest + Water) at `(1,0)` — it is now locked. Select any base tile type. Long-press `(1,0)`. Confirm the tile does NOT change, a distinct rejection feedback plays (visual flash, shake, or haptic), and the locked indicator remains visible.

**Acceptance Scenarios**:

1. **Given** a locked Swamp tile at `(1,0)` and Forest selected, **When** the player long-presses `(1,0)`, **Then** no change occurs to the tile, a rejection feedback animation plays within one frame, and the tile remains Swamp and locked.
2. **Given** a locked tile, **When** rejection feedback plays, **Then** the feedback is visually distinct from both a successful mix and a standard placement rejection — it communicates "this tile is complete" rather than "invalid location".

---

### User Story 3 - Full Catalogue: All 6 Combinations Valid, All Other Combinations Invalid (Priority: P3)

As a player, I want to be confident that only the 6 defined hybrid combinations exist, and that any attempt to produce an unlisted combination (including hybrid-on-hybrid or same-type mixing) is cleanly rejected, so that the game's tile taxonomy is coherent and trustworthy.

**Why this priority**: Catalogue completeness is a correctness guarantee, not a moment-to-moment player interaction. It is P3 because it is validated by the same test harness as the P1 mixing story; it only becomes a distinct priority if cataloguing hybrid combinations requires additional configuration work.

**Independent Test**: Run an automated test that attempts every possible biome-on-biome combination, including same-type (Forest+Forest), hybrid-on-base (Swamp+Stone), and hybrid-on-hybrid (Swamp+Canyon). Confirm that only the 6 valid pairs produce a hybrid result, and all others produce a defined rejection (not a crash or silent failure).

**Acceptance Scenarios**:

1. **Given** a Forest tile at `(1,0)` and Forest selected, **When** the player attempts to mix Forest onto Forest, **Then** the placement is rejected as same-type and no change occurs.
2. **Given** a locked Swamp tile at `(1,0)` and Stone selected, **When** the player attempts to mix Stone onto Swamp, **Then** the placement is rejected as locked-tile and no change occurs.
3. **Given** any unlocked base tile, **When** a base tile of the same type is placed on it, **Then** the rejection feedback specifically communicates "same type" or generic "invalid mix" — no hybrid is created.
4. **Given** the full 6-combination table, **When** each valid pair is tested in both orders (e.g. Forest+Water and Water+Forest), **Then** both orders produce the same hybrid result (commutative mixing).

---

### Edge Cases

- **Hybrid-on-base mixing attempt**: A player tries to place a base tile on top of an existing hybrid (e.g. Stone onto a Swamp tile). The Swamp tile is locked; this must be caught by the lock-state check (FR-004) and rejected before the mixing table is even consulted.
- **Same-type mixing**: Player places Forest on an unlocked Forest tile. This must be explicitly rejected by FR-005 (not silently ignored), with feedback explaining the issue — otherwise players may assume the game did not register their input.
- **Hybrid-on-hybrid**: Both tiles are locked; the lock-state check rejects the first tile immediately. The system must never attempt to look up "Swamp + Canyon" in the mixing table.
- **Mixing order (commutativity)**: Forest + Water and Water + Forest must both produce Swamp. The lookup must normalise the input pair (e.g. sort biome IDs) before consulting the table to avoid maintaining duplicate entries.
- **Rapid double-press on the same tile**: If a player taps a tile twice quickly before the first mix animation finishes, the second press must be buffered or ignored to prevent a race condition where the tile is mutated mid-animation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect when a player places a base tile onto an existing unlocked base tile of a different type at the same coordinate, distinguishing this from a standard adjacency placement.
- **FR-002**: System MUST replace the tile at that coordinate with the correct hybrid biome according to the following mixing table (commutative): Forest+Water=Swamp, Stone+Water=Tundra, Earth+Water=Mudflat, Forest+Stone=Mossy Crag, Forest+Earth=Savannah, Stone+Earth=Canyon.
- **FR-003**: System MUST mark the resulting hybrid tile as permanently locked immediately upon creation; the lock state cannot be reversed.
- **FR-004**: System MUST reject any mixing attempt targeting a tile whose lock state is `locked`, and emit a distinct rejection feedback response within one frame.
- **FR-005**: System MUST reject mixing a tile with the same biome type as itself (same-type placement onto an unlocked tile), with a feedback response indicating the action is invalid.
- **FR-006**: System MUST reject any biome combination not present in the 6-entry mixing table (e.g. hybrid + any tile type), routing the interaction to the lock-rejection path.
- **FR-007**: System MUST provide differentiated visual and haptic feedback for a successful mix (merge effect) versus a standard tile placement versus a rejected mix attempt — the three outcomes must be distinguishable by a player without reading any text.
- **FR-008**: Locked tiles MUST display a persistent visual indicator (e.g. a glyph, border treatment, or colour shift) that is legible at all supported zoom levels on mobile screen sizes.

### Key Entities

- **AlchemyResult**: A lookup entry in the mixing table. Attributes: `biome_a` (enum), `biome_b` (enum), `result_biome` (enum). The table is commutative — lookup must normalise input order. There are exactly 6 valid entries.
- **TileLockState**: An enum value on `TileData`. Two values: `UNLOCKED` (base tile eligible for mixing) and `LOCKED` (hybrid tile — immutable). The transition from `UNLOCKED` to `LOCKED` is one-way and fires immediately when a successful mix is resolved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 6 hybrid combinations produce the correct biome with zero incorrect results across a 100-mix automated test covering both orders of each pair (200 total operations).
- **SC-002**: A newly created hybrid tile is visually distinct from its pre-mix state within the same frame the mix resolves — the old tile type is never rendered after the mix completes.
- **SC-003**: Attempting to mix a locked tile triggers a clear, unambiguous rejection feedback response within one frame, confirmed across 50 consecutive attempts in an automated test.
- **SC-004**: No mixing action in any automated test produces a tile type outside the 6-hybrid catalogue; the system either produces a known hybrid or rejects the action — never produces `null`, an engine error, or an undefined biome type.
