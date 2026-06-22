# Quickstart: Ritual Menu and Slot-Based Creation

**Branch**: `022-ritual-menu-slots` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## Automated Validation

Run focused GUT suites after implementation:

```powershell
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs
```

Minimum tests to add or update:

- Ritual normalization rejects duplicate input identities.
- Ritual normalization is order-insensitive.
- Wind Essence produces Meadow Seed through the ritual path.
- Living Wood + Fire Essence produces Warm Hollow.
- Duplicate legacy building tokens do not produce a building.
- Inventory-full ritual attempt preserves inputs and discoveries.
- Warm Hollow placement on Meadow resolves to Meadow Dwelling.
- Warm Hollow placement on Fire/Hearth resolves to Scorched Hollow.
- First-session bridge test: Meadow creation, Meadow spirit invitation and valid spirit housing still work after grid replacement.

## Manual Editor Flow

1. Launch `project.godot` in Godot 4.6+.
2. Start a fresh garden.
3. Open the ritual menu.
4. Confirm the panel shows up to three ritual slots, not a 9-cell grid.
5. Select Wind Essence and confirm; verify a Meadow Seed or placeable is added.
6. Create or debug-add Living Wood.
7. Select Living Wood + Fire Essence; verify Warm Hollow preview and confirm result.
8. Try selecting the same essence twice; verify the UI blocks or clearly rejects it.
9. Place Warm Hollow on Meadow; verify Meadow Dwelling outcome and housing eligibility.
10. Place Warm Hollow on Fire/Hearth; verify Fire-context shelter outcome.

## First-Session Bridge Gate

This feature is not complete if replacing the grid makes the game untestable until later material/spirit work lands.

Minimum playable path after `022`:

1. Fresh garden can create and place Meadow.
2. Meadow can still invite at least one current Meadow spirit, preferably Red Fox or Hare.
3. The player can still place a valid house for that spirit.
4. If natural Living Wood spawning from `023` is not implemented yet, the implementation must keep a documented temporary way to obtain or simulate Living Wood for the Warm Hollow path, or keep a no-duplicate compatibility housing recipe active.

## Copy Review

Review the affected UI and feedback for player-facing legacy terms:

- Avoid: "craft grid", "grid recipe", "slot pattern" in player-facing text.
- Prefer: "ritual", "shape", "form", "seed", "essence", "material", "context".

## Regression Notes

- Existing seed recipe IDs may stay internal.
- Existing `BuildingRecipeCatalog.gd` may remain as migration data until replaced, but duplicate-token entries must not be reachable as valid player rituals.
- Do not block old duplicate-token building recipes until a playable no-duplicate housing replacement exists.
- Update `specs/master/recipes.md` if implementation renames any unlocks or changes first discovery mappings.
