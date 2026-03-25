# Feature Specification: Living Garden — Satori v2 Core Loop

**Feature Branch**: `015-living-garden`
**Created**: 2026-03-24
**Status**: Draft
**Input**: Design session — "make the game something players return to daily for 10 minutes instead of doom scrolling; like watching a painting slowly becoming alive"

---

## Overview

This specification redesigns Satori's core gameplay loop from real-time tile placement into a **living garden** ritual. Five changes work together as a unified system:

1. **Tiles become seeds** — you plant and wait; the garden grows in your absence
2. **Biome mixing becomes seed alchemy** — a dedicated mixing UI replaces long-press grid interaction, built on the Japanese Godai elemental system
3. **Bloom is a deliberate act** — grown seeds must be tapped to reveal; you witness every transformation
4. **Spirits tend the garden** — they are drawn to habitats they love and teach you recipes you cannot discover alone
5. **The Codex is your field guide** — a living journal of everything the garden has revealed so far

The goal: a 3-minute session feels complete. The garden is always doing something when you are not looking. Returning is an act of discovery, not obligation.

---

## Clarifications

### Session 2026-03-24

- Q: Are Godai elements (Chi, Sui, Ka, Fū) a free/unlimited resource or something the player acquires? → A: Free/unlimited — elements are always available in the mixing UI at no cost; scarcity comes from growing slots and time, not element supply.
- Design change: Tile Vitality & Dormancy removed from this version. The mechanic where tiles decay to Dormant without spirit visits is deferred to a future spec. Spirits still wander toward preferred habitats; they no longer serve a vitality-restoration function in this release.
- Q: Should the system protect against device clock manipulation to prevent instant seed maturation? → A: No protection — the device clock is trusted unconditionally; clock manipulation is the player's own concern in a single-player offline game.
- Q: Which spirits receive habitat profiles (preferred biomes, harmony/tension, gift type) in this release? → A: Obvious subset only — the ~10 most ecologically distinct spirits are profiled; the remaining 20 retain random wander and receive profiles in a future update.
- Q: What triggers the first Satori Moment? → A: All four base biomes (Stone, River, Ember Field, Meadow) present in the garden AND at least three spirits summoned.
- Q: How is the Codex (and Mixing UI) accessed from the garden? → A: Minimalist HUD navigation bar with three mode buttons — Plant, Mix, Codex — always visible; tapping switches the active panel without a scene transition.

---

## Godai Element & Seed Recipe Reference

All seed creation flows through the five Japanese classical elements (五大, *Godai*).

### Elements

| Element | Kanji | Reading | Quality | Locked? |
|---|---|---|---|---|
| Earth | 地 | Chi | Solidity, stillness, foundation | No |
| Water | 水 | Sui | Flow, adaptability, depth | No |
| Fire | 火 | Ka | Transformation, energy, will | No |
| Wind | 風 | Fū | Freedom, change, breath | No |
| Void | 空 | Kū | Consciousness, spirit, the formless | Yes — spirit-unlocked |

### Tier 1 Seeds — Single Element

| Element | Biome Produced |
|---|---|
| Chi | Stone |
| Sui | River |
| Ka | Ember Field |
| Fū | Meadow |
| Kū | *(spirit-unlocked only — no single-element Kū seed)* |

### Tier 2 Seeds — Two Elements

| Elements | Biome Produced |
|---|---|
| Chi + Sui | Clay |
| Chi + Ka | Desert |
| Chi + Fū | Dune |
| Sui + Ka | Hot Spring |
| Sui + Fū | Bog |
| Ka + Fū | Cinder Heath |
| Chi + Kū | Sacred Stone |
| Sui + Kū | Veil Marsh |
| Ka + Kū | Ember Shrine |
| Fū + Kū | Cloud Ridge |

### Tier 3 Seeds — Three Elements (Spirit-Taught, examples)

| Elements | Biome Produced | Taught By |
|---|---|---|
| Chi + Sui + Ka | Obsidian Shore | Stone Serpent |
| Sui + Fū + Kū | Mist Valley | Mist Stag |
| Ka + Fū + Kū | Wildfire Veil | Ember Fox |
| Chi + Fū + Kū | Ancient Crag | Mountain Golem |
| Chi + Sui + Fū | Mossy Delta | River Otter |
| Ka + Sui + Chi | Ash Flat | Sun-Lizard |

*Full Tier 3 catalogue defined per-spirit in the spirit data resources.*

### Growth Duration by Tier (Real-Time Mode)

| Seed Tier | Duration |
|---|---|
| Tier 1 — single element | 10 minutes |
| Tier 2 — two elements | 30 minutes |
| Tier 3 — three elements | 2 hours |
| Wild Seed — gifted by spirit | 1 hour |

