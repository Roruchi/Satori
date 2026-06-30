# Satori Refactoring Plan

This plan turns the 2026-06-30 codewise scan into a runnable refactoring backlog.
It is intentionally checklist-driven because the scheduled worker must pick up
exactly one action per run, verify it, and leave a durable handoff.

## Worker Contract

Every scheduled refactor-worker run must follow this contract.

- [ ] Read `AGENTS.md` and this file before changing code.
- [ ] Inspect `git status --short --branch` with `git -c safe.directory=C:/Repo/Personal/Games/Satori`.
- [ ] Preserve unrelated local changes. If the selected action touches a file that already has unrelated edits, either work with those edits after reading them carefully or stop with a blocker.
- [ ] Select exactly one unchecked action from the Action Backlog, in listed order, skipping actions explicitly marked Blocked.
- [ ] Keep scope to that one action. Do not opportunistically complete later actions.
- [ ] If the selected action needs a prerequisite that is not done, complete the prerequisite instead and record the reason in the handoff.
- [ ] Before editing, identify the focused tests that should prove behavior did not change.
- [ ] After editing, run `tools/godot.ps1 -Command parse`.
- [ ] Run focused GUT tests for the touched system with `tools/godot.ps1 -Command test -Test "res://tests/unit/..."`.
- [ ] Run `tools/godot.ps1 -Command boot` when the action touches autoloads, startup wiring, scenes, UI initialization, save/load, or persistence.
- [ ] Do not mark an action complete unless validation passes.
- [ ] If validation fails, keep the action unchecked, record the exact failing command and reason in the run handoff, and do not continue to another action.
- [ ] If validation cannot run because Godot import/cache state is broken, repair state first with the established headless import flow, then rerun validation.
- [ ] If Godot cannot write to normal user directories, redirect `APPDATA` and `LOCALAPPDATA` to workspace-local `.codex-godot-home` paths and rerun sequentially.
- [ ] Do not loosen gameplay invariants: no duplicate ritual inputs, mixed-seed reservation, real inventory consumption for placement, active housed spirits for ritual spirit inputs, and existing progression gates.
- [ ] Keep recipes, CSVs, specs, runtime data, viewer/export tooling, and docs in sync when changing rituals, materials, recipes, tile unlocks, structure effects, or discovery data.
- [ ] End with a handoff containing: selected action, files changed, validation commands/results, what was intentionally not done, blockers/risks, and next recommended action.

## Definition Of Done For Each Action

- [ ] Behavior is unchanged unless the action explicitly calls for a behavior change.
- [ ] Public API names remain compatible, or all call sites and tests are migrated in the same action.
- [ ] No new autoload singleton key matches a script `class_name`.
- [ ] No broad `Variant`/`Dictionary.get()` warning regressions are introduced in warning-as-error files.
- [ ] New helper scripts/classes have focused tests or are covered by existing behavior tests.
- [ ] Any new constants remove duplicated literals from at least two call sites.
- [ ] Any extracted service has a clear owner and does not create a parallel second source of truth.
- [ ] Any UI refactor preserves mobile/web text fit and ASCII-safe display copy.
- [ ] Any catalog/data refactor preserves `specs/master/recipes.md` and CSV/runtime catalog consistency.
- [ ] The final diff does not include unrelated reformatting or generated churn outside the selected action.

## Validation Matrix

Use the smallest validation set that proves the action, plus `parse` every time.

| Area touched | Required focused validation |
| --- | --- |
| Structure catalog, structure effects, assets | `res://tests/unit/test_structure_catalog_data.gd`, `res://tests/unit/test_satori_service.gd` when runtime structures change |
| Rituals, materials, recipes, CSVs | `res://tests/unit/seeds/test_ritual_recipe_catalog.gd`, `res://tests/unit/seeds/test_ritual_menu_slots.gd`, `res://tests/unit/test_discovery_editor_runtime_data.gd` |
| Seed/alchemy inventory | `res://tests/unit/seeds/test_seed_growth_service.gd`, `res://tests/unit/test_place_inventory_buildings.gd`, relevant ritual tests |
| Placement/building input | `res://tests/unit/test_building_placement_session.gd`, `res://tests/unit/test_place_inventory_buildings.gd`, `res://tests/unit/test_build_mode_regressions.gd` |
| Garden rendering/hover/UI | `res://tests/unit/test_web_ui_smoke_contract.gd`, `res://tests/unit/test_ritual_menu_ui.gd`, `boot` |
| Spirits/housing | `res://tests/unit/spirits/test_spirit_service.gd`, `res://tests/unit/test_spirit_island_scope.gd`, `res://tests/unit/spirits/test_shrine_interact_flow.gd` |
| Pattern scans/discovery | `res://tests/unit/patterns/test_scan_scheduler.gd`, `res://tests/unit/test_pattern_duplicate_suppression.gd`, `res://tests/unit/test_pattern_scan_performance.gd` |
| Save/load/autosave | `res://tests/unit/test_save_game_service.gd`, `res://tests/unit/test_first_expansion_loop.gd`, `boot` |
| Audio/soundscape | `res://tests/unit/test_soundscape_engine.gd`, `boot` if autoload wiring changes |

