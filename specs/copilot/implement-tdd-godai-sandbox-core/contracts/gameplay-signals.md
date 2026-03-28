# Gameplay Contract — Audio Resonance and Kusho Model

## SoundscapeEngine Contract
- `trigger_keisu_resonance()`
  - Starts/resets a 5-second resonance decay window.
  - During decay, global background pitch scale is elevated and decays back to 1.0.
- `get_resonance_pitch_scale() -> float`
  - Returns current resonance pitch scale for test/diagnostics.

## KushoPool Contract
- `set_charge(element: int, charge: int) -> void`
- `get_charge(element: int) -> int`
- `consume(element: int, amount: int = 1) -> bool`
- `add_charge(element: int, amount: int = 1) -> int` (returns overflow)
- `is_low(element: int) -> bool`
- `is_depleted(element: int) -> bool`
- `are_all_depleted() -> bool`
