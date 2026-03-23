# Feature Specification: Accessibility and Settings Screen

**Feature Branch**: `013-accessibility-settings`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Accessibility options and settings screen for haptics, colorblind mode, and audio"

## User Scenarios & Testing *(mandatory)*

### Settings Summary

| Setting | Type | Values | Scope |
|---|---|---|---|
| Colorblind palette | Toggle | On / Off | Immediate — all rendered tiles |
| Haptic intensity | 3-way | Off / Low / Full | Immediate — all subsequent haptic events |
| Master volume | Slider | 0–100% | Immediate — all audio output |
| Ambient volume | Slider | 0–100% | Immediate — ambient buses only |
| SFX / stinger volume | Slider | 0–100% | Immediate — stinger and SFX buses only |
| Master mute | Toggle | On / Off | Immediate — all audio output |

All settings are stored in a separate config file (not the garden save file) and restored on launch.

---

### User Story 1 - Settings Panel Access and Colorblind Toggle (Priority: P1)

The player taps a small floating settings button in the thumb zone at the bottom of the screen. A settings panel opens. The player toggles the colorblind-friendly high-contrast palette. Every tile on screen immediately changes colour to the high-contrast variant without any app restart or reload.

**Why this priority**: The settings panel is the entry point to all accessibility features and audio controls. If the panel is unreachable or the colorblind toggle does not work immediately, a significant portion of players cannot use the game comfortably. This is a launch-blocking concern.

**Independent Test**: With the default palette active and tiles of each biome type visible, open settings and toggle the colorblind palette on. Verify all tile colours change within the same frame. Toggle it off. Verify all tiles revert to the standard palette within the same frame.

**Acceptance Scenarios**:

1. **Given** the game is running, **When** the player taps the settings button from a natural thumb position at the bottom of the screen, **Then** the settings panel opens without requiring a hand repositioning.
2. **Given** the settings panel is open and the colorblind palette is off, **When** the player toggles it on, **Then** all rendered tile colours switch to the high-contrast variants within the same frame — no tiles retain the standard palette colour.
3. **Given** the colorblind palette is on, **When** the player toggles it off, **Then** all rendered tile colours revert to the standard palette within the same frame.
4. **Given** the colorblind palette is active, **When** a new tile is placed, **Then** the new tile renders immediately in the high-contrast variant (no one-frame flash of the standard colour).

---

### User Story 2 - Haptic Intensity Control (Priority: P1)

The player can select one of three haptic intensity levels — Off, Low, or Full — from the settings panel. The selected level is applied immediately to all subsequent haptic events (tile placement pulses, discovery vibrations). The setting is stored and survives app restart.

**Why this priority**: Haptic feedback is a core tactile element of the mobile-first experience but also a common accessibility and preference concern. Players who are sensitive to vibration, using the device in a quiet environment, or on a device with aggressive haptics need control over this immediately.

**Independent Test**: Set haptic level to Off. Place a tile. Verify no haptic pulse fires. Set haptic level to Full. Place a tile. Verify a haptic pulse fires. Close the app and reopen. Verify the haptic level is still Full.

**Acceptance Scenarios**:

1. **Given** haptic intensity is set to Off, **When** the player places a tile, **Then** no haptic event fires.
2. **Given** haptic intensity is set to Full, **When** the player places a tile, **Then** a full-intensity haptic pulse fires.
3. **Given** haptic intensity is set to Low, **When** the player places a tile, **Then** a reduced-intensity haptic pulse fires (noticeably weaker than Full).
4. **Given** haptic intensity is set to Low, **When** the app is closed and relaunched, **Then** haptic intensity is still Low on the next launch.
5. **Given** the device does not support haptic feedback (capability check returns false), **When** the settings panel opens, **Then** the haptic intensity control is hidden or clearly disabled with an explanatory label such as "Haptics not supported on this device."

---

### User Story 3 - Audio Volume Controls (Priority: P2)

The player can independently set ambient audio volume and sound-effects/stinger volume, as well as a master volume that scales both. A mute toggle silences everything instantly. All controls are in the settings panel, always accessible from the thumb zone.

**Why this priority**: Volume control is a near-universal expectation in mobile games. Players in quiet environments, shared spaces, or wearing headphones have different volume needs. Independent ambient and SFX controls allow the game to be used as a background relaxation tool (ambient only) or with full audio feedback.

**Independent Test**: Set ambient volume to 0% and SFX volume to 100%. Trigger a discovery stinger. Verify the stinger plays. Verify no ambient audio is audible. Set ambient volume to 100% and SFX volume to 0%. Verify ambient plays and stingers are silent.

**Acceptance Scenarios**:

1. **Given** master volume is at 50%, ambient at 100%, and SFX at 100%, **When** audio plays, **Then** the effective output level for all buses is 50% (master acts as a multiplier on top of individual bus volumes).
2. **Given** ambient volume is 0% and SFX volume is 100%, **When** the ambient soundscape plays, **Then** no ambient audio is audible; discovery stingers continue to play at their full SFX volume.
3. **Given** master mute is on, **When** ambient audio would play, **Then** no audio output occurs regardless of individual volume slider positions.
4. **Given** a discovery stinger is currently playing, **When** the player adjusts the SFX volume slider, **Then** the currently-playing stinger's volume changes immediately to reflect the new setting (no delay until next stinger).

