# Evidence: Android Alpha

Run time: 2026-06-28 07:38:09 +02:00

Phase 6 / `032-android-alpha` is partially implemented and blocked before external validation.

## Completed Repo-Side Setup

- Added an Android export preset named `Android` in `export_presets.cfg`.
- Configured package id `com.lunaverse.satori`.
- Configured version code `2026062701` and version name `0.1.0-alpha+20260627.1`.
- Configured the title emblem asset as Android launcher icon source.
- Configured no orientation lock through the Android preset and project handheld orientation.
- Added `tools/godot.ps1` commands:
  - `check-android-env`
  - `export-android`
- Documented debug signing and release-like alpha signing expectations in `android-build.md`.
- Hid development-only fast progression and debug-info controls in non-debug exports.

## Local Android Toolchain Check

Godot export templates are installed under the local Godot 4.6.1 template directory, including:

- `android_debug.apk`
- `android_release.apk`
- `android_source.zip`

The Android build environment is not currently complete:

- `ANDROID_HOME` is empty.
- `ANDROID_SDK_ROOT` is empty.
- `JAVA_HOME` is empty.
- `adb` is not on `PATH`.

Expected helper result until the environment is configured:

```text
Android environment incomplete: ANDROID_HOME or ANDROID_SDK_ROOT, JAVA_HOME, adb on PATH.
```

A direct Godot export probe recognized the `Android` preset and then failed on the same missing local toolchain:

```text
Cannot export project with preset "Android" due to configuration errors:
A valid Java SDK path is required in Editor Settings.
Invalid Android SDK path in Editor Settings. Missing 'platform-tools' directory!
Unable to find Android SDK platform-tools' adb command.
Invalid Android SDK path in Editor Settings. Missing 'build-tools' directory!
Unable to find Android SDK build-tools' apksigner command.
```

## Automated Validation

After a one-time headless editor import repaired the detached worktree `.godot` cache, these checks passed:

- `.\tools\godot.ps1 -Command parse`
- `.\tools\godot.ps1 -Command boot`
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_progression_speed_settings.gd` - 6/6 passed
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_web_ui_smoke_contract.gd` - 2/2 passed
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_save_game_service.gd` - 10/10 passed
- `.\tools\godot.ps1 -Command test -Test res://tests/unit/test_first_expansion_loop.gd` - 4/4 passed

The import step again reported the known corrupt non-runtime discovery viewer screenshots under `data/discovery_editor/viewer/screenshots/`.

## Open Validation Gates

The following tasks remain open because no Android SDK/JDK/device bridge is available in this shell:

- Export debug APK or equivalent.
- Install on device/emulator and launch to title.
- Validate touch controls.
- Validate portrait and landscape phone layouts.
- Validate background/resume and close/reopen save behavior.
- Audit the produced Android package contents.

The roadmap row must remain `Not Started` until these gates have current evidence.
