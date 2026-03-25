# Research: Living Garden — Satori v2 Core Loop

**Branch**: `015-living-garden` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)

---

## 1. BiomeType Migration Strategy

**Decision**: Extend `BiomeType.Value` enum with Godai-aligned biome IDs. Retire the existing `FOREST/WATER/STONE/EARTH` base values and replace with `STONE/RIVER/EMBER_FIELD/MEADOW`. Hybrids are similarly replaced by the Tier 2 recipe table.

**Rationale**: Both persistence autoloads (`DiscoveryPersistence`, `SpiritPersistence`) have their `_load()/_save()` stubs disabled — there are no user saves to migrate. The codebase is cleanly in development. A full enum replacement is safe and produces a consistent Godai-aligned type system throughout.

**Alternatives considered**:
- *Additive extension* (keep old values, add new): produces dead code, split pattern tables, and confusing integer IDs for testers.
- *String-keyed biome IDs*: avoids enum fragility but breaks the existing typed-integer pattern matchers, rendering, and bitmask autotiler — too costly.

**New enum layout**:
```
NONE = -1
# Tier 1 — Single Godai element
STONE = 0        # Chi (地)
RIVER = 1        # Sui (水)
EMBER_FIELD = 2  # Ka  (火)
MEADOW = 3       # Fū  (風)
# Tier 2 — Two Godai elements
CLAY = 4           # Chi + Sui
DESERT = 5         # Chi + Ka
DUNE = 6           # Chi + Fū
HOT_SPRING = 7     # Sui + Ka
BOG = 8            # Sui + Fū
CINDER_HEATH = 9   # Ka  + Fū
SACRED_STONE = 10  # Chi + Kū
VEIL_MARSH = 11    # Sui + Kū
EMBER_SHRINE = 12  # Ka  + Kū
CLOUD_RIDGE = 13   # Fū  + Kū
# Tier 3 — Three elements (indices 20+ reserved, added as spirits unlock)
```

The static `BiomeType.mix()` function is **deprecated** — all recipe lookups route through `SeedRecipeRegistry`.

---

## 2. Seed Recipe Storage Format

**Decision**: Data-driven `.tres` Resource files, one per recipe, stored at `res://src/seeds/recipes/`. `SeedRecipeRegistry` loads them at startup using `ResourceLoader` with a directory scan, identical to how `PatternLoader` loads `PatternDefinition` resources.

**Rationale**: Consistent with existing pattern data approach. `.tres` files are type-safe, editor-editable, and require zero code changes to add new recipes. The `SeedRecipe` resource class maps cleanly to the entity spec.

**Alternatives considered**:
- *Hardcoded match table in GDScript*: fast, but adding a Tier 3 recipe requires a code change — violates FR-007.
- *JSON file*: requires manual parse and loses Godot type safety.

**Recipe file naming convention**: `recipe_{element_ids_sorted}.tres`
Examples: `recipe_chi.tres`, `recipe_chi_sui.tres`, `recipe_chi_ka_fu.tres`

---

## 3. Seed Growth Timer Architecture

**Decision**: Wall-clock persistence using `Time.get_unix_time_from_system()`. No `_process()` polling — instead evaluate on **focus return** (`ApplicationFocusChanged` notification) and on a **60-second Scene `Timer`** while the app is foregrounded. Seeds are stored as plain Dictionaries in `user://garden_seeds.json`.

**Rationale**: Per FR-019, device clock is trusted unconditionally. Running evaluation on focus return means seeds that matured while the app was closed are immediately READY when the player opens the app — exactly the desired UX. The 60-second timer covers in-app maturation for Tier 1 seeds (10-min duration) without polling every frame.

**Instant mode override**: `SeedGrowthService.set_mode(GrowthMode.INSTANT)` sets all GROWING seeds to READY synchronously and sets `_instant_mode = true`, causing all newly planted seeds to enter READY immediately via `_evaluate_seed(seed)` returning `true` unconditionally.

**Alternatives considered**:
- *`_process(delta)` per-seed timer*: unacceptably heavy for 10+ active seeds on mobile.
- *Engine Timer per seed*: does not survive app close; cannot use wall-clock delta.

---

## 4. GrowthMode Settings Storage

