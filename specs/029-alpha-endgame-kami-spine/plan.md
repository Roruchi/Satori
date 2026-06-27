# Implementation Plan: Alpha Endgame Kami Spine

**Branch**: `029-alpha-endgame-kami-spine` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/029-alpha-endgame-kami-spine/spec.md`

## Summary

Implement the alpha finale from normal play: Mist Stag unlocks Ku, Ku Seed places Void that separates islands, and Chi+Ku biome placement on a calm water island invites Suijin with persistence and duplicate safety.

## Technical Context

**Language/Version**: GDScript, Godot 4.6  
**Primary Dependencies**: `SpiritService`, `SatoriService`, `GameState`, `SeedAlchemyService`, island membership logic, pattern/discovery services, Codex, save service  
**Storage**: Save data for Ku unlock, island state, kami invitation, discoveries  
**Testing**: GUT for gates/conditions/persistence plus full manual playthrough  
**Target Platform**: Desktop dev first, Web/Android later  
**Project Type**: Godot game  
**Performance Goals**: Invitation checks must not regress pattern scan performance  
**Constraints**: No full kami roster or restoration system  
**Scale/Scope**: One alpha kami only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phase 3 and user correction.
- **Godot-Native Fit**: PASS. Extends existing island/spirit/discovery systems.
- **Validation Strategy**: PASS. GUT plus full manual fresh-save playthrough.
- **World Rule Safety**: PASS. Void and Chi+Ku placement must be persistent and irreversible.
- **Mobile Budgets**: PASS. Guidance must be readable.
- **Guardrails**: PASS. Avoid autoload naming collisions and Variant inference hazards.

## Project Structure

```text
data/discovery_editor/runtime/
src/autoloads/
src/biomes/
src/spirits/
src/satori/
src/ui/
tests/unit/
specs/029-alpha-endgame-kami-spine/
```

**Structure Decision**: Add the minimum data and service behavior necessary for Void island separation and Suijin invitation.

## Complexity Tracking

No planned constitution violations.
