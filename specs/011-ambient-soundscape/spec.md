# Feature Specification: Ambient Soundscape System

**Feature Branch**: `011-ambient-soundscape`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Ambient soundscape system with per-biome audio and proximity blending"

## User Scenarios & Testing *(mandatory)*

### Biome Audio Assignments

| Biome / Discovery | Ambient Character |
|---|---|
| Forest | Deep woodland — bird calls, rustling leaves, distant woodpecker |
| Water | Flowing stream — babbling water, occasional frog call |
| Stone / Mountain | Wind over rock — low resonant hum, distant rockfall echo |
| Earth / Savannah | Open grassland — warm breeze, crickets, far-off cattle |
| Swamp | Murky wetland — low drone, bubbling mud, crickets |
| Tundra | Arctic silence — icy wind, distant wolf howl |
| Meadow | Gentle meadow — bees, soft breeze, birdsong |
| Boreal Forest | Cold conifer — wind through pines, owl calls |
| Desert / Sand | Dry heat — wind over dunes, distant hawk |
| Mudflat / Reef | Coastal — waves, seabird calls, tidal wash |
| (Empty / no tiles) | Neutral wind — light breeze, total calm |
| Tier 1 Discoveries (12) | Each has a unique ambient identity layered on top of the base biome |

---

### User Story 1 - Camera-Driven Ambient Mix Crossfade (Priority: P1)

As the player pans the camera, the audio mix continuously adjusts to reflect the biome composition currently visible on screen. Panning from a pure Forest area to a pure Water area causes the soundscape to smoothly transition from woodland to flowing water with no sudden cut or silence gap.

**Why this priority**: Ambient audio is the primary atmospheric layer of Satori. A static audio track or abrupt cuts would break the meditative tone on every camera move. Smooth crossfading is the feature's core value.

**Independent Test**: Build a garden with a large Forest area on the left and a large Water area on the right. Pan slowly from the Forest to the Water and listen. Verify the audio transitions gradually — Forest sounds fade out as Water sounds fade in — with no abrupt jump. Pan back. Verify the transition is symmetric.

**Acceptance Scenarios**:

1. **Given** the camera viewport is entirely over Forest tiles, **When** the player pans slowly to the right until the viewport is entirely over Water tiles, **Then** Forest ambient volume decreases continuously and Water ambient volume increases continuously; neither track drops to zero before the transition is complete.
2. **Given** the camera viewport is split equally between Forest and Water tiles, **When** audio volumes are sampled, **Then** the Forest bus and Water bus are each at approximately 50% of their maximum volume (±5%).
3. **Given** the player pans quickly across multiple biomes in under one second, **When** they stop, **Then** the audio mix settles to match the biome composition at the final camera position within 500ms, with no sustained ghost volume from passed-over biomes.
4. **Given** the camera is on an empty area (no placed tiles), **When** audio is sampled, **Then** the neutral wind ambient plays at full volume and all biome buses are silent.

---

### User Story 2 - Discovery Stinger Playback (Priority: P1)

When a Tier 1, Tier 2, or Tier 3 discovery is triggered, a short one-shot audio stinger plays once at full volume over the ambient mix. After the stinger completes, the ambient mix resumes at its normal level. The stinger never loops.

**Why this priority**: Stingers are the audio signal that something significant has happened. Without them discoveries feel silent and underwhelming. They share P1 priority because discovery feedback is a core game loop mechanic.

**Independent Test**: Trigger a known discovery (e.g., place tiles to form a Forest cluster that completes a Tier 1 pattern). Verify the stinger plays once. Wait for it to complete. Verify the ambient mix resumes with no stutter. Trigger the same discovery again (if somehow possible). Verify the stinger does not play a second time for the same discovery.

**Acceptance Scenarios**:

1. **Given** the ambient mix is playing, **When** a discovery is triggered, **Then** the stinger for that discovery plays once at full volume immediately over the ambient mix.
2. **Given** a stinger is playing, **When** the stinger reaches its end, **Then** the ambient mix resumes at normal volume with no audible cut or click.
3. **Given** two discoveries are triggered within 500ms of each other, **When** their stingers are queued, **Then** the stingers play sequentially (not simultaneously) in trigger order; the second begins immediately after the first ends.
4. **Given** a stinger has played for a specific discovery, **When** a second event for the same discovery fires (which should not happen for unique discoveries, but guards against logic bugs), **Then** no second stinger plays.

---

### User Story 3 - Master Volume and Mute Control (Priority: P2)

The player can open settings at any time and adjust the master volume slider or toggle mute. Changes apply instantly to all audio output. The setting persists after the app is closed and reopened.

**Why this priority**: Volume control and mute are baseline accessibility and usability requirements — players need to silence the game in public or at night without closing it. Persistence is necessary to avoid re-muting on every launch.

**Independent Test**: Start the game with audio playing. Open settings. Toggle mute. Verify all audio stops immediately. Toggle mute off. Verify audio resumes at the previous level. Close the app. Reopen. Verify the mute state from the previous session is restored (persistence is coordinated with spec 012/013).

