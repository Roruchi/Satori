# Implementation Plan: Spirit Happiness, Ritual Assistants and Components

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/024-spirit-assistants-components/spec.md`

## Summary

Extend the spirit system from presence and housing into mood, happiness and assistant readiness, then allow assistant-ready spirits and discovered/placed components to participate in the same three-slot ritual grammar introduced by `022-ritual-menu-slots`. Spirits are never consumed. Components allow future rituals to scale through meaningful forms and context rather than large material counts.

## Technical Context

**Language/Version**: GDScript on Godot 4.6
**Primary Dependencies**: `src/spirits/spirit_service.gd`, `src/spirits/spirit_instance.gd`, `src/spirits/spirit_definition.gd`, `src/autoloads/spirit_persistence.gd`, `src/autoloads/spirit_ecology_service.gd`, `src/autoloads/satori_service.gd`, `src/autoloads/seed_alchemy_service.gd`, ritual menu work from feature 022, structure placement metadata
**Storage**: Extend spirit persistence with mood state and assistant cooldown/readiness; component availability derives from discoveries and placed structures
**Testing**: GUT for mood transitions, assistant availability, no-consumption rituals and component availability; manual editor validation for mood UI and ritual menu selection
**Target Platform**: Mobile-first Godot gameplay with desktop/editor parity
**Project Type**: Single-player Godot progression and ritual extension
**Performance Goals**: Mood updates are event-driven or timer-batched; component availability lookup is bounded by current island/known discoveries
**Constraints**: Spirits are never consumed; no duplicate ritual slots; no undo/reset; all assistant/component rituals revalidate on confirm
**Scale/Scope**: Starts with Red Fox and Hare as early meaningful cases, plus component hooks for Warm Hollow/Meadow Dwelling, Wind Chime and Tiny Shrine. The final gate preserves the expansion loop through Mist Stag, Ku, second island and new island-local spirits.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Plan maps to US1-US3 and FR-001..FR-015.
- **Godot-Native Fit**: PASS. Extends existing spirit, Satori, persistence and ritual systems.
- **Validation Strategy**: PASS. Deterministic mood and ritual rules are automated; UI/feel gets manual validation.
- **World Rule Safety**: PASS. Spirit state is persistent and meaningful; rituals do not erase or consume spirits.
- **Mobile Budgets**: PASS. Assistant selection uses the existing small ritual slot model and mood evaluation is not per-frame.
- **Guardrails**: PASS. Persistence changes must use explicit typed reads and avoid autoload/class collisions if helper services are added.

## Project Structure

### Documentation (this feature)

```text
specs/024-spirit-assistants-components/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    ├── spirit-assistant-contract.md
    └── component-ritual-contract.md
```

### Source Code (repository root)

```text
src/
├── spirits/
│   ├── spirit_service.gd
│   ├── spirit_instance.gd
│   ├── spirit_definition.gd
│   └── assistant/mood helpers if split
├── autoloads/
│   ├── spirit_persistence.gd
│   ├── spirit_ecology_service.gd
│   ├── satori_service.gd
│   └── seed_alchemy_service.gd
├── components/
│   └── component definitions if split from structures
├── ui/
│   └── ritual assistant/component selection surfaces
└── grid/
    └── placement metadata used for placed component checks

tests/
└── unit/
    ├── spirits/
    └── ritual/component tests
```

**Structure Decision**: Keep mood state on `SpiritInstance`/`SpiritService` first, because existing housing assignment and persistence already live there. Component availability may begin as a resolver helper over discoveries and placed structure metadata.

## Phase 0: Research Results

Research completed in [research.md](research.md):

1. Assistant readiness is derived from mood and housing, not inventory ownership.
2. Spirits contribute elemental intent but are never consumed.
3. Components can be symbolic or placed; both share a stable ritual input identity.
4. Confirm-time revalidation is required because spirit mood and placement can change after preview.
5. Start with Red Fox and Hare to solve the Meadow dwelling concern before expanding to all spirits.

No unresolved NEEDS CLARIFICATION items remain.

## Phase 1: Design and Contracts

Design artifacts produced:

1. [data-model.md](data-model.md): defines mood state, assistant availability, component definitions and component ritual rules.
2. [contracts/spirit-assistant-contract.md](contracts/spirit-assistant-contract.md): defines assistant selection, no-consumption and revalidation.
3. [contracts/component-ritual-contract.md](contracts/component-ritual-contract.md): defines component availability and ritual use.
4. [quickstart.md](quickstart.md): provides automated and manual validation flow.

## Phase 2: Implementation Strategy (for /speckit.tasks)

1. Extend `SpiritInstance` serialization with mood and readiness fields.
2. Add mood evaluation in `SpiritService` driven by housing assignment, preferred biome and time.
3. Add Red Fox and Hare early mood/assistant profiles.
4. Add assistant availability view for the ritual menu.
5. Integrate spirit assistant input identities into the feature 022 ritual resolver.
6. Add component definitions for selected discovered/placed structures.
7. Add component availability checks for symbolic discovery and placed island-local structure requirements.
8. Add no-consumption, revalidation and cooldown semantics.
9. Preserve or migrate the Mist Stag -> Ku unlock path and cover it with regression tests.
10. Preserve or migrate the Ku -> second island path and cover second-island spirit spawning.
11. Add GUT tests for mood, persistence, assistants, components, Mist Stag/Ku and second-island spirit discovery.
12. Run the end-to-end 10-minute loop gate from `quickstart.md`.
13. Update `specs/master/recipes.md` if ritual/component mappings change.

## Post-Phase 1 Constitution Re-check

- **Spec Traceability**: PASS.
- **Godot-Native Fit**: PASS.
- **Validation Strategy**: PASS.
- **World Rule Safety**: PASS.
- **Mobile Budgets**: PASS.
- **Guardrails**: PASS.

## Complexity Tracking

No constitution violations require justification.