---

### User Story 4 - Settings Persistence Separate from Garden Data (Priority: P3)

All settings are stored in a dedicated configuration file that is entirely separate from the garden save file. Deleting or resetting the garden save does not affect settings, and vice versa. Settings are restored on every launch before the garden loads so that the correct palette and volume levels are active from the first rendered frame.

**Why this priority**: Mixing settings and garden data creates fragile coupling. If the garden save is wiped (e.g., a corrupted save recovery flow), the player should not also lose their accessibility preferences. Conversely, a settings migration should not require touching garden save data.

**Independent Test**: Set colorblind palette on and master volume to 30%. Simulate a garden save reset (delete the garden save file). Relaunch the app. Verify the player is presented with an empty garden, but colorblind palette is still on and master volume is still 30%.

**Acceptance Scenarios**:

1. **Given** colorblind palette is on and master volume is 30%, **When** the app is closed and relaunched, **Then** the colorblind palette is active and master volume is 30% from the first rendered frame.
2. **Given** the garden save file is deleted, **When** the app is launched, **Then** a fresh empty garden loads but all settings retain the values saved in the config file.
3. **Given** the settings config file does not exist (first install), **When** the app launches, **Then** all settings initialise to their default values (colorblind off, haptics Full, all volumes 100%, mute off) and a default config file is written.

---

### Edge Cases

- **Device does not support haptics**: The haptic capability is checked at launch using the platform API. If haptics are unavailable, the haptic intensity setting is hidden from the settings panel entirely (or shown as a greyed-out row with the label "Not supported on this device"). No haptic API calls are made regardless of the stored setting value.
- **Player changes settings while a discovery notification is playing**: Settings changes are applied immediately. If colorblind mode is toggled mid-notification, the tile colours update; if volume is changed during a stinger, the stinger volume updates in real time. There is no freeze or queue.
- **Settings config file corrupted**: If the settings file fails to parse on launch, the system falls back to defaults silently and writes a fresh default config file. The player is not shown an error; they may notice their preferences were reset, which is acceptable as a graceful degradation.
- **Settings changed faster than one frame**: If the player drags a volume slider rapidly, the audio system receives a new target volume every frame. This is handled by the audio interpolation system (spec 011) — the actual bus volume lerps toward the target rather than jumping, preventing audio artefacts from rapid slider movement.
- **OS-level volume override**: The settings master volume is applied within the game's audio system; it does not override the device's OS-level volume. The effective output is the product of both. This is expected behaviour and requires no special handling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a settings panel accessible from a floating button always visible in the thumb zone (bottom 20% of screen height in portrait orientation)
- **FR-002**: System MUST support a colorblind high-contrast palette toggle that immediately updates all rendered tile colours in the same frame as the toggle action; palette colours are sourced from spec 009
- **FR-003**: System MUST support three haptic intensity levels (Off, Low, Full) applied immediately to all subsequent haptic events; the level is sourced by the haptic trigger points defined in spec 010
- **FR-004**: System MUST provide a master volume slider (0–100%) and a master mute toggle that apply instantly to all game audio output
- **FR-005**: System MUST provide independent volume sliders (0–100%) for the ambient soundscape bus and the sound-effects/stinger bus
- **FR-006**: System MUST save all settings to a configuration file that is separate from the garden save data file managed by spec 012
- **FR-007**: System MUST restore all settings from the configuration file before the first garden frame is rendered on app launch, so that correct palette and volume levels are active from startup
- **FR-008**: On devices where haptic feedback capability is absent, the haptic intensity control MUST be hidden or clearly disabled with an explanatory label; no haptic API calls MUST be made on such devices
- **FR-009**: All settings changes MUST take effect immediately without requiring an app restart

### Key Entities

- **AppSettings**: `haptic_level` (enum: off/low/full), `colorblind_mode` (bool), `master_volume` (float 0–1), `ambient_volume` (float 0–1), `sfx_volume` (float 0–1), `master_mute` (bool)
- **SettingsFile**: serialised AppSettings plus a `version` integer field for future migrations; stored at a fixed config path distinct from the garden save path

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Enabling the colorblind palette causes all visible tile colours to change to the high-contrast variant within one render frame — verified by frame-capture diff showing zero standard-palette tiles on the frame after the toggle
- **SC-002**: Changing haptic level to Off prevents any haptic events from firing immediately, without requiring an app restart — verified by placing 10 tiles after setting Off and confirming zero haptic events in the platform event log
- **SC-003**: All settings survive an app restart — values recorded before closing exactly match values observed on relaunch, across all 6 setting dimensions, verified by automated read-write-relaunch-read test
- **SC-004**: The settings panel button is reachable with a single thumb from a natural hand position at the bottom of a standard 6.1-inch portrait-mode phone screen, verified by a reachability overlay showing the button within the natural thumb arc