---

## User Scenarios & Testing *(mandatory)*

---

### User Story 1 — Seed Alchemy: Mixing UI (Priority: P1)

The player creates seeds through a dedicated mixing UI rather than by interacting directly with placed tiles. They combine Godai elements (1–3) to produce a specific seed type which is added to their seed pouch.

**Why this priority**: This replaces the existing long-press mixing interaction entirely. Without the mixing UI the game has no way to create seeds and the entire loop is broken.

**Independent Test**: Open the mixing UI. Place Chi in slot 1, Sui in slot 2. Confirm the preview shows "Clay Seed." Tap confirm. Verify a Clay seed appears in the pouch and the Codex Seeds section marks the Chi+Sui recipe as discovered.

**Acceptance Scenarios**:

1. **Given** the player opens the mixing UI, **When** they tap Chi, **Then** Chi occupies slot 1 and the UI previews all valid single and multi-element combinations that include Chi.
2. **Given** Chi is in slot 1 and Sui is tapped, **When** both elements are loaded, **Then** the preview shows "Clay Seed" and a confirm button becomes active.
3. **Given** the player confirms a Chi+Sui combination, **When** the seed is produced, **Then** a Clay seed is added to the pouch and the slot 1 and slot 2 are cleared.
4. **Given** the player tries to add a duplicate element (Chi in slot 1, Chi again), **Then** the duplicate tap is rejected with a subtle visual shake; the slot remains unchanged.
5. **Given** the Kū element has not been unlocked by a spirit, **When** the player views the mixing UI, **Then** the Kū element button is locked with a faint silhouette and a hint: "a spirit holds this secret."
6. **Given** a Tier 3 slot has not been unlocked by a spirit recipe gift, **When** the player taps a third element slot, **Then** the slot shows a lock icon and the tooltip reads "a spirit can teach you this."
7. **Given** the pouch is full (all slots occupied by unplanted seeds), **When** the player opens the mixing UI, **Then** the confirm button is disabled and the UI shows "plant a seed first."
8. **Given** a new recipe combination is produced for the first time, **Then** the Codex immediately gains a discovered entry for that recipe and a brief "Discovered" toast appears.

**Edge Cases**:
- All element slots selected but combination is invalid (should never occur if UI only shows valid options — UI must be designed to prevent invalid state rather than reject at confirm)
- Mixing UI opened with zero seeds in pouch and one or more seeds in the ground (valid — player may mix freely as long as pouch has space)

---

### User Story 2 — Seed Planting and Edge Expansion (Priority: P1)

The player plants seeds at valid edge positions — unoccupied hexes adjacent to at least one bloomed tile. Planting consumes a growing slot. The garden's boundary expands only as seeds bloom.

**Why this priority**: Planting is the primary garden-building action. Edge expansion defines the fundamental shape of the garden over time.

**Independent Test**: Start with the origin tile. Verify 6 edge positions are highlighted as plantable. Plant a Tier 1 seed. Verify the growing slot count decreases by 1. After blooming, verify up to 6 new edges appear from the new tile.

**Acceptance Scenarios**:

1. **Given** there is at least one bloomed tile and a seed in the pouch, **When** the player taps a valid edge hex, **Then** the seed is planted (pouch slot freed, growing slot consumed, sprout visual appears at that hex).
2. **Given** all growing slots are occupied, **When** the player taps any edge hex, **Then** no seed is planted and the edge hex shows a brief "full" visual indicator.
3. **Given** a seed has been planted and not yet bloomed, **When** the player taps the sprouting hex, **Then** nothing happens (sprouts are not tappable until ready to bloom).
4. **Given** a seed blooms, **When** the new tile is placed, **Then** up to 6 adjacent unoccupied hexes are added to the valid edge set immediately.
5. **Given** the player has 3 growing slots and all 3 are occupied, **When** one seed blooms, **Then** the growing slot count returns to 1 available and a new seed may be planted.

**Edge Cases**:
- Origin tile placed at game start does not consume a growing slot (it is a gift, not a planted seed)
- A seed planted at an edge that later becomes surrounded (all adjacents bloomed) does not change; it blooms normally and adds no new edges

---

### User Story 3 — Seed Growth and Bloom Confirmation (Priority: P1)

Seeds grow over time. When growth completes the seed enters a "ready" state — it glows and pulses, waiting. The player must tap the seed to trigger the bloom. No auto-bloom occurs. All pattern discoveries and spirit evaluations fire at bloom time, not at growth completion.

