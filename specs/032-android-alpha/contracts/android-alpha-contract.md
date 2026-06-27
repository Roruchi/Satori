# Contract: Android Alpha Build

## Purpose

Defines the minimum Android build acceptable for alpha testing.

## Contract

The Android build must:

- have an Android export preset using package id `com.lunaverse.satori`,
- use the title emblem as the app icon,
- avoid orientation lock while preserving usable portrait and non-broken landscape layouts,
- show build version in the menu using `0.x.y-alpha+<build_id>` format,
- exclude placeholder art, audio, icon, and UI assets from the primary alpha path and release shell,
- install and launch on device or emulator,
- support touch pan, zoom, tap, placement, ritual slots, build/project confirmation, Codex, and settings,
- keep alpha-critical UI reachable on phone ratios,
- preserve save state after background/resume and close/reopen,
- have documented build steps.

## Validation

- Device or emulator install evidence.
- Manual touch and lifecycle script recorded in `quickstart.md`.
