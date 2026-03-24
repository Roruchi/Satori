# Research: Feature 007 — Tier 2 Structural Landmark Discoveries

## Shape Constraint Support

### Decision: Extend Dictionary-based shape_recipe with new entry keys
- **Rationale**: `PatternDefinition.shape_recipe` is already `Array[Dictionary]`. Adding `must_be_empty: bool` and `absolute_anchor: bool` keys to individual recipe entries avoids schema changes and stays backward compatible — entries missing these keys default to `false`.
- **Alternatives considered**: A new `PatternType.LANDMARK_SHAPE` enum variant. Rejected because the existing SHAPE type machinery handles all the same logic; a new variant would duplicate code.

### Decision: absolute_anchor constrains the anchor iteration set in ShapeMatcher
- **Rationale**: When a recipe entry has `absolute_anchor: true`, its `offset` value is an absolute grid coordinate (not relative to an anchor). ShapeMatcher must only try that coordinate as the anchor, preventing false-positive matches at other anchors.
- **Effect**: Origin Shrine (Stone at absolute `(0,0)`) fires only when the Stone is placed at the grid origin and four Water tiles occupy the cross arms.

### Decision: must_be_empty entries require the position to have no tile
- **Rationale**: Echoing Cavern has an empty centre ring. The centre coordinate is never in `grid.tiles`, so it cannot serve as anchor. By anchoring on one of the ring Stone tiles and encoding the centre as `{offset: Vector2i(-1,0), must_be_empty: true}`, the match succeeds only when the centre is empty and all six surrounding tiles are Stone.

### Decision: Repurpose existing forbidden_biomes field for isolated-tile constraint
- **Rationale**: `PatternDefinition.forbidden_biomes` is already an exported `Array[int]` and is currently unused by any matcher. For SHAPE patterns, ShapeMatcher will check — after a recipe match — that none of the six hex neighbours of the anchor tile has a biome in `forbidden_biomes`. This covers Floating Pavilion ("no adjacent land tiles") without adding a new field.

## Rotation Handling

### Decision: Create multiple .tres files per rotationally ambiguous landmark
- **Rationale**: Bridge of Sighs (3-tile line, 3 directions), Bamboo Chime (5-tile line, 3 directions), and Whale-Bone Arch (U-shape, 6 rotations) each need multiple pattern definitions sharing the same `discovery_id`. The registry suppresses duplicate IDs after the first match, so only one fires per garden. This avoids adding rotation logic to ShapeMatcher.
- **Alternatives considered**: A `rotatable: bool` field + rotation matrix in ShapeMatcher. Rejected to keep the first implementation minimal — can be added later if needed.

## Biome Mapping

- "Sand" in the spec → **EARTH** (base biome value 3, sandy brown colour). Confirmed by: "Sand+Stone mixed" = CANYON = Stone+Earth.
- "Forest" → **FOREST** (0)
- "Water" → **WATER** (1)  
- "Stone" → **STONE** (2)
- "Swamp (mixed)" → **SWAMP** (4, Forest+Water hybrid)
- "Forest+Sand mixed" → **SAVANNAH** (8, Forest+Earth hybrid)
- "Sand+Stone mixed" → **CANYON** (9, Stone+Earth hybrid)

## Pattern Type Selection Per Landmark

| Landmark | PatternType | Rationale |
|---|---|---|
| Origin Shrine | SHAPE | Cross geometry + absolute coordinate anchor |
| Bridge of Sighs | SHAPE ×3 | 3-tile Stone-Water-Stone line in 3 hex directions |
| Lotus Pagoda | CLUSTER | Any 4+ connected Swamp tiles |
| Monk's Rest | SHAPE | Earth enclosed by all 6 Forest neighbours |
| Star-Gazing Deck | COMPOUND | prerequisite: Mountain Peak; cluster threshold ≥ 20 Stone |
| Sun-Dial | RATIO_PROXIMITY | Stone centre + ≥5 Earth in radius 1 |
| Whale-Bone Arch | SHAPE ×6 | U-shape of Canyon in all 6 hex rotations |
| Echoing Cavern | SHAPE | 6-Stone ring + must_be_empty centre (anchor = E Stone tile) |
| Bamboo Chime | SHAPE ×3 | 5-tile Savannah line in 3 hex directions |
| Floating Pavilion | SHAPE | Single Swamp tile; forbidden_biomes blocks any non-water neighbour |

## Visual Overlay Strategy

All 10 landmarks hook into the existing `_draw_discovery_overlay(discovery_id, coords)` dispatch in `GardenView`. Discovery coords (triggering tile positions) are passed as received from `PatternMatcher` and stored in `_discovery_overlays`. Overlays persist for the lifetime of the session (no fade) matching existing Tier 1 behaviour.
