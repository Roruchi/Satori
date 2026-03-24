# Implementation Plan: Living Garden — Satori v2 Core Loop

**Branch**: `015-living-garden` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)

---

## Summary

This plan redesigns Satori's core loop from real-time tile-placement into a living-garden ritual built on five interlocking systems: **Godai seed alchemy** (a dedicated mixing UI replacing long-press grid interaction), **seed growth timing** (planted seeds mature offline and bloom on explicit player tap), **a three-panel HUD** (Plant / Mix / Codex navigation), **spirit habitat ecology** (spirits drawn to preferred biomes, tension and harmony between pairs), and **Satori Moments** (rare peak events that fire when the garden reaches deep balance). A new **Codex** acts as a persistent field guide recording all discoveries.

The existing codebase is cleanly in development — both persistence stubs are disabled, and no user saves exist — allowing clean enum migration and full save-system activation. The spirit wanderer already implements preferred-biome weighting; the primary additions are data authoring, new services, and UI panels. Seven implementation phases proceed from lowest-dependency foundations upward, keeping the game runnable after each phase.

---

## Technical Context

**Language/Version**: GDScript 4 — Godot 4.6
**Primary Dependencies**: Godot engine only; GUT for tests
**Storage**: JSON files under `user://` (six new files alongside existing two)
**Testing**: GUT (`addons/gut/`, `tests/gut_runner.tscn`)
**Target Platform**: Mobile-first (Android/iOS); also desktop via Godot export
**Project Type**: Mobile game — single-player offline
**Performance Goals**: 60 fps on mid-range mobile; seed timer evaluation < 1ms per cycle; pattern scan unaffected by seed system
**Constraints**: No `_process()` polling for timers; no scene transitions between HUD modes; all new autoloads must avoid `class_name` collision with their autoload key
**Scale/Scope**: Up to 10 concurrent growing seeds; up to 30 spirits; up to ~50 Codex entries; up to 5 Satori condition sets in v1

---

## Constitution Check

### I. Spec-Driven Delivery ✅
All work traces to spec 015 user stories (US1–US9). No unplanned work. Phase numbers map directly to user story groups. Tasks will each reference a US or a shared foundational task.

### II. Godot-Native Architecture ✅
All new code is GDScript under `src/`. New autoloads in `src/autoloads/`. New resource types in `src/seeds/`, `src/codex/`, `src/satori/`. No external dependencies. UI panels are `Control` nodes in the existing scene tree — no new scene files beyond HUD panels.

**Autoload name collision check**:
- `SeedAlchemyService` key → class `SeedAlchemyServiceNode` ✅
- `SeedGrowthService` key → class `SeedGrowthServiceNode` ✅
- `SpiritEcologyService` key → class `SpiritEcologyServiceNode` ✅
- `SatoriService` key → class `SatoriServiceNode` ✅
- `CodexService` key → class `CodexServiceNode` ✅
- `GardenSettings` key → class `GardenSettingsNode` ✅

### III. Testable Gameplay Systems ✅
Deterministic systems with GUT coverage:
- `SeedRecipeRegistry` — recipe lookup, element lock enforcement, Tier 3 gate
- `SeedGrowthService` — instant mode promotion, slot tracking, wall-clock evaluation
- `SatoriConditionEvaluator` — each condition type, fire-once guarantee
- `SpiritEcologyService` — tension detection, harmony accumulation, fire-once guarantee
- `BiomeType` enum — value integrity after migration

Scene-heavy systems (HUD, bloom VFX, Satori sequence) validated via quickstart manual tests.

### IV. Deterministic World Rules ✅ with caution
- Recipe lookup is deterministic: same elements → same biome, always.
- Bloom is player-triggered only (FR-020); no hidden auto-resolution.
- Satori fires at most once per condition set (fired flag persisted).
- ⚠️ **BiomeType enum migration**: existing pattern `.tres` files reference old biome integer IDs. These must be updated as part of Phase 1 or patterns will silently fail to match. Full audit required before Phase 1 is complete.
- ⚠️ **Save enablement**: enabling `_save()/_load()` in existing persistence stubs will make save state active. Any test that relies on clean state between runs must explicitly reset persistence.

