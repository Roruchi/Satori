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

## US1 – Notification + Audio Validation (Manual)

**Goal**: Confirm named/flavor discovery notifications display correctly and audio fires on first match only.

1. Select "Forest" tile and place 9 connected Forest tiles.
2. Place the 10th Forest tile.
3. Confirm within one frame:
   - The "The Deep Stand" banner appears showing the display name and flavor text.
   - The matching stinger key is logged/played (audio placeholder will log a warning if `.ogg` file is absent — this is expected until audio assets are supplied).
4. Wait 4 seconds and confirm the banner auto-dismisses without any player interaction.
5. Place an 11th Forest tile. Confirm no second banner appears for "The Deep Stand".
6. **Dual-trigger test**: Build a 10-Water-tile River AND place a tile that also completes a second discovery simultaneously.
   - Confirm both discovery banners appear sequentially, NOT at the same time.
   - Confirm the second banner only appears after the first has started dismissing.

**Expected outcome**: One unique, named notification per discovery; auto-dismiss after 4 seconds; strict sequential queue.

## US2 – Persistence Validation (Manual)

**Goal**: Confirm discoveries survive app restart.

1. Trigger at least 3 distinct Tier 1 discoveries (e.g. The River, The Mountain Peak, The Peat Bog).
2. Close and relaunch the game.
3. Confirm:
   - The same discoveries do NOT re-fire notifications on reload.
   - The discovery log file exists at `user://garden_discoveries.json` and contains the recorded entries with their original timestamps.
4. Inspect the JSON file directly and verify:
   - Each entry has a `discovery_id`, `display_name`, `trigger_timestamp`, and `triggering_coords` field.
   - Timestamps match the original trigger time, not the reload time.

**Expected outcome**: Persisted discoveries load silently; no re-notification; timestamps preserved.

## US3 – Audio Distinctness Validation (Manual)

**Goal**: Each of the 12 discoveries references a unique audio stinger key.

1. Trigger all 12 Tier 1 discoveries.
2. Observe the logs — each discovery should log a warning with its unique audio key path (e.g. `"Audio asset not found (placeholder): res://assets/audio/discoveries/river.ogg"`).
3. Confirm all 12 audio key paths are distinct — no two discoveries reference the same `.ogg` file.
4. Test with device muted/silent: confirm that the discovery notification banner still appears even when audio fails.

**Expected outcome**: 12 unique stinger keys, audio failure does not block visual notification.

## Automated Test Commands

```bash
# Full suite
godot --path . --headless -s tests/gut_runner.tscn

# Discovery-focused tests
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_tier1_discovery_pipeline.gd
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_tier1_discovery_persistence.gd
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_tier1_discovery_audio_map.gd
```

## Expected MVP Pass Criteria

- 12/12 Tier 1 discoveries are data-registered and trigger exactly once each.
- Notification queue never overlaps two discovery banners.
- Each discovery references a distinct stinger key.
- Persisted discoveries survive restart with original timestamps.
- Audio failure (missing placeholder `.ogg` assets) does NOT suppress visual notifications.

