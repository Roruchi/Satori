# Implementation Plan: Playable First Session

**Branch**: `027-playable-first-session` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/027-playable-first-session/spec.md`

## Summary

Make the first 10 minutes playable and understandable through the normal game UI: first ritual, Meadow, First Bloom Living Wood, Red Fox, Warm Hollow, Meadow dwelling, and save/load continuity.

## Technical Context

**Language/Version**: GDScript, Godot 4.6  
**Primary Dependencies**: `SeedAlchemyService`, `SeedGrowthService`, `GameState`, `SpiritService`, `SatoriService`, HUD/ritual scenes  
**Storage**: Existing save game service and runtime CSV catalogs  
**Testing**: GUT focused suites plus manual first-session playtest  
**Target Platform**: Desktop dev, mobile-like viewport, later Web/Android  
**Project Type**: Godot game  
**Performance Goals**: No first-session interaction should introduce visible stalls  
**Constraints**: No debug-only grants for alpha acceptance  
**Scale/Scope**: Fresh save through first dwelling only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phase 1.
- **Godot-Native Fit**: PASS. Uses existing autoloads, scenes, and CSV data.
- **Validation Strategy**: PASS. Deterministic services through GUT; UI comprehension manually.
- **World Rule Safety**: PASS. Irreversible placement must remain clear.
- **Mobile Budgets**: PASS. Requires mobile-like viewport verification.
- **Guardrails**: PASS. Use preloads/explicit types for GDScript edits.

## Project Structure

```text
data/discovery_editor/runtime/
src/autoloads/
src/seeds/
src/spirits/
src/ui/
scenes/UI/
tests/unit/
specs/027-playable-first-session/
```

**Structure Decision**: Extend existing first-session systems rather than adding a separate tutorial subsystem unless the audit proves one is needed.

## Complexity Tracking

No planned constitution violations.
