# Feature Specification: Android Alpha

**Feature Branch**: `032-android-alpha`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phase 6.

## Clarifications

- This spec owns Android export, install, touch validation, lifecycle save, and mobile layout gates.
- It depends on save safety and core alpha spine implementation.
- Android package id is `com.lunaverse.satori`.
- The alpha does not lock orientation; both orientations must avoid broken layouts, with phone portrait treated as the primary manual-check path.
- The Android icon uses the title emblem, not a placeholder icon.
- Alpha builds use zero-based SemVer with alpha prerelease and build metadata in the menu, for example `0.1.0-alpha+20260627.1`.

## User Scenarios & Testing

### User Story 1 - Build and Install Android Alpha (Priority: P1)

As the developer, I can produce an Android build that installs and launches.

**Independent Test**: Godot Android export and install on physical device or emulator.

**Acceptance Scenarios**:

1. **Given** Android export configuration, **When** export runs, **Then** an installable APK/AAB is produced.
2. **Given** a device/emulator, **When** the build installs, **Then** Satori launches to title.

### User Story 2 - Play With Touch (Priority: P1)

As a mobile tester, I can play the alpha spine using touch controls.

**Independent Test**: Manual touch playthrough on device/emulator.

**Acceptance Scenarios**:

1. **Given** Android gameplay, **When** I pan, zoom, tap, and confirm placement, **Then** controls do not conflict.
2. **Given** ritual/build UI, **When** I use touch, **Then** targets are reachable and legible.

### User Story 3 - Resume Safely (Priority: P1)

As a mobile tester, I can background and resume without losing progress.

**Independent Test**: Manual lifecycle save/resume check.

**Acceptance Scenarios**:

1. **Given** meaningful progress, **When** I background and reopen the app, **Then** progress remains.

## Requirements

- **FR-001**: Android export preset MUST exist with package id `com.lunaverse.satori`, version, title-emblem icon, no orientation lock, and signing approach.
- **FR-002**: Debug APK or equivalent MUST install and launch.
- **FR-003**: Touch pan, zoom, tap, placement, ritual slots, build/project confirmation, Codex, and settings MUST be usable.
- **FR-004**: Android background/resume MUST preserve alpha-critical state.
- **FR-005**: Release-like build steps MUST be documented.
- **FR-006**: Android alpha package MUST exclude placeholder art, audio, icon, and UI assets from the primary alpha path and release shell; non-primary placeholders are allowed when hidden, gated, or outside the intended tester route.
- **FR-007**: Android alpha build MUST show the build version in the menu using `0.x.y-alpha+<build_id>` format.

### Experience & Runtime Constraints

- **EX-001**: Touch interactions MUST preserve irreversible-action clarity.
- **EX-002**: UI MUST fit common phone ratios and safe areas.
- **EX-003**: Release build SHOULD keep debug overlay disabled and performance acceptable.

### Key Entities

- **AndroidExportPreset**: Godot Android export configuration.
- **TouchValidationResult**: Manual device/emulator validation record.
- **LifecycleSaveCheck**: Background/resume persistence evidence.
- **AndroidIdentity**: Package id, title-emblem icon, orientation behavior, and version display.

## Success Criteria

- **SC-001**: Android build installs and launches.
- **SC-002**: First-session and endgame spine are touch-playable.
- **SC-003**: Background/resume preserves alpha-critical save state.
