# Feature Specification: itch.io Web Alpha

**Feature Branch**: `031-itch-web-alpha`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 5.

## Clarifications

- This spec owns the browser-playable itch.io build path.
- It depends on first-session and save safety for meaningful external testing.
- It does not own Android export.
- The itch.io alpha build is a restricted manual upload package. PWA is disabled for the first alpha unless a later implementation task proves it is needed for save testing.
- The primary Web alpha path and release shell must ship with polished assets only. Placeholder assets are allowed for non-primary content if that content is hidden, gated, or clearly outside the intended tester route.

## User Scenarios & Testing

### User Story 1 - Export Playable Web Build (Priority: P1)

As the developer, I can produce a Web build that loads locally.

**Independent Test**: Godot Web export plus local browser smoke.

**Acceptance Scenarios**:

1. **Given** the Web preset, **When** export runs, **Then** `build/web/index.html` is produced.
2. **Given** the exported build, **When** it opens locally, **Then** the title screen appears.

### User Story 2 - Preserve Runtime Data and Saves (Priority: P1)

As a Web tester, I can play the alpha spine and reload the page without losing progress.

**Independent Test**: Playwright smoke plus manual browser reload.

**Acceptance Scenarios**:

1. **Given** the Web build, **When** I perform first ritual and save/reload, **Then** progress remains.
2. **Given** runtime CSV/material assets, **When** build loads, **Then** alpha content is available.

### User Story 3 - Package for itch.io (Priority: P2)

As the developer, I can upload a reproducible package to itch.io.

**Independent Test**: Build artifact review and documented packaging command.

**Acceptance Scenarios**:

1. **Given** a clean export, **When** packaging runs, **Then** the output can be uploaded to itch.io.

## Requirements

- **FR-001**: Web export MUST include runtime CSV data and alpha-critical assets.
- **FR-002**: Web export MUST exclude tests, editor cache, tools, and debug-only flows.
- **FR-003**: Web build MUST pass a title/new-game/first-ritual smoke.
- **FR-004**: Web persistence MUST survive same-browser reload for alpha-critical state.
- **FR-005**: itch.io packaging steps MUST be documented.
- **FR-006**: Web alpha package MUST exclude placeholder art, audio, icon, and UI assets from the primary alpha path and release shell.
- **FR-007**: Web alpha package MUST show the build version in the menu using `0.x.y-alpha+<build_id>` format.

### Experience & Runtime Constraints

- **EX-001**: Browser play MUST preserve irreversible progress through save.
- **EX-002**: Web UI MUST remain playable with mouse and mobile-like browser viewport.
- **EX-003**: Load time should be acceptable for alpha testers.

### Key Entities

- **WebExportPreset**: Godot export preset named `Web`.
- **ItchPackage**: Uploadable Web build folder/archive.
- **WebSmokeResult**: Evidence from Playwright/manual browser validation.
- **PlaceholderAssetAudit**: Review that no placeholder assets appear on the primary alpha path or release shell; non-primary placeholders must be hidden, gated, or outside the tester route.

## Success Criteria

- **SC-001**: Local Web build exports and loads.
- **SC-002**: Playwright smoke reaches title/new-game/first-ritual.
- **SC-003**: Same-browser reload preserves alpha-critical save state.
