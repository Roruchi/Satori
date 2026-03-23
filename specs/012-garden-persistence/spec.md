# Feature Specification: Garden Persistence — Save and Load

**Feature Branch**: `012-garden-persistence`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Garden state persistence with auto-save and load on startup"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Garden State Restored on Relaunch (Priority: P1)

When the player closes the app and reopens it, the garden is exactly as they left it — every tile, every completed discovery, every spirit animal in its place. Nothing is lost and nothing is displaced. The player should be able to return to the game hours or days later with confidence that their work is intact.

**Why this priority**: Tile placements are permanent and irreversible in Satori. If save/load is broken or lossy, players lose their garden forever with no way to recover. This is the highest-stakes feature in the game and must work flawlessly before any other feature can be shipped.

**Independent Test**: Place 50 tiles of mixed biomes, trigger at least one discovery, and note the grid coordinates of 5 specific tiles. Close the app completely (remove from recent apps). Reopen the app. Verify all 50 tiles are present at their correct coordinates, the discovery log contains the triggered discovery, and no unexpected tiles have appeared.

**Acceptance Scenarios**:

1. **Given** a garden with 100 mixed-biome tiles and 3 triggered discoveries, **When** the app is closed and relaunched, **Then** all 100 tiles are at their original coordinates with their original biome types and all 3 discoveries are in the discovery log.
2. **Given** a spirit animal (e.g., the Koi Fish) has been summoned and is wandering, **When** the app is closed and relaunched, **Then** the Koi Fish entity is present and wandering within its original bounding region.
3. **Given** a newly launched app with a pre-existing save, **When** the garden loads, **Then** the player is viewing the playable garden (not a loading screen) within 10 seconds of app launch.
4. **Given** the player force-closes the app immediately after placing a tile, **When** the app is relaunched, **Then** either the new tile is present (it was saved) or absent (it was not yet saved), but no intermediate corrupt state is present and the app does not crash on load.

---

### User Story 2 - Auto-Save after Every 10 Tile Placements (Priority: P1)

The garden saves automatically in the background every 10 tile placements. The player never has to think about saving. No spinner, no save dialog, no frame stutter appears during the save — it is completely invisible.

**Why this priority**: Since placements are permanent, the auto-save interval determines the maximum work a player can lose in a crash. A 10-tile interval keeps potential loss minimal. This is P1 because the save/load round-trip must be validated before any meaningful playtest can occur.

**Independent Test**: Place 9 tiles one by one. Verify no save file timestamp update occurs (or the timestamp matches the last save, not the current time). Place the 10th tile. Verify the save file timestamp updates within the same second. Measure frame time during the save. Verify it does not exceed 16.7ms on the reference device.

**Acceptance Scenarios**:

1. **Given** a garden in an active play session, **When** the 10th tile is placed since the last save, **Then** the garden state is written to storage and the save file's last-modified timestamp is updated.
2. **Given** the auto-save is triggered, **When** the save is in progress, **Then** no visible frame stutter occurs — the frame time budget is not exceeded on the reference device.
3. **Given** a save is mid-write, **When** the auto-save interval fires again (10 more tiles), **Then** the new save is queued and does not start until the previous write completes, preventing concurrent writes.

---

### User Story 3 - Save on Background / App Close (Priority: P2)

Whenever the app transitions to the background (e.g., player switches apps or locks the screen) or receives a system close signal, the garden saves immediately. This is the last-resort save that catches any work not captured by the 10-tile auto-save.

**Why this priority**: Mobile OS can kill background apps without warning. Saving on background transition is the safety net that prevents losing placements made since the last auto-save trigger. It is P2 because the 10-tile auto-save already covers most cases.

**Independent Test**: Place 5 tiles (below the 10-tile auto-save threshold). Press the home button to send the app to the background. Wait 2 seconds. Reopen the app. Verify all 5 tiles are present.

**Acceptance Scenarios**:

1. **Given** 5 tiles have been placed since the last auto-save, **When** the home button is pressed and the app goes to the background, **Then** a save is triggered immediately and completes before the OS may terminate the process.
2. **Given** the app receives a system close signal (e.g., OS low-memory kill), **When** the signal is received, **Then** the save is initiated synchronously in the app's shutdown handler before the process exits.
3. **Given** an auto-save is already in progress, **When** a background transition occurs simultaneously, **Then** the background save does not start a second concurrent write; it either waits for the in-progress save or merges with it.

---

### User Story 4 - Large Garden Loads within 10 Seconds (Priority: P3)

