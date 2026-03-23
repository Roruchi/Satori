# Feature Spec: Satori — Full Game Implementation

**Branch**: `master` | **Date**: 2026-03-23
**Source**: `Satori_ Comprehensive Game Design and Technical Implementation Report.md`

---

## Overview

*Satori: The Constant Garden* is a mobile-first zen garden builder built in Godot 4.6. Players place tiles that grow an infinite, permanent biome landscape. Every action is irreversible ("Permanent Emergence"). Discoveries — biome clusters, landmarks, and spirit animals — are triggered by spatial pattern matching. The game is designed for calm, meditative engagement with no HUD and no resets.

---

## High-Level Features

### F01 · Dev Tooling & Test Harness *(Enablement)*

A debug scene and tooling layer that allows rapid testing of all subsequent features without going through normal game flow.

**Requirements:**
- Debug overlay scene showing tile coordinates, biome labels, chunk boundaries
- Instant placement mode (bypass long-press timer)
- Tile flood-fill tool to seed the garden quickly for testing
- Pattern visualizer: highlight tiles participating in any active discovery check
- Console log panel showing discovery trigger events
- Toggleable via a keypress in-editor (never ships in release build)

**Testable when:** Debug scene launches, tile grid is visible, instant placement works, pattern events appear in log.

---

### F02 · Infinite Grid Engine *(Foundation)*

A coordinate-based tile grid that expands without bounds, partitioned into 16×16 chunks for memory efficiency.

**Requirements:**
- Square axial coordinate system using `Vector2i` coordinates
- `TileData` value type: `{ coord: Vector2i, biome: BiomeType, locked: bool, metadata: Dictionary }`
- Chunk manager: loads/unloads chunks as the camera viewport moves; only active chunks held in memory
- O(1) tile lookup by coordinate
- Coordinate origin (0, 0) is the "Origin Tile" — the only tile that can be placed without adjacency
- No maximum garden size

**Testable when:** Tiles can be placed at arbitrary coordinates across chunk boundaries; chunks load and unload correctly; performance stays ≥60 fps with 10,000+ placed tiles.

---

### F03 · Tile Placement & Organic Adjacency

The core interaction model: long-press to plant, strict adjacency rules, irreversible placement.

**Requirements:**
- Four base tile types: **Forest, Water, Stone, Earth/Sand**
- Long-press detection: 300–400 ms hold triggers placement intent; tap/scroll is ignored
- Adjacency validation: placement only legal on tiles neighboring an existing tile (except Origin)
- Highlight valid placement zones on long-press-start
- No undo, no clear — placement is permanent
- Origin tile auto-placed at (0,0) on new garden creation
- Mobile thumb-zone UI: tile selector accessible from bottom corners of screen

**Testable when:** Long-press places tiles; invalid placements are rejected; valid zone highlight appears; Origin is auto-placed.

---

### F04 · Biome Alchemy — Mixing & Locking

Players can layer a second base tile onto an existing tile to produce a hybrid biome. The result is permanently locked.

**Requirements:**
- Mixing matrix (all 6 hybrid combos):
  - Forest + Water → Swamp
  - Stone + Water → Tundra
  - Earth + Water → Mudflat
  - Forest + Stone → Mossy Crag
  - Forest + Earth → Savannah
  - Stone + Earth → Canyon
- Long-pressing a new base tile onto an existing **unlocked** base tile triggers the merge
- Result tile is marked `locked = true`; no further mixing allowed
- Visual/haptic feedback distinguishes a "mix" action from a "place" action
- Locked tiles display a distinct visual treatment

**Testable when:** All 6 mixing combos produce correct biome; locking prevents re-mixing; UI feedback fires.

---

### F05 · Pattern Matching Engine

A background scan that evaluates spatial patterns after every tile placement and fires discovery events.

**Requirements:**
- Runs asynchronously (thread or deferred) so it never blocks the 60 fps render loop
- Pattern types supported:
  - **Cluster** — contiguous region of biome type(s) meeting size/purity conditions
  - **Shape** — specific geometric configuration (line, ring, cross, U, enclosure)
  - **Ratio/Proximity** — tile at center surrounded by required neighbors at specific ratios
  - **Distance** — tile within N steps of a named landmark or cluster