## Action Backlog

### Phase 0 - Baseline Safety Rails

- [ ] **R0.1 Capture current refactor baseline**
  - [ ] Read the latest scan summary in this file and current largest-file/hotspot metrics.
  - [ ] Confirm the checkout branch and dirty state.
  - [ ] Run `tools/godot.ps1 -Command parse`.
  - [ ] If parse fails due to import/cache state, repair Godot cache before diagnosing code.
  - [ ] Record baseline validation evidence in the run handoff.

- [ ] **R0.2 Add a refactor progress note section**
  - [ ] Add a `## Progress Log` entry at the bottom of this file for the run.
  - [ ] Include date, selected action, files touched, validation, and next action.
  - [ ] Do not mark any code refactor action complete in the same run unless it is the selected action.

### Phase 1 - Low-Risk Shared Helpers

- [ ] **R1.1 Introduce a runtime node lookup helper**
  - [ ] Add a small helper under `src/runtime/` or another established neutral location.
  - [ ] Centralize repeated `/root/SpiritService`, `/root/Garden/SpiritService`, and `/root/VoxelGarden/SpiritService` lookup.
  - [ ] Migrate exactly one repeated resolver first, preferably `SeedAlchemyService._resolve_spirit_service()`.
  - [ ] Validate with ritual and spirit-focused tests.
  - [ ] Leave other resolver migrations for later actions.

- [ ] **R1.2 Migrate remaining spirit-service lookup call sites**
  - [ ] Replace repeated spirit-service fallback lookup in `GardenView`, `PlacementController`, `spirit_wanderer`, and `HUDController`.
  - [ ] Preserve all existing fallback paths.
  - [ ] Validate with spirit, placement, UI smoke, and parse.

- [ ] **R1.3 Introduce tile metadata key constants**
  - [ ] Add a `TileMetadataKeys` helper or equivalent.
  - [ ] Move repeated keys such as `is_build_block`, `is_building_complete`, `build_discovery_id`, `structure_discovery_id`, `shrine_built`, `material_node`, `build_started_at`, and `build_duration`.
  - [ ] Migrate no more than one subsystem in this action, preferably `PlacementController`.
  - [ ] Validate placement/building tests.

- [ ] **R1.4 Migrate remaining tile metadata call sites**
  - [ ] Migrate `GameState`, `GardenView`, `SpiritService`, and `SatoriService` to the metadata key helper.
  - [ ] Avoid changing serialized save payload field names.
  - [ ] Validate save/load, placement, structure, and spirit tests.

- [ ] **R1.5 Extract shared UI style helpers**
  - [ ] Add a small helper for common `StyleBoxFlat` construction and button hover/focus style creation.
  - [ ] Migrate one low-risk UI file first, preferably `SettingsMenu.gd` or `TitleScreen.gd`.
  - [ ] Validate parse and boot.

- [ ] **R1.6 Migrate HUD and ritual panel style duplication**
  - [ ] Use the shared style helper in `HUDController.gd` and `SeedAlchemyPanel.gd`.
  - [ ] Keep visual constants local unless they are genuinely shared tokens.
  - [ ] Validate UI smoke, ritual UI, and boot.

- [ ] **R1.7 Extract shared texture loading helper**
  - [ ] Replace repeated `_load_texture_resource` implementations in `GardenView`, `HUDController`, `SeedAlchemyPanel`, and `tile_selector_hex`.
  - [ ] Preserve fallback `Image.load_from_file` behavior.
  - [ ] Validate UI smoke, structure catalog asset tests, and boot.

- [ ] **R1.8 Add shared GUT fixture helpers**
  - [ ] Introduce test helpers for root singleton setup/cleanup and user save-path cleanup.
  - [ ] Migrate one test file with repeated setup first.
  - [ ] Validate the migrated test file and parse.

### Phase 2 - Catalog And Data Single Source Of Truth

- [ ] **R2.1 Extract structure effect normalization**
  - [ ] Move duplicated legacy effect normalization out of `SatoriService` and `StructureCatalogData`.
  - [ ] Keep output shape exactly `{ "type": ..., "params": ... }`.
  - [ ] Validate structure catalog and Satori service tests.

