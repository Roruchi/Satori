# Research: Ku Tile Placement (Abyss Biome + Island System)

**Feature**: Ku Tile Placement  
**Branch**: `copilot/implement-ku-tile-placement`  
**Date**: 2026-03-26

## Decision 1: Island Labelling Algorithm

**Decision**: BFS connected-component labelling on the `GridMap.tiles` dictionary, treating KU tiles as walls (they are excluded from flood-fill).

**Rationale**: BFS naturally handles sparse hex grids — it only visits occupied tiles. Island IDs are stable strings derived from a canonical tile in each component (the lowest-coordinate tile found first in sorted order), making them deterministic across placements. The algorithm is O(n) in tile count and completes well under 1 ms for typical garden sizes.

**Alternatives considered**:

- Union-Find (Disjoint Set Union): More complex to implement in GDScript without a dedicated data structure; BFS is idiomatic for this codebase and already used by `SpatialQuery.get_connected_region()`.
- Persistent incremental labels: Would complicate merge/split detection when Ku tiles are placed between existing clusters. Full recomputation on each placement is simpler and correct.

## Decision 2: Island ID Format

**Decision**: Island IDs are string representations of the canonical tile's coordinate: `"q,r"` where `(q, r)` is the lexicographically smallest `Vector2i` in the connected component (sorted by `x` first, then `y`).

**Rationale**: A coordinate-derived ID is stable as long as the tile exists (permanent-placement rule) and does not require a monotone counter. It is deterministic, human-readable, and can be reproduced from the grid state alone.

**Alternatives considered**:

- Monotone integer counter: Requires storing "highest assigned ID" in GridMap state; loses determinism across save-load cycles until persistence is re-enabled.
- Hash of sorted tile coords: Opaque and harder to debug; no advantage over coordinate-derived ID for this scale.

## Decision 3: Per-Island Spirit Key Format

**Decision**: Spirit summoning records in `SpiritPersistence` are keyed by `"island_{island_id}|spirit_{spirit_id}"`. The `|` separator avoids collisions with coordinate string `","`.

**Rationale**: Additive key format — existing single-island sessions continue to work because the origin island ID `"0,0"` produces a valid key. Old global spirit_id keys (from pre-feature code) are not read during `is_summoned_on_island()`, providing a clean separation.

**Alternatives considered**:

- Nested dictionary `{island_id → {spirit_id → true}}`: More idiomatic, but harder to serialise to flat JSON without custom nesting logic. Flat compound keys are simpler given the existing persistence layer.
- Storing island_id directly in SpiritInstance: Chosen as the canonical source of truth so that restore-from-persistence can rebuild per-island active_instances.

## Decision 4: KU Biome Enum Value

**Decision**: `KU = 14` in `BiomeType.Value`. The four Ku-pair biomes are 10–13, so 14 is the next sequential value and does not conflict.

**Rationale**: Sequential ordering preserves existing integer-keyed dictionary lookups. The standalone Ku biome is conceptually distinct from the paired Ku biomes; placing it last in sequence makes it easy to identify in debug output.

**Alternatives considered**:

- Negative value (e.g., KU = -2): Would require sign-checking in render/placement code; rejected.
- Value of 100 as a "special" sentinel: Arbitrary gap; harder to iterate over all valid biomes.

## Decision 5: Ku Tile Render Colour

**Decision**: Ku (abyss) renders as near-black `Color(0.05, 0.02, 0.1)` in GardenView. Uses the same voxel rendering path as other tiles but with a dark void palette.

**Rationale**: Visually communicates "void/abyss" without requiring new render nodes. Consistent with the existing per-biome colour lookup in `GardenView._get_biome_color()`.

**Alternatives considered**:

- Transparent / hole: Would require render-order changes and an alpha-compositing pass; over-engineered for a single biome.
- Animated shimmer: Nice visual, but outside current render architecture; deferred to a later polish feature.
