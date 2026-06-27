# Implementation Plan: Alpha Content and External Readiness

**Branch**: `033-alpha-content-readiness` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/033-alpha-content-readiness/spec.md`

## Summary

Add a restrained alpha content pass and prepare tester-facing release materials for closed itch.io and Android alpha testing.

## Technical Context

**Language/Version**: Godot 4.6, Markdown docs  
**Primary Dependencies**: Runtime CSV catalogs, Codex, save/load, Web and Android builds  
**Storage**: Content data, save state, tester docs  
**Testing**: Data checks, GUT where content affects rules, manual playtest  
**Target Platform**: Web and Android alpha  
**Project Type**: Godot game  
**Performance Goals**: No regression to alpha performance or load targets  
**Constraints**: Do not broaden to full content roster  
**Scale/Scope**: Final alpha pass only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phases 7 and 8.
- **Godot-Native Fit**: PASS. Uses existing content/data systems.
- **Validation Strategy**: PASS. Data tests plus manual external-readiness review.
- **World Rule Safety**: PASS. Content must respect permanent world state.
- **Mobile Budgets**: PASS. Tester docs cover Web and Android.
- **Guardrails**: PASS. Use existing content pipelines.

## Project Structure

```text
data/discovery_editor/runtime/
src/codex/
docs/
specs/033-alpha-content-readiness/
```

**Structure Decision**: Keep alpha content in existing data/Codex pipelines and release notes in docs/specs.

## Complexity Tracking

No planned constitution violations.
