# Quickstart: Android Alpha

## Preflight

```powershell
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
```

Confirm Android export templates and SDK/JDK are configured in Godot.
Confirm the Android preset uses package id `com.lunaverse.satori`, no orientation lock, title-emblem icon, and `0.x.y-alpha+<build_id>` menu versioning.

## Export

Use the Godot editor export dialog or documented CLI once the Android preset exists.

## Manual Device Script

1. Install build on device or emulator.
2. Launch to title screen.
3. Start new game.
4. Validate pan, zoom, tap, placement, ritual menu, build/project confirmation, Codex, settings.
5. Complete first-session loop.
6. Play through Mist Stag -> Ku Seed -> Void separation -> Chi+Ku calm-water island -> Suijin.
7. Background app and resume.
8. Close app and reopen.
9. Confirm save state persists.
10. Confirm no placeholder art, audio, icon, or UI assets appear on the primary alpha path or release shell.