### V. Mobile Experience Budgets ✅ with notes
- Seed timer evaluation uses focus-return + 60s `Timer` — no per-frame cost.
- HUD buttons are anchored to bottom safe area; thumb-zone reachable.
- Bloom VFX must be tested at 60 fps on mid-range hardware (GS23 target).
- Instant mode badge must not obscure garden tiles (anchored to top corner).
- Codex and Mix panels slide in without scene transitions.

### Technical Guardrails Check
- No `:=` for `Variant`-returning calls (e.g., `Dictionary.get()`) in warnings-as-errors files — all new code uses explicit types.
- `preload("res://...")` used for all cross-script typed dependencies.
- `SeedInstance.evaluate_growth()` returns `bool` (not inferred Variant).

---

## Project Structure

### Documentation (this feature)

```text
specs/015-living-garden/
├── plan.md          ← this file
├── research.md      ← Phase 0 output
├── data-model.md    ← Phase 1 output
├── quickstart.md    ← Phase 1 output
└── tasks.md         ← Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
project.godot                         ← add 6 new autoloads

src/
├── autoloads/
│   ├── GameState.gd                  ← modify: retire try_mix_tile, add place_tile_from_seed
│   ├── seed_alchemy_service.gd       ← NEW: element unlock, recipe lookup, pouch
│   ├── seed_growth_service.gd        ← NEW: timer eval, slot tracking, bloom trigger
│   ├── spirit_ecology_service.gd     ← NEW: tension/harmony detection
│   ├── satori_service.gd             ← NEW: condition eval, sequence trigger
│   ├── codex_service.gd              ← NEW: discovered state management
│   ├── garden_settings.gd            ← NEW: GrowthMode persistence
│   ├── discovery_persistence.gd      ← modify: enable _save/_load
│   └── spirit_persistence.gd         ← modify: enable _save/_load
│
├── biomes/
│   └── BiomeType.gd                  ← modify: replace enum with Godai biomes, deprecate mix()
│
├── seeds/                            ← NEW directory
│   ├── GodaiElement.gd
│   ├── SeedRecipe.gd
│   ├── SeedRecipeRegistry.gd
│   ├── SeedState.gd
│   ├── SeedInstance.gd
│   ├── GrowthMode.gd
│   ├── SeedPouch.gd
│   ├── GrowthSlotTracker.gd
│   └── recipes/                      ← NEW: .tres files (one per recipe)
│       ├── recipe_chi.tres
│       ├── recipe_sui.tres
│       ├── recipe_ka.tres
│       ├── recipe_fu.tres
│       ├── recipe_chi_sui.tres
│       ├── recipe_chi_ka.tres
│       ├── recipe_chi_fu.tres
│       ├── recipe_sui_ka.tres
│       ├── recipe_sui_fu.tres
│       └── recipe_ka_fu.tres
│
├── spirits/
│   ├── spirit_definition.gd          ← modify: add habitat + gift fields
│   ├── spirit_wanderer.gd            ← modify: disliked_biomes, moved_to signal
│   ├── spirit_service.gd             ← modify: gift processing on summon
│   ├── SpiritGiftType.gd             ← NEW
│   └── SpiritGiftProcessor.gd        ← NEW: dispatch gift to correct service
│
├── codex/                            ← NEW directory
│   ├── CodexEntry.gd
│   └── entries/                      ← NEW: .tres files (one per Codex entry)
│
├── satori/                           ← NEW directory
│   ├── SatoriConditionSet.gd
│   ├── SatoriConditionEvaluator.gd   ← static helper: evaluates one condition Dict
│   └── conditions/
│       └── satori_first_awakening.tres
│
└── ui/
    ├── HUDController.gd              ← NEW: Plant/Mix/Codex mode switching
    ├── SeedAlchemyPanel.gd           ← NEW: Mix mode UI
    ├── CodexPanel.gd                 ← NEW: Codex mode UI
    └── SeedPouchDisplay.gd           ← NEW: pouch indicator in Plant mode HUD

scenes/
└── UI/
    ├── HUD.tscn                      ← NEW (or modify existing TileSelector scene)
    ├── SeedAlchemyPanel.tscn         ← NEW
    └── CodexPanel.tscn               ← NEW

tests/
└── unit/
    ├── seeds/
    │   ├── test_seed_recipe_registry.gd  ← NEW
    │   └── test_seed_growth_service.gd   ← NEW
    ├── test_satori_service.gd            ← NEW
    ├── test_spirit_ecology_service.gd    ← NEW
    └── test_biome_type.gd                ← NEW (migration integrity)
```

