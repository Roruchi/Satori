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

1. Create or identify the Satori itch.io project page in the itch.io dashboard.
2. Set access to Draft or Restricted for closed-alpha testing.
3. Set the project/game kind to HTML/browser-playable before final verification.
4. Record the owner, slug, page URL, access mode, and intended upload channel in `specs/031-itch-web-alpha/evidence.md`.
5. Rebuild with `.\tools\godot.ps1 -Command export-web`.
6. Run `npx playwright test tests/playwright/satori-web-smoke.spec.js`.
7. Confirm `specs/031-itch-web-alpha/evidence.md` has current local run evidence.
8. Zip the contents of `build/web/`, not the `build/web/` directory itself.
9. Upload to the restricted itch.io page as an HTML/Web build.
10. Smoke the actual itch.io URL for title, new game, first ritual, first placement, and same-browser reload persistence.
11. Record the visible version: `0.1.0-alpha+20260627.1`.
12. Record the upload/channel identifier, itch.io URL, smoke result, and known issues for testers.
13. Include `specs/031-itch-web-alpha/known-issues.md` in tester notes.

Do not mark Phase 5 Verified from local export/package evidence alone.

## Butler Notes

Use butler only after the itch.io project page exists and account authentication is available:

```powershell
butler push build/web <owner>/<slug>:web-alpha --userversion <version>
```

After the first push, use the itch.io Edit game page to ensure the page and upload are configured as HTML/browser-playable.