- Pattern registry: data-driven definitions (not hard-coded per-discovery)
- Emits `discovery_triggered(discovery_id: String, triggering_tiles: Array[Vector2i])` signal
- Idempotent: re-scanning the same state does not fire duplicate events

**Testable when:** Known configurations reliably fire their expected discovery signals; no duplicates; placing 10 Stone tiles triggers the Mountain cluster event; scan completes in <16 ms on a 1,000-tile garden.

---

### F06 · Tier 1 — Biome Cluster Discoveries *(Builds on F05)*

The 12 Sub-Discovery biome clusters, each with a unique ambient audio bed trigger.

**Discoveries (abbreviated):**
1. The River — 10+ tiles, 1-wide Water line
2. The Deep Stand — 10+ Forest, no adjacent Stone
3. The Glade — 1 Earth surrounded by 6 Forest
4. Mirror Archipelago — 5+ alternating Water/Sand pairs
5. Barren Expanse — 25+ Earth, no Water nearby
6. Great Reef — 15 Water with 3 non-adjacent Stone inside
7. Lotus Pond — Water enclosed by Earth then by Forest
8. The Mountain Peak — 10th contiguous Stone tile
9. Boreal Forest — 5 Forest + 5 Tundra interwoven
10. The Peat Bog — 20+ Swamp tiles
11. Obsidian Expanse — Canyon surrounded by Water
12. The Waterfall — River touching Mountain Peak edge

**Requirements:**
- Each discovery registered as a pattern definition in the F05 registry
- Discovery notification: text pop-in with discovery name + flavor text, auto-dismiss after 4 s
- Trigger corresponding audio bed (audio asset placeholder acceptable at this stage)
- Once discovered, marked in a persistent discovery log

**Testable when:** All 12 configurations reliably trigger their events in the debug scene (F01 flood-fill seeding).

---

### F07 · Tier 2 — Structural Landmark Discoveries *(Builds on F05)*

10 geometric "recipe" landmarks triggered by specific tile shapes.

**Landmarks:**
1. Origin Shrine — cross (+) of Water with Stone at (0,0)
2. Bridge of Sighs — 3-tile Stone line spanning Water
3. Lotus Pagoda — 2×2 square of Mixed Swamp tiles
4. Monk's Rest — 1 Earth fully enclosed by 6 Forest
5. Star-Gazing Deck — 1 Stone atop a 20+ Mountain cluster
6. Sun-Dial — 5 Sand in a ring with Stone center
7. Whale-Bone Arch — U-shape of 5 Sand+Stone
8. Echoing Cavern — 3×3 Stone ring with empty center
9. Bamboo Chime — 5-tile line of Forest+Sand
10. Floating Pavilion — Water/Forest mix tile isolated from land

**Requirements:**
- Shape-matching algorithms: line, ring, cross, U, enclosure, isolation
- Discovery notification same as F06
- Landmarks may unlock decorative visual overlays on affected tiles (placeholder mesh acceptable)

**Testable when:** All 10 shape recipes fire in the debug scene.

---

### F08 · Tier 3 — Spirit Animal System *(Builds on F06 + F07)*

30 autonomous spirit entities summoned by complex multi-variable conditions.

