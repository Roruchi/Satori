# Evidence: itch.io Web Alpha

Run date: 2026-06-28

## Current Status

Status: Blocked.

Local Web export, package structure, browser smoke, the draft itch.io page identity, and the uploaded HTML build are validated. The Phase 5 exit gate still requires the visible tester-facing page content to be complete on itch.io, plus full smoke from the actual itch.io URL through first ritual, first placement, and same-browser reload persistence.

Pending page gate:

- Restricted or draft itch.io page URL: `https://roruchi.itch.io/satori`.
- Itch.io owner/slug: `roruchi/satori`.
- Access mode: Draft.
- Page content populated from `itch-page.md`: partial; short description metadata and editor form copy were applied, but the long description was not visible on the rendered page during current smoke.
- Page visuals/screenshots: pending.
- Feedback route: itch.io comments or direct developer feedback.
- Uploaded HTML/browser-playable build or channel: `web-alpha`.
- Upload identifier: `#18139525`.
- Build identifier: `#1759450`.
- Build version on itch.io: `0.1.0-alpha+20260627.1`.
- Actual itch.io page content review, first ritual, first placement, and reload persistence: pending.

## Actual itch.io Page Progress

Date: 2026-06-29

- Page edit URL provided by owner: `https://itch.io/game/edit/4723679`.
- Canonical page URL: `https://roruchi.itch.io/satori`.
- Owner/slug: `roruchi/satori`.
- Access mode: Draft.
- Project kind: HTML/browser-playable.
- Mobile-friendly embed: enabled.
- Local butler version installed for this run: `v15.27.0`.
- `.\build\tools\butler\butler.exe validate build\web`
  - Result: passed.
  - Result detail: `build\web\index.html` detected as an HTML5 app.
- `.\build\tools\butler\butler.exe push build\web roruchi/satori:web-alpha --userversion 0.1.0-alpha+20260627.1 --if-changed`
  - Result: passed.
  - Channel: `web-alpha`.
  - Upload: `#18139525`.
  - Build: `#1759450`.
  - Version: `0.1.0-alpha+20260627.1`.
- `.\build\tools\butler\butler.exe status roruchi/satori:web-alpha`
  - Result: passed.
  - Status: channel `web-alpha`, upload `#18139525`, build `#1759450`, version `0.1.0-alpha+20260627.1`.
- Actual itch.io page smoke:
  - Page loads as Draft.
  - Page reports HTML5 platform.
  - Clicking `Run game` creates iframe `https://html-classic.itch.zone/html/18139525-1759450/index.html?...`.
  - Godot canvas appears and renders the Satori title screen.
  - Known audio sampling warnings appear in browser logs; no title-screen blocker observed.
- Remaining blockers before Phase 5 can be Verified:
  - Long tester-facing page description is now visible on the rendered draft page, including the player guide and feedback focus.
  - Page visuals/screenshots or cover image still need to be added/reviewed.
  - Actual itch.io URL smoke still needs to cover new game, first ritual, first placement, and same-browser reload persistence.

## Itch.io Page Content Follow-up

Date: 2026-06-29

- Updated the draft itch.io page long description through the visible Redactor editor after confirming source-mode edits did not sync into the saved `game[description]` field.
- Rendered page verification at `https://roruchi.itch.io/satori`:
  - `Enter the garden`: present.
  - `Player guide`: present.
  - `Feedback focus`: present.
- T016 remains open because page visuals/screenshots or cover imagery still need to be added/reviewed.

## Itch.io Visual Direction Follow-up

Date: 2026-06-29

- Compared the current Satori page against the user-provided polished itch.io references:
  - `https://digitarium.itch.io/peggys-post`
  - `https://naoimh-murchan.itch.io/once-upon-a-witchs-curse`
- Prepared local page assets from existing Satori art:
  - `specs/031-itch-web-alpha/page-assets/satori-itch-cover.png`
  - `specs/031-itch-web-alpha/page-assets/satori-itch-banner.png`
  - `specs/031-itch-web-alpha/page-assets/satori-itch-gallery-alpha-loop.png`