**Why this priority**: The deliberate bloom tap is the core ritual of the game. It ensures the player witnesses every consequence of their planting decisions.

**Independent Test** (Instant mode): Plant a Tier 1 seed. Confirm it immediately shows the "ready to bloom" visual. Tap it. Confirm the tile blooms with a visual/audio effect. Confirm any patterns that would be completed by this tile evaluate and fire at this moment.

**Independent Test** (Real-time mode): Plant a Tier 1 seed. Confirm it shows a living sprout animation (no progress bar). Close and reopen the app after 10+ minutes. Confirm the seed now shows "ready to bloom." Tap it and confirm normal bloom behaviour.

**Acceptance Scenarios**:

1. **Given** a seed is planted in instant mode, **When** the next frame completes, **Then** the seed immediately shows the "ready to bloom" state (pulsing glow).
2. **Given** a seed is planted in real-time mode, **When** its growth duration has not elapsed, **Then** the seed displays a living sprout animation with no numerical timer or progress bar.
3. **Given** a seed in real-time mode has reached its growth duration (app open or closed), **When** the player next views the garden, **Then** the seed displays the "ready to bloom" state.
4. **Given** a seed is in "ready to bloom" state, **When** the player taps it, **Then** the tile blooms: the biome mesh appears, a bloom visual effect plays, a bloom audio cue sounds, and the growing slot is freed.
5. **Given** a bloom completes the final tile of a discovered pattern, **When** the bloom animation finishes, **Then** the discovery fires and its discovery event is processed in the same frame.
6. **Given** the app is closed while seeds are growing, **When** the app reopens, **Then** seeds that reached their duration during closure are in the "ready to bloom" state; seeds still growing resume from their correct elapsed time using wall-clock delta.

**Edge Cases**:
- Multiple seeds ready to bloom simultaneously: player may tap them in any order; each fires independently
- A seed is ready to bloom but the player does not return for 3 days: seed remains in "ready to bloom" state indefinitely — there is no penalty for delayed blooming

---

### User Story 4 — Growing Slot Capacity (Priority: P1)

The player has a limited number of seeds that can grow concurrently (growing slots). This starts at 3 and may increase through spirit gifts or garden milestones. The slot limit creates meaningful session decisions without blocking progress.

**Why this priority**: Without this limit, the player can carpet-plant unlimited seeds and walk away — the garden degenerates into a batch job rather than a ritual.

**Independent Test**: Verify the UI shows "growing slots: 1/3" (available/total). Plant 3 seeds. Verify the counter shows "0/3" and further planting is blocked. Bloom one seed. Verify the counter returns to "1/3" and planting is re-enabled.

**Acceptance Scenarios**:

1. **Given** the player has 3 total growing slots and 1 seed in the ground, **When** they view the garden, **Then** the HUD shows 2 available growing slots.
2. **Given** all growing slots are occupied, **When** the player attempts to plant, **Then** the action is blocked and a gentle visual indicator communicates "slots full."
3. **Given** a spirit gift expands the pouch by 1 slot, **When** the gift is received, **Then** the total growing slot count permanently increases by 1.
4. **Given** the player's total growing slots is 5 (after expansions), **When** 5 seeds are in the ground, **Then** planting is blocked as expected.

**Edge Cases**:
- Growing slot capacity persists across sessions and is stored in save data
- Maximum growing slot capacity is configurable in project settings (default ceiling: 10)

---

### User Story 5 — Godai Elements and Recipe Discovery (Priority: P1)

The game defines five Godai elements. Four are available from the start; Kū (Void) is locked until a spirit unlocks it. The element system drives the entire seed recipe tree. Tier 1 and Tier 2 recipes are freely discoverable through experimentation. Tier 3 recipes are locked until specific spirits teach them.

**Why this priority**: Elements are the atomic unit of seed creation. Without a working element system the mixing UI produces nothing.

**Independent Test**: Verify Chi, Sui, Ka, Fū are available on a new game. Verify Kū is locked. Mix each single element and confirm it produces the correct base biome. Mix Chi+Sui and confirm Clay. Mix Chi+Ka and confirm Desert. Attempt a third element slot — confirm it is locked.

**Acceptance Scenarios**:

1. **Given** a new garden is started, **When** the mixing UI is opened, **Then** Chi, Sui, Ka, Fū are selectable; Kū shows as locked.
2. **Given** a single element is placed in the mixing UI, **When** confirm is tapped, **Then** the produced seed's biome matches the Tier 1 recipe table exactly.
3. **Given** two elements are placed in the mixing UI, **When** confirm is tapped, **Then** the produced seed's biome matches the Tier 2 recipe table exactly (order of selection does not matter).
4. **Given** the Mist Stag has been summoned and its gift is a Kū unlock, **When** the player opens the mixing UI, **Then** the Kū element is now selectable.
5. **Given** a Tier 3 recipe has been taught by a spirit, **When** the player loads those three elements in the mixing UI, **Then** a third element slot is active for that combination and a Tier 3 seed is produced on confirm.
6. **Given** a Tier 3 recipe combination is entered without the spirit unlock, **Then** the third slot remains locked regardless of which elements are in slots 1 and 2.

