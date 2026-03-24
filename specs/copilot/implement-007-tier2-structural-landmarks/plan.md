# Implementation Plan: Feature 007 — Tier 2 Structural Landmark Discoveries

**Branch**: `copilot/implement-007-tier2-structural-landmarks` | **Date**: 2026-03-24 | **Spec**: `specs/007-tier2-structural-landmarks/spec.md`

## Summary

Tier 2 Structural Landmarks are ten named geometric recipes that trigger a discovery notification when a player constructs the required tile arrangement. Once discovered, the contributing tiles display a unique visual overlay. Each landmark fires at most once per garden. The implementation extends the existing Pattern Matching Engine (Feature 005) and Tier 1 Discovery Pipeline (Feature 006) with three new shape-recipe constraint types (`must_be_empty`, `absolute_anchor`, forbidden-neighbour), 19 new `.tres` pattern resources, catalog entries for 10 new discoveries, and 10 new overlay drawing functions in `GardenView`.

## Technical Context

**Language/Version**: GDScript 4.6 (Godot 4.6)
**Primary Dependencies**: Godot 4.6 engine, GUT test framework
**Storage**: Existing `DiscoveryLog` / `DiscoveryPersistence` — no schema changes
**Testing**: GUT (`tests/unit/`)
**Target Platform**: Mobile-first (Android / iOS), also desktop
**Project Type**: Godot 4 game (mobile-first)
**Performance Goals**: Pattern scan < 16 ms per placement on mid-range mobile
**Constraints**: No new autoloads; Variant-safe typing throughout
**Scale/Scope**: 10 new landmarks; 19 new `.tres` files; ~400 lines of GDScript changes

## Constitution Check

- **Spec Traceability**: Rooted in `specs/007-tier2-structural-landmarks/spec.md`. All tasks trace to the four user stories.
- **Godot-Native Fit**: All code in GDScript under `src/`; no new autoloads; `project.godot` unchanged.
- **Validation Strategy**: GUT unit tests cover all 10 landmark triggers, duplicate suppression, and three new constraint types. Manual verification via in-editor play (F5).
- **World Rule Safety**: Discovery is deterministic and additive. Permanence model unchanged. `forbidden_biomes` repurposed from currently-unused state — no existing `.tres` affected.
- **Mobile Budgets**: 19 new patterns add constant overhead per scan; no render budget change beyond 10 new overlay draw calls already batched in `_draw()`.
- **Guardrails**: No `class_name` conflicts; explicit types used for all new GDScript paths.

## Project Structure

### Documentation (this feature)

```text
specs/copilot/implement-007-tier2-structural-landmarks/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
src/
├── biomes/
│   ├── discovery_catalog_data.gd      # add get_tier2_entries()
│   ├── discovery_catalog.gd           # load tier2 entries
│   ├── matchers/
│   │   └── shape_matcher.gd           # absolute_anchor + forbidden_biomes
│   └── patterns/
│       └── tier2/                     # 19 new .tres files
└── grid/
    ├── GardenView.gd                  # 10 new overlay functions
    └── spatial_query.gd               # must_be_empty + absolute_anchor

tests/
└── unit/
    └── test_tier2_landmark_discoveries.gd
```

## Complexity Tracking

No constitution violations. All changes are additive extensions to existing machinery.
