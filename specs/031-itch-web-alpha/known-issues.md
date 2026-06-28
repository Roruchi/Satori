# Known Issues: Restricted Web Alpha

Run date: 2026-06-28

## Web Runtime

- Browser startup in Playwright logs repeated Godot audio warnings: `AudioStreamPlayer is trying to play a sample from a stream that cannot be sampled.` The build continues running and the title canvas renders.
- Chromium may log WebGL `ReadPixels` performance warnings during automated screenshots. These are test-environment warnings, not observed gameplay blockers.

## Package Scope

- No actual restricted or draft itch.io page URL has been recorded yet. Phase 5 remains blocked until the page content is populated, the current Web build is uploaded to that page, and both the page and game are smoke-tested from the actual itch.io URL.
- PWA behavior remains disabled for the first restricted alpha.
- The package is intended for a restricted itch.io page, not a public release.
- Broader alpha content breadth remains owned by later roadmap phases.

## Tester Notes

- Testers should use the same browser profile when checking reload persistence.
- If a tester reports a blank canvas, first confirm the uploaded package includes the repaired `index.js` produced by `.\tools\godot.ps1 -Command export-web`.
