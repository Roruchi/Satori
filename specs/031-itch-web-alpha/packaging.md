# Packaging: Restricted itch.io Web Alpha

Run date: 2026-06-28

## Build

```powershell
.\tools\godot.ps1 -Command export-web
npx playwright test tests/playwright/satori-web-smoke.spec.js
```

Use only the generated contents of `build/web/` for the upload package.

## Package Contents

Required files:

- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`
- `index.png`
- `index.icon.png`
- `index.apple-touch-icon.png`
- `index.audio.worklet.js`
- `index.audio.position.worklet.js`

Do not include repo source folders such as `tests/`, `tools/`, `specs/`, `.godot/`, `.github/`, Playwright reports, or package-manager folders.

## Upload

1. Rebuild with `.\tools\godot.ps1 -Command export-web`.
2. Run `npx playwright test tests/playwright/satori-web-smoke.spec.js`.
3. Confirm `specs/031-itch-web-alpha/evidence.md` has current run evidence.
4. Zip the contents of `build/web/`, not the `build/web/` directory itself.
5. Upload to a restricted itch.io page as an HTML/Web build.
6. Record the visible version: `0.1.0-alpha+20260627.1`.
7. Include `specs/031-itch-web-alpha/known-issues.md` in tester notes.
