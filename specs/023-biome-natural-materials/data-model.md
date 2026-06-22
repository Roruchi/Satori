# Data Model: Biome Natural Materials and Harvesting

**Branch**: `023-biome-natural-materials` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## MaterialId

Canonical material IDs used by rituals and inventory.

Initial values:

- `living_wood`
- `reed_fiber`
- `spirit_stone`
- `ember_clay`

Validation:

- IDs must match `specs/master/recipes.md` unless the master reference is updated in the same change.

## BiomeMaterialDefinition

Data mapping biome context to a material output.

Fields:

- `definition_id: StringName`
- `biome_ids: Array[int]`
- `biome_tags: Array[StringName]`
- `material_id: StringName`
- `base_spawn_seconds: float`
- `max_nodes_per_cluster: int`
- `cluster_landmark_threshold: int`
- `small_visual_id: StringName`
- `landmark_visual_id: StringName`

Initial mappings:

- Meadow -> Living Wood
- Pond/Water family -> Reed Fiber
- Stonefield/Stone family -> Spirit Stone
- Hearth/Fire family -> Ember Clay

Validation:

- `base_spawn_seconds > 0`.
- `max_nodes_per_cluster >= 1`.
- At least one biome ID or biome tag is required.

## MaterialSpawnCluster

Deterministic group of connected eligible biome tiles.

Fields:

- `cluster_id: String`
- `biome_key: StringName`
- `coords: Array[Vector2i]`
- `anchor_coord: Vector2i`
- `last_evaluated_at: float`
- `next_spawn_at: float`
- `active_node_ids: Array[StringName]`

Validation:

- `anchor_coord` must be one of `coords`.
- `cluster_id` is stable while the same connected region exists.
- Active node count must not exceed definition cap.

## MaterialNode

Persistent harvestable world object.

Fields:

- `node_id: StringName`
- `material_id: StringName`
- `amount: int`
- `coord: Vector2i`
- `cluster_id: String`
- `visual_id: StringName`
- `spawned_at: float`
- `state: StringName` (`growing|ready|collected`)
- `harvested_at: float`

Validation:

- `amount >= 1`.
- Ready nodes are harvestable once.
- Collected nodes cannot award material again.

## MaterialInventory

Store for harvested materials used by rituals.

Fields:

- `counts: Dictionary[StringName, int]`
- `capacity_by_material: Dictionary[StringName, int]`

Validation:

- Counts cannot be negative.
- Capacity failures preserve the node state.
- Low default capacities are allowed; storage structures can raise caps later.

## MaterialSpawnModifier

Effect from structures or island states.

Fields:

- `source_id: StringName`
- `material_id: StringName`
- `coord: Vector2i`
- `radius: int`
- `spawn_speed_multiplier: float`
- `auto_harvest: bool`

Initial hooks:

- Root Network: increases Living Wood generation speed near Meadow tiles.
- Wind Chime: can auto-harvest nearby Living Wood.

Validation:

- Multipliers must be clamped to a configured min/max range.
- Auto-harvest must use the same inventory-capacity rules as manual harvest.

## State Transitions

1. **Cluster Evaluation**: Build or refresh eligible clusters after tile changes or scheduled ticks.
2. **Spawn Check**: If a cluster has capacity and time has elapsed, create a `MaterialNode`.
3. **Ready Visual**: Draw node or landmark in the garden.
4. **Harvest Attempt**: Player interacts with node.
5. **Inventory Commit**: Add material to inventory.
6. **Collected Mark**: Mark node collected only after inventory commit succeeds.
7. **Persistence**: Save inventory, node states and cluster timers.
