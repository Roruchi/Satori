# Implementation Plan: Biome Natural Materials and Harvesting

**Branch**: `023-biome-natural-materials` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/023-biome-natural-materials/spec.md`

## Summary

Introduce natural material spawning as a deterministic garden system: biomes and clusters produce visible harvestable material nodes, starting with Meadow -> Living Wood. Players actively harvest nodes into material inventory, while the system leaves hooks for Root Network speed boosts and Wind Chime auto-harvest.

## Technical Context

**Language/Version**: GDScript on Godot 4.6
**Primary Dependencies**: `src/grid/GardenView.gd`, `src/grid/PlacementController.gd`, `src/autoloads/GameState.gd`, `src/autoloads/seed_growth_service.gd`, `src/biomes/BiomeType.gd`, `src/spirits/spirit_service.gd`, future ritual material inventory
**Storage**: Existing save/autoload pattern; add persisted material inventory and material node state under `user://` or existing garden save payload
**Testing**: GUT for spawn rules, harvest mutation, caps and save/load serialization; manual in-editor validation for visuals and mobile interaction
**Target Platform**: Mobile-first Godot gameplay with desktop/editor parity
**Project Type**: Single-player Godot game system extension
**Performance Goals**: Material evaluation bounded by dirty clusters or timer batches; no all-garden full scan every frame
**Constraints**: Materials are harvested actively in early game; nodes never duplicate harvest; spawn rules deterministic; no undo/reset behavior
**Scale/Scope**: Starts with Living Wood from Meadow and data model for Reed Fiber, Spirit Stone and Ember Clay families. The first-session ritual loop must be testable without waiting for spirit-assistant work.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Plan maps to US1-US3 and FR-001..FR-015.
- **Godot-Native Fit**: PASS. Uses GDScript services, garden rendering and existing grid data.
- **Validation Strategy**: PASS. Spawn/harvest/persistence rules are automated; visual appeal and tap target quality are manual checks.
- **World Rule Safety**: PASS. Harvested materials become inventory history; transformed biomes do not erase already harvested outcomes.
- **Mobile Budgets**: PASS. Cluster caps and timer-based evaluation avoid per-frame heavy scans.
- **Guardrails**: PASS. Any new service must avoid autoload/class_name collision; serialization must use explicit `Variant` handling.

## Project Structure

### Documentation (this feature)

```text
specs/023-biome-natural-materials/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── material-spawn-harvest-contract.md
```

### Source Code (repository root)

```text
src/
├── autoloads/
│   └── material service or garden save extension
├── materials/
│   ├── MaterialInventory.gd
│   ├── MaterialNode.gd
│   └── BiomeMaterialDefinition.gd
├── grid/
│   ├── GardenView.gd
│   └── PlacementController.gd
├── biomes/
│   └── BiomeType.gd
└── ui/
    └── HUD/material inventory surfaces if needed

tests/
└── unit/
    └── materials/
```

**Structure Decision**: Add a small materials domain under `src/materials/` for data and pure logic. Rendering and interaction are integrated through `GardenView` and `PlacementController` so material nodes appear as part of the existing garden.

## Phase 0: Research Results

Research completed in [research.md](research.md):

1. Use deterministic material nodes rather than random ephemeral drops.
2. Use cluster anchors for expressive visuals and anti-clutter.
3. Persist material nodes and inventory separately from seed pouch.
4. Keep spawn evaluation timer-based and dirty-cluster aware.
5. Leave modifiers as explicit hooks for Root Network and Wind Chime.

No unresolved NEEDS CLARIFICATION items remain.

## Phase 1: Design and Contracts

Design artifacts produced:

1. [data-model.md](data-model.md): defines material definitions, nodes, inventory, clusters and modifiers.
2. [contracts/material-spawn-harvest-contract.md](contracts/material-spawn-harvest-contract.md): defines spawn and harvest invariants.
3. [quickstart.md](quickstart.md): provides test and manual visual validation.

## Phase 2: Implementation Strategy (for /speckit.tasks)

1. Add material IDs and material inventory.
2. Add biome material definitions for Meadow/Living Wood and placeholder-ready families for Reed Fiber, Spirit Stone and Ember Clay.
3. Add material spawn service or equivalent state owner.
4. Add deterministic cluster anchor selection.
5. Render Living Wood nodes and large Meadow tree landmarks in `GardenView`.
6. Add harvest interaction through `PlacementController` or interact-mode flow.
7. Persist material nodes and inventory.
8. Add hooks for Root Network spawn-speed modifier and Wind Chime auto-harvest.
9. Integrate Living Wood with the Warm Hollow ritual path from feature 022.
10. Run the first-session material gate: Meadow -> Living Wood -> Warm Hollow -> Meadow Dwelling -> housed Meadow spirit.
11. Add GUT coverage for spawn, cap, harvest, persistence and first-session material flow.
12. Update `specs/master/recipes.md` if material IDs or source mappings differ.

## Post-Phase 1 Constitution Re-check

- **Spec Traceability**: PASS.
- **Godot-Native Fit**: PASS.
- **Validation Strategy**: PASS.
- **World Rule Safety**: PASS.
- **Mobile Budgets**: PASS.
- **Guardrails**: PASS.

## Complexity Tracking

No constitution violations require justification.
