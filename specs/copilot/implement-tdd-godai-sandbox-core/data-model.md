# Data Model — Godai Sandbox Core (v6.0) Phase A

## Entity: KushoPool
- **Type**: RefCounted domain model
- **Fields**:
  - `CAPACITY_PER_ELEMENT: int = 3`
  - `_charges: Dictionary<int, int>` keyed by `GodaiElement.Value`
- **Validation Rules**:
  - Charges clamp to `[0, CAPACITY_PER_ELEMENT]`
  - Unknown elements default to `0`
- **Behavior**:
  - `consume(element, amount)` succeeds only when enough charge exists
  - `add_charge(element, amount)` adds up to cap and returns overflow amount
  - `is_low(element)` true at exactly `1`
  - `is_depleted(element)` true at `0`
  - `are_all_depleted()` true when every element is `0`

## Entity: ResonanceState
- **Type**: Internal SoundscapeEngine runtime state
- **Fields**:
  - `_resonance_time_left: float`
  - `_resonance_pitch_scale: float`
  - `RESONANCE_DECAY_SECONDS: float = 5.0`
  - `RESONANCE_MAX_PITCH_DELTA: float = 0.12`
- **Validation Rules**:
  - Time left is clamped to `>= 0`
  - Pitch scale defaults to `1.0` at rest
- **State Transition**:
  - `idle (time_left=0, pitch=1.0)`
  - `active (trigger_keisu_resonance => time_left=5.0, pitch>1.0)`
  - `decay (_process delta decrements time until 0; pitch approaches 1.0)`
