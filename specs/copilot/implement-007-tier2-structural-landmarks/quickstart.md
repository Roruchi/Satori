# Quickstart: Feature 007 — Tier 2 Structural Landmark Discoveries

## Triggering a Landmark in the Editor

1. Launch Godot and press **F5** to run the game.
2. Select a biome and place tiles to build the desired recipe.
3. The discovery notification appears automatically after the final tile is placed.

### Example — Origin Shrine (fastest to trigger)
1. Ensure the grid origin `(0,0)` has a **Stone** tile (place it first, or it may already exist as Forest; replace by mixing if needed).
2. Place **Water** tiles at the four cross arms: `(1,0)`, `(-1,0)`, `(0,1)`, `(0,-1)`.
3. After the fourth Water placement the "Origin Shrine" notification fires.

### Example — Echoing Cavern
1. Place six **Stone** tiles around any empty hex centre: `(1,0)`, `(-1,0)`, `(0,1)`, `(0,-1)`, `(1,-1)`, `(-1,1)` relative to the empty centre cell.
2. After placing the sixth Stone the "Echoing Cavern" notification fires and the ring tiles receive a glowing overlay.

## Automated Tests

Run all unit tests headlessly:
```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

The new test suite `tests/unit/test_tier2_landmark_discoveries.gd` covers:
- All 10 landmark pattern matches (SC-001)
- Duplicate-suppression after second shape construction (SC-002)
- `must_be_empty` constraint (Echoing Cavern centre cell)
- `absolute_anchor` constraint (Origin Shrine Stone at `(0,0)`)
- `forbidden_biomes` neighbour check (Floating Pavilion isolation)

## Pattern Resource Layout

```
src/biomes/patterns/
├── tier1/                 # existing Tier 1 patterns
└── tier2/
    ├── origin_shrine.tres
    ├── bridge_of_sighs_e.tres
    ├── bridge_of_sighs_se.tres
    ├── bridge_of_sighs_ne.tres
    ├── lotus_pagoda.tres
    ├── monks_rest.tres
    ├── star_gazing_deck.tres
    ├── sun_dial.tres
    ├── whale_bone_arch_0.tres  (U-shape 0° rotation)
    ├── whale_bone_arch_1.tres  (60°)
    ├── whale_bone_arch_2.tres  (120°)
    ├── whale_bone_arch_3.tres  (180°)
    ├── whale_bone_arch_4.tres  (240°)
    ├── whale_bone_arch_5.tres  (300°)
    ├── echoing_cavern.tres
    ├── bamboo_chime_e.tres
    ├── bamboo_chime_se.tres
    ├── bamboo_chime_ne.tres
    └── floating_pavilion.tres
```

## Discovery Catalog

`DiscoveryCatalogData.get_tier2_entries()` returns all 10 landmark entries. `DiscoveryCatalog.load_from_data()` loads both tier1 and tier2 entries. The `DiscoveryEventRouter` uses this catalog to populate `DiscoveryPayload.display_name` and `flavor_text` for the notification UI.

## Visual Overlays

Landmark tile overlays are drawn in `GardenView._draw_discovery_overlay()`. Each landmark has a unique artistic treatment (e.g. golden cross for Origin Shrine, cave-mouth glow for Echoing Cavern). Overlays persist until the session ends, matching existing Tier 1 behaviour.
