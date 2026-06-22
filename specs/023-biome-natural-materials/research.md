# Research: Biome Natural Materials and Harvesting

**Branch**: `023-biome-natural-materials` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## 1. Natural Nodes vs Passive Counters

**Decision**: Represent generated materials as visible harvestable nodes in the garden.

**Rationale**: The master plan says materials appear naturally and are actively harvested. Visible nodes make the loop legible and satisfying.

**Alternatives Considered**:

- Add passive material counters per biome. Rejected because it hides the ecosystem fantasy.
- Add instant material on tile placement. Rejected because it removes growth and harvesting from the loop.

## 2. Cluster Anchor Visuals

**Decision**: Clusters can spawn a large landmark visual, starting with a Meadow Living Wood tree, instead of spawning one object per tile.

**Rationale**: This gives visual reward without clutter and matches the user's example.

**Alternatives Considered**:

- Spawn tiny objects on every eligible tile. Rejected due to visual noise and mobile tap precision problems.

## 3. Determinism

**Decision**: Spawn timing and anchor selection use deterministic state derived from cluster identity, last spawn time and persisted node IDs.

**Rationale**: Saves and offline progression must restore the same material state.

**Alternatives Considered**:

- Use non-seeded random placement each load. Rejected because material nodes would jump or duplicate.

## 4. Storage Boundary

**Decision**: Material inventory is separate from seed pouch and building place inventory.

**Rationale**: Materials are ritual inputs and should not compete with placeable seeds/buildings for slots unless a later economy design chooses that intentionally.

**Alternatives Considered**:

- Reuse `SeedPouch`. Rejected because seeds/placeables and materials have different semantics and stack behavior.

## 5. Modifier Hooks

**Decision**: Material spawn definitions support modifiers from structures, but the MVP only needs manual harvesting and data hooks.

**Rationale**: Root Network and Wind Chime are already defined in recipes. Hooking for speed/auto-harvest avoids redesign later.

**Alternatives Considered**:

- Implement automation fully now. Rejected because it belongs after basic material spawning is readable and tested.