---

## Implementation Approach

### Phase 1 — Godai Element & Recipe Foundation (US5)

**Goal**: All seed recipes exist as data; BiomeType reflects the Godai world. Game must still run after this phase (old mixing is removed, but origin tile plants fine with the new STONE biome).

1. Create `src/seeds/GodaiElement.gd` (enum only, no logic).
2. Create `src/seeds/SeedRecipe.gd` (Resource with fields per data-model.md).
3. Modify `src/biomes/BiomeType.gd`:
   - Replace all enum values with Godai-aligned set.
   - Deprecate `mix()` (returns NONE always, body replaced with comment).
4. Create `src/seeds/SeedRecipeRegistry.gd`:
   - Directory-scan `res://src/seeds/recipes/` for `.tres` files.
   - Build `_recipes: Dictionary` keyed by sorted-element join string.
   - `lookup(elements)` returns null for missing or locked Tier 3 recipes.
5. Author all 10 Tier 1 + Tier 2 recipe `.tres` files.
6. Create `src/seeds/SeedState.gd`, `GrowthMode.gd`.
7. Audit all existing `.tres` pattern files for old biome integer IDs → update to new values.
8. **Tests**: `test_biome_type.gd` (enum values, mix() returns NONE), `test_seed_recipe_registry.gd` (all 10 recipes found, element lock, Tier 3 gate).

### Phase 2 — Seed Growth Engine (US2, US3, US4, US10)

**Goal**: Seeds can be planted and bloom. Pattern scanner fires at bloom time.

1. Create `src/seeds/SeedInstance.gd` + `SeedPouch.gd` + `GrowthSlotTracker.gd`.
2. Create `src/autoloads/garden_settings.gd` (GrowthMode storage + JSON save/load).
3. Create `src/autoloads/seed_growth_service.gd`:
   - `try_plant(coord, recipe)` → creates SeedInstance, adds to tracker, emits `seed_planted`.
   - `try_bloom(coord)` → transitions READY → BLOOMED, calls `GameState.place_tile_from_seed()`, emits `bloom_confirmed`.
   - `set_mode(INSTANT)` → promotes all GROWING seeds to READY immediately.
   - `_evaluate_all()` → calls `evaluate_growth()` on all GROWING seeds.
   - Focus-return evaluation via `_notification(NOTIFICATION_APPLICATION_FOCUS_IN)`.
   - 60-second Timer child node.
4. Modify `src/autoloads/GameState.gd`:
   - Add `place_tile_from_seed(coord, biome)` — direct tile placement, emits `tile_placed`.
   - Mark `try_mix_tile()` as deprecated (retain signature, return false with warning).
5. Reconnect `PatternScanService`: connect to `SeedGrowthService.bloom_confirmed` instead of `GameState.tile_placed` (for new placements; retain tile_placed connection for origin tile).
6. Register `SeedGrowthService` + `GardenSettings` in `project.godot`.
7. Enable `_load()/_save()` in `SeedGrowthService` (save path: `user://garden_seeds.json`).
8. **Tests**: `test_seed_growth_service.gd` — instant promotion, slot blocking, wall-clock evaluation, bloom fires pattern trigger.

