# Quickstart: Biome Natural Materials and Harvesting

**Branch**: `023-biome-natural-materials` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## Automated Validation

Run focused GUT suites after implementation:

```powershell
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs
```

Minimum tests to add:

- Meadow material definition maps to `living_wood`.
- Spawn evaluation creates no more than the configured cap per cluster.
- Spawn anchor selection is deterministic.
- Harvesting a ready node increments material inventory.
- Harvesting the same node twice does not duplicate inventory.
- Inventory-full harvest preserves the ready node.
- Save/load restores material inventory and ready node state.
- First-session material flow can reach Warm Hollow and Meadow Dwelling from a fresh garden.

## Manual Editor Flow

1. Start a fresh garden.
2. Create and place a Meadow.
3. Advance time through debug controls or wait for the configured spawn interval.
4. Verify a Living Wood node appears and is visually readable.
5. Build a larger Meadow cluster and verify a large tree-style landmark can appear when the threshold is met.
6. Tap/click the material node and verify harvest feedback plus inventory count.
7. Save and reload; verify unharvested nodes persist.
8. Check standard zoom and mobile viewport: the node should be tappable without precision frustration.

## First-Session Material Gate

After `023`, the player should be able to test the opening loop without debug grants:

1. Create Meadow from Wind.
2. Wait for or accelerate natural Living Wood.
3. Harvest Living Wood.
4. Use Living Wood + Fire Essence in the ritual menu.
5. Receive Warm Hollow.
6. Place Warm Hollow on Meadow and verify Meadow Dwelling.
7. Verify Red Fox, Hare or another Meadow spirit can be housed there.

## Visual Review

Material nodes should:

- Read as part of the biome, not as UI stickers.
- Be clearly harvestable.
- Avoid hiding structure placement previews.
- Use deterministic placement so screenshots do not flicker across reloads.

## Regression Notes

- This feature should not change seed growth rules.
- This feature should not change spirit invite triggers except where material visuals share rendering space.
- This feature should not break Mist Stag, Ku unlock or second-island flows; those remain explicit end-to-end gates in feature 024.
- Root Network and Wind Chime can be no-op modifier hooks until their structures are implemented.
