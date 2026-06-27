# Contract: Web Alpha Build

## Purpose

Defines the minimum browser build acceptable for itch.io alpha.

## Contract

The Web build must:

- export through the `Web` preset,
- include runtime CSV data and alpha-critical assets,
- exclude placeholder art, audio, icon, and UI assets from the primary alpha path and release shell,
- exclude tests, tools, specs, editor cache, and debug-only release behavior,
- load to title screen,
- show build version in the menu,
- start a new game,
- complete first ritual smoke,
- preserve save state across same-browser reload,
- be packageable for restricted itch.io upload.

## Validation

- Export output exists under `build/web/`.
- Playwright and manual smoke checks pass.
