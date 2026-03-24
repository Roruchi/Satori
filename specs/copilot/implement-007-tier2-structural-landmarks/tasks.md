# Tasks: Feature 007 — Tier 2 Structural Landmark Discoveries

**Branch**: `copilot/implement-007-tier2-structural-landmarks`
**Plan**: `specs/copilot/implement-007-tier2-structural-landmarks/plan.md`

## Phase 1: Engine Extensions

### T01 — Extend SpatialQuery.recipe_matches_at for new entry keys
- **File**: `src/grid/spatial_query.gd`
- **Change**: Handle `must_be_empty: bool` (position must have no tile) and `absolute_anchor: bool` (`offset` is absolute coord not relative) in `recipe_matches_at()`.
- **Status**: [ ]

### T02 — Extend ShapeMatcher for absolute_anchor anchoring + forbidden_biomes check
- **File**: `src/biomes/matchers/shape_matcher.gd`
- **Change**: When any recipe entry has `absolute_anchor: true`, only try that coordinate as anchor. After a shape match, if `pattern.forbidden_biomes` is non-empty, reject matches where any of the anchor's 6 neighbours has a forbidden biome.
- **Depends on**: T01
- **Status**: [ ]

## Phase 2: Catalog Data

### T03 — Add get_tier2_entries() to DiscoveryCatalogData
- **File**: `src/biomes/discovery_catalog_data.gd`
- **Change**: Add `get_tier2_entries() -> Array[Dictionary]` returning the 10 Tier 2 landmark catalog entries (discovery_id, display_name, flavor_text, audio_key, tier).
- **Status**: [ ]

### T04 — Load Tier 2 entries in DiscoveryCatalog
- **File**: `src/biomes/discovery_catalog.gd`
- **Change**: Update `load_from_data()` to call `data.get_tier2_entries()` in addition to `get_tier1_entries()`.
- **Depends on**: T03
- **Status**: [ ]

## Phase 3: Pattern Resources

### T05 — Create tier2 pattern directory and 19 .tres files
- **Dir**: `src/biomes/patterns/tier2/`
- **Files**:
  - `origin_shrine.tres` (SHAPE, absolute_anchor Stone at (0,0), Water cross)
  - `bridge_of_sighs_e.tres`, `bridge_of_sighs_se.tres`, `bridge_of_sighs_ne.tres` (SHAPE, Stone-Water-Stone line)
  - `lotus_pagoda.tres` (CLUSTER, Swamp ≥4)
  - `monks_rest.tres` (SHAPE, Earth + 6× Forest ring)
  - `star_gazing_deck.tres` (COMPOUND, prereq disc_mountain_peak, Stone ≥20)
  - `sun_dial.tres` (RATIO_PROXIMITY, Stone centre + ≥5 Earth r=1)
  - `whale_bone_arch_0.tres` through `whale_bone_arch_5.tres` (SHAPE, Canyon U-shape × 6 rotations)
  - `echoing_cavern.tres` (SHAPE, 6-Stone ring + must_be_empty centre)
  - `bamboo_chime_e.tres`, `bamboo_chime_se.tres`, `bamboo_chime_ne.tres` (SHAPE, 5-tile Savannah line)
  - `floating_pavilion.tres` (SHAPE, Swamp + forbidden_biomes for non-Water neighbours)
- **Depends on**: T01, T02
- **Status**: [ ]

## Phase 4: Visual Overlays

### T06 — Add 10 landmark overlay functions to GardenView
- **File**: `src/grid/GardenView.gd`
- **Change**: Add 10 new cases to `_draw_discovery_overlay()` dispatch and corresponding `_draw_*_overlay()` helper functions for each Tier 2 landmark.
- **Status**: [ ]

## Phase 5: Tests

### T07 — Write unit tests for Tier 2 landmarks
- **File**: `tests/unit/test_tier2_landmark_discoveries.gd`
- **Coverage**:
  - All 10 landmarks trigger on correct tile configuration
  - Duplicate suppression (each landmark fires at most once)
  - `must_be_empty` constraint (Echoing Cavern)
  - `absolute_anchor` constraint (Origin Shrine)
  - `forbidden_biomes` check (Floating Pavilion)
- **Depends on**: T01–T05
- **Status**: [ ]
