# Quickstart: Satori Progression & Architectural Effects

**Branch**: `018-satori-progression-effects` | **Date**: 2026-03-28

## Goal

Validate the Satori cap/generation loop, era-driven spirit-tier transitions, runtime Satori UI visibility, structure effects, and unique monument confirmation behavior.

## Prerequisites

1. Godot 4.6 available locally.
2. Run from repository root.
3. Use either clean save state or controlled debug harness state for deterministic checks.

## Automated validation

Run focused suites first:

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gtest=res://tests/unit/test_satori_service.gd -gexit
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gtest=res://tests/unit/patterns/test_pattern_loader.gd -gexit
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gtest=res://tests/unit/spirits/test_shrine_interact_flow.gd -gexit
```

Then run full unit suite:

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

## Manual verification flow

### 1) Satori tick + clamp behavior

1. Configure a state with known housed/unhoused counts.
2. Advance one minute tick.
3. Confirm expected delta and clamp to `[0, cap]`.
4. Repeat with underflow and overflow boundary cases.

Expected:
- Formula matches `housed - (unhoused*2)` before modifiers.
- Final Satori never drops below 0 or exceeds cap.

### 2) Era transitions and spirit-tier behavior

1. Move Satori across each threshold upward: 499→500, 1499→1500, 4999→5000.
2. Move downward across thresholds: 500→499, 1500→1499, 5000→4999.
3. Observe era indicators, spirit appearance checks on upward crossing, and spirit disappearance on downward crossing.

Expected:
- Era changes only at boundary crossings.
- Tier 2/Tier 3/Tier 4 spirit eligibility updates immediately according to era.
- Spirits requiring a higher era disappear when the era falls below their threshold.

### 2.5) Satori HUD visibility

1. Trigger Satori changes through housed/unhoused state.
2. Trigger cap changes through structure builds.
3. Observe player HUD element for Satori and era.

Expected:
- HUD always shows current Satori amount and current cap.
- HUD era label/value updates immediately with era transitions.
- HUD values match authoritative progression state.

### 3) Structure cap growth

1. Build one Tier 1 dwelling; verify cap +50.
2. Build one Tier 2 pavilion; verify cap +250.
3. Build one Tier 3 monument; verify cap +1000.

Expected:
- Cap increments match tier definitions.
- Current Satori is re-clamped if needed after cap-affecting events.

### 4) Unique monument rejection

1. Build a unique monument once; confirm success.
2. Recreate matching blueprint for same monument.
3. Observe confirmation UI state.

Expected:
- Second attempt is blocked pre-confirmation.
- Bell does not appear/activate for blocked unique.
- Player receives visible rejection feedback.

### 5) Monument-specific effects

1. Great Torii: verify instant +500 grant capped by current cap.
2. Pagoda of the Five: verify +5 passive per minute and universal housing capacity behavior.
3. Void Mirror: verify 1.5x housed-spirit generation multiplier on its island.

Expected:
- Effects apply deterministically and only where scoped.

## Verification checklist

- [ ] Tick delta/clamp cases pass (including edge cases).
- [ ] Era boundary transitions pass in both directions with correct summon/despawn behavior.
- [ ] Tier cap contributions are correct.
- [ ] Satori HUD shows amount/cap/era and updates immediately.
- [ ] Unique monument second-attempt rejection works.
- [ ] Monument special effects behave as specified.
- [ ] Focused GUT suites and full suite pass.
