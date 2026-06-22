# Implementation Plan: Ritual Menu and Slot-Based Creation

**Branch**: `022-ritual-menu-slots` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/022-ritual-menu-slots/spec.md`

## Summary

Replace the player-facing 9-slot crafting grid with a three-slot ritual menu and route seed, structure-form and placement-context outcomes through a shared ritual resolver. The resolver is order-insensitive, always requires unique input identities, keeps essence seed rituals compatible with current seed inventory, and introduces Warm Hollow as the first material + essence form whose final role is decided by placement context.

## Technical Context

**Language/Version**: GDScript on Godot 4.6
**Primary Dependencies**: `src/autoloads/seed_alchemy_service.gd`, `src/ui/SeedAlchemyPanel.gd`, `src/seeds/SeedRecipeRegistry.gd`, `src/seeds/BuildingRecipeCatalog.gd`, `src/seeds/SeedPouch.gd`, `src/grid/PlacementController.gd`, `src/grid/BuildingPlacementSession.gd`, `src/grid/GardenView.gd`, discovery/Codex services
**Storage**: Existing save/autoload state for discoveries, place inventory and element charge; optional migration for stale grid UI state
**Testing**: GUT tests under `tests/unit`, plus manual in-editor validation for ritual panel, mobile layout and placement previews
**Target Platform**: Mobile-first Godot gameplay with desktop/editor parity
**Project Type**: Single-player Godot game feature migration
**Performance Goals**: Ritual preview/confirmation is bounded to at most three slots; no frame-blocking scans or broad grid traversal during menu interaction
**Constraints**: No duplicate ritual inputs ever; at least one essence per ritual; no undo/reset additions; failed rituals are non-destructive; old duplicate building token recipes are migration-only
**Scale/Scope**: Touches UI creation flow, seed/building resolution, place inventory, placement metadata and focused catalog/docs synchronization. The first-session playtest loop must remain usable during migration.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Plan maps directly to US1-US3 and FR-001..FR-016.
- **Godot-Native Fit**: PASS. Work stays in existing GDScript services, UI scenes and placement controllers.
- **Validation Strategy**: PASS. Resolver and placement context rules get GUT coverage; menu ergonomics and copy get manual in-editor checks.
- **World Rule Safety**: PASS. The feature preserves permanence and strengthens deterministic discovery by moving to canonical ritual identities.
- **Mobile Budgets**: PASS. Three slots are simpler than nine cells; preview logic is bounded and UI validation covers mobile layout.
- **Guardrails**: PASS. New autoloads are not required for MVP. If a `RitualResolver` script is introduced, avoid matching an autoload key to its `class_name`; use explicit typing around `Dictionary.get()` and dynamic service calls.

## Project Structure

### Documentation (this feature)

```text
specs/022-ritual-menu-slots/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── ritual-attempt-contract.md
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   └── seed_alchemy_service.gd
├── seeds/
│   ├── SeedRecipeRegistry.gd
│   ├── SeedPouch.gd
│   ├── BuildingRecipeCatalog.gd
│   └── ritual data/scripts if split from the existing alchemy service
├── ui/
│   ├── SeedAlchemyPanel.gd
│   └── HUDController.gd
├── grid/
│   ├── PlacementController.gd
│   ├── BuildingPlacementSession.gd
│   └── GardenView.gd
└── codex/

scenes/
├── Garden.tscn
└── UI/
    └── SeedAlchemyPanel.tscn

tests/
└── unit/
    ├── seeds/
    ├── test_building_placement_session.gd
    └── ritual tests added by this feature
```

**Structure Decision**: Extend the existing `SeedAlchemyService`/`SeedAlchemyPanel` pathway first, because it already owns essence charges, recipe discovery, inventory insertion and feedback. Extract a dedicated resolver only if the implementation becomes clearer than keeping the logic inside the service.

## Phase 0: Research Results

Research completed in [research.md](research.md):

1. Replace slot position with canonical ritual input identities.
2. Keep seed recipes compatible by adapting existing seed registry entries into ritual definitions.
3. Treat old building recipes as migration content, not valid ritual patterns.
4. Add placement-context resolution for forms, starting with Warm Hollow.
5. Preserve place-inventory semantics and non-destructive failure ordering.

No unresolved NEEDS CLARIFICATION items remain.

## Phase 1: Design and Contracts

Design artifacts produced:

1. [data-model.md](data-model.md): defines ritual slots, input identities, recipe definitions, attempt results and form placement rules.
2. [contracts/ritual-attempt-contract.md](contracts/ritual-attempt-contract.md): defines resolver invariants, result shapes and no-consumption failure semantics.
3. [quickstart.md](quickstart.md): provides automated and manual validation flow.

## Phase 2: Implementation Strategy (for /speckit.tasks)

1. Replace `SeedAlchemyPanel` 9-cell grid with a compact ritual slot UI.
2. Add ritual slot state and duplicate-prevention UI handling.
3. Add a canonical ritual normalization path that rejects duplicate input identities.
4. Adapt existing seed recipe lookup to ritual attempts.
5. Add material + essence form lookup for Living Wood + Fire Essence -> Warm Hollow.
6. Add form placement context resolution for Warm Hollow -> Meadow Dwelling / Scorched Hollow.
7. Preserve a valid housing path before blocking old duplicate-token building recipes. The preferred replacement is Warm Hollow -> Meadow Dwelling; a temporary compatibility recipe is acceptable only if documented and covered by tests.
8. Migrate building craft preview/attempt copy away from grid terminology and block duplicate-token legacy recipes only after the replacement path is playable.
9. Add GUT coverage for resolver, failure, inventory-full, migration housing path and placement context contracts.
10. Run the first-session bridge validation: Meadow seed creation, Meadow placement, Meadow spirit invitation and at least one valid house placement.
11. Update `specs/master/recipes.md` if implementation IDs or display names differ from the current master reference.

## Post-Phase 1 Constitution Re-check

- **Spec Traceability**: PASS. The design artifacts preserve direct mapping to the user stories and functional requirements.
- **Godot-Native Fit**: PASS. No non-Godot runtime is introduced.
- **Validation Strategy**: PASS. Deterministic resolver behavior is automatable; scene presentation remains manual validation.
- **World Rule Safety**: PASS. Failed attempts are non-destructive; successful attempts are deterministic and discovery-bound.
- **Mobile Budgets**: PASS. The UI becomes smaller and the resolver checks fewer slots than before.
- **Guardrails**: PASS. Implementation notes identify autoload/class naming and `Variant` typing risks.

## Complexity Tracking

No constitution violations require justification.
