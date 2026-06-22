# Quickstart: Validate Craft Mode Building Placement

## Prerequisites
- Godot 4.6.x available locally.
- Run from repository root.

## Automated Validation (targeted)
1. Run build-mode retirement regressions (to be updated for craft-mode flow):

```powershell
& "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --path . --headless -s addons/gut/gut_cmdln.gd -- '-gdir=res://tests/unit' -ginclude_subdirs '-gprefix=test_' '-gsuffix=.gd' '-gtest=res://tests/unit/test_build_mode_regressions.gd' -gexit
```

2. Run seed crafting grid regressions (inventory-failure semantics baseline):

```powershell
& "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --path . --headless -s addons/gut/gut_cmdln.gd -- '-gdir=res://tests/unit' -ginclude_subdirs '-gprefix=test_' '-gsuffix=.gd' '-gtest=res://tests/unit/seeds/test_seed_crafting_grid.gd' -gexit
```

3. Add and run new tests for this feature scope:
- Pattern-based building craft success/failure.
- Discovery recorded on success only.
- Full-inventory failure causes no consumption and no discovery.
- Same-type stacking rules and 99-cap rollover behavior.
- Placement session confirm/cancel and footprint blocking.

## Manual In-Editor Validation
1. Open project and enter Craft mode; confirm no separate Build tab/mode remains.
2. Compose a known building pattern (for example 2x2 with Fu top and Chi bottom) and craft.
3. Verify crafted building appears in shared 8-slot inventory.
4. Repeat same building crafts to confirm same-type stacking up to 99.
5. With stack at 99 and at least one free slot, craft again and verify a second same-type stack is created.
6. Fill all 8 slots, attempt valid craft, and verify hard failure with no ingredient loss and no new discovery.
7. Select a building inventory entry and preview placement on valid and invalid tiles.
8. Confirm placement and verify one item consumed and structure placed.
9. Cancel placement and verify no world or inventory mutation.
10. Validate one-tile and multi-tile building footprints.

## Reference Artifact Sync
- If unlock tables or discovery IDs change, update `specs/master/recipes.md` in the same implementation and keep `tests/unit/test_recipes_catalog.gd` passing.
