# Contract: Progression Signals and Thresholds

## Purpose

Define authoritative Satori threshold behavior, minute-tick math, and emitted progression signals used by gameplay and UI systems.

## Tick calculation contract

1. Tick cadence is 60 seconds.
2. Base delta is:
   - `delta = housed_count - (unhoused_count * 2)`
3. Structure modifiers adjust this tick deterministically in the same update cycle.
4. Final Satori value is clamped to `[0, current_satori_cap]`.

## Cap contract

1. New game cap starts at `250`.
2. Each Tier 1 structure contributes `+50` cap.
3. Each Tier 2 structure contributes `+250` cap.
4. Each Tier 3 structure contributes `+1000` cap.
5. Great Torii one-time `+500` grant must not exceed cap.

## Era threshold contract

Era derivation is purely value-based:

- Stillness: `0..499`
- Awakening: `500..1499`
- Flow: `1500..4999`
- Satori: `5000+`

On any Satori update:
1. Recompute era from thresholds.
2. Emit `era_changed(new_era)` only if derived era differs from previous era.
3. Update Kami gates immediately:
   - Lesser Kami open in Awakening+
   - Major Kami open in Flow+
   - Prestige/Sky Whale readiness in Satori era

## Signal behavior contract

1. Progression listeners must receive deterministic ordering: value update, era derivation, then era signal when changed.
2. No duplicate era-changed signal may be emitted when Satori changes within the same era range.
3. Falling below a threshold immediately closes dependent gate states.

## Non-goals

1. This contract does not define visual styling of era UI widgets.
2. This contract does not alter unrelated discovery/spawn systems beyond era-gate predicates.
