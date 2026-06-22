# Research: Ritual Menu and Slot-Based Creation

**Branch**: `022-ritual-menu-slots` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## 1. Ritual Identity Normalization

**Decision**: Normalize rituals by input identity, not slot index. Each input exposes a stable identity such as `essence:fire`, `material:living_wood`, `component:wind_chime` or `spirit:spirit_red_fox`.

**Rationale**: The master plan says ritual slots are unique and recipes are meaning-based. Identity keys let all input categories share one duplicate rule.

**Alternatives Considered**:

- Keep the 9-slot normalizer and only hide unused slots. Rejected because it preserves grid thinking and duplicate-token behavior.
- Allow duplicate essences but not duplicate materials. Rejected because the user explicitly requires no duplicates ever.

## 2. Seed Recipe Compatibility

**Decision**: Keep current seed recipe resources and registry as the seed-result source, but route menu attempts through ritual normalization before seed lookup.

**Rationale**: Seed creation is already implemented and tested. The design change is player-facing grammar and resolver constraints, not a need to rewrite the seed catalog immediately.

**Alternatives Considered**:

- Replace all seed recipes with a new resource type in the same feature. Rejected as too broad for the foundation step.

## 3. Building Recipe Migration

**Decision**: Current `BuildingRecipeCatalog.gd` entries with duplicate tokens are invalid in the target ritual grammar and should be blocked or replaced by no-duplicate material/essence recipes.

**Rationale**: Keeping `CHI + CHI + FU` style recipes would directly violate the new slot rule and keep the old design alive.

**Alternatives Considered**:

- Temporarily grandfather duplicate building recipes. Rejected because it would make the most important rule inconsistent at the moment the player learns rituals.

## 4. Form Before Placement Role

**Decision**: A material ritual can create a placeable form that resolves to its final structure role when placed. Warm Hollow is the first case.

**Rationale**: This answers the design question: Meadow material + Fire does not always need to produce that biome's house directly. Placement context carries meaning.

**Alternatives Considered**:

- Make every material + Fire recipe produce a direct house. Rejected because it flattens the ritual language and makes Fire too repetitive.

## 5. Service Boundary

**Decision**: Start inside `SeedAlchemyService` and `SeedAlchemyPanel`; extract `RitualRecipeCatalog` or `RitualResolver` only when implementation needs it.

**Rationale**: The existing service already owns charges, inventory insertion and discovery signals. A premature new autoload would add load-order and naming risk.

**Alternatives Considered**:

- Create a new autoload immediately. Rejected for MVP because there is no cross-scene state that the existing alchemy service cannot host yet.
