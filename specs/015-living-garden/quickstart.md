# Quickstart: Living Garden — Satori v2 Core Loop

**Branch**: `015-living-garden` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)

## Goal

Validate the complete seed-alchemy-bloom loop in instant mode: mix a seed, plant it, bloom it, trigger a pattern discovery, summon a spirit, receive a recipe gift, mix a Tier 2 seed.

---

## Prerequisites

- Godot 4.6+ with the project open
- Feature branch `015-living-garden` checked out
- New autoloads registered in `project.godot` (see data-model.md)
- GUT installed at `addons/gut/`

---

## Run the Project

```
F5 in Godot editor
```
or headless:
```
godot --path . --headless
```

---

## US10 — Instant Mode (Manual)

1. Open **Settings** in game.
2. Enable **Instant Mode** (⚡ badge should appear in HUD).
3. Verify all subsequently planted seeds enter READY state immediately.

**Expected**: ⚡ badge visible. Any seed planted transitions to glowing/pulsing state within one frame.

---

## US1 — Seed Alchemy: Mixing (Manual)

1. Tap the **Mix** HUD button.
2. Tap **Chi** — slot 1 fills with Chi.
3. Tap **Sui** — slot 2 fills with Sui. Preview shows "Clay Seed".
4. Tap **Confirm**.
5. Tap the **Plant** HUD button — seed pouch shows 1 seed.
6. Tap **Mix** again. Tap **Kū** — verify it is locked with hint "a spirit holds this secret".

**Expected**: Clay seed in pouch. Kū button is visually locked. Codex Seeds tab shows Chi+Sui as newly discovered.

---

## US2 + US3 — Plant and Bloom (Manual)

1. In Plant mode, verify 6 edge hexes are highlighted around the origin tile.
2. Tap any edge hex — Clay seed is planted; sprout visual appears immediately in Instant mode.
3. Immediately after planting, tap the sprout — it should already show the "ready to bloom" glow.
4. Tap the glowing sprout — **Bloom**: Clay tile appears, bloom VFX plays, bloom SFX sounds.
5. Verify new edge hexes appear around the Clay tile.
6. Verify HUD growing slot count returns to 1 available (was 0 while seed was planted).

**Expected**: Full bloom ritual works. No auto-bloom occurs between planting and player tap.

---

## US4 — Growing Slot Limit (Manual)

1. Ensure pouch has 3 seeds (craft 3 in Mix mode).
2. Plant all 3 — growing slot counter should show 0/3.
3. Attempt to plant a 4th seed by tapping an edge hex.

**Expected**: Planting is blocked. A gentle visual indicator appears on the edge hex (no alarm, no error popup).

---

## US5 — Element Locks and Tier 3 (Manual)

1. Open Mix mode. Verify only Chi, Sui, Ka, Fū are selectable. Kū is locked.
2. Try tapping a third element slot — verify it is locked with "a spirit can teach you this".
3. Via debug panel: call `SeedAlchemyService.unlock_element(GodaiElement.Value.KU)`.
4. Open Mix mode — Kū is now selectable.
5. Mix Chi + Kū → verify "Sacred Stone Seed" is previewed and producible.

**Expected**: Element unlock propagates immediately. Tier 2 Kū recipes become available.

---

## US6 — Spirit Habitat (Manual)

1. Via debug panel: force-summon Red Fox (`SpiritService` debug call).
2. Bloom 6+ Meadow seeds (Fū) in one region of the garden.
3. Observe Red Fox wander target over 5+ wander cycles.

**Expected**: Red Fox trends toward the Meadow cluster. If only Stone tiles are present, Red Fox wanders randomly within bounds (fallback, no error).

---

## US7 — Codex (Manual)

1. Tap **Codex** HUD button.
2. Check Seeds tab — Chi, Sui, Ka, Fū single-element entries are shown as known; all two-element entries show silhouettes with hint text.
3. Mix and plant a Hot Spring seed (Sui + Ka). After blooming, reopen Codex.
4. Check Spirits tab — all 30 spirit entries show silhouettes with riddle text.

**Expected**: Seeds tab updates immediately on recipe discovery. Spirits tab shows riddles for all unsummoned spirits.

---

## US8 — Satori Moment (Manual / Instant Mode Debug)

1. In instant mode, open debug panel.
2. Call `SatoriService.trigger_debug()`.
3. Observe: camera pull-back, tile geometric light overlay, resonant audio, fade after ~8s.
4. After sequence, verify growing slot capacity increased by 1 (first Satori unlock).
5. Trigger debug again — sequence must NOT replay.

**Expected**: Single fire. Unlock applied. Second trigger is silently ignored.

---

## Automated Tests

```bash
# Full suite
godot --path . --headless -s tests/gut_runner.tscn

# Seed recipe registry
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/seeds/test_seed_recipe_registry.gd

# Seed growth service (instant mode)
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/seeds/test_seed_growth_service.gd

# Satori condition evaluator
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_satori_service.gd

# Spirit ecology (tension/harmony)
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_spirit_ecology_service.gd

# BiomeType enum integrity
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_biome_type.gd
```

---

## Key Debug Panel Shortcuts (Instant Mode only)

| Action | Debug Call |
|---|---|
| Unlock Kū element | `SeedAlchemyService.unlock_element(4)` |
| Force bloom all READY seeds | `SeedGrowthService.debug_bloom_all()` |
| Force spirit summon | `SpiritService.debug_summon("spirit_red_fox")` |
| Trigger Satori sequence | `SatoriService.trigger_debug()` |
| Expand growing slots +1 | `SeedGrowthService.debug_expand_slots()` |

---

## Common Pitfalls

| Symptom | Likely Cause |
|---|---|
| Kū still locked after unlock call | `SeedAlchemyService` not in autoloads list |
| Seeds never transition to READY in real-time | `GardenSettings.growth_mode` defaulting to INSTANT after mode write error |
| Pattern not firing on bloom | `PatternScanService` still connected to `tile_placed` instead of `bloom_confirmed` |
| Harmony event fires repeatedly | `_harmony_fired` Dictionary not persisted to `spirit_gifts.json` |
| Autoload parse error on launch | Autoload key matches a `class_name` — rename the class to use `Node` suffix |
