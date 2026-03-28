# Implementation Plan: Godai Sandbox Core (v6.0) - Phase A

**Branch**: `copilot/implement-tdd-godai-sandbox-core` | **Date**: 2026-03-28 | **Spec**: [/home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/spec.md](/home/runner/work/Satori/Satori/specs/copilot/implement-tdd-godai-sandbox-core/spec.md)
**Input**: Feature specification from `/specs/copilot/implement-tdd-godai-sandbox-core/spec.md`

## Summary

Implement a minimal, test-driven vertical slice of the Godai Sandbox Core by adding (1) a reusable Kusho counter domain model and (2) a 5-second Keisu resonance pitch influence in `SoundscapeEngine`. This delivers foundational systems for resource-state logic and audio feedback while preserving existing gameplay and architecture.

## Technical Context

**Language/Version**: GDScript on Godot 4.6  
**Primary Dependencies**: Godot runtime, existing autoload/services, GUT test framework  
**Storage**: In-memory runtime state (no new persistence in this phase)  
**Testing**: GUT unit tests under `tests/unit/`  
**Target Platform**: Existing Godot targets (desktop + mobile path)  
**Project Type**: Godot game project  
**Performance Goals**: No noticeable frame impact; O(number of active audio layers) resonance update per frame  
**Constraints**: No breaking changes to current discovery, spirit audio, or growth systems; maintain deterministic counter logic  
**Scale/Scope**: One focused implementation slice touching audio runtime and domain model only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Traceability**: PASS. Scope maps directly to FR-002/FR-003 foundation (Kusho counters) and FR-020 (bell resonance pitch influence).
- **Godot-Native Fit**: PASS. Changes stay in GDScript under `src/` and tests under `tests/unit/`.
- **Validation Strategy**: PASS. Add/extend GUT tests for Kusho logic and Soundscape resonance behavior; manual in-editor validation documented.
- **World Rule Safety**: PASS. No changes to permanence/delete behaviors, persistence format, or discovery determinism.
- **Mobile Budgets**: PASS. Resonance update is simple scalar pitch assignment and bounded duration.
- **Guardrails**: PASS. No autoload/class_name naming conflict introduced; explicit types used where `Variant` may appear.

## Project Structure

### Documentation (this feature)

```text
specs/copilot/implement-tdd-godai-sandbox-core/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── gameplay-signals.md
└── tasks.md
```

### Source Code (repository root)

```text
project.godot

src/
├── autoloads/
│   └── kusho_pool.gd
└── audio/
    ├── procedural_audio_bed.gd
    └── soundscape_engine.gd

tests/
└── unit/
    ├── test_soundscape_engine.gd
    └── test_kusho_pool.gd
```

**Structure Decision**: Implement a domain-level Kusho pool class and extend existing audio classes in place to minimize risk and churn.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
