# Implementation Plan: First Island Fun Loop

**Branch**: `028-first-island-fun-loop` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/028-first-island-fun-loop/spec.md`

## Summary

Make the first island fun after the first dwelling by clarifying Red Fox care, Satori pressure/recovery, Dew Bowl, Wind Chime, and invalid action feedback.

## Technical Context

**Language/Version**: GDScript, Godot 4.6  
**Primary Dependencies**: `SpiritService`, `SatoriService`, `SeedAlchemyService`, `GameState`, structure catalog/runtime CSVs, HUD/Codex UI  
**Storage**: Save game state for spirits, structures, Satori, inventory, discoveries  
**Testing**: GUT for deterministic rules; manual UI validation for readability  
**Target Platform**: Desktop dev, Web/Android later  
**Project Type**: Godot game  
**Performance Goals**: Housing/Satori recomputes remain responsive for alpha-scale islands  
**Constraints**: No broad spirit assistant system in this spec  
**Scale/Scope**: First island depth only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phase 2.
- **Godot-Native Fit**: PASS. Extends existing services and scenes.
- **Validation Strategy**: PASS. GUT plus manual scene validation.
- **World Rule Safety**: PASS. Invalid project confirmation must be non-destructive.
- **Mobile Budgets**: PASS. UI readability required.
- **Guardrails**: PASS. Avoid autoload/class_name naming collisions and Variant inference hazards.

## Project Structure

```text
data/discovery_editor/runtime/
src/autoloads/
src/spirits/
src/grid/
src/ui/
scenes/UI/
tests/unit/
specs/028-first-island-fun-loop/
```

**Structure Decision**: Use existing first-island services and add focused clarity rather than a new island-loop subsystem.

## Complexity Tracking

No planned constitution violations.
