# Implementation Plan: Tier 1 Biome Cluster Discoveries (MVP)

**Branch**: `006-tier1-biome-discoveries` | **Date**: 2026-03-23 | **Spec**: `specs/006-tier1-biome-discoveries/spec.md`
**Input**: Feature specification from `specs/006-tier1-biome-discoveries/spec.md`

## Summary

Deliver a production-ready MVP for Tier 1 discoveries by completing the end-to-end loop that already begins in the pattern engine: register all 12 Tier 1 pattern resources, emit one-time deterministic discovery signals, persist discovery history into garden save data, and present queued discovery notifications with unique audio stingers. The MVP intentionally reuses the existing `PatternScanService` + `PatternMatcher` architecture and adds a thin discovery presentation/persistence layer instead of introducing new subsystem boundaries.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)  
**Primary Dependencies**: Godot built-ins, existing `PatternScanService` autoload, `PatternMatcher`, `PatternDefinition`, GUT (`addons/gut/`)  
**Storage**: Garden save file under `user://` including a persisted discovery log payload  
**Testing**: GUT unit/integration tests in `tests/unit/` + manual in-editor validation for UI/audio queue behavior  
**Target Platform**: Godot desktop dev runtime and mobile-targeted runtime (Android/iOS budget constraints)  
**Project Type**: Godot game feature in existing single-project repo  
**Performance Goals**: Preserve scan budget under 16ms for 1,000-tile representative case and avoid frame hitch during discovery UI/audio playback  
**Constraints**: No duplicate discovery firing per garden, deterministic discovery ordering, no permanence-rule regressions, no autoload/class_name naming collisions  
**Scale/Scope**: 12 Tier 1 discoveries, one persistent discovery log, one notification queue, one audio stinger per discovery

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Work maps directly to `specs/006-tier1-biome-discoveries/spec.md` and its three user stories (notification/audio, persistence, unique stingers).
- **Godot-Native Fit**: PASS. Runtime work stays in `src/`, scenes in `scenes/`, existing autoloads remain the integration points.
- **Validation Strategy**: PASS with required work. Add/extend GUT tests for 12-discovery registration, one-time emission, persistence restore suppression, and sequential queue behavior; include manual audio distinctness verification.
- **World Rule Safety**: PASS with explicit guard. Feature strengthens deterministic discovery/persistence behavior and does not alter permanence (no tile removal/undo).
- **Mobile Budgets**: PASS with monitoring. Discovery UI/audio queue is lightweight; scan/path remains unchanged except additional post-scan handling.
- **Guardrails**: PASS. Continue explicit typing in Variant-return paths; avoid autoload key/class_name collisions; prefer `preload` for typed cross-script dependencies.

## Project Structure

### Documentation (this feature)

```text
specs/006-tier1-biome-discoveries/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── discovery-event-contract.md
│   └── discovery-log-schema.md
└── tasks.md                # Created later by /speckit.tasks
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   └── GameState.gd
├── biomes/
│   ├── pattern_scan_scheduler.gd
│   ├── pattern_matcher.gd
│   ├── discovery_registry.gd
│   ├── discovery_signal.gd
│   └── patterns/           # Tier 1 .tres resources
├── ui/
│   └── TileSelector.gd     # Existing discovery toast integration point (to be evolved)
└── ...

scenes/
├── Garden.tscn
└── UI/

tests/
├── gut_runner.tscn
└── unit/
```

**Structure Decision**: Keep the current architecture and add a focused Tier 1 discovery orchestration/persistence layer connected to existing scan signals; avoid new global framework or non-Godot runtime dependencies.

## Phase 0: Research Plan

Research tasks generated from technical unknowns and integration decisions:

1. Determine the safest MVP persistence strategy for discoveries in the current repo (which currently lacks a full save manager in `src/`).
2. Decide where discovery display metadata (display name, flavor text, audio key) should live relative to existing `PatternDefinition` resources.
3. Decide notification queue ownership (UI node-owned queue vs service-owned queue) to guarantee sequential display and no overlap.
4. Confirm audio trigger strategy that tolerates mute/silent conditions without suppressing visual notification.
5. Confirm deterministic ordering strategy when one placement yields multiple discoveries.

## Phase 1: Design Plan

1. Define discovery domain entities and state transitions (`data-model.md`).
2. Define integration contracts for scan output, queue input, and persisted discovery payload (`contracts/`).
3. Write a practical implementation/validation runbook for developers (`quickstart.md`).
4. Re-run constitution gate after design output is complete.

## Phase 2: Task Planning Approach (for /speckit.tasks)

1. Foundation tasks: Tier 1 pattern resource completion + metadata catalog wiring.
2. Story-aligned tasks:
   - US1: notification queue and audio stinger playback from discovery events.
   - US2: persistence read/write and duplicate suppression across relaunch.
   - US3: unique audio mapping validation and graceful mute handling.
3. Verification tasks: automated GUT suites + manual validation checklist for queue and audio behavior.
4. Final integration tasks: end-to-end regression run, budget checks, and artifact updates.

## Post-Design Constitution Check

- **Spec Traceability**: PASS. `research.md`, `data-model.md`, contracts, and quickstart are all scoped to feature 006.
- **Godot-Native Fit**: PASS. Design uses existing Godot scripts/resources/signals and keeps all runtime logic in `src/`.
- **Validation Strategy**: PASS. Automated + manual coverage explicitly defined.
- **World Rule Safety**: PASS. Discovery persistence and idempotency are deterministic and save-compatible.
- **Mobile Budgets**: PASS. No heavy rendering/pathfinding/system changes introduced by MVP.
- **Guardrails**: PASS. Guardrails documented and preserved in the design choices.

## Complexity Tracking

No constitution violations requiring exception records.
