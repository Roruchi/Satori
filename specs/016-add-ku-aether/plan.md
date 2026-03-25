# Implementation Plan: Mixable Ku Recipes

**Branch**: `016-add-ku-aether` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/016-add-ku-aether/spec.md`

## Summary

Add four playable Ku pair recipes (Chi+Ku, Sui+Ku, Ka+Ku, Fu+Ku) and connect them to four new Ku biomes, four direct Shinto deity spirit discoveries, and four worship-structure discoveries, while keeping Ku unlock behavior tied to the existing Mist Stag summon path. The plan also adds codex guidance that names Mist Stag and points players toward the unlock direction without exposing numeric checklist thresholds in pre-unlock text.

Specific unlock conditions included in scope:
- Ku element unlock remains triggered by Mist Stag summon gift (`gift_type = KU_UNLOCK`).
- Mist Stag summon remains gated by pattern `spirit_mist_stag`: BOG cluster (`required_biomes = [8]`) with `size_threshold = 5` and prerequisite discovery `disc_deep_stand`.
- `disc_deep_stand` remains gated by MEADOW cluster (`required_biomes = [3]`) with `size_threshold = 10` and forbidden biome EMBER_FIELD (`forbidden_biomes = [2]`).

## Technical Context

**Language/Version**: GDScript on Godot 4.6  
**Primary Dependencies**: Godot runtime only; GUT test framework in `addons/gut`  
**Storage**: Existing JSON persistence files under `user://`; no new persistence guarantees added in this feature  
**Testing**: GUT unit tests plus manual in-editor and debug-harness checks  
**Target Platform**: Mobile-first (Android/iOS), desktop-compatible development builds  
**Project Type**: Single-player Godot game feature extension  
**Performance Goals**: Preserve 60 fps behavior and current pattern-scan responsiveness  
**Constraints**: No changes to permanence rules; Ku pre-unlock codex hint must avoid exact numeric thresholds; maintain existing save/load behavior  
**Scale/Scope**: 4 new Ku recipes, 4 new Ku biomes, 4 new deity spirits, 4 new structures, codex unlock hint updates, matching tests

## Constitution Check

*GATE: Pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. All planned changes map directly to US1-US3 and FR-001..FR-017 in the feature spec.
- **Godot-Native Fit**: PASS. Changes stay in `src/`, `scenes/`, `tests/`, and resource `.tres` assets; no non-Godot architecture introduced.
- **Validation Strategy**: PASS. Add GUT coverage for Ku recipes/unlock wiring and manual checks for codex hint UX and discovery chaining.
- **World Rule Safety**: PASS. No permanence or reset-rule changes. Explicitly preserves current persistence behavior (FR-015).
- **Mobile Budgets**: PASS. Scope adds content data and existing flow wiring, with no new per-frame systems.
- **Guardrails**: PASS. Continue preload-based typed dependencies, avoid autoload/class_name collisions, and keep explicit typing around Variant-returning APIs.

## Project Structure

### Documentation (this feature)

```text
specs/016-add-ku-aether/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── ku-unlock-and-recipes.md
│   └── ku-content-mapping.md
└── tasks.md  # generated later by /speckit.tasks
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   ├── seed_alchemy_service.gd         # recipe lookup/unlock path behavior
│   └── codex_service.gd                # Ku hint and discovery state presentation
├── biomes/
│   ├── BiomeType.gd                    # confirms Ku biome enum mapping
│   ├── pattern_catalog_data.gd         # new structure discovery metadata
│   └── patterns/
│       ├── spirits/                    # 4 new deity pattern definitions
│       └── tier2/ or tier3/            # 4 new worship structure patterns
├── codex/
│   └── entries/                        # seed/biome/spirit/structure hint/full entries
├── seeds/
│   ├── SeedRecipeRegistry.gd
│   └── recipes/                        # add 4 Ku recipe resources
├── spirits/
│   ├── spirit_catalog_data.gd          # 4 deity entries + gifts if needed
│   └── SpiritGiftProcessor.gd
└── ui/
    └── SeedAlchemyPanel.gd             # Ku recipe display names and feedback

tests/
└── unit/
    ├── seeds/
    │   └── test_seed_recipe_registry.gd
    ├── test_spirit_service.gd          # or equivalent spirit summon/gift tests
    └── test_codex_service.gd           # or equivalent codex hint tests
```

**Structure Decision**: Reuse existing seed, spirit, codex, and pattern pipelines. Add only new data resources and narrow service/UI wiring updates required for Ku content and hint behavior.

## Phase 0: Research Plan

Research tasks dispatched from technical context and spec constraints:
1. Respectful direct Shinto deity reference usage in game flavor text and codex wording.
2. Best-practice way to express guided unlock hints that name an unlock source but avoid threshold spoilers.
3. Existing codebase pattern for gift-driven unlocks and deterministic recipe expansion without new persistence semantics.

Phase 0 output is captured in `research.md` with concrete decisions and alternatives.

## Phase 1: Design and Contracts Plan

Design outputs produced in this phase:
1. `data-model.md` with Ku recipe, biome, deity spirit, structure, and codex hint entities.
2. `contracts/ku-unlock-and-recipes.md` defining unlock and recipe invariants.
3. `contracts/ku-content-mapping.md` defining one-to-one biome-spirit-structure mappings and IDs.
4. `quickstart.md` with end-to-end validation steps including specific unlock conditions.

Agent context update step:
1. Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`.
2. Confirm context update success and keep manual sections intact.

## Phase 2: Implementation Planning Outline

Ordered workstreams for execution in `/speckit.tasks`:
1. **Ku Recipe Expansion**
   - Add 4 Ku recipe `.tres` files and registry coverage.
   - Update mix panel recipe display names and preview strings.
2. **Unlock Path and Codex Guidance**
   - Preserve Mist Stag-driven Ku unlock behavior.
   - Add codex hint text that names Mist Stag and directionally hints prerequisites without numeric thresholds.
3. **Ku Content Authoring**
   - Add 4 Ku biomes (using existing enum entries and recipe outputs).
   - Add 4 deity spirit entries using direct Shinto deity names and lore references.
   - Add 4 worship structure discoveries with one-to-one mapping per Ku biome.
4. **Discovery Wiring**
   - Wire new spirit and structure patterns into existing discovery catalogs and codex entries.
   - Ensure duplicate unlock/discovery triggers remain idempotent.
5. **Validation**
   - Add/extend GUT tests for recipe availability, lock behavior, and codex hint behavior.
   - Execute manual quickstart checks for unlock progression and content reveal flow.

## Post-Phase 1 Constitution Re-check

- **Spec Traceability**: PASS. Design artifacts map to FR/US without drift.
- **Godot-Native Fit**: PASS. All contracts/design point to existing Godot services/resources.
- **Validation Strategy**: PASS. Quickstart + GUT coverage paths are explicit.
- **World Rule Safety**: PASS. Plan explicitly keeps current save/load semantics unchanged.
- **Mobile Budgets**: PASS. No new high-frequency runtime systems introduced.
- **Guardrails**: PASS. No autoload/class_name conflicts planned; explicit typed-script guardrails retained.

## Complexity Tracking

No constitution violations currently require justification.