A garden of 10,000 tiles restores from disk and is ready for interaction within 10 seconds of app launch. The player does not stare at a loading screen for longer than this before reaching their garden.

**Why this priority**: Long load times are a known killer of daily-habit mobile games. If early players with large gardens wait 30+ seconds on every launch, they stop launching. This target sets a hard architectural constraint on the serialisation format and load path.

**Independent Test**: Generate a save file containing exactly 10,000 tiles spread across multiple biomes. Launch a cold start of the app. Measure the time from app process start to the first interactive garden frame. Verify this time is ≤10 seconds on the reference mid-range device.

**Acceptance Scenarios**:

1. **Given** a save file containing 10,000 tiles, **When** the app is cold-started, **Then** the garden is interactive (player can place a tile) within 10 seconds.
2. **Given** a save file containing 1,000 tiles, **When** the app is cold-started, **Then** the garden is interactive within 3 seconds (proportional loading target).
3. **Given** the loading is in progress, **When** assets are streaming in, **Then** previously loaded tiles are visible and interactive before the full garden has finished rendering (progressive load, not a blocking all-or-nothing load).

---

### Edge Cases

- **App force-closed mid-save**: Atomic write semantics are required. The system writes to a temporary file first, then atomically renames it over the live save file only after the write is complete and verified. A partial write leaves the previous save file untouched.
- **Save data from an older format version**: The save file contains a `format_version` integer field. On load, if the version differs from the current version, a migration function is applied before the data is deserialised into the live garden state. Unknown future versions that are higher than the current parser version should surface a clear error rather than silently loading corrupt data.
- **No existing save on first launch**: If no save file exists (first install), the system initialises a fresh empty garden with a single Origin tile at (0,0) and creates a new save file. No error is shown to the player.
- **Storage full during save**: If the write fails due to insufficient device storage, the save is abandoned silently (the temporary file is deleted). A non-intrusive notification informs the player that the garden could not be saved and invites them to free storage space. The existing valid save file is not disturbed.
- **Save file corrupted or unreadable**: If the save file fails to parse (corrupted), the system falls back to a backup save file if one exists. If neither is readable, the player is offered the choice to start a new garden or contact support — the game does not silently wipe the save.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist the full tile grid (grid coordinate, biome type, locked state) to local device storage
- **FR-002**: System MUST persist the full discovery log including all Tier 1, Tier 2, and Tier 3 discoveries with their UTC discovery timestamps
- **FR-003**: System MUST persist all active spirit animal instances including type, spawn coordinate, and wander bounding box
- **FR-004**: System MUST auto-save all garden state after every 10 tile placements; the save MUST complete without causing a perceptible frame drop
- **FR-005**: System MUST trigger a save when the app transitions to the background (ApplicationFocused = false) or receives a system close signal
- **FR-006**: System MUST perform all save I/O on a background thread or deferred coroutine so that gameplay is not blocked during the write
- **FR-007**: System MUST restore all garden state (tiles, discoveries, spirits) on app launch and present the interactive garden to the player within 10 seconds for a 10,000-tile garden on reference mid-range hardware
- **FR-008**: Save files MUST include a `format_version` integer field; on load, the system MUST apply version migrations if the saved version differs from the current version
- **FR-009**: System MUST use atomic write semantics — write to a temporary file first, then rename atomically over the live save file — so that a failed write does not corrupt the existing save data

### Key Entities

- **SaveData**: `format_version` (int), `tile_array` (array of {coord, biome_type, locked}), `discovery_log` (array of {type, tier, timestamp}), `spirit_instances` (array of SpiritInstance), `last_saved_at` (UTC timestamp)
- **SaveOperation**: represents a single in-progress write; tracks write state (idle / writing / complete / failed); enforces that only one write is active at a time; exposes the atomic rename step as a single finalise call

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All tiles, discoveries, and spirits are present and correctly positioned after a clean app close and relaunch — verified by automated round-trip test comparing garden state before close to garden state after relaunch with zero discrepancies
- **SC-002**: Auto-save triggered by the 10th tile placement causes no perceptible frame drop — frame time during the save window does not exceed 16.7ms on the reference mid-range device
- **SC-003**: A garden with 10,000 tiles loads and is interactive (player can place a tile) within 10 seconds of cold app start on the reference mid-range mobile device
- **SC-004**: A save interrupted mid-write (simulated by injecting a write failure after 50% of bytes are written) leaves the previous valid save file fully intact and loadable, with no data corruption
