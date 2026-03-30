This serves as a bug history and implementation checklist for testing-session issues.

# Bugs

## 1) Build mode removes existing house without explicit cancel/confirm
- [x] Analyze
	- Root cause: build mode started countdown immediately and lacked explicit pre-countdown confirmation semantics.
- [x] Fix
	- Build blocks now enter a pending state first (`build_countdown_started = false`).
	- Left click on a pending block explicitly confirms and starts countdown.
	- Right click cancels pending blocks before confirm (refund applies).
	- Once confirmed, cancellation/removal is blocked by permanence rule.
- [x] Regression test
	- `tests/unit/test_build_mode_regressions.gd::test_build_confirm_starts_countdown_and_disables_cancel`
	- `tests/unit/test_build_mode_regressions.gd::test_build_cancel_only_allowed_before_confirm`
	- `tests/unit/test_build_mode_regressions.gd::test_build_mode_places_pending_block_without_starting_countdown`
	- `tests/unit/test_build_mode_regressions.gd::test_completed_house_is_not_removed_by_build_toggle`
	- `tests/unit/test_build_mode_regressions.gd::test_completed_house_cannot_be_restarted_as_new_build_block`

## 2) Structure recipes/charges unclear; cannot place multiple charges
- [ ] Analyze
	- Current behavior supports stacked shrine charges and multi-element charge payloads, but UX clarity still needs dedicated UI copy and flow review.
- [ ] Fix
	- Not fully addressed in this patch set (logic already existed for multi-charge collection).
- [ ] Regression test
	- Existing coverage remains in `tests/unit/spirits/test_shrine_interact_flow.gd` for multi-element charge collection.

## 3) Water spirit essence drops at origin shrine instead of completed water house
- [x] Analyze
	- Root cause: `SpiritGiftProcessor` always selected origin first and only used water-house fallback in narrower island-mismatch cases.
- [x] Fix
	- Water spirits now prefer completed water-house dropoff on their island before origin fallback.
- [x] Regression test
	- `tests/unit/spirits/test_shrine_interact_flow.gd::test_water_spirit_prefers_completed_water_house_for_charge_dropoff`

## 4) Unlocking special build shows auto-placement style build icons immediately
- [x] Analyze
	- Root cause: build prompts rendered regardless of current player mode, creating an "auto-placed" impression.
- [x] Fix
	- Build prompts are now shown only in Build mode.
- [ ] Regression test
	- Visual/UI behavior needs scene-level integration test coverage (unit-only not yet added).

## 5) Spirit name color should be red when spirit is unhoused (negative Satori)
- [x] Analyze
	- Root cause: spirit labels were always rendered with a static light color.
- [x] Fix
	- Added per-spirit housing status API in `SpiritService`.
	- `SpiritWanderer` now refreshes label color: white when housed, red when unhoused.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_is_spirit_housed_reports_false_for_unhoused_spirit`

## 6) Mist Stag should unlock Ku at 3/3 and only restore Ku charges
- [x] Analyze
	- Root causes:
		- Ku unlock did not initialize Ku charge to full.
		- Mist Stag essence mapping followed biome mapping instead of Ku-only special behavior.
- [x] Fix
	- Ku unlock now sets Ku to full capacity (3/3).
	- Mist Stag essence drops now restore only Ku.
- [x] Regression test
	- `tests/unit/seeds/test_seed_growth_service.gd::test_ku_unlock_to_craft_flow_requires_mist_stag_gift`
	- `tests/unit/spirits/test_shrine_interact_flow.gd::test_mist_stag_essence_drop_restores_only_ku_charge`

## 7) Weird gold icon appears when a house is built
- [x] Analyze
	- Root causes:
		- Legacy lock-dot rendering on locked tiles displayed a gold marker.
		- Completed buildings could retain locked state.
- [x] Fix
	- Removed legacy lock-dot render path from `GardenView`.
	- Build completion now clears `tile.locked`.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_finalize_pending_buildings_clears_locked_state`

## 8) Deep Stand overlay draws above house; structures should always be highest layer
- [x] Analyze
	- Root cause: structure icon drawing happened before cluster/discovery overlays.
- [x] Fix
	- Deferred build/structure icon drawing to after biome/discovery overlays so structures stay visually on top.
