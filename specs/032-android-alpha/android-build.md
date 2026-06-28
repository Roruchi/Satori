# Android Alpha Build Notes

Current Android identity:

- Package id: `com.lunaverse.satori`
- App name: `Satori`
- Version code: `2026062701`
- Version name: `0.1.0-alpha+20260627.1`
- Icon source: `res://assets/ui/title/satori-logo-emblem.png`
- Orientation policy: no orientation lock, with portrait-primary manual validation.

## Signing

Debug alpha builds use Godot's Android debug signing path.

Release-like alpha builds require a project-specific Android keystore before external distribution. Do not commit the keystore or its passwords. Configure release keystore paths and credentials through the local Godot editor export settings or another machine-local secret path before producing a release-like package.

## Environment Preflight

```powershell
.\tools\godot.ps1 -Command check-android-env
```

The preflight checks:

- Godot 4.6.1 Android export templates,
- `ANDROID_HOME` or `ANDROID_SDK_ROOT`,
- `JAVA_HOME`,
- `adb` on `PATH`.

## Debug APK Export

```powershell
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
.\tools\godot.ps1 -Command export-android
```

Expected output:

```text
build/android/Satori-alpha-debug.apk
```

## Device Or Emulator Validation

After `export-android` succeeds:

```powershell
adb install -r .\build\android\Satori-alpha-debug.apk
```

Record device/emulator name, Android version, orientation, and viewport in `evidence.md`.

Run the manual script from `quickstart.md`:

1. Launch to title.
2. Confirm the title-emblem launcher icon.
3. Confirm settings show `Version 0.1.0-alpha+20260627.1`.
4. Start a new game.
5. Validate pan, zoom, tap, placement confirmation, ritual slots, build/project confirmation, Codex, and settings.
6. Complete the first-session path.
7. Complete Mist Stag -> Ku Seed -> Void separation -> Chi+Ku calm-water island -> Suijin.
8. Background and resume.
9. Close and reopen.
10. Confirm save state persists.

## Current Blocker

As of 2026-06-28 07:38:09 +02:00, this worktree has Godot 4.6.1 export templates installed, including Android templates, but the shell has no configured Android SDK/JDK/device bridge:

- `ANDROID_HOME` is empty.
- `ANDROID_SDK_ROOT` is empty.
- `JAVA_HOME` is empty.
- `adb` is not on `PATH`.

Android export, install, touch playthrough, and lifecycle validation remain open until those tools and a device or emulator are available.
