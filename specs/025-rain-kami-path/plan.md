# Implementation Plan: Rain Kami Path

## Data

- Add ritual CSV rows for `Reed Nest` and `Stone Basin`.
- Use existing form ritual plumbing in `RitualRecipeCatalog`.
- Gate Suijin on `disc_reed_nest` instead of late Misogi shrine content.

## Runtime

- Extend the ritual panel with Reed Fiber and Spirit Stone material buttons.
- Persist form discoveries through `DiscoveryPersistence` so pattern prerequisites can see them.
- Keep Reed Nest as a normal completed dwelling structure via `structure_discovery_id`.
- Keep Stone Basin data-only for now so future Rain work has a stable form contract.

## Pattern

- Reuse `spirit_suijin` as the first Rain Kami slice.
- Require a small River cluster in Awakening.
- Keep Suijin in the existing deity/shrine handling path.

## Tests

- Add CSV/catalog coverage for Reed Nest and Stone Basin.
- Add ritual service coverage for Reed Fiber + Water and Spirit Stone + Water.
- Add UI scene coverage for the new material buttons.
- Add an end-to-end Rain Kami path regression where possible.

## Validation

- Run `tools/godot.ps1 parse`.
- Run focused GUT tests for ritual catalog, ritual menu, UI, and Rain path.
- If the current local Godot runner continues to crash, document the exact blocker separately from code/test changes.