- [ ] Regression test
	- Visual ordering validated by draw-order implementation; no rendering snapshot test yet.

## 9) Build mode allows building on empty coordinates
- [x] Analyze
	- Root cause: build mode still routed empty coordinates through build-block placement, creating new tiles implicitly.
- [x] Fix
	- Build mode now only applies to existing tiles.
	- Empty coordinates in build mode no longer create pending build blocks or tiles.
- [x] Regression test
	- `tests/unit/test_build_mode_regressions.gd::test_build_mode_does_not_create_build_tile_on_empty_coord`

## 10) Multiple buildings can get stuck showing Build 0s
- [x] Analyze
	- Root cause: completion sweep required active builder-spirit presence, so elapsed build timers could remain at 0s indefinitely when that condition was not met.
- [x] Fix
	- Build completion now finalizes strictly from elapsed countdown state for every eligible tile.
	- Completion clears countdown metadata after finishing to avoid stale 0s overlay state.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_finalize_pending_buildings_completes_multiple_elapsed_countdowns`

## 11) Ku-separated islands do not spawn multiple instances of the same spirit
- [x] Analyze
	- Root cause: global pattern scan emitted at most one match per spirit discovery ID, so only one island could trigger a summon for that spirit.
- [x] Fix
	- Added island-local spirit scan on tile placement in `SpiritService`.
	- Each non-Ku island is now evaluated independently and can summon its own instance of the same spirit.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_tile_placed_spawns_same_spirit_on_two_ku_separated_islands`

## 12) Secondary islands cannot create their own Origin Shrine via Fu build block
- [x] Analyze
	- Root causes:
		- Origin shrine handling remained effectively global and did not support per-island creation flow.
		- Charge dropoff looked up a single origin shrine without island preference.
- [x] Fix
	- Build mode now supports Fu-on-Stone as an origin-shrine build intent.
	- Origin shrine creation is limited to one shrine per island.
	- Completing that build stamps origin shrine metadata (`is_origin_shrine`, `shrine_built`, `disc_origin_shrine`).
	- Spirit charge dropoff now prefers the origin shrine on the spirit's island, with fallback to any origin shrine.
- [x] Regression test
	- `tests/unit/test_build_mode_regressions.gd::test_fu_build_block_on_stone_marks_pending_origin_shrine`
	- `tests/unit/test_build_mode_regressions.gd::test_origin_shrine_build_is_limited_to_one_per_island`
	- `tests/unit/spirits/test_spirit_service.gd::test_finalize_pending_buildings_converts_pending_origin_shrine_metadata`
	- `tests/unit/spirits/test_shrine_interact_flow.gd::test_godai_charge_prefers_origin_shrine_on_spirit_island`

## 13) Structure unlocks auto-mark build labels instead of recipe-based projects
- [x] Analyze
	- Root causes:
		- `GardenView` stamped `shrine_buildable` metadata immediately on discovery trigger, creating auto-placement prompts.
		- Build mode had no contiguous project model (no one-project limit, no adjacency gating, no project-wide confirm).
- [x] Fix
	- Removed auto build-label metadata stamping on discovery unlock.
	- Added codex structure recipe hint entries on structure unlock (cryptic hint text; starts as hinted, not discovered).
	- Build mode now enforces one active contiguous project at a time:
		- New pending build blocks must be adjacent to the same project.
		- Confirming any pending block starts countdown for the full project.
		- New non-adjacent project placement is blocked until active project completes.
	- Added blue highlight treatment for pending project blocks.
	- Added recipe-state feedback for pending projects:
		- Green outline/fill when project matches a valid unlocked recipe.
		- Blue outline/fill when recipe is missing or still locked.
		- Confirm on invalid recipe triggers red flash outline (1s fade in + 1s fade out) and does not start countdown.
	- Added pagoda project recipe path: Fu-build blocks on Wetlands in a 4-tile square/parallelogram convert to `disc_lotus_pagoda` on completion.
	- Countdown behavior adjusted so a confirmed project can count down while a new pending project is started elsewhere.
	- Spirit dedupe now checks the current island component (not only cached island key string), preventing same-island re-spawns when island IDs shift as terrain expands.
	- Housing assignment now only considers houses on the spirit's own island.
	- Special structures (Origin Shrine, Pagoda, etc.) are finalized as structures only and are no longer also marked as houses on the same tile.
	- House assignment now uses stable spirit-to-house binding on the same island: preferred-biome houses first, then fallback to any remaining same-island house; existing bindings are preserved across recomputes.
	- Interact mode now shows hover popovers for houses/structures/shrines with type, house owner binding (if any), and shrine essence contents.
	- Hover popovers are now rendered via HUD canvas overlay so they stay on the top UI layer above world sprites/effects.