**Edge Cases**:
- Kū as a solo element: cannot be used alone (no Tier 1 Kū seed exists); UI prevents single-slot confirm when Kū is the only element selected
- Recipe table is data-driven (resource file); adding new entries does not require code changes

---

### User Story 6 — Spirit Habitat Preferences (Priority: P2)

Each spirit has preferred and disliked biome types. A spirit's wander logic weights movement toward preferred biome tiles within its wander radius. When good habitat is plentiful the spirit settles; when it is absent or overcrowded by a rival spirit the spirit drifts.

**Why this priority**: Habitat preference transforms spirits from passive decorations into responsive inhabitants. It creates a feedback loop between what the player plants and where spirits go — the primary way the player "guides" spirits without directly commanding them.

**Independent Test**: Summon the Red Fox (forest habitat preferred). Add 8+ Forest/Meadow tiles to one corner of the garden. Over 3 wander cycles, confirm the Red Fox's average position moves toward that corner. Then remove those tiles (replace with Stone). Over 3 wander cycles confirm the Red Fox drifts away.

**Acceptance Scenarios**:

1. **Given** a spirit has preferred biomes defined, **When** tiles of those biome types are bloomed within its wander radius, **Then** the spirit's next wander step weights toward those tiles with probability ≥ 60% vs random.
2. **Given** a spirit has disliked biomes defined, **When** it reaches a tile of a disliked biome type, **Then** the spirit immediately weights its next step away from that tile.
3. **Given** two spirits with a tension relationship are within N hexes of each other, **When** they remain in proximity for ≥ 30 seconds (real-time) or ≥ 10 wander ticks (instant), **Then** both spirits' occupied tiles gain a "tension" visual shader.
4. **Given** two spirits with a harmony relationship have overlapping territory for ≥ 60 seconds (real-time) or ≥ 20 wander ticks (instant), **Then** a Harmony Event fires: a visual bloom on overlap tiles, a unique audio cue, and a permanent subtle visual accent on those tiles.
5. **Given** a spirit's preferred biome is entirely absent from the garden, **When** it wanders, **Then** it falls back to standard random wander within its bounding region (no error, no freeze).

**Edge Cases**:
- Spirit with no preferred biomes defined: uses standard random wander (backward-compatible with existing 30 spirits)
- Harmony event fires at most once per unique spirit pair per garden session; a second overlap period does not re-fire

---

### User Story 7 — The Codex (Priority: P2)

The Codex is a persistent field guide accessed via the Codex HUD button — one of three minimalist mode buttons always present on screen (Plant, Mix, Codex). It has four sections — Seeds, Biomes, Spirits, Structures — and populates progressively as the player makes discoveries. Unknown entries show silhouettes and hint text. Known entries show full detail. The Codex is read-only; it records, it does not instruct.

**Why this priority**: The Codex is the primary progression compass. Without it players have no direction after the first session and cannot leverage the hint system to discover new seeds or spirits.

**Independent Test**: Open the Codex on a new garden. Confirm Seeds shows Chi, Sui, Ka, Fū single-element recipes as known and all two-element recipes as silhouettes with hint text. Discover a Clay seed (Chi+Sui). Confirm the Clay entry fills in. Confirm Spirits shows all 30 spirit silhouettes with riddle text visible.

**Acceptance Scenarios**:

1. **Given** the player opens the Codex, **When** it loads, **Then** four tabs are visible: Seeds, Biomes, Spirits, Structures.
2. **Given** a seed recipe has not been discovered, **When** the player views the Seeds tab, **Then** the entry shows a shadowed seed silhouette and a material hint string (e.g., "smells of still water and bark").
3. **Given** a seed recipe has been discovered, **When** the player views the Seeds tab, **Then** the entry shows the seed's full name, element combination, and biome produced.
4. **Given** a biome tile has bloomed at least once in the garden, **When** the player views the Biomes tab, **Then** the entry is fully revealed with its name, description, and visual sample.
5. **Given** a spirit has not been summoned, **When** the player views the Spirits tab, **Then** the entry shows a spirit silhouette and the full riddle text (the riddle is always visible; the identity is not).
6. **Given** a spirit has been summoned, **When** the player views the Spirits tab, **Then** the entry fills in fully, including any recipe gift or Kū unlock it granted.
7. **Given** a spirit granted a Tier 3 recipe on summon, **When** the player views the Seeds tab, **Then** the relevant Tier 3 entry is now fully revealed.
8. **Given** the player closes and reopens the app, **When** the Codex is opened, **Then** all previously discovered entries remain discovered; no entries regress.

