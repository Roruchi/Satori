# Pattern Matching Engine Quickstart

## Overview

Pattern discovery is fully data-driven. Add a `PatternDefinition` `.tres` file under `src/biomes/patterns/` and the matcher will load it automatically.

## Create a New Pattern

1. Duplicate an existing pattern file such as `src/biomes/patterns/deep_stand_cluster.tres`.
2. Update `discovery_id` with a unique stable ID.
3. Set `pattern_type`:
- `0` = cluster
- `1` = shape
- `2` = ratio_proximity
- `3` = compound
4. Fill only fields relevant to that type:
- Cluster: `required_biomes`, `size_threshold`
- Shape: `shape_recipe`
- Ratio/proximity: `required_biomes`, `neighbour_requirements` (`radius`, `biomes`)
- Compound: `prerequisite_ids` plus one spatial condition set (cluster, shape, or ratio)

## Validation Rules

A pattern is skipped with a warning if invalid:

- Missing `discovery_id`
- Cluster without `required_biomes` or `size_threshold <= 0`
- Shape without `shape_recipe`
- Ratio/proximity without `neighbour_requirements.radius` and `neighbour_requirements.biomes`
- Compound without `prerequisite_ids` or spatial requirements

## Runtime Behavior

- Scan runs after each tile placement through `PatternScanScheduler`.
- `PatternMatcher` emits `discovery_triggered(discovery_id, triggering_coords)`.
- Discovery IDs are persisted by `DiscoveryRegistry` and only emit once.
- Emission order is deterministic (ascending `discovery_id`).
