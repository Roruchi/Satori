# Evidence: Alpha Endgame Kami Spine

Recorded: 2026-06-27 20:05 +02:00

## Implementation Evidence

- Mist Stag still gates Ku by era: Stillness blocks Mist Stag, Awakening allows it, and repeated discovery unlocks Ku once.
- Ku unlock state round-trips through `SaveGameService` with element charge state.
- Ku Seed produces `BiomeType.KU`, and saved Ku tiles retain empty island IDs so Void separates islands after reload.
- Suijin invitation now requires the candidate island to have Sacred Stone, at least 10 water tiles, no fire-based tiles, and Satori 1000.
- Suijin invitation is island-local, duplicate-safe, records through existing spirit persistence, and marks the Codex entry on arrival.
- The old Reed Nest-only Suijin path was replaced in the Suijin pattern and Codex guidance with the Chi+Ku calm-water-island path.

## Validation Evidence

- One-time detached-worktree import: `Godot_v4.6.1-stable_win64_console.exe --headless --editor --quit --path .`
  - Result: completed; reported known corrupt non-runtime discovery viewer PNGs in `data/discovery_editor/viewer/screenshots/`.
- `.\tools\godot.ps1 -Command parse`
  - Result: passed after import-cache repair.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed; `res://scenes/Garden.tscn` loaded and core autoloads were present.
- `.\tools\godot.ps1 -Command test -Test tests/unit/spirits/test_spirit_service.gd`
  - Result: 33/33 passed.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_save_game_service.gd`
  - Result: 5/5 passed.
- `.\tools\godot.ps1 -Command test -Test tests/unit/seeds/test_seed_recipe_registry.gd`
  - Result: 8/8 passed.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_island_labelling.gd`
  - Result: 7/7 passed.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_first_expansion_loop.gd`
  - Result: 4/4 passed, including `test_alpha_endgame_spine_invites_suijin_and_survives_save_load`.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_data_driven_pattern_addition.gd`
  - Result: 2/2 passed.
- `.\tools\godot.ps1 -Command test -Test tests/unit/test_codex_service.gd`
  - Result: 3/3 passed.
