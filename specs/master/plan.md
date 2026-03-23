# Implementation Plan: Satori — Full Game

**Branch**: `master` | **Date**: 2026-03-23 | **Spec**: `specs/master/spec.md`
**Input**: Feature specification from `specs/master/spec.md`

---

## Summary

Build *Satori: The Constant Garden* — a Godot 4.6 mobile-first zen tile-placement game — from an empty project to a fully playable release candidate. The architecture follows 13 incremental, independently-testable features that compose from a grid foundation upward through pattern matching, biome alchemy, voxel rendering, audio, and persistence. Every feature adds testable value and is enabled by a dedicated debug/test harness (F01).

---

## Technical Context

**Language/Version**: GDScript 2.0 (Godot 4.6)
**Primary Dependencies**: Godot 4.6 engine (Jolt Physics, Forward Plus renderer); no external packages
**Storage**: Binary or compressed-JSON file in `user://` (Godot's user data path)
**Testing**: GdUnit4 (Godot unit testing framework); manual playtesting via F01 debug scene
**Target Platform**: Mobile-first (iOS 16+ / Android 12+); desktop editor for development
**Project Type**: Mobile game (single-player, no network)
**Performance Goals**: Stable 60 fps on mid-range mobile; pattern scan ≤16 ms for ≤1,000 tiles; app launch ≤10 s
**Constraints**: No undo/reset in production build; chunk-based world partitioning (16×16 tiles); <200 MB RAM budget
**Scale/Scope**: Infinite garden (unbounded coordinates); 13 biome types; 52 discovery definitions; 30 spirit animals

---

## Constitution Check

*Constitution file is currently a blank template — no project-specific principles have been ratified. No gates apply. This section should be revisited once `/speckit.constitution` is run to establish project principles.*

**Status**: PASS (no active constraints to violate)

---

## Project Structure

### Documentation (this feature)

```text
specs/master/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
# Godot 4 project layout
project.godot

src/
├── autoloads/
│   ├── GameState.gd          # Singleton: garden data, save/load, discovery log
│   ├── PatternEngine.gd      # Singleton: background pattern scan, signals
│   └── AudioManager.gd       # Singleton: ambient soundscape blending
├── grid/
│   ├── TileData.gd           # Value type: coord, biome, locked, metadata
│   ├── ChunkManager.gd       # 16×16 chunk load/unload
│   └── GridMap.gd            # O(1) coord→TileData lookup (Dictionary wrapper)
├── biomes/
│   ├── BiomeType.gd          # Enum + static mixing table
│   └── BiomeRegistry.gd      # Mesh, audio, palette lookups per biome
├── patterns/
│   ├── PatternDefinition.gd  # Resource: declarative pattern spec
│   ├── ClusterMatcher.gd     # Flood-fill cluster detection
│   ├── ShapeMatcher.gd       # Geometric shape recipes
│   └── DiscoveryRegistry.gd  # All 52 discovery definitions
├── entities/
│   └── SpiritAnimal.gd       # Autonomous wandering entity base class
├── ui/
│   ├── TileSelector.gd       # Bottom-corner tile pick UI
│   ├── DiscoveryNotification.gd
│   └── SettingsScreen.gd
├── rendering/
│   ├── TileMeshInstancer.gd  # Per-tile voxel mesh placement
│   ├── BitmaskAutotiler.gd   # Neighbour bitmask → mesh variant
│   └── MountainMerger.gd     # Stone cluster collapse → Mountain mesh
└── debug/
    ├── DebugOverlay.gd       # Coordinate/chunk labels
    ├── FloodFill.gd          # Instant garden seeding tool
    └── PatternVisualizer.gd  # Highlight discovery-qualifying tiles

scenes/
├── Main.tscn                 # Root scene
├── Garden.tscn               # TileMap + camera + input handler
├── Debug.tscn                # Debug harness (strips from export)
├── UI/
│   ├── HUD.tscn
│   ├── Discovery.tscn
│   └── Settings.tscn
└── Entities/
    └── SpiritAnimal.tscn

tests/                        # GdUnit4 test suites
├── test_grid.gd
├── test_alchemy.gd
├── test_pattern_engine.gd
├── test_discoveries_tier1.gd
├── test_discoveries_tier2.gd
├── test_spirits.gd
└── test_persistence.gd
```

**Structure Decision**: Single Godot project. `src/` holds GDScript logic; `scenes/` holds `.tscn` compositions. Autoloads for cross-cutting singletons. Tests in `tests/` via GdUnit4. Debug scenes excluded from export via export presets.

---

## Complexity Tracking

*No constitution violations — section left blank.*

---

## Phase 0: Research Findings

*See `research.md` for full details. Summary:*

| Decision | Rationale |
|----------|-----------|
| Square axial grid (Vector2i) | Godot's built-in TileMap uses square; simpler coordinate math; the game's visual style (voxel diorama) suits orthographic squares more than hex |
| GdUnit4 for testing | Most mature Godot 4 unit testing framework; integrates with CI; supports GDScript |
| Dictionary-based grid storage | O(1) lookup; sparse (only placed tiles stored); serialises trivially to JSON |
| Chunking via Dictionary of Dictionaries | `chunks[chunk_coord][local_coord]` — natural fit for Godot's node tree; no external spatial index needed at projected scale |
| Deferred thread via `Thread` + `Mutex` | Godot 4 supports threads; pattern scan dispatched to worker thread, results sent back via `call_deferred` to avoid race conditions |
| Binary save via `FileAccess` + `var_to_bytes` | Godot 4 native; fast; no external serialisation library needed |
| GodotJolt already enabled | Jolt Physics configured in `project.godot`; no physics toggle required |
| Forward Plus renderer | Already set; suitable for voxel diorama aesthetic on mobile |

---

## Phase 1: Design Artifacts

*See `data-model.md` for entity schemas and `quickstart.md` for how to run the project.*