### Phase 3 — Three-Panel HUD (US1, US2)

**Goal**: Player can switch between Plant, Mix, and Codex modes via minimalist buttons.

1. Create `src/ui/HUDController.gd` — manages three `Button` nodes, shows/hides panels.
2. Create `src/seeds/SpiritGiftType.gd` enum (needed by SeedAlchemyService).
3. Create `src/autoloads/seed_alchemy_service.gd`:
   - Tracks `_unlocked_elements: Array[int]` (CHI/SUI/KA/FU unlocked by default).
   - `craft_seed(elements)` → calls `SeedRecipeRegistry.lookup()`, adds to pouch, emits `recipe_discovered` on first-time.
   - `unlock_element(KU)` → adds KU to unlocked list, emits `element_unlocked`.
4. Create `src/ui/SeedAlchemyPanel.gd` + `SeedAlchemyPanel.tscn`:
   - Five element buttons (Chi, Sui, Ka, Fū, Kū-locked).
   - Two active element slots + one locked slot.
   - Preview label showing recipe result or "unknown combination".
   - Confirm button (disabled when pouch full or no recipe).
5. Create `src/ui/SeedPouchDisplay.gd` — shows current seed in pouch (or empty state).
6. Create `scenes/UI/HUD.tscn` — assembles HUDController + panels.
7. Register `SeedAlchemyService` in `project.godot`.
8. Enable `_save()/_load()` in `SeedAlchemyService` (save path: part of `garden_seeds.json` or separate `alchemy_state.json`).

### Phase 4 — Spirit Habitat Ecology (US6)

**Goal**: Spirits move toward preferred biomes; tension and harmony events fire.

1. Create `src/spirits/SpiritGiftProcessor.gd` (dispatches gift → correct service method).
2. Modify `src/spirits/spirit_definition.gd` — add fields per data-model.md.
3. Modify `src/spirits/spirit_wanderer.gd`:
   - Add `_disliked_biomes: Array[int]`; populate in `setup()`.
   - Add `signal moved_to(spirit_id: String, coord: Vector2i)` — emit when target reached.
   - On arrival at disliked biome tile: immediately call `_pick_new_target()`.
4. Create `src/autoloads/spirit_ecology_service.gd`:
   - Connects to `SpiritWanderer.moved_to` for each active wanderer.
   - Tension detection: distance check on each movement, emit `tension_active/cleared`.
   - Harmony accumulation: tick counter per pair, emit `harmony_event_fired` at threshold.
5. Modify `src/spirits/spirit_service.gd`:
   - After `_summon_spirit()`: call `SpiritGiftProcessor.process(spirit_id, definition)`.
   - Register new wanderer with `SpiritEcologyService` on spawn.
6. Author habitat data for ~10 profiled spirits (update their `.tres` or catalog data):
   - Koi Fish → preferred: RIVER; tension: River Otter; harmony: Blue Kingfisher
   - Red Fox → preferred: MEADOW, DUNE; tension: Hare
   - White Heron → preferred: RIVER, BOG
   - Mountain Goat → preferred: STONE, DUNE
   - Boreal Wolf → preferred: BOG; tension: Tundra Lynx
   - Mist Stag → preferred: BOG, VEIL_MARSH; gift: KU_UNLOCK
   - Blue Kingfisher → preferred: RIVER; harmony: Koi Fish
   - River Otter → preferred: RIVER, BOG; gift: TIER3_RECIPE (Mossy Delta)
   - Meadow Lark → preferred: MEADOW; gift: GROWING_SLOT_EXPAND
   - Golden Bee → preferred: MEADOW, SAVANNAH (mapped to DUNE)
7. Register `SpiritEcologyService` in `project.godot`.
8. Enable harmony state persistence (`user://spirit_gifts.json`).
9. **Tests**: `test_spirit_ecology_service.gd` — tension threshold, harmony accumulation, fire-once.

### Phase 5 — Codex (US7)

**Goal**: Codex panel shows all seeds, biomes, spirits, structures with hint/full views.

