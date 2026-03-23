# Feature Specification: Tier 1 — Biome Cluster Discoveries

**Feature Branch**: `006-tier1-biome-discoveries`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Tier 1 biome cluster discoveries with audio triggers"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discovery Notification and Audio Stinger on First Match (Priority: P1)

As a player, I want to see a named discovery notification and hear a unique audio stinger the moment I place the tile that completes a Tier 1 discovery, so that the moment of discovery feels rewarding and memorable.

**Why this priority**: The notification and audio response is the player-facing payoff for the entire pattern-matching pipeline. Without it, discoveries happen silently in the data and the player never knows they've achieved something. This is the highest-value player-facing moment in the game.

**Independent Test**: Seed a test garden with 9 contiguous Forest tiles and no adjacent Stone. Place the 10th Forest tile. Confirm: (a) the "The Deep Stand" notification banner appears with the correct name and flavor text, (b) the unique audio stinger for The Deep Stand plays simultaneously, (c) the notification auto-dismisses after 4 seconds, (d) no second notification appears for The Deep Stand if an 11th Forest tile is added.

**Acceptance Scenarios**:

1. **Given** 9 contiguous Forest tiles with no adjacent Stone, **When** the 10th Forest tile is placed, **Then** the "The Deep Stand" notification appears with name and flavor text, and its unique audio stinger plays within the same frame.
2. **Given** 10+ Water tiles forming a 1-tile-wide line, **When** the 10th Water tile completes the River configuration, **Then** the "The River" notification and audio stinger fire.
3. **Given** a notification is displayed, **When** 4 seconds elapse, **Then** the notification auto-dismisses cleanly without player interaction.
4. **Given** The Deep Stand has already been discovered, **When** an 11th Forest tile is placed, **Then** no second notification appears and no audio stinger replays.
5. **Given** a single tile placement that completes both "The Mountain Peak" and "The Peat Bog", **When** the scan fires both signals, **Then** both notifications queue and display sequentially — not simultaneously — each with its own audio stinger.

---

### User Story 2 - Persistent Discovery Log Survives App Restart (Priority: P2)

As a player who returns to my garden after closing the app, I want all discoveries I made in a previous session to remain recorded in my discovery log, so that my sense of progress and the garden's history are never lost.

**Why this priority**: Persistence is what transforms discoveries from transient UI events into a meaningful record of the garden's story. Without persistence the discovery system has no lasting value and compound discoveries (F05 compound patterns) cannot rely on previously logged IDs.

**Independent Test**: In a test session, trigger all 12 Tier 1 discoveries. Terminate and relaunch the app. Open the discovery log. Confirm all 12 discoveries are present with their timestamps. Confirm no discovery fires a second notification on reload.

**Acceptance Scenarios**:

1. **Given** the player has triggered 5 discoveries in a session, **When** the app is closed and reopened, **Then** all 5 discoveries are present in the discovery log with their original timestamps.
2. **Given** a persisted discovery log containing "The River", **When** the game session starts, **Then** "The River" pattern is pre-loaded into the "already discovered" set and will not re-fire even if the tile configuration still matches.
3. **Given** a discovery is logged with a timestamp, **When** the log is read after restart, **Then** the timestamp matches the original trigger time (not the reload time).

---

### User Story 3 - Distinct Audio per Discovery (Priority: P3)

As a player, I want each of the 12 discoveries to have a clearly different audio stinger, so that I can begin to associate specific sounds with specific discoveries and the garden's soundscape feels varied and alive.

**Why this priority**: Audio distinctiveness is a quality-of-experience enhancement. The system works without unique audio (notifications alone convey the information), so this is P3 — important for the final experience but not blocking the core discovery pipeline.

**Independent Test**: Trigger all 12 discoveries in a single test session. Record the audio key played for each. Confirm all 12 audio keys are distinct (no two discoveries share a stinger). Confirm each audio key maps to a loaded audio asset.

**Acceptance Scenarios**:

1. **Given** all 12 discovery audio assets are loaded, **When** each discovery fires its audio stinger, **Then** no two discoveries play the same audio file.
2. **Given** a discovery fires its audio stinger, **When** the next discovery fires in the same session, **Then** the first stinger either completes or ducks before the second begins — they do not overlap in a jarring way.
3. **Given** the device is on silent/mute, **When** a discovery triggers, **Then** the notification still appears (audio failure does not suppress the visual notification).

---

### Discovery Catalogue Reference

