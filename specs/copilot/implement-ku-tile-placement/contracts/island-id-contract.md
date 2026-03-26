# Contract: Island ID Assignment

**Feature**: Ku Tile Placement  
**Date**: 2026-03-26

## Invariants

1. Every non-Ku tile in `GridMap.tiles` has a non-empty `metadata["island_id"]` string after `compute_island_ids()` runs.
2. Two non-Ku tiles have the same `island_id` if and only if they are connected by a path of non-Ku tiles through hex adjacency.
3. A KU tile always has `metadata["island_id"] == ""` (empty string).
4. `compute_island_ids()` is called by `GridMap.place_tile()` after every placement, so the island map is always current.
5. Island IDs are derived from grid state alone — they are fully reproducible from the tile dictionary without external counters.

## ID Format

```
island_id = "{q},{r}"
```

Where `(q, r)` is the `Vector2i` coord of the **lexicographically smallest** tile in the connected component (sorted by `.x` first, then `.y` as tiebreaker).

**Example**: A component containing tiles at `(0,0)`, `(1,0)`, `(0,1)` has `island_id = "0,0"`.

## Spirit Compound Key Format

```
spirit_key = "island_{island_id}|spirit_{spirit_id}"
```

**Example**: `"island_0,0|spirit_spirit_mist_stag"`

The `|` character is chosen because it cannot appear in either a coordinate string or a spirit ID.

## Recompute Trigger

`compute_island_ids()` is called from within `GridMap.place_tile()` immediately after adding the tile to `tiles`. This ensures all downstream consumers (SpiritService, pattern scan) see a current island map at the time the `GameState.tile_placed` signal fires.
