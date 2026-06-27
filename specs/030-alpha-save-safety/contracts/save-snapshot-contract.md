# Contract: Alpha Save Snapshot

## Purpose

Defines alpha-critical state that must round-trip before external testing.

## Contract

A valid alpha save snapshot includes:

- tiles and biome state,
- seed/material/form inventory,
- discoveries and Codex state,
- spirits and house bindings,
- structures and active projects,
- Satori state,
- Ku unlock state,
- Void-separated island state,
- Chi+Ku calm-water island state,
- Satori threshold state for Suijin,
- Suijin invitation/presence state,
- confirmed active project timer/progress state,
- schema version,
- producing build version in `0.x.y-alpha+<build_id>` format.

## Validation

- Save/load round-trip tests cover first-session, first-island, and endgame checkpoints.
- Load failure is visible and non-destructive.
