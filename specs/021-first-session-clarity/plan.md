# Implementation Plan: First-Session Clarity and Structure Feedback

**Branch**: `021-first-session-clarity` | **Date**: 2026-06-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/021-first-session-clarity/spec.md`

## Summary

Add a lightweight first-session guide, normalize player-facing terminology across HUD and prompts, and make structure crafting feedback explicit enough that players can understand what to do without external help.

## Technical Context

**Language/Version**: GDScript on Godot 4.6  
**Primary Dependencies**: Existing Godot scenes, autoloads, HUD, craft panel, Codex, and grid systems  
**Storage**: Existing separate settings/config path for guidance completion state; no change to garden save format unless explicitly required by implementation  
**Testing**: GUT unit coverage plus manual in-editor verification for HUD and first-session flow  
**Target Platform**: Desktop and mobile-first Godot game  
**Project Type**: Godot 2D game  
**Performance Goals**: Preserve current frame-time and interaction responsiveness; guidance should be effectively UI-only  
**Constraints**: Preserve permanent-emergence rules, keep guidance state separate from garden state, and avoid adding new brittle runtime branches  
**Scale/Scope**: Small cross-cutting UX feature touching HUD, craft feedback, Codex hints, and one profile-level guidance flag

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: This work is directly traceable to the three user stories in `spec.md`.
- **Godot-Native Fit**: Proposed changes stay inside `src/`, `scenes/`, and existing autoload/UI wiring.
- **Validation Strategy**: Add GUT coverage for guide completion, vocabulary mapping, and blocked structure feedback, plus manual in-editor checks for HUD flow and readability.
- **World Rule Safety**: No change to permanence, discovery determinism, or save-time world state is intended.
- **Mobile Budgets**: Guide and feedback changes must stay lightweight and thumb-reachable.
- **Guardrails**: Avoid autoload/class_name naming collisions, keep typed Variant use explicit where needed, and prefer preloaded typed dependencies if a new shared helper is introduced.

## Project Structure

### Documentation (this feature)

```text
specs/021-first-session-clarity/
├── plan.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
├── grid/
├── ui/
└── codex/

scenes/
├── Garden.tscn
└── UI/

tests/
├── gut_runner.tscn
└── unit/
```

**Structure Decision**: Keep the feature as a small UX layer on top of existing gameplay systems. First-session state belongs with profile/settings persistence, wording normalisation belongs in shared UI copy or HUD helpers, and structure feedback stays in the existing craft/popup/codex flow.

## Design Notes

- The first-session guide should be a small state machine with a handful of steps rather than a large scripted tutorial.
- The guide should be non-blocking and should not prevent the player from exploring or skipping forward.
- Player-facing terminology should come from one shared vocabulary source so HUD buttons, prompts, popovers, and codex labels do not drift apart.
- Structure feedback should use explicit outcome data where possible, not ad-hoc string assembly in multiple UI layers.
- Codex hints should remain discoverable and readable, but should be clearer about the next in-game action the player should try.

## Validation Strategy

- Add GUT coverage for:
  - first-session completion state,
  - step progression,
  - copy/vocabulary consistency,
  - blocked structure craft feedback,
  - no-resource-loss failure paths.
- Manually verify:
  - first-run guide flow in a fresh profile,
  - repeat-session skip behavior,
  - HUD labels on desktop and mobile-like aspect ratios,
  - structure preview readability,
  - Codex hint readability.

