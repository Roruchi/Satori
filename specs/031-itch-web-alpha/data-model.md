# Data Model: itch.io Web Alpha

## WebExportPreset

- `name`: `Web`
- `export_path`: `build/web/index.html`
- `include_filter`: runtime data and required assets
- `exclude_filter`: tests, specs, tools, editor cache
- `pwa_enabled`: false for first alpha unless later save testing requires it

## WebSmokeResult

- `build_id`: export timestamp or version
- `browser`: local browser used
- `checks`: title, new game, first ritual, save reload
- `result`: pass/fail with notes

## ItchPackage

- `source_dir`: `build/web`
- `archive_path`: optional zip
- `version`: visible build version in `0.x.y-alpha+<build_id>` format
- `upload_notes`: tester-facing instructions
- `visibility`: restricted alpha upload

## PlaceholderAssetAudit

- `asset_path`: reviewed asset
- `surface`: title, menu, gameplay, Codex, audio, icon, or UI
- `route`: primary, release-shell, or non-primary
- `status`: final-enough, placeholder-allowed-non-primary, replaced, hidden, gated, or deferred
- `notes`: action required before packaging