**Acceptance Scenarios**:

1. **Given** ambient audio is playing at 80% master volume, **When** the player toggles the mute switch, **Then** all audio output stops within the same frame.
2. **Given** audio is muted, **When** a discovery stinger would normally fire, **Then** the stinger does not play; no audio output occurs.
3. **Given** audio is muted, **When** the player toggles mute off, **Then** the ambient mix resumes at the volume level that was active before muting (not at maximum or zero).
4. **Given** the player sets master volume to 40%, **When** the app is closed and reopened, **Then** master volume is 40% on the next launch (settings persistence per spec 013).

---

### User Story 4 - Per-Biome and Per-Discovery Ambient Identity (Priority: P3)

Each of the 10 macro-biomes and the 12 Tier 1 discoveries has a distinct, recognisable ambient audio identity. A player who has played for several sessions should be able to identify a biome by its sound alone when blindfolded.

**Why this priority**: Distinct audio identities deepen the sense of place and world-building. They are non-blocking for core mechanics but are what elevates the game from functional to atmospheric.

**Independent Test**: Play a blinded audio test: play each biome's ambient track in isolation and ask testers to identify which biome they are hearing from a list. Target: at least 80% correct identification rate per biome after one play session.

**Acceptance Scenarios**:

1. **Given** the camera is over a pure Tundra area, **When** audio plays, **Then** the soundscape is identifiably distinct from Forest, Water, and Swamp to a listener who has heard all four.
2. **Given** a Tier 1 discovery (e.g., Deep Stand) is active in the viewport, **When** audio plays, **Then** the discovery's layered ambient is audibly different from the base Forest ambient underneath it.
3. **Given** the neutral wind ambient is playing (empty garden), **When** the first tile is placed and the camera is over it, **Then** that biome's ambient fades in within 500ms, replacing or blending over the neutral wind.

---

### Edge Cases

- **Empty garden (no tiles placed)**: The neutral wind ambient plays at full volume. As soon as a tile is placed and the camera is over it, the biome mix begins blending in over the neutral wind; the neutral wind fades out proportionally as biome tiles fill the viewport.
- **Many biomes equally represented on screen**: All biome buses play simultaneously, each at an equal fraction of full volume (e.g., 5 biomes = each at 20%). Total perceived volume may be lower in these mixed areas, which is acceptable as a deliberate design signal that the garden is highly diverse.
- **Player pans rapidly between distant biome areas**: The crossfade interpolation has a configurable minimum transition time (e.g., 100ms) to prevent audio snapping. If the camera moves so fast that the target biome changes before the previous fade completes, the interpolation target is updated mid-fade — no audio is cut abruptly.
- **Discovery stinger triggered while another is already playing**: Stingers are queued and play sequentially. The queue has a maximum depth (e.g., 5 stingers). If the queue is full, additional stingers for that session are dropped with a debug log entry.
- **App goes to background while audio is playing**: All audio buses are paused when the app loses focus and resumed when focus returns, matching platform audio session management expectations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST assign a distinct ambient audio track to each of the 10 macro-biomes and each of the 12 Tier 1 discoveries, stored as audio resource references in data files (not hard-coded)
- **FR-002**: System MUST sample the biome composition within the camera viewport each frame (or on camera move events) and compute per-bus target volumes proportional to each biome's tile coverage percentage
- **FR-003**: System MUST smoothly interpolate audio bus volume changes toward their targets each frame using a configurable lerp rate, producing no abrupt volume cuts when the camera moves
- **FR-004**: System MUST play a one-shot audio stinger when a discovery is triggered, queue simultaneous stingers sequentially, and return to the ambient mix volume after each stinger completes
- **FR-005**: System MUST provide a master volume control (0–100%) and a mute toggle that apply to all audio output immediately; both values are sourced from the settings system (spec 013)
- **FR-006**: System MUST keep all ambient tracks looping seamlessly, with loop points authored to avoid audible gaps or clicks
- **FR-007**: System MUST play a default neutral ambient (gentle wind) whenever the camera viewport contains no placed tiles; the neutral ambient fades out proportionally as biome tiles fill the viewport

### Key Entities

- **BiomeAudioBed**: maps a biome type (or Tier 1 discovery type) to an audio track identifier and a default bus volume ceiling; stored as a data resource
- **AmbientMix**: the live per-bus volume state computed each frame from the viewport biome composition — a float per registered biome bus, plus the neutral wind bus, plus any active stinger channel

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Panning the camera from a 100% Forest viewport to a 100% Water viewport over 3 seconds produces a continuous audio transition with no abrupt volume change greater than 5% per frame, verified by audio analysis of a recorded session
- **SC-002**: Discovery stingers play exactly once per unique discovery event and do not loop — verified by automated test triggering 12 Tier 1 discoveries and asserting each stinger plays once and stops
- **SC-003**: Toggling the mute setting from the settings screen silences all audio within the same frame and the mute state is correctly restored after an app restart
- **SC-004**: No audible gap (silence >5ms) or click artefact is detected at any ambient track loop point during a 10-minute continuous automated playback session on target hardware
