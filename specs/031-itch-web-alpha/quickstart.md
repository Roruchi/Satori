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
