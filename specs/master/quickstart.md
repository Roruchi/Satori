# Quickstart: Satori Development

**Branch**: `master` | **Date**: 2026-03-23

---

## Prerequisites

- **Godot 4.6** (Download from godotengine.org — use the .NET-free Standard build)
- **GdUnit4** addon installed in the project (see below)
- **Git** (branch management via Speckit sequential numbering)

## Opening the Project

```bash
# Open in Godot editor
godot --editor "C:/Repo/Personal/Games/Satori/project.godot"
# Or simply double-click project.godot in the Godot Project Manager
```

## Installing GUT v9+ (First-Time Setup)

1. In the Godot editor: **AssetLib → Search "Gut" → Install**
2. Or manually: download from https://github.com/bitwes/Gut/releases and place the `gut/` folder in `addons/gut/`
3. Enable in **Project → Project Settings → Plugins → GUT ✓**

## Running the Game

- **F5** in the Godot editor to launch from the Main scene
- Or headless: `godot --path . --headless` (no window; useful for CI)

## Running Tests

```bash
# All tests via GUT headless runner scene
godot --path . --headless -s tests/gut_runner.tscn

# Single test file (pass the path as a GUT argument)
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_grid.gd
```

Or use the **GUT panel** in the Godot editor bottom dock.

## Running the Debug Scene

1. Open `scenes/Debug.tscn` in the editor
2. Press **F5** to run with debug overlay active
3. Keybinds (in-editor only):
   - `D` — toggle coordinate overlay
   - `F` — flood-fill N tiles for quick seeding
   - `P` — toggle pattern visualizer
   - `I` — toggle instant-placement mode (bypass long-press)

## Export (Mobile)

- **Project → Export → Android / iOS** preset
- Debug scene is excluded via export filter: `scenes/Debug.tscn` excluded; `RELEASE` feature flag set
- Ensure `user://` is writable on device for save data

## Project Configuration Notes

- Physics: **Jolt** (already set in `project.godot`)
- Renderer: **Forward Plus** (already set)
- Graphics API (Windows dev): **Direct3D 12** (already set)
- Line endings: **LF** (enforced via `.gitattributes` — do not change)
