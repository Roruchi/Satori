# Evidence: Alpha Content and External Readiness

Run date: 2026-06-29

## Current Status

Status: In progress.

Phase 6 / Phase 7 content-readiness work has started. This run completed the repo-side content audit, deferred placeholder discovery stingers, added focused alpha content validation, and wrote the Web tester brief plus known issues.

The spec is not ready for roadmap `Verified` status yet. Remaining open work includes primary-surface polish review, manual playtest beyond the first island, normal UI gap audit, final placeholder confirmation, and a Web fresh-save playthrough to Suijin.

## Changes

- Added `content-audit.md` with the included primary alpha content list, intentionally deferred content, and asset audit.
- Added `tester-brief.md` with Web tester scope, out-of-scope notes, feedback prompts, and Android follow-up.
- Added `known-issues.md` with deferred discovery stinger audio, Android follow-up, and Phase 5 itch.io smoke dependency.
- Added `tests/unit/test_alpha_content_readiness.gd`.
- Deferred authored discovery stingers by keeping `DiscoveryAudioPlayer.AUDIO_MAP` empty until final-enough `.ogg` files exist.
- Removed placeholder wording from discovery stinger and spirit rhythm comments/warnings.

## Validation

All commands below were run with Godot `APPDATA` and `LOCALAPPDATA` redirected into `.godot-user/` under this worktree. Without that redirection, the sandbox user could not use the normal Godot user/cache directories and headless Godot hung or crashed.

- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_alpha_content_readiness.gd`
  - Result: 6/6 passed.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_save_game_service.gd`
  - Result: 10/10 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_first_expansion_loop.gd`
  - Result: 4/4 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_spirit_island_scope.gd`
  - Result: 7/7 passed.
  - Note: existing unfreed-child warning and ObjectDB shutdown leak warning remain.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_structure_catalog_data.gd`
  - Result: 3/3 passed.
  - Note: existing unfreed-child warning and ObjectDB shutdown leak warning remain.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_soundscape_engine.gd`
  - Result: 24/24 passed.
  - Note: existing expected queue-full warning, unfreed-child warning, and ObjectDB shutdown leak warning remain.

## Remaining Tasks

- T010 polish review for first ritual, Red Fox, Meadow dwelling, Fox Den migration/bonus, Dew Bowl, Wind Chime, Mist Stag, Ku Seed, Void, Chi+Ku calm-water island, and Suijin surfaces.
- T011 manual playtest beyond first island.
- T013 normal UI audit for broken-looking alpha gaps.
- T014 final confirmation that no placeholder art, audio, icon, or UI assets remain on the primary alpha path or release shell.
- T017 Web fresh-save playthrough to Suijin.