**Edge Cases**:
- Kū-element seeds in the Seeds tab: shown as fully locked (no silhouette, no hint) until Kū is unlocked by a spirit — the player does not know Kū seeds exist until the unlock occurs
- Structures tab on a new game: all structures show as silhouettes; hint text describes approximate tile requirements without specifying the pattern geometry

---

### User Story 8 — Satori Moments (Priority: P3)

A Satori Moment is a rare, earned event that fires when the garden reaches a state of deep balance. It is not triggered by the player directly — it emerges from the garden's own condition. When it fires, the garden briefly reveals its true nature in a full visual and audio sequence, and one new content item unlocks.

**Why this priority**: The Satori Moment ties the game's title to a mechanical climax. It is the horizon that makes daily tending feel purposeful without being a task list.

**Independent Test** (Instant mode, debug panel): Manually satisfy a Satori condition set via the debug panel. Confirm the sequence fires: camera pull-back, tile light patterns, resonant audio, fade. Confirm the unlock is registered. Confirm the same condition set cannot fire again.

**Acceptance Scenarios**:

1. **Given** all Satori conditions for a defined condition set are met simultaneously, **When** the condition evaluator runs (triggered by any bloom or spirit summon), **Then** the Satori Moment fires automatically.
2. **Given** a Satori Moment fires, **When** the sequence plays, **Then**: the camera slowly pulls back to show the full garden, all tiles display a brief geometric light overlay, a single resonant audio event plays and fades over ~8 seconds, then the garden returns to normal.
3. **Given** the Satori sequence is playing, **When** the player taps the screen after a 2-second delay, **Then** the sequence fades out gracefully within 1 second (skippable).
4. **Given** a Satori Moment completes, **Then** one unlock is registered: a new Tier 3 recipe, a Kū unlock, an additional growing slot, or a new spirit catalogue entry.
5. **Given** a Satori Moment has fired for a given condition set, **When** those same conditions are met again, **Then** no second Satori Moment fires; the condition is marked as consumed.
6. **Given** the player is in instant mode with the debug panel visible, **When** they activate "Trigger Satori" in the debug panel, **Then** the sequence fires as if conditions were met naturally.

**First Satori Condition (Condition Set 1)**:
- All four base biomes have at least one bloomed tile: Stone (Chi), River (Sui), Ember Field (Ka), Meadow (Fū)
- At least three spirits have been summoned in the garden
- Unlock: one additional growing slot

**Edge Cases**:
- Multiple Satori condition sets exist (one per unlock); they are independent — meeting set A and set B fires two separate Satori Moments over time
- Satori Moment fires mid-bloom: the bloom completes first, then the Satori sequence begins on the next frame
- App closed during Satori sequence: sequence does not replay on reopen; the unlock is still registered

---

### User Story 9 — Growth Timing Modes (Priority: P1)



The game supports two growth modes switchable in Settings: **Instant** (all seeds grow immediately) and **Real-Time** (seeds grow over configured durations using wall-clock time — the intended play experience).

**Why this priority**: Instant mode is required for development and QA. Real-time mode is the actual game. Both must be correct and both must be switchable without data loss.

**Independent Test**: Set instant mode. Plant a seed — confirm immediate bloom-ready state. Switch to real-time. Plant a seed — confirm growth animation, no immediate bloom. Close app for 10+ minutes. Reopen — confirm seed is bloom-ready. Switch back to instant — confirm in-progress seeds immediately become bloom-ready.

**Acceptance Scenarios**:

1. **Given** instant mode is active, **When** a seed is planted, **Then** it immediately enters the "ready to bloom" state.
2. **Given** real-time mode is active, **When** a seed is planted, **Then** it begins growing and reaches "ready to bloom" only after its configured duration has elapsed in wall-clock time.
3. **Given** real-time mode is active and a seed is 50% through its growth, **When** the mode is switched to instant, **Then** the seed immediately enters "ready to bloom."
4. **Given** instant mode is active and a seed is ready to bloom, **When** the mode is switched to real-time, **Then** the seed retains its "ready to bloom" state (it was already done; it does not regress to growing).
5. **Given** the app is closed in real-time mode with seeds growing, **When** the app reopens, **Then** seeds whose duration elapsed during closure are in "ready to bloom" state; seeds still growing show the correct remaining elapsed fraction.
6. **Given** instant mode is active, **When** the garden is rendered, **Then** a visible indicator (e.g., ⚡ badge or "INSTANT" label in the HUD) makes clear to the tester which mode is active.
**Edge Cases**:
- Mode toggle lives in Settings, not the main gameplay HUD, to prevent accidental toggles during play
- Switching modes does not affect the Codex, discovered recipes, summoned spirits, or any persistent game state other than active seed timers