- [ ] **R2.2 Make StructureCatalogData own merged structure definitions**
  - [ ] Extend `StructureCatalogData` so runtime callers can ask for discovery-backed structure definitions.
  - [ ] Preserve asset paths, sprite frames paths, cap increases, uniqueness, housing capacity, effect params, and effects.
  - [ ] Validate `test_structure_catalog_data.gd`.

- [ ] **R2.3 Simplify SatoriService structure loading**
  - [ ] Replace `SatoriService._load_structure_definitions()` duplication with the StructureCatalogData API.
  - [ ] Preserve `_structure_defs` public behavior.
  - [ ] Validate Satori service, structure catalog, save/load if serialized structure state is affected, and boot.

- [ ] **R2.4 Add catalog drift tests**
  - [ ] Add tests that compare discovery catalog, structure catalog, ritual form entries, and structure asset references.
  - [ ] Cover missing assets, missing hover summaries, and effect normalization drift.
  - [ ] Validate the new tests.

- [ ] **R2.5 Consolidate material display names**
  - [ ] Remove duplicated material display-name mapping from `SeedAlchemyService`, UI, and structure surfaces.
  - [ ] Prefer CSV/runtime catalog names when available.
  - [ ] Validate ritual catalog, material harvesting, HUD, and parse.

### Phase 3 - Placement And Build Flow Split

- [ ] **R3.1 Extract placement action decision model**
  - [ ] Add a small result object or dictionary schema for placement decisions.
  - [ ] Document outcomes such as harvest, collect charge, build shrine, toggle build block, plant seed, bloom seed, ignore, and cancel.
  - [ ] Add focused unit coverage for the decision schema without moving behavior yet.

- [ ] **R3.2 Move left-click release branching out of PlacementController**
  - [ ] Extract the non-input branching from `PlacementController._unhandled_input()`.
  - [ ] Preserve call order: material harvest, bloom, HUD mode check, spirit charge, build actions, plant seed.
  - [ ] Validate build mode regressions, placement, material harvesting, and ritual/seed growth tests.

- [ ] **R3.3 Extract build block rules**
  - [ ] Move `_toggle_build_block` rule checks into a build-rule helper while preserving tile metadata writes.
  - [ ] Keep inventory consumption and pending-project semantics unchanged.
  - [ ] Validate placement, save/load, Satori service structure tests, and spirit housing tests.

- [ ] **R3.4 Extract building footprint resolution**
  - [ ] Move footprint caching/resolution out of `PlacementController`.
  - [ ] Keep single-tile default behavior.
  - [ ] Validate building placement session and place-inventory building tests.

### Phase 4 - GardenView Rendering Split

- [ ] **R4.1 Extract background renderer**
  - [ ] Move `_init_background_data`, `_draw_background`, `_draw_edge_mist`, and related constants into a helper.
  - [ ] Preserve deterministic seeds and animation timing.
  - [ ] Validate parse and boot.

- [ ] **R4.2 Extract terrain decoration renderer**
  - [ ] Move `_draw_tile_decorations` and biome decoration constants into a helper.
  - [ ] Preserve fallback behavior for biomes unsupported by the terrain tilesheet.
  - [ ] Validate terrain/hex tests, UI smoke, and boot.

- [ ] **R4.3 Extract structure icon collection**
  - [ ] Move build icon data collection out of `_draw()` into a helper that returns typed dictionaries or lightweight objects.
  - [ ] Preserve draw order and structure discovery metadata handling.
  - [ ] Validate structure catalog, placement, and boot.

- [ ] **R4.4 Extract material node drawing**
  - [ ] Move material-node atlas region and draw calculations into a helper.
  - [ ] Preserve growth-stage visuals and hover behavior.
  - [ ] Validate material growth atlas, material harvesting, UI smoke, and boot.

- [ ] **R4.5 Add viewport-aware render culling only if safe**
  - [ ] Measure current draw loops first.
  - [ ] Add culling only for obviously offscreen tile decorations/material nodes.
  - [ ] Validate boot and any existing performance tests.

### Phase 5 - Spirit Service Split

- [ ] **R5.1 Extract housing assignment calculator**
  - [ ] Move `_compute_housing_assignment` and direct helper dependencies into a focused collaborator.
  - [ ] Preserve house binding stability, upgraded-house preference, island-local counts, and Sky Whale exclusions.
  - [ ] Validate spirit service, shrine interact flow, island scope, and first expansion loop tests.

