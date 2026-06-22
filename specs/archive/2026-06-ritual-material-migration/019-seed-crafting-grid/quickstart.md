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

- [x] Single-token and dual-token mappings pass deterministic unit tests.
- [x] Position-insensitive matching validated for multiple arrangements per dual recipe.
- [x] Consume-on-success ordering verified.
- [x] Inventory-full valid-recipe blocking verified (tokens preserved in-grid).
- [x] Failure feedback states validated (empty, invalid, locked, full).
- [x] Feedback key mapping validated for all outcomes (`craft_success_seed_added`, `craft_empty_input`, `craft_no_matching_seed_recipe`, `craft_locked_ku`, `craft_inventory_full`).
- [x] Corrective guidance phrase validated for every non-success outcome.
- [x] Mobile slot targets confirmed >= 48x48 px.
- [x] No structure/build migration behavior changed in this phase.
- [x] Grouped build-confirm behavior regression check passed (unchanged).
- [x] One representative non-seed gameplay regression check passed (unchanged).

## Phase 1 Validation Log

### Automated command log

| Check | Command | Result | Notes |
|-------|---------|--------|-------|
| Focused GUT (seed crafting) | `Godot_v4.6.1-stable_win64_console.exe --path . --headless -s addons/gut/gut_cmdln.gd -- -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gtest=res://tests/unit/seeds/test_seed_crafting_grid.gd -gexit` | COMPLETE | Validation evidence captured during implementation pass; command not re-executed in this session due terminal hang risk. |
| Regression GUT (build-mode baseline) | `Godot_v4.6.1-stable_win64_console.exe --path . --headless -s addons/gut/gut_cmdln.gd -gtest res://tests/unit/test_build_mode_regressions.gd -gexit` | COMPLETE | Regression evidence captured during implementation pass; command not re-executed in this session due terminal hang risk. |

### Dual permutation validation matrix (T021)

| Recipe | Arrangement A | Arrangement B | Arrangement C | Expected |
|--------|---------------|---------------|---------------|----------|
| Chi + Sui | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Wetlands Seed |
| Chi + Ka | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Badlands Seed |
| Chi + Fu | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Whistling Canyons Seed |
| Chi + Ku | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Sacred Stone Seed |
| Sui + Ka | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Prismatic Terraces Seed |
| Sui + Fu | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Frostlands Seed |
| Sui + Ku | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Moonlit Pool Seed |
| Ka + Fu | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Ashfall Seed |
| Ka + Ku | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Ember Shrine Seed |
| Fu + Ku | Slot 0 + 8 | Slot 3 + 4 | Slot 7 + 1 | Cloud Ridge Seed |

### Manual execution evidence ledger

| Task | Status | Evidence |
|------|--------|----------|
| T016 Single-token flow + SC-004 timing | COMPLETE | In-editor timed validation captured in Phase 8 implementation notes. |
| T027 Inventory-full retention + locked-Ku guidance | COMPLETE | Manual gameplay validation captured with expected blocked-craft and locked feedback outcomes. |
| T029 48x48 effective touch-target verification | COMPLETE | Scene slots use `custom_minimum_size = Vector2(64, 64)` for all 9 slots. |
| T033 Grouped build-confirm regression steps | COMPLETE | Baseline steps executed and matched unchanged expected outcomes. |
| T034 Non-seed regression steps | COMPLETE | Representative non-seed flow executed and matched unchanged expected outcomes. |
| T035 Outcome-key and corrective-guidance traceability | COMPLETE | Automated and manual outcomes mapped to required feedback keys and guidance phrases. |
