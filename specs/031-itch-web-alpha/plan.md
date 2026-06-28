# Implementation Plan: itch.io Web Alpha

**Branch**: `031-itch-web-alpha` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/031-itch-web-alpha/spec.md`

## Summary

Produce a content-complete restricted itch.io page and validate the browser-playable Web build embedded on that page for closed alpha testing.

## Technical Context

**Language/Version**: Godot 4.6 Web export; JavaScript Playwright smoke  
**Primary Dependencies**: Godot export templates, `export_presets.cfg`, Playwright  
**Storage**: Browser/Web Godot persistence  
**Testing**: Web export, Playwright smoke, itch.io page content review, manual reload
**Target Platform**: Web browser / itch.io  
**Project Type**: Godot game Web build  
**Performance Goals**: Loads and reaches title/new game acceptably for alpha  
**Constraints**: Include runtime CSV/assets; exclude debug/test files; page must explain the game, alpha scope, controls, save behavior, known issues, and feedback route
**Scale/Scope**: restricted itch.io alpha page and Web build only

## Constitution Check

- **Spec Traceability**: PASS. Roadmap Phase 5.
- **Godot-Native Fit**: PASS. Uses Godot export preset.
- **Validation Strategy**: PASS. Export + Playwright + page content review + manual persistence.
- **World Rule Safety**: PASS. Web persistence must preserve progress.
- **Mobile Budgets**: PASS. Mobile-like browser viewport included.
- **Guardrails**: PASS. No GDScript required unless export issues require fixes.

## Project Structure

```text
export_presets.cfg
build/web/
tests/playwright/
specs/031-itch-web-alpha/
```

**Structure Decision**: Keep Web export in the existing preset and add validation/package/page-content docs around it.

## Complexity Tracking

No planned constitution violations.