---

## Requirements *(mandatory)*

### Functional Requirements

#### Seed Alchemy

- **FR-001**: The game HUD contains exactly three minimalist mode buttons: **Plant** (default), **Mix**, and **Codex**. Tapping a button switches the active panel in-place without a scene transition; the garden remains rendered beneath all panels.
- **FR-002**: The mixing UI must support 1–3 element input slots. Slot 3 is locked by default and unlocked only by a spirit's Tier 3 recipe gift.
- **FR-003**: Tapping an already-selected element slot must deselect it, returning that slot to empty.
- **FR-004**: Confirming a valid combination produces exactly the seed defined in the recipe table and adds it to the pouch.
- **FR-005**: Confirming when the pouch is full must be blocked; the confirm button is disabled and a "pouch full" message displayed.
- **FR-006**: Invalid combinations (duplicate elements) must be prevented by the UI — not rejected at confirm time.
- **FR-007**: All recipes are stored as data resources; adding new recipes requires no engine code changes.
- **FR-008**: Godai elements Chi, Sui, Ka, and Fū are free and unlimited — no resource cost, stock, or acquisition step is required. Tier 1 and Tier 2 recipes are always available to experiment with (no unlock required beyond the Kū restriction).

#### Element System

- **FR-009**: Five GodaiElement resources must be defined: Chi, Sui, Ka, Fū, Kū.
- **FR-010**: Kū must be flagged `locked_by_default = true` and becomes available only after a spirit grants a Kū unlock gift.
- **FR-011**: Recipe lookup must be order-independent (Chi+Sui and Sui+Chi produce the same result).
- **FR-012**: Kū cannot be used as a solo element (no Tier 1 Kū seed); the mixing UI must prevent single-slot confirm when only Kū is selected.

#### Seed Pouch and Growing Slots

- **FR-013**: The seed pouch has a configurable capacity (default: 3 unplanted seeds). Seeds are removed from the pouch when planted.
- **FR-014**: Growing slots represent seeds currently in the ground. Default capacity: 3. Planting consumes one slot; blooming frees one slot.
- **FR-015**: Pouch capacity and growing slot capacity are independent values, both stored in save data.
- **FR-016**: Both capacities may be increased by spirit gifts or garden milestones; increases are permanent for the save.

#### Seed Growth

- **FR-017**: Each SeedInstance stores: recipe ID, hex coordinate, planted_at timestamp (Unix), growth_duration (seconds, 0 in instant mode), and state (GROWING / READY / BLOOMED).
- **FR-018**: In instant mode, growth_duration is forced to 0 for all newly planted seeds.
- **FR-019**: Growth completion uses wall-clock time: `Time.get_unix_time_from_system() - planted_at >= growth_duration`. The device clock is trusted unconditionally; no manipulation detection or server validation is applied.
- **FR-020**: Blooming must be triggered by an explicit player tap on a READY seed; no auto-bloom under any circumstance.
- **FR-021**: Blooming fires: tile mesh placement, bloom VFX, bloom SFX, growing slot freed, pattern evaluation, spirit condition evaluation.
- **FR-022**: Seeds in READY state persist indefinitely until the player taps them — there is no expiry.

#### Edge Expansion

- **FR-023**: Valid planting positions are defined as: unoccupied hexes adjacent to ≥ 1 BLOOMED tile.
- **FR-024**: Seeds in GROWING or READY state do not contribute to the valid edge set — only BLOOMED tiles do.
- **FR-025**: The edge set is recomputed after each bloom.

#### Spirit Habitat

