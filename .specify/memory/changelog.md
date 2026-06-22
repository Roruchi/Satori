# Project Memory Changelog

## Merged Features Log

### Ritual and Material Migration Archive — 2026-06-22

**Scope:** changelog-only archival of superseded Speckit specs
**Archive:** `specs/archive/2026-06-ritual-material-migration`

**What changed:**

- Archived `019-seed-crafting-grid`, which introduced the 3x3 seed crafting grid.
- Archived `020-craft-mode-buildings`, which moved buildings into craft-mode grid recipes and retired build mode.
- Archived `021-first-session-clarity`, which captured first-session clarity and structure-craft feedback before the ritual/material direction.
- Kept the archived specs intact so the repository still tells the design history.

**Current active direction:**

- `022-ritual-menu-slots`: replaces grid crafting with unique ritual slots.
- `023-biome-natural-materials`: makes biomes produce visible, harvestable materials.
- `024-spirit-assistants-components`: preserves the expansion loop while adding spirit happiness, ritual assistants and components.

**Regression gate:**

The migration must preserve the playable first expansion loop: Meadow, Living Wood,
Warm Hollow, Meadow Dwelling, housed spirits, Mist Stag, Ku, second island and
new island-local spirits.

**Tasks Completed:**

- `019-seed-crafting-grid`: 31/37 tasks
- `020-craft-mode-buildings`: 48/48 tasks
- `021-first-session-clarity`: 0/23 tasks