- Recommended itch.io theme palette recorded in `itch-page.md`: deep garden teal, warm paper panel, dark moss text, shrine-gold accents.
- The in-app browser control session timed out while probing the live itch page after visiting the references, so these visual assets were prepared locally but not uploaded to itch.io in this run.
- T016 remains open until the assets/theme are applied and visually reviewed on the actual itch.io page.

## Itch.io Theme Application Follow-up

Date: 2026-06-29

- Regenerated `specs/031-itch-web-alpha/page-assets/satori-itch-banner.png` as a separate scenic banner with no logo text and no repeated wordmark.
- Applied the available itch.io theme colors on the live draft page:
  - Outer/page background: deep garden teal.
  - Content panel: warm paper.
  - Main text: dark moss.
  - Buttons/links: shrine gold.
- Rendered page verification showed the improved theme live with dark teal page sides, warm paper content panel, dark moss text, and gold action buttons.
- Attempted the itch.io Banner image upload through the visible theme editor Upload control, but the in-app browser automation exposed only a hidden file input and did not open a Windows file picker; the banner image id stayed empty.
- T016 remains open until the prepared cover/gallery/banner assets are uploaded to itch.io and visually reviewed.

## Itch.io Repeating Backdrop Follow-up

Date: 2026-06-29

- Generated a separate repeating page backdrop asset:
  - `specs/031-itch-web-alpha/page-assets/satori-itch-background-tile.png`
- Generated a local repeat QA preview:
  - `specs/031-itch-web-alpha/page-assets/satori-itch-background-repeat-preview.png`
- Visual QA:
  - The tile uses dark teal mossy stone, subtle shrine-gold flecks, faint teal spirit glows, and low-contrast garden texture.
  - The 3x2 repeat preview is suitable as a tiled page background behind the warm paper content panel.
- T016 remains open until the backdrop image is uploaded to the itch.io Background image slot with repeat/tile behavior and visually reviewed on the actual page.

## Current Focused Validation

Date: 2026-06-29

- `.\tools\godot.ps1 -Command export-web`
  - Result: passed.
  - Output: `build/web/index.html` and related Web artifacts regenerated.
  - Note: wrapper repaired the generated Godot 4.6 Web shell async WASM loader override.
- `npx playwright test tests/playwright/satori-web-smoke.spec.js`
  - Result: 4/4 passed.
  - Coverage: local Web shell/assets, Godot runtime boot, packaged seed/runtime/icon data, and development-only path exclusions.
- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.

## Corrective Validation

Date: 2026-06-28

- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.

## Page Content Correction

Date: 2026-06-28

- Draft itch.io page content and publication checklist added in `specs/031-itch-web-alpha/itch-page.md`.
- `docs/alpha-roadmap.md`, `spec.md`, `plan.md`, `data-model.md`, `tasks.md`, `packaging.md`, `quickstart.md`, `research.md`, and `known-issues.md` now require both a tester-facing itch.io content page and the uploaded playable game before Phase 5 can be Verified.
- `.\tools\godot.ps1 -Command parse`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command boot`
  - Result: passed.
  - Note: existing ObjectDB shutdown leak warning remains.
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd`
  - Result: 2/2 passed.

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
- Restricted/draft itch.io page exists and URL is recorded: pending.
- Actual itch.io page content is populated and reviewed: pending.
- Current Web package is uploaded to the itch.io page as an HTML/browser-playable build: pending.
- Actual itch.io URL smoke passes content review/title/new-game/first-ritual/first-placement/reload persistence: pending.
- Known issues: documented in `known-issues.md`.

Result: Phase 5 is locally validated and has a draft page brief, but it is not Verified. It remains Blocked until the actual itch.io page is created or identified, the content page is populated and reviewed, the current build is uploaded, and smoke/reload evidence is recorded from the itch.io URL. Android validation remains owned by Phase 6.
