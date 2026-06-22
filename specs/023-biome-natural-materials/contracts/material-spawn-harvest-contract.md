# Contract: Material Spawn and Harvest

**Branch**: `023-biome-natural-materials` | **Date**: 2026-06-22

## Spawn Input

```gdscript
{
	"now": float,
	"changed_coords": Array[Vector2i],
	"force_full_refresh": bool
}
```

## Spawn Output

```gdscript
{
	"spawned_nodes": Array[Dictionary],
	"updated_clusters": Array[String],
	"next_due_at": float
}
```

## Harvest Input

```gdscript
{
	"node_id": StringName,
	"actor": StringName,       # player, auto_harvest, debug
	"coord": Vector2i
}
```

## Harvest Output

```gdscript
{
	"outcome": StringName,     # success|missing_node|not_ready|already_collected|inventory_full
	"material_id": StringName,
	"amount": int,
	"feedback_key": StringName
}
```

## Invariants

- Nodes spawn only on existing eligible biome tiles.
- A node can award material at most once.
- Inventory-full harvest attempts leave the node ready and harvestable.
- Spawn caps are enforced per cluster.
- Spawn evaluation is deterministic from persisted state.
- Manual and auto-harvest use the same inventory and duplicate-prevention rules.
- Visual landmarks are representations of material nodes; they do not bypass the node contract.

## Initial Acceptance Fixtures

| Garden State | Time | Expected |
|--------------|------|----------|
| One Meadow tile, no nodes | spawn interval elapsed | one Living Wood node or pending node |
| Meadow cluster above landmark threshold | spawn interval elapsed | Living Wood landmark node eligible |
| Ready Living Wood node | player harvest | material inventory `living_wood += amount` |
| Collected Living Wood node | player harvest again | already_collected, no inventory change |
| Ready node, full inventory | player harvest | inventory_full, node remains ready |
