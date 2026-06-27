# Evidence: Playable First Session

Validated on 2026-06-27 in `C:\Users\roelv\.codex\worktrees\9e46\Satori`.

## Scope

Phase 1 proves the fresh first-session route:

1. Shape Wind/Fu into Meadow Seed.
2. Plant Meadow and grow it.
3. Spawn and harvest Living Wood.
4. Spawn Red Fox from the early Meadow island.
5. Shape Living Wood + Fire Essence into Warm Hollow.
6. Place Warm Hollow on Meadow as `building_meadow_dwelling`.
7. Confirm Red Fox is automatically housed.
8. Save, reload, restore the first-session services, and confirm the housed state persists.

## Current Validation

- `.\tools\godot.ps1 -Command parse`: passed after the detached worktree import cache was refreshed once with a headless editor import. Remaining console note is the existing ObjectDB leak warning at exit.
- `.\tools\godot.ps1 -Command boot`: passed. `res://scenes/Garden.tscn` loaded and core autoloads were present.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_ritual_menu_ui.gd`: passed, 9/9 tests.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_biome_material_harvesting.gd`: passed, 16/16 tests.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_first_expansion_loop.gd`: passed, 3/3 tests, including `test_first_session_housed_red_fox_survives_save_load`.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_save_game_service.gd`: passed, 2/2 tests.

## Notes

- The first-session save now includes `GameState`, seed growth/pouch state, seed alchemy state, and spirit persistence state in the autosave payload.
- The focused GUT first-session script is the current executable evidence for the manual quickstart route in this headless automation run.
- The headless editor import still reports the pre-existing corrupt screenshot PNGs under `data/discovery_editor/viewer/screenshots/`; those files are non-runtime discovery editor assets and were also reported during Phase 0.
