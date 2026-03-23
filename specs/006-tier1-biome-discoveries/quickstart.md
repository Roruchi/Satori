# Quickstart: Tier 1 Biome Discoveries MVP

**Branch**: `006-tier1-biome-discoveries` | **Date**: 2026-03-23

## Goal

Validate the Tier 1 discovery MVP end-to-end:
- detection and one-time emission,
- sequential notification queue,
- per-discovery audio trigger,
- persistent discovery log across restart.

## Prerequisites

- Godot 4.6 installed
- Project opens successfully via `project.godot`
- GUT available in `addons/gut/`

## Run The Project

```bash
godot --editor "C:/Repo/Personal/Games/Satori/project.godot"
```

Then run the game with F5 (main scene: `scenes/Garden.tscn`).

## MVP Validation Flow (Manual)

1. Seed a near-complete Tier 1 pattern (for example, 9 Forest tiles with no adjacent Stone).
2. Place the triggering tile.
3. Confirm within one frame:
   - discovery notification appears with display name + flavor text,
   - matching stinger plays.
4. Wait 4 seconds and confirm notification auto-dismisses.
5. Trigger a same-placement dual discovery case and confirm queue behavior:
   - not shown simultaneously,
   - second appears after first starts dismissing/finishes.
6. Save/exit and relaunch.
7. Confirm discovery log still contains previously triggered entries and no duplicate trigger occurs on load.

## Automated Test Commands

```bash
# Full suite
godot --path . --headless -s tests/gut_runner.tscn

# Discovery-focused tests (to be created/updated in this feature)
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_tier1_discovery_pipeline.gd
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_tier1_discovery_persistence.gd
```

## Expected MVP Pass Criteria

- 12/12 Tier 1 discoveries are data-registered and trigger exactly once each.
- Notification queue never overlaps two discovery banners.
- Each discovery references a distinct stinger key.
- Persisted discoveries survive restart with original timestamps.