| # | Name | Pattern Summary |
|---|------|----------------|
| 1 | The River | 10+ Water tiles forming a 1-tile-wide line |
| 2 | The Deep Stand | 10+ Forest tiles with no adjacent Stone |
| 3 | The Glade | 1 Earth tile surrounded by 6 Forest tiles |
| 4 | Mirror Archipelago | 5+ alternating Water/Sand pairs |
| 5 | Barren Expanse | 25+ Earth tiles with no Water nearby |
| 6 | Great Reef | 15 Water tiles containing 3 non-adjacent Stone |
| 7 | Lotus Pond | Water surrounded by Earth, then by Forest |
| 8 | The Mountain Peak | 10th contiguous Stone tile |
| 9 | Boreal Forest | 5 Forest + 5 Tundra tiles interwoven |
| 10 | The Peat Bog | 20+ Swamp tiles |
| 11 | Obsidian Expanse | Canyon surrounded by Water |
| 12 | The Waterfall | A River touching the edge of a Mountain Peak |

---

### Edge Cases

- **Two Tier 1 discoveries from the same placement**: Both must be queued and displayed sequentially (FR-007). The notification system must not drop either signal. Audio stingers must not overlap; the second plays after the first completes or fades.
- **Discovery pattern "broken" after discovery**: Tiles are permanent — once placed they cannot be removed — so a discovery configuration can never be physically dismantled. The discovery is never "un-discovered". No logic is needed for reversal; this case cannot occur by design.
- **The Waterfall (compound pattern)**: Requires The River AND The Mountain Peak to already be in the discovery log. If both are triggered in the same scan pass (same tile placement), the engine must ensure The River and The Mountain Peak signals are processed and logged before evaluating The Waterfall. The scan order for compound patterns must respect prerequisite ordering.
- **Boreal Forest requires a hybrid biome (Tundra)**: The Tundra tiles must be locked (created by alchemy) before this discovery can fire. The pattern definition must reference the Tundra biome type as a distinct tile type from its base components.
- **App crash mid-discovery**: If the app crashes between a discovery firing and the log being written to disk, the discovery must be retried on next scan or the save must be atomic to prevent a logged-but-unnotified or notified-but-unlogged state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register all 12 Tier 1 discoveries as `PatternDefinition` resources in the pattern engine registry, using the pattern types defined in F05.
- **FR-002**: System MUST display a discovery notification banner containing the discovery's display name and flavor text, auto-dismissing after 4 seconds, when a Tier 1 discovery signal is received.
- **FR-003**: System MUST play the unique audio stinger associated with each discovery at the moment the discovery signal fires.
- **FR-004**: System MUST record each discovery in the persistent discovery log with: discovery ID, display name, trigger timestamp, and the array of triggering tile coordinates.
- **FR-005**: System MUST prevent the same discovery from triggering more than once per garden — a discovery ID already present in the log must be suppressed by the pattern engine (via FR-008 in F05).
- **FR-006**: Discoveries logged to the discovery log MUST persist across app restarts, saved as part of the garden save data.
- **FR-007**: When multiple discoveries are triggered by the same tile placement, each discovery notification MUST display sequentially in a queue — never simultaneously overlapping on screen.

### Key Entities

- **Discovery**: A triggered instance of a Tier 1 discovery. Attributes: `discovery_id` (String), `display_name` (String), `flavor_text` (String), `audio_key` (String — references the audio asset for the stinger), `trigger_timestamp` (int, Unix epoch), `triggering_coords` (Array[Vector2i]).
- **DiscoveryLog**: The ordered, persistent collection of all triggered discoveries for this garden. Stored as part of the garden save file. Exposes a method to check whether a given discovery ID is already logged (used by the pattern engine's duplicate-suppression and compound-prerequisite checks).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 12 discovery configurations, when seeded in a test garden and the triggering tile placed, each produce exactly one notification and one audio stinger — verified by an automated test covering all 12 cases.
- **SC-002**: The discovery notification banner appears within one frame of the discovery signal firing, is readable at the target screen resolution, and auto-dismisses after exactly 4 seconds without any player interaction — verified by visual and timing tests.
- **SC-003**: All 12 discoveries appear in the discovery log after being triggered in a test session, and all 12 are still present after the app is terminated and relaunched — verified by a persistence integration test.
- **SC-004**: No two discovery notifications are ever displayed simultaneously on screen — when two discoveries fire from the same placement, the second notification does not appear until the first has begun dismissing — verified by a dual-trigger test.
