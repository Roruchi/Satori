# Data Model: Android Alpha

## AndroidExportPreset

- `package_id`: `com.lunaverse.satori`
- `version_code`: integer build version
- `version_name`: human-readable zero-based alpha version, such as `0.1.0-alpha+20260627.1`
- `orientation`: no orientation lock
- `icon_source`: title emblem
- `signing_mode`: debug or release-like

## AndroidIdentity

- `package_id`: `com.lunaverse.satori`
- `menu_version`: visible `0.x.y-alpha+<build_id>` string
- `icon_source`: title emblem
- `orientation_policy`: no lock; portrait-primary validation plus no broken landscape layout

## TouchValidationResult

- `device`: physical or emulator target
- `viewport`: resolution/aspect ratio
- `orientation`: portrait or landscape
- `controls_checked`: pan, zoom, tap, placement, rituals, build, Codex, settings
- `issues`: list of blockers or polish notes

## LifecycleSaveCheck

- `checkpoint`: first session, first island, endgame
- `action`: background, resume, close, reopen
- `result`: pass/fail
- `evidence`: notes or video/screenshot path
