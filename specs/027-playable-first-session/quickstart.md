# Quickstart: Playable First Session

## Automated Validation

Run focused suites as implementation lands:

```powershell
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
.\tools\godot.ps1 -Command test -Test tests/unit/test_ritual_menu_ui.gd
.\tools\godot.ps1 -Command test -Test tests/unit/test_biome_material_harvesting.gd
.\tools\godot.ps1 -Command test -Test tests/unit/test_first_expansion_loop.gd
```

## Manual First-Session Script

1. Start from a fresh save.
2. Start a new game from the title screen.
3. Open the ritual menu.
4. Create Meadow Seed from Wind/Fu.
5. Plant Meadow Seed.
6. Let Meadow reach the First Bloom material-producing state.
7. Harvest Living Wood.
8. Confirm Red Fox state is visible.
9. Shape Warm Hollow from Living Wood and Fire Essence.
10. Place Warm Hollow as a valid Meadow dwelling.
11. Confirm Red Fox automatically becomes housed and Satori feedback updates.
12. Save, quit, reload, and confirm the housing state persists.

## Completion Evidence

Attach command output and manual notes to the roadmap tracker before marking this spec verified.