1. Create `src/codex/CodexEntry.gd` (Resource + Category enum).
2. Author `CodexEntry` .tres files for all known entries (14 biomes, 10 Tier 1+2 seeds, 30 spirit entries, placeholder structure entries).
3. Create `src/autoloads/codex_service.gd`:
   - Loads all `.tres` files at startup.
   - Tracks discovered state in memory; persists to `user://codex_state.json`.
   - `mark_discovered()` called from `SeedAlchemyService.recipe_discovered` and `SpiritService.spirit_summoned`.
4. Create `src/ui/CodexPanel.gd` + `CodexPanel.tscn`:
   - Four tabs: Seeds, Biomes, Spirits, Structures.
   - Grid of `CodexEntryCard` items — silhouette vs full view based on `is_discovered()`.
   - Hint text always visible (except `always_hidden` entries).
5. Register `CodexService` in `project.godot`.
6. Wire `CodexPanel` into `HUDController`.

### Phase 6 — Satori Moments (US8)

**Goal**: First Satori Moment fires when all four base biomes exist and 3 spirits are summoned.

1. Create `src/satori/SatoriConditionSet.gd` (Resource per data-model.md).
2. Create `src/satori/SatoriConditionEvaluator.gd` (static class, one method per condition type).
3. Author `satori_first_awakening.tres` condition set.
4. Create `src/autoloads/satori_service.gd`:
   - Connects to `SeedGrowthService.bloom_confirmed` and `SpiritService.spirit_summoned`.
   - `evaluate()` checks all unfired condition sets.
   - On match: sets `fired = true`, persists to `user://satori_state.json`, emits signal, plays sequence.
   - `trigger_debug()` for instant mode debug panel.
5. Create Satori sequence: camera pull-back (Tween), tile overlay (shader or CanvasLayer), resonant audio (one-shot AudioStreamPlayer), skip-on-tap after 2s.
6. Register `SatoriService` in `project.godot`.
7. **Tests**: `test_satori_service.gd` — condition evaluation per type, fire-once, debug trigger.

### Phase 7 — Persistence Activation (Cross-cutting)

**Goal**: All game state survives app close and reopen correctly.

1. Implement `_load()/_save()` in `DiscoveryPersistence` (JSON read/write at existing path).
2. Implement `_load()/_save()` in `SpiritPersistence` (JSON read/write at existing path).
3. Verify `SeedGrowthService` save/load: wall-clock timestamps survive serialization round-trip; GROWING seeds resume from correct elapsed time; READY seeds remain READY.
4. Verify `CodexService` save/load: all discovered entries persist across session.
5. Verify `SatoriService` save/load: fired flags persist; Satori sequence does not replay.
6. Verify `SpiritEcologyService` save/load: harmony fired pairs persist.
7. Integration test: full session → app close → app reopen → verify all state consistent.

---

## Complexity Tracking

| Area | Risk | Mitigation |
|---|---|---|
| BiomeType enum migration | High — breaks all pattern .tres files | Audit all pattern files in Phase 1 before any other work; run GUT suite as gate |
| Save enablement side effects | Medium — tests that relied on blank state will fail | Add explicit state reset helper to persistence classes for test use |
| PatternScanService reconnection | Low — known signal swap | Single connection change; covered by integration test |
| Spirit habitat data authoring | Medium — 10 spirits need manual .tres edits | Prioritize spirits with existing tests (Red Fox, Koi Fish, White Heron) |
| Satori sequence VFX | Low functional risk, high artistic risk | Implement minimal fade + camera pull for v1; polish in follow-up |
| Autoload load order | Medium — SeedGrowthService needs SeedAlchemyService | Register in dependency order in project.godot; use `call_deferred` for cross-autoload setup |

---

## Post-Phase 1 Constitution Re-check

After BiomeType migration: re-run GUT suite against all existing pattern tests. Any test failure in `tests/unit/patterns/` indicates a pattern .tres file that was not updated. This is the only gate that can block Phase 2 from starting.
