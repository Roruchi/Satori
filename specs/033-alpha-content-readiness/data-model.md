# Data Model: Alpha Content and External Readiness

## AlphaContentItem

- `item_id`: content id
- `type`: spirit, structure, material, Codex entry, island rule
- `purpose`: why it supports alpha fun
- `systems_wired`: Codex, save/load, tests, UI
- `status`: included, gated, deferred
- `path_role`: primary, release-shell, or non-primary
- `asset_status`: final-enough, placeholder-allowed-non-primary, replace-before-alpha, hidden, gated, or deferred

## PolishSurface

- `surface_id`: title, menu, HUD, Codex, gameplay, audio, icon, or feedback
- `obvious_path_role`: first ritual, Red Fox, Meadow dwelling, Fox Den migration, Red-Fox-only double Satori generation, Dew Bowl, Wind Chime, Mist Stag, Ku, Void, Chi+Ku calm-water island, Suijin, or platform shell
- `path_role`: primary, release-shell, or non-primary
- `placeholder_status`: none, allowed-non-primary, replace, hide, gate, or defer
- `owner_note`: required action before external alpha

## KnownIssue

- `issue_id`: stable id
- `severity`: blocker, major, minor, note
- `platform`: Web, Android, all
- `description`: tester-facing issue
- `workaround`: optional workaround

## TesterBrief

- `build_version`: visible menu version in `0.x.y-alpha+<build_id>` format
- `scope`: expected working features
- `out_of_scope`: deferred content
- `reporting_channel`: where feedback goes
- `feedback_questions`: fun and clarity questions