- [x] Regression test
	- `tests/unit/test_build_mode_regressions.gd::test_build_project_requires_adjacency_for_new_pending_blocks`
	- `tests/unit/test_build_mode_regressions.gd::test_confirming_one_pending_project_starts_countdown_for_all_project_tiles`
	- `tests/unit/test_build_mode_regressions.gd::test_invalid_recipe_confirm_flashes_and_does_not_start_countdown`
	- `tests/unit/test_build_mode_regressions.gd::test_valid_recipe_project_turns_green_and_confirms`
	- `tests/unit/test_build_mode_regressions.gd::test_can_start_new_project_while_previous_project_counts_down`
	- `tests/unit/spirits/test_spirit_service.gd::test_finalize_pending_buildings_converts_pending_structure_metadata`
	- `tests/unit/spirits/test_spirit_service.gd::test_tile_placed_does_not_respawn_same_spirit_when_island_id_changes`
	- `tests/unit/spirits/test_spirit_service.gd::test_housing_does_not_use_houses_from_other_islands`
	- `tests/unit/spirits/test_spirit_service.gd::test_housing_falls_back_to_any_house_on_same_island_when_preferred_missing`
	- `tests/unit/spirits/test_spirit_service.gd::test_house_binding_remains_with_spirit_after_recompute`
	- `tests/unit/spirits/test_spirit_service.gd::test_get_house_owner_at_coord_returns_bound_spirit`
	- `tests/unit/spirits/test_shrine_interact_flow.gd::test_get_shrine_charge_counts_returns_pending_amounts`

## 15) Spirit can become homeless/stuck after nearby biome expansion
- [x] Analyze
	- Root cause: active spirit dictionaries were keyed by cached island ID strings. When island IDs drifted after contiguous expansion, active spirit keys, wanderer keys, drop timers, and house-binding keys could go stale and de-sync from current grid island IDs.
- [x] Fix
	- Added active-island refresh/rekey on tile placement in `SpiritService`.
	- Rekey now synchronizes `_active_instances`, `_active_wanderers`, `_next_essence_drop_at`, and `_house_binding_by_spirit` to current island IDs.
	- Added `SpiritWanderer.set_island_id(...)` so rekey updates the wanderer's island filter immediately.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_island_id_drift_rekeys_spirit_without_losing_house_binding`

## 16) Mist Stag can spawn during Stillness instead of Awakening
- [x] Analyze
	- Root cause: summon paths did not enforce the spirit `min_era` gate before creating active instances.
- [x] Fix
	- Added era requirement validation before summoning in `SpiritService`.
	- Mist Stag (`min_era = awakening`) now stays blocked during Stillness and only spawns once era requirements are met.
- [x] Regression test
	- `tests/unit/spirits/test_spirit_service.gd::test_mist_stag_does_not_spawn_in_stillness_era`
	- `tests/unit/spirits/test_spirit_service.gd::test_mist_stag_spawns_in_awakening_era`

# Debugging features

## 14) Remove instant/realtime toggle and replace with speedup mechanism
- [x] Analyze
	- Root cause: growth flow depended on a binary mode toggle, forcing dual-path debugging.
- [x] Fix
	- Removed instant-mode runtime logic from core services/settings/HUD paths.
	- Growth now runs in real-time only, with speed multiplier controlling pace.
	- Added growth speed multiplier (`x1..x16`) in `GardenSettings` and `SeedGrowthService`.
	- Rewired settings/toggle UI to use speed multiplier rather than switching growth mode.
	- HUD badge now reflects active growth speedup (`xN`).
- [x] Regression test
	- `tests/unit/seeds/test_seed_growth_service.gd::test_growth_speed_multiplier_reduces_real_time_duration`