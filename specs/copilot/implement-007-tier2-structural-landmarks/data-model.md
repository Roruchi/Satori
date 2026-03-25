# Data Model: Feature 007 — Tier 2 Structural Landmark Discoveries

## Entities

### LandmarkDefinition (extends PatternDefinition)
Tier 2 landmarks are stored as `PatternDefinition` resources (`.tres` files under `src/biomes/patterns/tier2/`). No new class is needed because the existing `PatternDefinition` schema covers all required fields plus two new implicit recipe-entry keys.

| Field | Type | Notes |
|---|---|---|
| `discovery_id` | String | e.g. `"disc_origin_shrine"` — unique, stable |
| `display_name` | String | In `DiscoveryCatalogData.get_tier2_entries()` |
| `flavor_text` | String | In `DiscoveryCatalogData.get_tier2_entries()` |
| `audio_key` | String | In `DiscoveryCatalogData.get_tier2_entries()` |
| `tier` | int | 2 — stored in catalog data entry |
| `pattern_type` | PatternType | SHAPE / CLUSTER / RATIO_PROXIMITY / COMPOUND |
| `shape_recipe` | Array[Dictionary] | See Recipe Entry below |
| `forbidden_biomes` | Array[int] | For SHAPE: biomes forbidden on anchor neighbours |
| `size_threshold` | int | For CLUSTER / COMPOUND |
| `prerequisite_ids` | Array[String] | For COMPOUND |
| `neighbour_requirements` | Dictionary | For RATIO_PROXIMITY |

### Recipe Entry (Dictionary inside shape_recipe)
Extended semantics for Tier 2 constraint types:

| Key | Type | Default | Meaning |
|---|---|---|---|
| `offset` | Vector2i | required | Relative offset from anchor (or absolute coord if `absolute_anchor` is true) |
| `biome` | int | required if not `must_be_empty` | BiomeType value the tile must have |
| `must_be_empty` | bool | false | Position must have no tile |
| `absolute_anchor` | bool | false | `offset` is an absolute grid coordinate; ShapeMatcher only tries this coordinate as anchor |

### Landmark Catalogue (10 landmarks)

| ID | Display Name | Pattern | Key biomes |
|---|---|---|---|
| `disc_origin_shrine` | Origin Shrine | SHAPE | Stone @ abs(0,0); Water cross |
| `disc_bridge_of_sighs` | Bridge of Sighs | SHAPE ×3 | Stone–Water–Stone line |
| `disc_lotus_pagoda` | Lotus Pagoda | CLUSTER | Swamp ≥ 4 |
| `disc_monks_rest` | Monk's Rest | SHAPE | Earth + 6× Forest ring |
| `disc_star_gazing_deck` | Star-Gazing Deck | COMPOUND | prereq Mountain Peak; Stone ≥ 20 |
| `disc_sun_dial` | Sun-Dial | RATIO_PROXIMITY | Stone centre + ≥5 Earth r=1 |
| `disc_whale_bone_arch` | Whale-Bone Arch | SHAPE ×6 | Canyon U-shape |
| `disc_echoing_cavern` | Echoing Cavern | SHAPE | 6-Stone ring + empty centre |
| `disc_bamboo_chime` | Bamboo Chime | SHAPE ×3 | Savannah 5-tile line |
| `disc_floating_pavilion` | Floating Pavilion | SHAPE | Swamp; no adjacent non-Water |

## Key System Relationships

```
DiscoveryCatalogData
  get_tier1_entries() → Array[Dictionary]    (existing)
  get_tier2_entries() → Array[Dictionary]    (new)
        ↓
DiscoveryCatalog.load_from_data(data)
  loads both tier1 and tier2 entries

PatternLoader
  loads all .tres under src/biomes/patterns/ (recursive, includes tier2/)

PatternMatcher
  existing: SHAPE → ShapeMatcher (extended)
  existing: CLUSTER → ClusterMatcher
  existing: RATIO_PROXIMITY → RatioProximityMatcher
  existing: COMPOUND → CompoundMatcher + fallback

SpatialQuery.recipe_matches_at()
  extended: handles must_be_empty, absolute_anchor entry keys

GardenView._discovery_overlays  (discovery_id → Array[Vector2i])
  populated by PatternScanService.discovery_triggered signal
  rendered per-frame in _draw() → _draw_discovery_overlay() (10 new cases)
```

## State & Persistence

Discovered landmark IDs are stored in `DiscoveryRegistry` (in-memory, session) and persisted via `DiscoveryPersistence` (existing `DiscoveryLog`). No schema changes to persistence are required; the same `discovery_id` / `trigger_timestamp` / `triggering_coords` structure handles Tier 2 entries identically to Tier 1.
