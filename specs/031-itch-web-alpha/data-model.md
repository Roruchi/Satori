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

## ItchProjectPage

- `page_url`: restricted or draft itch.io page URL
- `owner`: itch.io account or organization owner
- `slug`: itch.io game slug
- `access_mode`: draft or restricted
- `content_status`: pending, populated, reviewed, or needs-fix
- `playable_upload`: channel or upload identifier for the HTML/Web build

## ItchPageContent

- `title`: game title shown on itch.io
- `short_description`: one-line game description
- `long_description`: tester-facing game explanation and alpha scope
- `visuals`: screenshots or key art visible on the page
- `controls`: browser/touch/mouse play notes
- `known_issues`: current closed-alpha caveats
- `save_guidance`: browser-local persistence notes
- `feedback_route`: where testers should report feedback
- `build_version`: visible build version

## PlaceholderAssetAudit

- `asset_path`: reviewed asset
- `surface`: title, menu, gameplay, Codex, audio, icon, or UI
- `route`: primary, release-shell, or non-primary
- `status`: final-enough, placeholder-allowed-non-primary, replaced, hidden, gated, or deferred
- `notes`: action required before packaging
