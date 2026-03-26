# Quickstart: Ku Tile Placement — Manual Validation Guide

**Feature**: Ku Tile Placement  
**Branch**: `copilot/implement-ku-tile-placement`

## Automated Tests

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -ginclude_subdirs \
  -gprefix=test_ -gsuffix=.gd -gexit
```

Expected: `test_island_labelling.gd` and `test_spirit_island_scope.gd` all pass.

## Manual In-Editor Validation

### Step 1 — Place a Ku tile

1. Launch `scenes/Garden.tscn` (F5 in editor).
2. Complete the Mist Stag unlock chain (or use debug console) so the Ku element is unlocked.
3. Open the tile selector — the **Ku (Abyss)** tile should appear as a near-black hex.
4. Select Ku and tap an empty adjacent hex.
5. **Expected**: A dark void tile appears at that coordinate. No discovery scan fires for it.

### Step 2 — Verify Island Separation

1. Place tiles to create this layout (`.` = empty, `K` = Ku, `S` = Stone):

   ```
     S S
    S K S
     S S
   ```

2. The central Ku tile should split the left-group and right-group if they were only connected through the center — but in the above they remain connected around the edges. Instead try a full vertical strip:

   ```
    S S K S S
   ```

3. **Expected**: The two Stone groups on either side of K have different island IDs. Verify in GUT test output or by printing `GameState.grid.get_island_id(coord)` from a debug script.

### Step 3 — Verify Per-Island Spirit Spawning

1. Build a pattern that triggers spirit_mist_stag on Island 1 (left group).
2. Observe Mist Stag spawning on Island 1.
3. Build an identical or triggering pattern on Island 2 (right group, separated by Ku strip).
4. **Expected**: Mist Stag spawns a second instance wandering Island 2's area.
5. **Expected (island confinement)**: Each spirit instance stays on its own island — it only wanders onto tiles that share the same `island_id`. It will never cross a Ku tile or appear on a different island. A spirit treats Ku tiles (and empty space) identically: both are impassable void.

### Step 4 — Regression Check

1. Start a fresh garden (no Ku tiles). Build normal biome patterns.
2. **Expected**: All existing spirits summon as before. No duplicate spawns. No errors in Output panel.