- **FR-026**: SpiritDefinition must be extended with: `preferred_biomes: Array[BiomeType]`, `disliked_biomes: Array[BiomeType]`, `harmony_partner_id: StringName`, `tension_partner_id: StringName`, `gift_type: SpiritGiftType`, `gift_payload: StringName`. In this release, approximately 10 ecologically distinct spirits are fully profiled (e.g. Koi Fish, Red Fox, White Heron, Mountain Goat, Boreal Wolf); the remaining spirits leave these fields empty and fall back to random wander per FR-028 fallback behaviour.
- **FR-027**: `gift_type` values: `NONE`, `KU_UNLOCK`, `TIER3_RECIPE`, `POUCH_EXPAND`, `GROWING_SLOT_EXPAND`, `CODEX_REVEAL`.
- **FR-028**: Spirit wander logic must apply a directional weight toward preferred biome tiles within wander radius (weight ≥ 60% toward preferred vs uniform random).
- **FR-029**: Spirit wander logic must apply a directional weight away from disliked biome tiles.
- **FR-030**: Tension detection: if two tension-pair spirits are within `tension_distance` hexes (configurable, default 5), the tension visual shader is applied to their respective current tiles.
- **FR-031**: Harmony detection: if two harmony-pair spirits have overlapping territory (their wander regions share ≥ 1 tile) for `harmony_duration` ticks (configurable, default 20 ticks in instant, 60 real-time seconds), a Harmony Event fires.
- **FR-032**: Harmony Event: signals `harmony_event_fired(spirit_a_id, spirit_b_id, overlap_hexes: Array[Vector2i])`; overlap tiles receive a permanent visual accent; fires at most once per unique pair per garden.
- **FR-033**: Spirit gift processing occurs at summon time (the same frame the spirit spawns); it is idempotent (re-processing the same gift does not duplicate the effect).

#### Codex

- **FR-040**: The Codex panel is shown when the player taps the Codex HUD button (FR-001). It has four tabs: Seeds, Biomes, Spirits, Structures.
- **FR-041**: Each Codex entry has: `category`, `entry_id`, `discovered: bool`, `hint_text: String`, `full_content` (shown only when discovered).
- **FR-042**: `hint_text` is always visible for non-Kū Seeds, all Biomes, all Spirits, and all Structures regardless of discovered state.
- **FR-043**: Kū-element seed entries remain fully hidden (no hint) until Kū is unlocked.
- **FR-044**: Codex state (discovered booleans) is stored in save data.
- **FR-045**: The Codex is read-only; it has no interactive elements other than tab switching and scrolling.

#### Satori Moments

- **FR-046**: A `SatoriConditionEvaluator` runs after each bloom and each spirit summon.
- **FR-047**: Satori conditions are data-driven (same composable condition architecture as spirit summon conditions, see spec 008).
- **FR-048**: Each Satori condition set has a `fired: bool` flag. Once fired, it is never re-evaluated.
- **FR-049**: The Satori sequence: camera pull-back over 2s → tile light overlay for 4s → resonant audio plays → overlay fades over 2s → garden returns to normal. Total: ~8s, skippable after 2s by player tap.
- **FR-050**: After the sequence, the unlock registered in the condition's `unlock_payload` is applied immediately.

#### Growth Timing Modes

- **FR-051**: `GrowthMode` enum: `INSTANT`, `REAL_TIME`. Stored in project settings (not per-garden save data).
- **FR-052**: Switching to INSTANT: all GROWING seeds immediately set state to READY.
- **FR-053**: Switching to REAL_TIME: all READY seeds that were force-completed by INSTANT mode retain READY state; newly planted seeds use real durations.
- **FR-054**: The active mode is visibly flagged in the HUD when INSTANT is selected.

### Experience Requirements

- **EX-001**: The three HUD mode buttons (Plant, Mix, Codex) must be small, iconic, and visually recessive — they indicate state without competing with the garden for attention.
- **EX-001b**: The mixing UI must feel tactile — elements tap-to-slot, not selected from a dropdown or list.
- **EX-002**: The bloom tap must have a response clearly distinct from ordinary camera/UI taps: a dedicated VFX and a unique audio cue.
- **EX-003**: Dormancy transition must be ambient and calm — a slow desaturation, not a warning flash or alert sound.
- **EX-004**: The Codex must feel like a hand-drawn field guide: illustrated, textured, unhurried.
- **EX-005**: Seeds show a living animation while growing (slow pulse, micro-movement) — no numerical timer, no progress bar, no percentage.
- **EX-006**: The Satori Moment sequence must feel rare and weightless — no score, no fanfare, no congratulatory text. Just the garden revealing itself.
- **EX-007**: Instant mode's HUD indicator must be immediately legible to a developer at a glance without cluttering the play experience.
- **EX-008**: The garden must never communicate urgency. Dormancy, full growing slots, and empty pouches are states to notice — not crises to resolve.

---

## Key Entities

### GodaiElement *(new resource)*
- `id: StringName` — "chi" | "sui" | "ka" | "fu" | "ku"
- `display_name: String` — "Chi (地)"
- `kanji: String`
- `locked_by_default: bool` — true for Kū only

