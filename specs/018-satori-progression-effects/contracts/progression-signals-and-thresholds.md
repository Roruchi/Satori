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
3. Update spirit-tier eligibility immediately:
   - Tier 2 spirits eligible in Awakening+
   - Tier 3 spirits (all Kami/deities) eligible in Flow+
   - Tier 4 spirit (Sky Whale) eligible in Satori era
4. Trigger summon checks when crossing upward into a newly eligible era.
5. Remove active spirits that require a higher era when crossing downward below their requirement.

## Signal behavior contract

1. Progression listeners must receive deterministic ordering: value update, era derivation, then era signal when changed.
2. No duplicate era-changed signal may be emitted when Satori changes within the same era range.
3. Falling below a threshold immediately enforces spirit despawn for spirits that no longer meet era requirements.
4. A player-visible UI element must display current Satori amount and cap at runtime, and update immediately after Satori or cap changes.
5. Era display state in UI must stay synchronized with the currently derived era.

## Non-goals

1. This contract does not define visual styling of era UI widgets.
2. This contract does not alter unrelated discovery/spawn systems beyond era-based eligibility predicates.

## Implementation sync notes

- Era constants and threshold helpers are centralized in `src/satori/SatoriIds.gd` and `src/satori/SatoriConditionEvaluator.gd`.
- Runtime progression authority is implemented in `src/autoloads/satori_service.gd`:
  - `satori_changed(current, cap)`
  - `satori_cap_changed(cap)`
  - `era_changed(new_era)` only on actual threshold crossings
- Spirit-tier gating/despawn hook is wired in `src/spirits/spirit_service.gd` via `SatoriService.era_changed`.
- HUD/player-facing updates are wired in:
  - `src/ui/HUDController.gd` (`SatoriLabel`, `EraLabel`)
  - `src/grid/GardenView.gd` in-world text overlay fallback
