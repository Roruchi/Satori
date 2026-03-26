# Implementation Plan: Ku Tile Placement (Abyss Biome + Island System)

**Branch**: `copilot/implement-ku-tile-placement` | **Date**: 2026-03-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/copilot/implement-ku-tile-placement/spec.md`

## Summary

Add a standalone `KU` (abyss) biome tile that acts as a void separator between land masses. Implement connected-component island labelling (BFS flood-fill, Ku = wall) that assigns an `island_id` to every non-Ku tile after each placement. Scope spirit summoning per island so the same spirit can appear on multiple isolated islands.

## Technical Context

**Language/Version**: GDScript 4 (Godot 4.6)  
**Primary Dependencies**: Godot engine built-ins; GUT addon for automated tests  
**Storage**: In-memory `Dictionary` in GridMap; serialised via SpiritPersistence JSON  
**Testing**: GUT (addons/gut/) — headless: `godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit`  
**Target Platform**: Mobile-first (iOS/Android), desktop secondary  
**Project Type**: Mobile/desktop garden game (Godot 4 project)  
**Performance Goals**: Stable 60 fps; island recomputation < 1 ms for gardens ≤ 500 tiles  
**Constraints**: No undo/reset (permanent-placement rule); Ku tile cannot be mixed  
**Scale/Scope**: Single-session garden; up to ~500 tiles in typical play

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: ✅ Work is rooted in `specs/copilot/implement-ku-tile-placement/spec.md`. All tasks will be traceable to US1 (place Ku tile), US2 (island isolation), or US3 (per-island spirit spawning).
- **Godot-Native Fit**: ✅ All logic lives in `src/` (GDScript). GridMap.gd extended with island tracking. SpiritPersistence and SpiritService updated. No external dependencies added. BiomeType.gd extended with one new enum value.
- **Validation Strategy**: GUT tests in `tests/unit/` cover (a) island-ID assignment after BFS, (b) per-island spirit summoning guard. Manual in-editor validation: place Ku tiles to split the garden and confirm island colours differ.
- **World Rule Safety**: Permanence rule preserved — Ku tile is placed like any other biome and cannot be mixed. Island IDs are derived from the immutable grid state so they are deterministic. SpiritPersistence key format changes are additive; old global keys are still valid for single-island saves.
- **Mobile Budgets**: BFS runs once per tile placement, O(n) where n = total tile count. For 500 tiles this is < 1 ms. No UI layout changes beyond surfacing the Ku biome in the tile selector. Accessibility settings are unaffected.
- **Guardrails**: No new autoload is added. The island-labelling logic is a method on GridMap (an existing non-autoload RefCounted). No class_name conflicts introduced. All `Dictionary.get()` calls use explicit `int`/`String` casts to avoid Variant-inferred `:=` pitfalls.

## Project Structure

### Documentation (this feature)

```text
specs/copilot/implement-ku-tile-placement/
├── plan.md              # This file
├── research.md          # Phase 0 — design decisions
├── data-model.md        # Phase 1 — entity shapes
├── quickstart.md        # Phase 1 — manual validation guide
├── contracts/           # Phase 1 — island-id contract
└── tasks.md             # Phase 2 — ordered task list (/speckit.tasks)
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   ├── GameState.gd           (no change — place_tile already emits signal)
│   └── spirit_persistence.gd  (CHANGE — island-keyed summoning records)
├── biomes/
│   └── BiomeType.gd           (CHANGE — add KU = 14)
├── grid/
│   ├── GridMap.gd             (CHANGE — add compute_island_ids(), get_island_id())
│   └── TileData.gd            (CHANGE — document island_id in metadata comment)
├── spirits/
│   ├── spirit_instance.gd     (CHANGE — add island_id field, update serialize/deserialize)
│   └── spirit_service.gd      (CHANGE — per-island active-instance key, island-aware spawn guard)
└── ui/
    └── TileSelector.gd        (CHANGE — expose KU when unlocked, add KU colour hint)

scenes/
└── UI/
    └── TileSelector.tscn      (possible CHANGE — if hardcoded biome count)

tests/
└── unit/
    ├── test_island_labelling.gd      (NEW — GUT coverage for FR-004/FR-005/FR-006)
    └── test_spirit_island_scope.gd   (NEW — GUT coverage for FR-007/FR-008/FR-009)

specs/copilot/implement-ku-tile-placement/
└── ...feature artifacts...
```

**Structure Decision**: All changes are additive — one new enum value, new methods on existing classes, updated key format in persistence. No new autoloads. Two new GUT test files cover the two non-trivial algorithmic requirements (island BFS and per-island spirit guard).

## Complexity Tracking

> No constitution violations detected — no entries needed.