- [ ] **R5.2 Extract pending building tracker**
  - [ ] Move pending building timers/finalization concerns out of `SpiritService`.
  - [ ] Preserve `register_pending_building`, build completion signal behavior, and save/load behavior.
  - [ ] Validate spirit service, save/load, placement, and boot.

- [ ] **R5.3 Extract essence charge timer logic**
  - [ ] Move essence drop scheduling/charge processing into a collaborator.
  - [ ] Preserve GardenSettings progression-speed scaling.
  - [ ] Validate spirit service, seed/alchemy material count changes, save/load, and boot.

- [ ] **R5.4 Reduce SpiritService dynamic calls**
  - [ ] Replace `has_method`/dynamic service calls with small helper APIs where safe.
  - [ ] Avoid autoload/class_name collisions.
  - [ ] Validate spirit, Satori, and boot tests.

### Phase 6 - Save And Autosave Cleanup

- [ ] **R6.1 Replace arity-specific autosave signal connectors**
  - [ ] Collapse `_connect_signal_0` through `_connect_signal_4` into a data-driven connector or tiny adapter.
  - [ ] Preserve bound reason strings and signal arity behavior.
  - [ ] Validate save game service tests and boot.

- [ ] **R6.2 Introduce optional service serialization registry**
  - [ ] Replace repeated `_add_optional_service_payload` and `_restore_optional_service` call lists with a small registry table.
  - [ ] Preserve payload keys and schema version.
  - [ ] Validate save/load and first expansion loop tests.

- [ ] **R6.3 Add save schema smoke coverage for refactor helpers**
  - [ ] Add coverage that serialized keys stay stable after metadata/helper extraction.
  - [ ] Validate save game service tests.

### Phase 7 - Data Pipeline And Generated Catalog Hygiene

- [ ] **R7.1 Document generated catalog ownership**
  - [ ] Clarify in docs that `tools/sync_discovery_csvs.py` owns generated catalog surfaces.
  - [ ] Document when to run export vs sync and how to review generated churn.
  - [ ] Validate no code behavior changes with parse.

- [ ] **R7.2 Add a catalog sync dry-check command**
  - [ ] Add or document a command that detects CSV/catalog drift without rewriting files.
  - [ ] Keep the command local and deterministic.
  - [ ] Validate by running the command and focused catalog tests.

- [ ] **R7.3 Consolidate dictionary key literals for catalog rows**
  - [ ] Add catalog key constants for `display_name`, `discovery_id`, `effect_type`, `effect_params`, `cap_increase`, `audio_key`, and `flavor_text`.
  - [ ] Migrate one catalog module first.
  - [ ] Validate catalog tests.

### Phase 8 - Broad Verification And Cleanup

- [ ] **R8.1 Run a broad refactor verification pass**
  - [ ] Run parse.
  - [ ] Run boot.
  - [ ] Run all focused tests touched by completed refactor actions.
  - [ ] If practical, run the full GUT suite with the known pending/risky audio gaps documented.
  - [ ] Record final evidence in the Progress Log.

- [ ] **R8.2 Remove temporary compatibility helpers**
  - [ ] Search for helpers introduced only for migration.
  - [ ] Remove dead code and update tests.
  - [ ] Validate parse, boot, and affected focused tests.

- [ ] **R8.3 Update refactor summary**
  - [ ] Summarize completed phases, remaining risk, and validation evidence.
  - [ ] Keep the summary factual and file-referenced.
  - [ ] Do not overclaim performance improvements without measurements.

## Known Hotspots From The Scan

- `src/grid/GardenView.gd`: 2,290 lines; immediate-mode draw orchestrates terrain, decorations, overlays, materials, structures, background animation, hover, Satori state, and service connections.
- `src/spirits/spirit_service.gd`: 1,197 lines; spirit spawning, housing assignment, persistence restoration, building completion, essence timers, and multiple autoload connections.
- `src/ui/HUDController.gd`: 1,000 lines; HUD state, material/build inventory rendering, world popovers, mode tabs, and style construction.
- `src/ui/SeedAlchemyPanel.gd`: 952 lines; ritual input state, inventory, adaptive layout, styling, and structure previews.
- `src/grid/PlacementController.gd`: 805 lines; input handling, material harvesting, build block toggling, seed planting, building sessions, spirit charge collection, and service lookups.
- `src/autoloads/satori_service.gd` and `src/biomes/structure_catalog_data.gd`: duplicated structure-definition and legacy-effect normalization.
- `src/autoloads/save_game_service.gd`: arity-specific signal connector duplication and optional-service payload lists.
- Tests: repeated root-singleton setup, save-path cleanup, and large fixture-heavy suites.

## Progress Log

No scheduled worker actions have been completed yet.
