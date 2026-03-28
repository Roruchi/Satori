# Quickstart — Godai Sandbox Core (v6.0) Phase A

## Automated Validation

Run GUT tests (CI-equivalent):

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

### Validation status in current environment

- Attempted command on 2026-03-28 in sandbox shell failed with: `bash: godot: command not found`.
- Result: local automated execution blocked by missing Godot binary in this runtime.
- CI workflow (`.github/workflows/godot-tests.yml`) remains the source of truth for automated execution.

## Manual Validation

1. Launch game and load Garden scene.
2. Trigger `SoundscapeEngine.trigger_keisu_resonance()` from debug console or temporary call site.
3. Confirm background/procedural layers pitch up and smoothly decay over ~5 seconds.
4. In script console, instantiate `KushoPool` and verify:
   - low/depleted states at 1 and 0
   - cap behavior at 3
   - consume fails when depleted