**Requirements:**
- Condition engine extends F05 pattern registry with compound rules (e.g., "within a named cluster" + "adjacent to a landmark")
- Spirit spawn: instantiate autonomous scene with idle wandering behaviour within their triggering region
- Discovery revealed as a riddle (shown before discovery is complete); answer revealed on trigger
- Spirits persist in the garden and remain visible as the camera pans
- Sky-Whale (spirit #30): requires 1,000 total tiles with balanced biome ratios (special macro check)
- All 30 spirit definitions data-driven (resource files or JSON)

**Testable when:** Each spirit's condition can be seeded via F01 tooling and the spirit spawns + wanders correctly.

---

### F09 · Voxel Rendering & Mesh Merging *(Builds on F02 + F04)*

Per-tile voxel mesh instantiation, bitmask autotiling for texture blending, and cluster mesh collapse.

**Requirements:**
- Each placed tile instantiates a biome-appropriate voxel mesh (placeholder meshes acceptable initially)
- Bitmask autotiling: evaluate 6 (hex) or 4/8 (square) neighbours → select correct edge/corner texture variant
- Mountain Growth: when a Stone cluster reaches 10+ contiguous tiles, individual voxel meshes collapse into a single unified Mountain mesh (procedural or pre-authored)
- LOD: tiles beyond camera viewport + N chunks are reduced or culled
- Colorblind-friendly palette per biome (high-contrast variant toggle)

**Testable when:** Placing tiles shows correct mesh; tile texture updates when neighbours change; 10 connected Stone tiles produce a Mountain mesh; no visible mesh pop at chunk boundaries.

---

### F10 · Camera & Mobile Navigation *(Builds on F02)*

Touch-first camera with momentum panning, zoom, and thumb-zone layout.

**Requirements:**
- Drag-to-pan with momentum (velocity decays after finger lift)
- Pinch-to-zoom (min/max zoom limits)
- Double-tap to re-centre on Origin
- Camera bounds: soft-clamp at garden edge with resistance (never hard-locks)
- Haptic feedback on tile placement and discovery (toggleable in settings)
- UI elements confined to thumb-reachable bottom corners on phone aspect ratios

**Testable when:** Pan, zoom, and re-centre work on device/simulator; haptic toggle works; UI is reachable in thumb zone.

---

### F11 · Ambient Soundscape System *(Builds on F06)*

Per-biome audio layers with proximity blending as the camera moves.

**Requirements:**
- Each macro-biome and Tier 1 discovery has an assigned audio bus/track
- Blending algorithm: sample biome ratios within camera viewport radius; crossfade bus volumes each frame
- Smooth fade: no abrupt audio cuts when panning
- Master volume, mute toggle
- Discovery audio stinger plays once on discovery trigger, then fades to ambient

**Testable when:** Panning from Forest to Water area smoothly crossfades audio; discovery stingers play once; mute works.

---

### F12 · Garden Persistence — Save & Load *(Builds on F02)*

Serialise and restore the full garden state across sessions.

**Requirements:**
- Save format: binary or compressed JSON of `{ coord → TileData }` for all placed tiles + discovery log
- Auto-save: after every N tile placements (configurable, default 10) and on app background/close
- Load on startup: restore last garden state within 10 s target launch time
- Single-garden model (no multi-save slots required at this stage)
- Migration: forward-compatible format versioning for future tile type additions

**Testable when:** Garden survives app restart; discovery log persists; large gardens (10,000 tiles) save/load within target time.

---

### F13 · Accessibility & Settings Screen *(Builds on F10)*

User-facing settings and accessibility options.

**Requirements:**
- Haptic intensity: Off / Low / Full
- High-contrast colorblind palette toggle (activates F09 palette variant)
- Master volume slider + mute
- Sound effects vs. ambient music independent toggles
- Settings persisted to a separate config file (not bundled with garden save)
- Settings accessible from a minimal floating button (always in thumb zone)

**Testable when:** All toggles persist across restarts; high-contrast mode visually changes tile colours; haptic toggle suppresses vibration.

---

## Feature Dependency Graph

```
F01 (Dev Tooling)
  └─ used to test all features

F02 (Infinite Grid)
  ├─ F03 (Tile Placement)
  │   └─ F04 (Alchemy/Mixing)
  │       └─ F09 (Voxel Rendering)
  ├─ F10 (Camera)
  │   └─ F13 (Settings)
  └─ F12 (Persistence)

F05 (Pattern Matching)
  ├─ F06 (Tier 1 Discoveries)
  │   └─ F08 (Spirit Animals) ← also needs F07
  │   └─ F11 (Soundscape)
  └─ F07 (Tier 2 Landmarks)
      └─ F08 (Spirit Animals)
```

## User Stories and Implementation State

### User Story 1 - Developer Harness for Fast Validation (Priority: P1)

As a developer, I can run a debug harness with placement and discovery instrumentation so that downstream gameplay features can be validated quickly.

**Why this priority**: Every later feature depends on fast repeatable setup and visibility.

**Independent Test**: Launch debug scene, toggle overlay and instant placement, seed tiles, and verify discovery events in the debug log.

**Acceptance Scenarios**:

1. **Given** the debug scene is running, **When** I press the debug toggle key, **Then** overlay visibility toggles without changing gameplay state.
2. **Given** debug flood-fill is enabled, **When** I seed an area, **Then** placed tiles appear and discovery checks execute.

### User Story 2 - Infinite Sparse Grid Foundation (Priority: P1)

As a player, I can expand the garden in any direction without hard bounds so that the world feels truly unbounded.

**Why this priority**: All gameplay systems depend on stable coordinate storage and retrieval.

**Independent Test**: Place and retrieve tiles across negative and large coordinates while maintaining O(1) lookups and valid chunk lifecycle.

**Acceptance Scenarios**:

1. **Given** a new garden, **When** tiles are placed across multiple chunk boundaries, **Then** data retrieval remains correct.
2. **Given** camera movement across distant regions, **When** chunks leave the active radius, **Then** inactive chunks unload.

### User Story 3 - Intentional Placement and Adjacency (Priority: P1)

As a player, I place tiles with intentional input and adjacency rules so that growth remains structured and permanent.

**Why this priority**: This defines the core interaction loop and permanence model.

**Independent Test**: Long-press valid adjacent cells places tiles; invalid/non-adjacent attempts are rejected with feedback.

**Acceptance Scenarios**:

1. **Given** an adjacent empty coordinate, **When** long-press input completes, **Then** a tile is placed.
2. **Given** a non-adjacent coordinate, **When** I attempt placement, **Then** placement is rejected.

### User Story 4 - Biome Alchemy and Locking (Priority: P1)

As a player, I can merge base biomes once to create hybrids so that choices are meaningful and irreversible.

**Why this priority**: Alchemy is a central differentiator and prerequisite for discovery content.

**Independent Test**: All six valid base pair combinations produce the expected hybrid and lock state.

**Acceptance Scenarios**:

1. **Given** an unlocked base tile and a valid second base tile, **When** I perform a mix action, **Then** the expected hybrid biome is created and marked locked.

### User Story 5 - Deterministic Pattern Engine (Priority: P1)

As the game system, I scan for pattern matches asynchronously and idempotently so that discoveries are correct and performance-safe.

**Why this priority**: Discovery tiers and several NFR targets depend on this engine.

**Independent Test**: Cluster, shape, ratio/proximity, and distance patterns trigger expected events once and complete within frame budget.

**Acceptance Scenarios**:

1. **Given** a garden state that satisfies a known pattern, **When** the scan runs, **Then** one discovery event is emitted exactly once with deterministic triggering tiles.

### User Story 6 - Tier 1 Discovery Content (Priority: P1)

As a player, I receive Tier 1 discovery feedback and persistence so that exploration feels rewarding and trackable.

**Independent Test**: Seed each Tier 1 pattern and verify one-time trigger, notification, and log persistence.

**Acceptance Scenarios**:

1. **Given** an undiscovered Tier 1 pattern, **When** the player completes it, **Then** a notification appears once and the discovery is persisted.

### User Story 7 - Tier 2 Landmark Content (Priority: P1)

As a player, I can create geometric landmarks that trigger once and annotate the world visually.

**Independent Test**: Build each landmark shape once and verify trigger, log entry, and overlay marker.

**Acceptance Scenarios**:

1. **Given** a valid landmark geometry, **When** the shape is completed, **Then** the landmark discovery triggers once and overlays are rendered on relevant tiles.

### User Story 8 - Spirit Animal System (Priority: P1)

As a player, I unlock spirits from compound conditions and see them persist in the garden.

**Independent Test**: Trigger representative spirits (including Sky-Whale) and confirm one-time spawn plus restart persistence.

**Acceptance Scenarios**:

1. **Given** a satisfied spirit condition set, **When** discovery resolves, **Then** the corresponding spirit spawns once and remains present after reload.

### User Story 9 - Voxel Rendering and Merge Behavior (Priority: P1)

As a player, I see biome-aware tile visuals, autotiling transitions, and mountain merges at cluster thresholds.

**Independent Test**: Neighbor updates refresh visuals and 10+ Stone cluster merges into mountain representation.

**Acceptance Scenarios**:

1. **Given** connected Stone tiles reach the merge threshold, **When** the render update runs, **Then** the cluster is represented as mountain output without visual seams.

### User Story 10 - Mobile Camera Navigation (Priority: P1)

As a mobile player, I can pan, zoom, and recenter smoothly without accidental placement.

**Independent Test**: Drag, pinch, and double-tap interactions coexist with placement suppression.

**Acceptance Scenarios**:

1. **Given** touch navigation input, **When** the player pans and pinches, **Then** camera movement is smooth and tile placement is not triggered accidentally.

### User Story 11 - Ambient Soundscape Blending (Priority: P1)

As a player, I hear smooth biome-driven ambient transitions and one-time discovery stingers.

**Independent Test**: Move camera between biome regions and verify smooth crossfade and stinger queue behavior.

**Acceptance Scenarios**:

1. **Given** the camera crosses biome-dominant regions, **When** ambient mixing updates, **Then** track levels crossfade smoothly and discovery stingers play once.

### User Story 12 - Reliable Garden Persistence (Priority: P1)

As a returning player, I can restart and recover complete garden state quickly and safely.

**Independent Test**: Save/load round trip restores tiles, discoveries, and spirits with version-safe schema handling.

**Acceptance Scenarios**:

1. **Given** a non-trivial garden state, **When** the game is saved and restarted, **Then** all persisted gameplay entities reload consistently and schema version checks pass.

### User Story 13 - Accessibility and Settings (Priority: P1)

As a player, I can configure haptics, palette, and audio settings and keep them across restarts.

**Independent Test**: Settings apply immediately and persist in dedicated config storage.

**Acceptance Scenarios**:

1. **Given** updated accessibility and audio settings, **When** the player resumes later, **Then** settings are restored and applied without affecting garden save data.

### Story State Checklist

| Story | Feature | State | Evidence | Related Tasks | Last Checked |
|-------|---------|-------|----------|---------------|--------------|
| US1 | F01 Dev Tooling Harness | Not started | - | T010-T013 | 2026-03-23 |
| US2 | F02 Infinite Grid Engine | Not started | - | T014-T017 | 2026-03-23 |
| US3 | F03 Placement and Adjacency | Not started | - | T018-T021 | 2026-03-23 |
| US4 | F04 Biome Alchemy Mixing | Partially implemented | Existing 004 task set and runtime scripts | T022-T024 | 2026-03-23 |
| US5 | F05 Pattern Matching Engine | Mostly implemented | Existing 005 task set and pattern tests | T025-T029 | 2026-03-23 |
| US6 | F06 Tier 1 Discoveries | Not started | - | T030-T033 | 2026-03-23 |
| US7 | F07 Tier 2 Landmarks | Not started | - | T034-T037 | 2026-03-23 |
| US8 | F08 Spirit Animals | Not started | - | T038-T041 | 2026-03-23 |
| US9 | F09 Voxel Rendering | Not started | - | T042-T045 | 2026-03-23 |
| US10 | F10 Camera Mobile Nav | Partially implemented | Existing 010 US1 work and camera controller | T046-T049 | 2026-03-23 |
| US11 | F11 Ambient Soundscape | Not started | - | T050-T053 | 2026-03-23 |
| US12 | F12 Persistence | Not started | - | T054-T057 | 2026-03-23 |
| US13 | F13 Accessibility Settings | Not started | - | T058-T061 | 2026-03-23 |

### NFR Validation Checklist

- [ ] Launch time under 10 seconds validated on representative target profile
- [ ] Pattern scan under 16 ms validated for ~1,000 tiles
- [ ] Memory under 200 MB validated at stress target
- [ ] No-reset invariant validated in production build
- [ ] Debug tooling excluded from release build validation completed

## Edge Cases

- Corrupted or partially written save file: game starts safely, reports recoverable error, and preserves previous valid snapshot when available.
- Startup budget breach risk on large gardens: app still reaches a playable state with staged loading and visible status feedback.
- Memory pressure during large placement bursts: chunk eviction/deferred work prevents runaway memory growth.
- Missing or invalid audio assets: gameplay continues with silent fallback instead of runtime failure.
- Release export includes debug assets by mistake: build validation fails until debug scene/scripts/keybinds are excluded.

## Non-Functional Requirements (Cross-Cutting)

| Concern | Target |
|---------|--------|
| Frame rate | Stable 60 fps on mid-range mobile (iPhone 13 equivalent) |
| Launch time | Core gameplay reachable within 10 s |
| Pattern scan | Completes within 1 render frame (≤16 ms) for gardens up to ~1,000 tiles |
| Memory | Chunk unloading keeps active tile count reasonable; target <200 MB RAM |
| No-reset invariant | Platform-level: no undo/clear in production build |
