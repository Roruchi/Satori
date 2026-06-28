# Evidence: itch.io Web Alpha

Run date: 2026-06-28

## Export

- `.\tools\godot.ps1 -Command export-web`
- Result: passed.
- Output: `build/web/index.html` and related Web artifacts regenerated.
- Notes: Godot reports non-resource loader warnings for `data/discovery_editor/runtime/*.csv.txt` when packing explicit runtime data. The export wrapper treats only those paired runtime CSV include warnings as expected and keeps other Godot error lines fatal.

## Browser Smoke

- `npx playwright test tests/playwright/satori-web-smoke.spec.js`
- Result: 4 passed.
- Coverage:
  - Web shell and core assets serve from `build/web/`.
  - Godot runtime boots in mobile Chromium, removes the loader overlay, renders a full canvas, and reports no page errors.
  - `index.pck` contains seed recipes, runtime material/ritual CSV data, title version `0.1.0-alpha+20260627.1`, and the material icon spritesheet.
  - `index.pck` excludes representative tests, specs, tools, GUT command scripts, Playwright config, and `.godot/imported/` editor cache paths.

## Focused Godot Validation

- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_discovery_editor_runtime_data.gd`
  - Result: 2/2 passed.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_first_expansion_loop.gd`
  - Result: 4/4 passed.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_save_game_service.gd`
  - Result: 10/10 passed.

## Exit Gate Assessment

- Local Web build exports: passed.
- Title/runtime browser startup: passed by Playwright runtime boot.
- Runtime CSV and alpha-critical package contents: passed by Playwright package assertions and runtime data GUT.
- First ritual and alpha progression survival: passed by focused first expansion loop GUT.
- Save/reload persistence for alpha-critical state: passed by save service GUT and first expansion loop save/load assertions.
- Restricted itch.io package path: documented in `packaging.md`.
- Known issues: documented in `known-issues.md`.
