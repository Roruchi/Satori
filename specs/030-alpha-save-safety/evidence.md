# Evidence: Alpha Save Safety

Recorded: 2026-06-27 23:40 +02:00

## Scope

Phase 4 / `030-alpha-save-safety` is verified against the roadmap tracker gate:

- First-session, first-island, and endgame/kami checkpoint states round-trip through `SaveGameService`.
- Save payloads include schema version and producing build version metadata.
- Unsupported saves fail visibly and do not overwrite the current garden.
- Failed temp writes keep the previous live save intact.
- Confirmed active project countdown metadata survives save/load without refund, cancellation, duplication, or instant completion.
- Autosave now covers tile placement, blooms, harvests, pouch/material changes, discoveries, Satori changes, spirit persistence records, shrine charge collection, and app background/close notifications.

## Alpha-Critical State Audit

`SaveGameService` now serializes the alpha-critical state through existing service boundaries:

- `GameState`: tiles, selected biome, tile metadata, material nodes, material spawn accumulators, structure essence accumulators, Void-separated island IDs, houses, structures, and active project metadata.
- `SeedGrowthService`: active seeds, seed pouch entries, building/form inventory, growth capacity, and speed multiplier.
- `SeedAlchemyService`: materials, unlocked elements, element charges, ritual discoveries, building discoveries, and pending shrine charges.
- `DiscoveryPersistence`: discovered Codex/runtime discovery entries.
- `SpiritPersistence`: active spirit instances, including island-scoped Suijin and Red Fox persistence.
- `SatoriService`: current Satori, cap, era, tick accumulator, fractional delta, and fired Satori moments.

## Platform Save Path Notes

- Desktop validation ran under Godot's Windows user data location shown by GUT: `C:/Users/roelv/AppData/Roaming/Godot/app_userdata/Satori`.
- `SaveGameService.get_observed_save_environment()` records `user://` paths, globalized paths, OS name, and Web/Android feature flags for platform checks.
- Web browser reload persistence remains the owning gate for `031-itch-web-alpha`.
- Android background/resume persistence remains the owning gate for `032-android-alpha`, because this spec does not own Android export setup or device installation.

## Save Compatibility

- Current save schema version: `1`.
- Current producing build version: `0.1.0-alpha+20260627.1`.
- Supported saves load when `schema_version` or legacy `format_version` is between `1` and the current `FORMAT_VERSION`.
- Unsupported future saves emit `load_failed` with `unsupported_format_version` and display: `This garden save is from an unsupported alpha version.`
- Save writes use temp-file verification and live-to-backup promotion; a failed temp or promote step keeps the previous live save available.

## Validation Evidence

- One-time detached-worktree import: `Godot_v4.6.1-stable_win64_console.exe --headless --audio-driver Dummy --path . --import --quit`
  - Result: completed; reported known corrupt non-runtime discovery viewer PNGs in `data/discovery_editor/viewer/screenshots/`.
- `.\tools\godot.ps1 -Command parse`
  - Result: passed; only the existing ObjectDB shutdown warning remained.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed; `res://scenes/Garden.tscn` loaded and core autoloads were present.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_save_game_service.gd"`
  - Result: 10/10 passed.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_first_expansion_loop.gd"`
  - Result: 4/4 passed, covering first-session, first-island, and alpha endgame/Suijin save-load checkpoints.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/test_build_mode_regressions.gd"`
  - Result: 18/18 passed.
- `.\tools\godot.ps1 -Command test -Test "res://tests/unit/spirits/test_spirit_service.gd"`
  - Result: 34/34 passed.
