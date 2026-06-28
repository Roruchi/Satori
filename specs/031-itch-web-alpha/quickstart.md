# Quickstart: itch.io Web Alpha

## Export

```powershell
.\tools\godot.ps1 -Command export-web
```

If the wrapper command is unavailable, use the repo's Godot executable with the `Web` export preset.

## Smoke Test

```powershell
npx playwright test tests/playwright/satori-web-smoke.spec.js
```

## Manual Browser Checks

1. Open `build/web/index.html` through a local server or the wrapper preview.
2. Confirm title screen appears.
3. Start new game.
4. Perform first ritual.
5. Save/reload the page.
6. Confirm progress persists.

## itch.io Package

Package the contents of `build/web/` after smoke passes. Record the build version and known issues before upload.

Use `itch-page.md` for the restricted itch.io page copy and content checklist.

## Actual itch.io Page Gate

1. Create or identify the Satori itch.io project page.
2. Set the page to Draft or Restricted access.
3. Configure the project as an HTML/browser-playable game.
4. Populate the page with the game description, visuals, controls, alpha scope, known issues, browser save guidance, build version, and feedback route from `itch-page.md`.
5. Upload the current `build/web/` package.
6. Open the actual itch.io URL and confirm page content, title, new game, first ritual, first placement, and same-browser reload persistence.
7. Record the page URL, owner/slug, access mode, content review result, upload/channel identifier, build version, and smoke result in `evidence.md`.

Local smoke is not enough to mark this spec Verified.
