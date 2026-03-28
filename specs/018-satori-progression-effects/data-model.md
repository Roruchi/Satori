# Data Model: Satori Progression & Architectural Effects

**Branch**: `018-satori-progression-effects` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)

## SatoriProgressState

Global progression state for current garden.

Fields:
- `current_satori: int`
- `current_cap: int` (base 250 + structure contributions)
- `current_era: int|string` (Stillness, Awakening, Flow, Satori)
- `last_tick_unix_ms: int` or timer-driven cadence marker

Validation:
- `0 <= current_satori <= current_cap`
- `current_cap >= 250`
- Era derived from thresholds, never arbitrary input.

## SpiritHousingSnapshot

Tick-time aggregation inputs for generation math.

Fields:
- `housed_count: int`
- `unhoused_count: int`
- `local_pacified_unhoused: Dictionary[island_id, int]` (Guidance Lantern max 3 local)
- `island_housed_counts: Dictionary[island_id, int]` (for Void Mirror multiplier)

Validation:
- Counts are non-negative.
- Pacified count per local area capped at 3.

## EraDefinition

Static threshold model for spirit-tier transitions.

Fields:
- `era_id: int|string`
- `min_satori: int`
- `max_satori: int|INF`
- `spirit_tier_flags: Dictionary` (e.g., tier2, tier3, tier4)

Required ranges:
- Stillness: `0..499`
- Awakening: `500..1499`
- Flow: `1500..4999`
- Satori: `5000+`

Validation:
- Ranges are contiguous and non-overlapping.

## StructureDefinition (resource-backed)

Pattern/catalog definition for buildable architecture.

Fields:
- `structure_id: String`
- `tier: int` (1,2,3)
- `cap_increase: int` (50/250/1000 by tier)
- `is_unique: bool`
- `housing_capacity: int` (where applicable)
- `effect_type: String` (storage, speed, dropoff, tending_boost, pacification, burst, passive, multiplier)
- `effect_params: Dictionary`

Validation:
- Tier 1 cap increase is +50.
- Tier 2 cap increase is +250.
- Tier 3 cap increase is +1000.
- Unique monuments set `is_unique=true` and enforce max one instance.

## StructureInstance

Active manifested structure in world.

Fields:
- `structure_id: String`
- `island_id: String`
- `coord_anchor: Vector2i`
- `built_at_ms: int`
- `active: bool`

Validation:
- Unique definitions permit at most one active instance for same `structure_id`.

## ProgressionTickResult

Single-tick computed outcome for deterministic updates.

Fields:
- `base_delta: int` (`housed - unhoused*2` before modifiers)
- `modifier_delta: int` (passive and adjusted penalties/multipliers)
- `applied_delta: int`
- `new_satori: int`
- `new_era: int|string`
- `era_changed: bool`

Validation:
- `new_satori` always clamped to `[0, current_cap]`.
- `era_changed` true iff era boundary crossed.

## GateState

Era-based spirit availability state derived from era.

Fields:
- `tier2_spirits_allowed: bool` (Awakening+)
- `tier3_spirits_allowed: bool` (Flow+)
- `tier4_spirits_allowed: bool` (Satori era; Sky Whale)

Validation:
- Availability booleans are functionally derived from current era and update immediately on era change.

## SpiritTierDefinition

Tier mapping model for progression-controlled spirit visibility/summoning.

Fields:
- `spirit_id: String`
- `spirit_tier: int` (1, 2, 3, 4)
- `min_era: int|string`
- `despawn_below_required_era: bool`

Required tier assignments:
- Tier 1: baseline regular spirits (available in Stillness).
- Tier 2: higher regular spirits including Mist Stag (available in Awakening+).
- Tier 3: all Kami/deity spirits (available in Flow+).
- Tier 4: Sky Whale only (available in Satori era).

Validation:
- When current era drops below `min_era`, spawned spirits with `despawn_below_required_era=true` are removed from the world.
- Tier assignments are explicit and deterministic for spawn/despawn evaluation.

## SatoriHUDState

Player-facing runtime UI state for progression visibility.

Fields:
- `current_satori: int`
- `current_cap: int`
- `display_era: int|string`

Validation:
- HUD updates immediately after Satori/cap/era changes.
- HUD values match authoritative progression state.

## State transitions

1. **Tick transition**: `SatoriProgressState + SpiritHousingSnapshot + StructureInstances -> ProgressionTickResult -> updated SatoriProgressState`
2. **Era transition**: On Satori change, derive era; if changed, emit `era_changed(new_era)`, recompute spirit availability state, evaluate required summon/despawn updates, and refresh HUD state.
3. **Structure build transition**: On successful build, create `StructureInstance`, update cap, and apply one-time effects where applicable (Great Torii +500 up to cap).
4. **Unique reject transition**: On attempted confirmation of unique structure with existing active instance, reject confirmation and emit/UI-route blocked feedback.
