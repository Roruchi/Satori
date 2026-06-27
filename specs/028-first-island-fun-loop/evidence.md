# Evidence: First Island Fun Loop

Recorded: 2026-06-27 15:38:54 +02:00

## Scope

Phase 2 / `028-first-island-fun-loop` is verified for the first-island alpha gate:

- Red Fox can move from basic Meadow dwelling into Fox Den.
- Fox Den counts as upgraded Red Fox housing and grants Red-Fox-only double Satori generation.
- Dew Bowl and Wind Chime runtime data and effects are present.
- Duplicate ritual inputs are rejected without consumption.
- Invalid build projects remain non-destructive and now show actionable feedback.
- Save/load preserves Fox Den migration, helper structures, Satori value, and discovery persistence through `SaveGameService`.

## Implementation Evidence

- `src/autoloads/save_game_service.gd` now includes optional DiscoveryPersistence and SatoriService payloads.
- `src/autoloads/discovery_persistence.gd` now exposes save-service serialize/restore hooks.
- `src/autoloads/satori_service.gd` now exposes save-service serialize/restore hooks for current Satori, cap, era, tick state, and fired moments.
- `src/grid/PlacementController.gd` stores invalid project feedback alongside the invalid flash marker.
- `src/grid/GardenView.gd` renders the invalid project feedback while the failed project confirmation is flashing.
- `tests/unit/test_first_expansion_loop.gd` includes a Phase 2 round-trip covering Fox Den, Dew Bowl, Wind Chime, discovery persistence, Red Fox housing, and Satori state.
- `tests/unit/test_save_game_service.gd` includes DiscoveryPersistence and SatoriService save/load coverage.
- `tests/unit/test_build_mode_regressions.gd` asserts actionable invalid project feedback.

## Validation

- `.\tools\godot.ps1 -Command parse` passed after one headless editor import refreshed the detached worktree cache.
- `.\tools\godot.ps1 -Command boot` passed: `res://scenes/Garden.tscn` loaded and core autoloads were present.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_build_mode_regressions.gd"` passed, 18/18.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_save_game_service.gd"` passed, 3/3.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_first_expansion_loop.gd"` passed, 4/4.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/spirits/test_spirit_service.gd"` passed, 30/30.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_satori_service.gd"` passed, 18/18.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_structure_catalog_data.gd"` passed, 3/3.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_biome_material_harvesting.gd"` passed, 16/16.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/seeds/test_ritual_menu_slots.gd"` passed, 12/12.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_building_placement_session.gd"` passed, 14/14.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_ritual_menu_ui.gd"` passed, 9/9.

Known environment note: the headless editor import still reports corrupt non-runtime PNGs under `data/discovery_editor/viewer/screenshots/`, matching prior runs. These files are not on the runtime alpha path.
