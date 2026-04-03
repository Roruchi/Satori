# Quickstart: Phase 1 Seed Crafting in 3x3 Grid

**Branch**: `019-seed-crafting-grid` | **Date**: 2026-03-31

## Goal

Validate deterministic Phase 1 seed crafting from a 3x3 grid, including position-insensitive matching, consume-on-success semantics, inventory-full blocking behavior, clear feedback states, and mobile slot hit target sizing.

## SC-004 Timing Protocol

1. Test on desktop (mouse/keyboard) in a fresh play session with tutorial overlays disabled.
2. Use `CHI` single-token craft as the first craft attempt.
3. Start timer at first interaction with the already-open crafting menu.
4. Stop timer when the crafted seed appears in plant inventory.
5. Run at least 5 testers and record pass/fail against <= 30s.

## Prerequisites

1. Godot 4.6 available locally.
2. Run commands from repository root.
3. Use a deterministic save/debug state with known unlock and inventory capacity values.

## Automated validation

Run focused crafting tests first (update test paths when tasks are implemented):

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gtest=res://tests/unit/seeds/test_seed_crafting_grid.gd -gexit
```

Optional full unit sweep:

```bash
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

Expected automated assertions:
- All FR-005 single-token recipes succeed with exactly one output seed.
- All FR-006 dual-token recipes succeed across at least 3 slot arrangements each.
- Invalid or out-of-scope inputs produce no output.
- Ku-gated recipes fail when locked.
- Inventory-full valid recipe returns blocked outcome with no consumption.
- Successful craft clears consumed slots only.
- Every craft attempt emits the expected outcome feedback key.
- Every non-success outcome includes a corrective guidance phrase.

## Manual verification flow

### 1) Basic single-token craft

1. Open crafting menu.
2. Place `CHI` in any one slot.
3. Confirm craft.

Expected:
- One Stone Seed is added to plant inventory.
- The consumed slot is cleared.

### 2) Position-insensitive dual-token craft

1. Place `CHI` + `SUI` in two arbitrary slots.
2. Confirm craft.
3. Repeat with at least two different slot placements.

Expected:
- One Wetlands Seed is produced each time.
- Only occupied recipe slots are cleared on success.

### 3) Locked Ku behavior

1. Ensure Ku is locked.
2. Place `KU` (or Ku dual recipe pair) and confirm craft.

Expected:
- No output seed is created.
- Grid tokens remain unchanged.
- Unlock-required message appears.

### 4) Inventory-full blocking behavior

1. Fill plant inventory to capacity.
2. Enter a valid seed recipe.
3. Confirm craft.

Expected:
- Craft completion is blocked.
- No output seed is created.
- Recipe tokens remain in their current grid slots.
- Inventory-full message appears.

### 5) Invalid/non-seed combinations

1. Try 3+ token input and legacy structure-style combinations.
2. Confirm craft.

Expected:
- No output seed is created.
- Corrective no-matching-seed feedback appears.

### 6) Mobile touch target check

1. Open crafting UI in mobile preview or target device.
2. Inspect each slot touch area.

Expected:
- Each interactive slot target is at least 48x48 px.

### 7) Grouped build-confirm regression (unchanged)

1. Execute one baseline grouped build-confirm flow used before this feature scope.
2. Compare result to behavior from pre-feature baseline notes or expected current behavior.

Expected:
- Grouped build-confirm behavior is unchanged.
- No new seed-grid logic side effects are observed in grouped build-confirm flow.

### 8) Representative non-seed flow regression (unchanged)

1. Execute one representative non-seed flow (for example planting from plant inventory).
2. Validate expected inputs/outputs and user feedback.

Expected:
- Non-seed flow behavior remains unchanged from baseline.
- No seed-crafting regressions affect this flow.

## Verification checklist

- [ ] Single-token and dual-token mappings pass deterministic unit tests.
- [ ] Position-insensitive matching validated for multiple arrangements per dual recipe.
- [ ] Consume-on-success ordering verified.
- [ ] Inventory-full valid-recipe blocking verified (tokens preserved in-grid).
- [ ] Failure feedback states validated (empty, invalid, locked, full).
- [ ] Feedback key mapping validated for all outcomes (`craft_success_seed_added`, `craft_empty_input`, `craft_no_matching_seed_recipe`, `craft_locked_ku`, `craft_inventory_full`).
- [ ] Corrective guidance phrase validated for every non-success outcome.
- [ ] Mobile slot targets confirmed >= 48x48 px.
- [ ] No structure/build migration behavior changed in this phase.
- [ ] Grouped build-confirm behavior regression check passed (unchanged).
- [ ] One representative non-seed gameplay regression check passed (unchanged).
