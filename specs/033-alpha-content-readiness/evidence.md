# Evidence: Alpha Content and External Readiness

Run date: 2026-06-29; updated 2026-06-30

## Current Status

Status: In progress; blocked on rebuilt Web export and Web fresh-save playthrough evidence.

Phase 6 / Phase 7 content-readiness work has started. This run completed the repo-side content audit, deferred placeholder discovery stingers, added focused alpha content validation, and wrote the Web tester brief plus known issues.

The spec is not ready for roadmap `Verified` status yet. Remaining open work includes primary-surface polish review, manual playtest beyond the first island, normal UI gap audit, final placeholder confirmation on a rebuilt Web package, and a Web fresh-save playthrough to Suijin.

## 2026-07-01 Roadmap Worker Attempt

The roadmap worker preserved Phase 5 / `031-itch-web-alpha` as `Blocked` on the external itch.io page/upload/actual-URL smoke gate and selected Phase 6 / `033-alpha-content-readiness` as the first actionable non-Verified, non-Blocked row.

The fresh worktree again needed a headless editor import before validation: the first parse failed on missing global classes and imported texture cache entries, including the title logo `.ctex` files. The import repair completed and repeated the existing corrupt/non-PNG viewer screenshot warnings under `data/discovery_editor/viewer/screenshots/`, outside the primary alpha path.

Current validation after import repair:

- `.\tools\godot.ps1 -Command parse`
  - Initial result: failed with missing global classes and imported texture cache entries.
  - Repair: headless editor import with Godot 4.6.1 completed.
  - Final result: passed.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_alpha_content_readiness.gd`
  - Result: 6/6 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_save_game_service.gd`
  - Result: 10/10 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_first_expansion_loop.gd`
  - Result: 4/4 passed, including the unit endgame spine that invites Suijin and survives save/load.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command export-web`
  - Result: blocked because `web_nothreads_debug.zip` and `web_nothreads_release.zip` are missing under `.codex-godot-home/Roaming/Godot/export_templates/4.6.1.stable/`.

T010, T011, T013, T014, and T017 remain open. In particular, T014 and T017 cannot be closed until valid Godot 4.6.1 Web export templates are installed, `build/web` is rebuilt from the current project, the title/release-shell assets are visually confirmed in that rebuilt export, and a Web fresh-save playthrough reaches Suijin with reload persistence.

## 2026-06-30 Import Metadata Follow-up

This run rechecked the existing `build/web` export in the in-app browser through a local static server. The Web shell booted successfully at `http://127.0.0.1:8060/`: the Godot status element disappeared, the live canvas measured 1280x720 CSS pixels, and the title screen rendered. The title logo, however, rendered as a magenta/black missing-texture block in that existing export.

Root cause found: `assets/ui/title/satori-logo-*.png` source files are valid final-enough title art, but their Godot `.png.import` files were missing because `.gitignore` ignored all `.import` files except the material icon atlas. Added a narrow `!assets/ui/title/*.png.import` exception and generated/imported the four title logo metadata files.

Current local validation:

- Headless editor import repair: completed; repeated the known corrupt/non-PNG viewer screenshot warnings under `data/discovery_editor/viewer/screenshots/`, outside the primary alpha path.
- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_alpha_content_readiness.gd`
  - Result: 6/6 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command export-web`
  - Result: blocked in this redirected Godot sandbox because `web_nothreads_debug.zip` and `web_nothreads_release.zip` are not installed under `.codex-godot-home/Roaming/Godot/export_templates/4.6.1.stable/`.

T014 remains open until a rebuilt Web export proves the title logo no longer renders as a missing texture. T017 remains open until a fresh-save Web playthrough reaches Suijin and verifies reload persistence.

## 2026-06-30 Roadmap Worker Attempt

The roadmap worker preserved the earlier blocked Phase 5 itch.io row and selected the next actionable row, Phase 6 / `033-alpha-content-readiness`.

Current validation passed after a one-time headless editor import repaired the fresh worktree `.godot` global-class and asset import cache. The import repair also reported three existing corrupt/non-PNG viewer screenshot imports under `data/discovery_editor/viewer/screenshots/`; they are not on the primary alpha path and did not block parse, boot, or focused GUT validation.

The worker could not complete T017. `npm` is not available in the sandbox, so the Playwright Web smoke could not run from `package.json`. A fallback in-app browser attempt served the existing `build/web` export locally, but the browser automation timed out after reloading the fixed static server and did not return usable Web boot or fresh-save Suijin playthrough evidence. Because T017 remains unproven, the roadmap row remains unverified.

### 2026-06-30 Validation

- `.\tools\godot.ps1 -Command parse`
  - Initial result: failed with fresh worktree global-class and PNG loader cache errors.
  - Repair: headless editor import with Godot 4.6.1 completed.
  - Final result: passed.
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
  - Result: 4/4 passed, including the unit endgame spine that invites Suijin and survives save/load.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_spirit_island_scope.gd`
  - Result: 7/7 passed.
  - Note: existing unfreed-child and ObjectDB shutdown leak warnings remain.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_structure_catalog_data.gd`
  - Result: 3/3 passed.
  - Note: existing unfreed-child and ObjectDB shutdown leak warnings remain.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_soundscape_engine.gd`
  - Result: 24/24 passed.
  - Note: existing expected queue-full warning and unfreed-child warning remain.
- `npm test -- --reporter=line`
  - Result: not run; `npm` is not recognized in the sandbox shell.

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
- T014 final confirmation that no placeholder art, audio, icon, or UI assets remain on the primary alpha path or release shell; specifically re-export Web with templates installed and verify the title logo no longer renders as a missing texture.
- T017 Web fresh-save playthrough to Suijin.