### SeedRecipe *(new resource)*
- `id: StringName`
- `elements: Array[StringName]` — 1–3 GodaiElement IDs (order-independent; stored sorted)
- `produces_biome: BiomeType`
- `tier: int` — 1, 2, or 3
- `spirit_unlock_id: StringName` — empty for Tier 1/2; spirit ID for Tier 3
- `codex_hint: String` — shown before discovery

### SeedInstance *(per planted seed)*
- `recipe_id: StringName`
- `hex_coord: Vector2i`
- `planted_at: float` — Unix timestamp
- `growth_duration: float` — seconds (0 in instant mode)
- `state: SeedState` — GROWING | READY | BLOOMED

### SeedPouch *(garden-scoped)*
- `seeds: Array[SeedInstance]` — unplanted seeds in hand
- `capacity: int` — default 3

### GrowthSlotTracker *(garden-scoped)*
- `active_seeds: Array[SeedInstance]` — seeds in GROWING or READY state
- `capacity: int` — default 3

### GrowthMode *(enum, project settings)*
- `INSTANT`
- `REAL_TIME`

### SpiritHabitatProfile *(extends SpiritDefinition fields)*
- `preferred_biomes: Array[BiomeType]`
- `disliked_biomes: Array[BiomeType]`
- `harmony_partner_id: StringName`
- `tension_partner_id: StringName`
- `gift_type: SpiritGiftType` — NONE | KU_UNLOCK | TIER3_RECIPE | POUCH_EXPAND | GROWING_SLOT_EXPAND | CODEX_REVEAL
- `gift_payload: StringName` — recipe ID, spirit ID, or empty

### CodexEntry *(per Codex item)*
- `category: CodexCategory` — SEED | BIOME | SPIRIT | STRUCTURE
- `entry_id: StringName`
- `discovered: bool`
- `hint_text: String`

### SatoriConditionSet *(new resource)*
- `condition_id: StringName`
- `requirements: Array[Dictionary]` — composable condition descriptors (same format as spirit summon conditions)
- `fired: bool`
- `unlock_type: SpiritGiftType`
- `unlock_payload: StringName`

**Example — Condition Set 1 (`satori_first_awakening`)**:
```
requirements: [
  { type: "biome_present", biome: "stone" },
  { type: "biome_present", biome: "river" },
  { type: "biome_present", biome: "ember_field" },
  { type: "biome_present", biome: "meadow" },
  { type: "spirit_count_gte", count: 3 }
]
unlock_type: GROWING_SLOT_EXPAND
unlock_payload: ""
```

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All Tier 1 and Tier 2 seed recipes are producible in the mixing UI without external guidance; the UI rejects no valid combination silently.
- **SC-002**: In instant mode, a full new-game session (plant → bloom → pattern → spirit summon → recipe unlock → new seed → plant) completes without error in under 5 minutes.
- **SC-003**: In real-time mode, switching to instant mode causes all GROWING seeds to become READY within the same frame; switching back does not regress any READY seed to GROWING.
- **SC-004**: Seeds planted in real-time mode with the app closed for the seed's full duration are in READY state on next app open, verified across 3 consecutive close/open cycles.
- **SC-005**: No seed auto-blooms under any circumstance; every tile placement is preceded by an explicit player tap on a READY seed.
- **SC-006**: Spirit habitat weighting produces measurable directional drift toward preferred biomes within 5 wander ticks in a controlled test garden.
- **SC-007**: A Harmony Event fires exactly once per unique spirit pair and does not re-fire on repeated overlap periods.
- **SC-008**: The Codex correctly reflects all discovered and undiscovered items across a save-close-reopen cycle with zero regressions.
- **SC-009**: A Satori Moment fires exactly once per condition set and its unlock is applied; re-meeting the same conditions produces no second event.
- **SC-010**: Growing slot and pouch capacity expansions from spirit gifts persist across app restarts.

---

## Out of Scope (Future Specs)

The following are noted for future consideration and are explicitly excluded from this spec:

- **Audio design** for bloom events, harmony events, and the Satori sequence (→ amendment to spec 011)
- **Structure and landmark seeds** — Tier 3 seeds that produce structural biomes rather than natural biomes (→ amendment to spec 007)
- **Wild seed spawning logic** — mechanics for how wild seeds appear at garden edges
- **Spirit Codex portraits** — full illustrated art for summoned spirits
- **Push / local notifications** for ready-to-bloom seeds
- **Detailed Satori Moment unlock content** — full catalogue of what each Satori condition set unlocks (content pass, post-implementation)
- **Tile Vitality & Dormancy** — tiles transitioning to Dormant without spirit visits; deferred to a future spec
- **Multiplayer or shared garden** features