**Decision**: Store `GrowthMode` in a dedicated `user://garden_settings.json` file managed by a new `GardenSettings` autoload. Not in `ProjectSettings` (editor-only concern) and not embedded in the garden save (it's a device-level developer preference, not garden state).

**Rationale**: `ProjectSettings` persists to `project.godot` which is source-controlled — inappropriate for a runtime toggle. Separating from garden save means the setting survives garden resets and doesn't contaminate garden data.

---

## 5. Spirit Wanderer — Habitat Weighting Status

**Finding**: `SpiritWanderer.gd` already implements preferred biome weighting (lines 106–121). When `_preferred_biomes` is populated, `_get_candidate_coords()` returns only preferred-biome tiles (100% weight toward preferred). This exceeds the spec's ≥ 60% requirement.

**Decision**: The existing implementation is sufficient for US6 preferred-biome weighting. The spec's "≥ 60% probability" acceptance scenario is satisfied by the current all-or-nothing preferred-first approach (if preferred tiles exist, only preferred tiles are candidates).

**What needs adding**:
- `disliked_biomes` array: when a spirit's current tile is disliked, immediately re-call `_pick_new_target()` to force movement away.
- `tension_distance` check: evaluated in a new `SpiritEcologyService`, not in `SpiritWanderer`.
- `harmony_duration` tracking: also in `SpiritEcologyService`.
- `preferred_biomes` data must be authored in `SpiritDefinition` and passed through `SpiritCatalog` → `SpiritWanderer.setup()` — the plumbing already exists.

---

## 6. Spirit Gift Processing Architecture

**Decision**: Process gifts in `SpiritService._summon_spirit()` immediately after the instance is created, by dispatching to a new `SpiritGiftProcessor` helper class (not autoload). Gifts are idempotent — the gift flag is persisted alongside the spirit instance so re-loading never re-applies a gift.

**Gift types and their handlers**:
| Gift Type | Handler |
|---|---|
| `KU_UNLOCK` | Calls `SeedAlchemyService.unlock_element("ku")` |
| `TIER3_RECIPE` | Calls `SeedRecipeRegistry.unlock_recipe(payload)` |
| `POUCH_EXPAND` | Increments `SeedGrowthService.pouch_capacity` by 1 |
| `GROWING_SLOT_EXPAND` | Increments `SeedGrowthService.slot_capacity` by 1 |
| `CODEX_REVEAL` | Calls `CodexService.force_reveal(payload)` |
| `NONE` | No-op |

---

## 7. Harmony / Tension Detection

**Decision**: `SpiritEcologyService` runs a lightweight scan on every wander tick (already called from `SpiritWanderer._process()`). It checks active spirit positions against the tension/harmony pair tables defined in `SpiritDefinition`.

**Tension**: Detected when two tension-pair spirits are within `tension_distance` hexes of each other. Fires a `tension_active(spirit_a_id, spirit_b_id)` signal while in range; `tension_cleared` when they separate. Visual shader applied by `SpiritWanderer` on receipt.

**Harmony**: Tracked as accumulated ticks where two harmony-pair spirits share ≥ 1 wander region tile. When `harmony_ticks_accumulated >= harmony_threshold`, `harmony_event_fired` signal emits once and the flag is persisted.

**Tick source**: `SpiritEcologyService` is connected to `SpiritWanderer`'s movement completion (a new `moved_to(coord)` signal emitted each time a wanderer reaches its target). This is already near-zero cost since wanderers already have `_wait_time` idle periods.

---

## 8. Codex Entry Data Format

**Decision**: `CodexEntry` resources live in `res://src/codex/entries/` as `.tres` files. `CodexService` loads all entries at startup and tracks `discovered` state separately in `user://codex_state.json` (a flat Dictionary of `entry_id → bool`). Entries are never overwritten at runtime — only the external state file changes.

**Rationale**: Separating the entry definition (static, source-controlled) from discovered state (dynamic, user data) follows the same pattern as `PatternDefinition` + `DiscoveryRegistry`.

---

## 9. Satori Condition Evaluation Architecture

**Decision**: `SatoriConditionSet` resources live in `res://src/satori/conditions/`. `SatoriService` (new autoload) loads them at startup and evaluates on every `bloom_confirmed` and `spirit_summoned` signal. Each condition type maps to a static evaluator method:

| Condition type | Evaluator |
|---|---|
| `biome_present` | Check `GameState.grid` has ≥ 1 tile of that biome |
| `spirit_count_gte` | Check `SpiritService.active_count() >= N` |
| `harmony_count_gte` | Check `SpiritEcologyService.harmony_count() >= N` |
| `tile_count_gte` | Check `GameState.grid.tile_count >= N` |

The first condition set (`satori_first_awakening`) requires all four base biomes + 3 spirits — both are checkable with existing data. Unlock: `GROWING_SLOT_EXPAND`.

---

## 10. Three-Panel HUD Architecture

**Decision**: A single `HUDController` scene replaces the current `TileSelector` approach. It contains three `Button` nodes (Plant, Mix, Codex) in a horizontally-aligned container anchored to the bottom edge. Switching mode shows/hides the corresponding panel:

- **Plant**: Default. Garden is fully interactive; edge hexes are tappable.
- **Mix**: `SeedAlchemyPanel` slides in. Garden camera/touch is passed through (garden remains visible).
- **Codex**: `CodexPanel` slides in. Garden is visible but non-interactive.

Panels are `Control` nodes added as children of the HUD, not separate scenes, to avoid scene transitions.

---

## 11. Pattern Scanner Integration with Bloom

**Decision**: The existing `PatternScanService` fires `discovery_triggered` in response to `GameState.tile_placed`. Under the new system, `tile_placed` is replaced by `bloom_confirmed(coord, biome)`. `SeedGrowthService` emits `bloom_confirmed` when the player taps a READY seed. `PatternScanService` connects to `bloom_confirmed` instead of `tile_placed`.

`GameState.tile_placed` signal is **retained for backward compatibility** with tests but also emitted from `SeedGrowthService` at bloom time — making the pattern engine unaware of the seed system.

---

## 12. Save/Load Enablement

**Decision**: Enable `_load()/_save()` in `DiscoveryPersistence` and `SpiritPersistence` as part of this feature. Both already have JSON paths defined; only the stub bodies need implementing. New persistence files: `garden_seeds.json`, `garden_settings.json`, `codex_state.json`, `satori_state.json`.

**Format**: All files use `JSON.stringify()` / `JSON.parse()`. This is consistent with the existing save path conventions and avoids binary format edge cases on mobile.
