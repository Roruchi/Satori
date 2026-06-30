# Implementation Plan: Alpha Content and External Readiness

**Branch**: `033-alpha-content-readiness` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/033-alpha-content-readiness/spec.md`

## Summary

Add a restrained alpha content pass and prepare tester-facing release materials for Web-first closed alpha testing, with Android handed off as the final platform gate.

## Technical Context

**Language/Version**: Godot 4.6, Markdown docs  
**Primary Dependencies**: Runtime CSV catalogs, Codex, save/load, Web build  
**Storage**: Content data, save state, tester docs  
**Testing**: Data checks, GUT where content affects rules, manual playtest  
**Target Platform**: Web alpha first, Android final gate later  
**Project Type**: Godot game  
**Performance Goals**: No regression to alpha performance or load targets  
**Constraints**: Do not broaden to full content roster  
**Scale/Scope**: Final alpha pass only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phases 6 and 7.
- **Godot-Native Fit**: PASS. Uses existing content/data systems.
- **Validation Strategy**: PASS. Data tests plus manual external-readiness review.
- **World Rule Safety**: PASS. Content must respect permanent world state.
- **Mobile Budgets**: PASS. Polish keeps UI mobile-readable, while Android device proof stays in `032-android-alpha`.
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
