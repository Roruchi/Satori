# Tasks: Living Garden — Satori v2 Core Loop

**Input**: Design documents from `/specs/015-living-garden/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Scope note (user instruction)**: Persistence activation (Phase 7 of plan.md) is excluded.
All services operate with in-memory state only. A mode toggle button is added to the HUD
(US9) so developers can switch between INSTANT and REAL_TIME without opening Settings.

**Tests**: GUT automated tests are required for all deterministic gameplay logic
(recipe lookup, growth evaluation, satori conditions, ecology detection). Scene-heavy
and UI work requires explicit manual validation tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation
and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US9)
- All file paths are absolute from the project root

---

## Phase 1: Setup

**Purpose**: Confirm working state and register autoload stubs before any new code is written.

- [] T001 Verify all existing GUT tests pass via `tests/gut_runner.tscn`; note any pre-existing failures to exclude from this feature's scope
- [] T002 Add six empty autoload stub files to `project.godot` in dependency order: `GardenSettings`, `SeedAlchemyService`, `SeedGrowthService`, `SpiritEcologyService`, `CodexService`, `SatoriService` — each file must `extends Node` with a single `_ready()` no-op so the project loads without error; verify no parse errors on launch

---

## Phase 2: Foundational — BiomeType Migration

**Purpose**: The BiomeType enum underpins every subsequent phase. No user story work
can begin until pattern .tres files are consistent with the new Godai-aligned values.

**⚠️ CRITICAL**: Run the full GUT suite after T005 as the gate before Phase 3.

- [] T003 Rewrite `src/biomes/BiomeType.gd` — replace the entire `enum Value` block with the Godai-aligned set per data-model.md: `NONE=-1`, `STONE=0`, `RIVER=1`, `EMBER_FIELD=2`, `MEADOW=3`, `CLAY=4`, `DESERT=5`, `DUNE=6`, `HOT_SPRING=7`, `BOG=8`, `CINDER_HEATH=9`, `SACRED_STONE=10`, `VEIL_MARSH=11`, `EMBER_SHRINE=12`, `CLOUD_RIDGE=13`; replace the body of the static `mix()` function with `return Value.NONE` and add a comment `## Deprecated — use SeedRecipeRegistry.lookup() instead`
- [] T004 [P] Write `tests/unit/test_biome_type.gd` — GUT tests: STONE==0, RIVER==1, EMBER_FIELD==2, MEADOW==3; `mix()` returns NONE for all inputs including former valid pairs; NONE==-1; total enum count matches expected (14 named values + NONE)
- [] T005 Audit all pattern `.tres` files under `src/biomes/patterns/` and `res://resources/` — search for any integer biome references using the old values (FOREST=0, WATER=1, STONE=2, EARTH=3); update `required_biomes` and `forbidden_biomes` arrays to the new integer IDs (STONE=0, RIVER=1, EMBER_FIELD=2, MEADOW=3); run `test_biome_type.gd` and the full GUT suite to confirm no pattern test regressions
- [] T006 Update `src/autoloads/GameState.gd` — (a) change origin tile in `_ready()` from `BiomeType.Value.FOREST` to `BiomeType.Value.STONE`; (b) add `signal bloom_confirmed(coord: Vector2i, biome: int)` alongside the existing `tile_placed` signal; (c) add `func place_tile_from_seed(coord: Vector2i, biome: int) -> void` that calls `grid.place_tile(coord, biome)` and emits both `tile_placed` and `bloom_confirmed`; (d) mark `try_mix_tile()` deprecated with `push_warning("try_mix_tile is deprecated")` at the top of its body and return `false`

**Checkpoint**: `test_biome_type.gd` passes. Full GUT suite has no new failures vs T001 baseline. Phase 3 may begin.

---

## Phase 3: User Story 5 — Godai Elements & Recipe Foundation (Priority: P1)

**Goal**: All seed recipes exist as typed data resources; the registry loads and looks them
up correctly; Kū is locked; Tier 3 is gated by spirit unlock.

**Independent Test**: Run `test_seed_recipe_registry.gd`. Confirm all 10 Tier 1+2 recipes
are found, Chi+Sui returns Clay, Sui+Chi also returns Clay (order-independent), Kū is
locked and returns null for any Kū-containing recipe, and an unknown element set returns null.

- [] T007 [P] Create `src/seeds/GodaiElement.gd` — `class_name GodaiElement extends RefCounted`; define `enum Value { CHI=0, SUI=1, KA=2, FU=3, KU=4 }`; add `const DISPLAY_NAMES: Dictionary` mapping each value to its display string (e.g. `"Chi (地)"`); add `const LOCKED_BY_DEFAULT: Array[int] = [Value.KU]`
- [] T008 [P] Create `src/seeds/SeedState.gd` — `class_name SeedState extends RefCounted`; define `enum Value { GROWING=0, READY=1, BLOOMED=2 }`
- [] T009 [P] Create `src/seeds/GrowthMode.gd` — `class_name GrowthMode extends RefCounted`; define `enum Value { INSTANT=0, REAL_TIME=1 }`
- [] T010 Create `src/seeds/SeedRecipe.gd` — `class_name SeedRecipe extends Resource`; exports per data-model.md: `recipe_id: StringName`, `elements: Array[int]` (GodaiElement.Value[], stored sorted ascending), `tier: int`, `produces_biome: int` (BiomeType.Value), `spirit_unlock_id: StringName` (empty for Tier 1/2), `codex_hint: String`; add `func element_key() -> String` that joins the sorted elements with `_` (e.g. `"0_1"` for Chi+Sui)
- [] T011 Create `src/seeds/SeedRecipeRegistry.gd` — `class_name SeedRecipeRegistry extends RefCounted`; on construction, use `DirAccess.open("res://src/seeds/recipes/")` to load all `.tres` files as `SeedRecipe` resources into `_recipes: Dictionary` keyed by `element_key()`; implement `func lookup(elements: Array[int]) -> SeedRecipe` that sorts the input, builds the key, checks `_unlocked_tier3` for Tier 3 entries, returns `null` if not found or locked; implement `func unlock_recipe(recipe_id: StringName) -> void` and `func is_recipe_known(recipe_id: StringName) -> bool`; implement `func all_known_recipes() -> Array[SeedRecipe]`
- [] T012 [P] Author `src/seeds/recipes/recipe_chi.tres` — SeedRecipe resource: `recipe_id="recipe_chi"`, `elements=[0]`, `tier=1`, `produces_biome=0` (STONE), `spirit_unlock_id=""`, `codex_hint="Cold and still, the bones of the earth."`
- [] T013 [P] Author `src/seeds/recipes/recipe_sui.tres` — `recipe_id="recipe_sui"`, `elements=[1]`, `tier=1`, `produces_biome=1` (RIVER), `codex_hint="It finds its own way through stone."`
- [] T014 [P] Author `src/seeds/recipes/recipe_ka.tres` — `recipe_id="recipe_ka"`, `elements=[2]`, `tier=1`, `produces_biome=2` (EMBER_FIELD), `codex_hint="Where heat remembers the shape of fire."`
- [] T015 [P] Author `src/seeds/recipes/recipe_fu.tres` — `recipe_id="recipe_fu"`, `elements=[3]`, `tier=1`, `produces_biome=3` (MEADOW), `codex_hint="Grass that bends but does not break."`
- [] T016 [P] Author `src/seeds/recipes/recipe_chi_sui.tres` — `recipe_id="recipe_chi_sui"`, `elements=[0,1]`, `tier=2`, `produces_biome=4` (CLAY), `codex_hint="Earth softened by patient water."`
- [] T017 [P] Author `src/seeds/recipes/recipe_chi_ka.tres` — `recipe_id="recipe_chi_ka"`, `elements=[0,2]`, `tier=2`, `produces_biome=5` (DESERT), `codex_hint="Earth baked dry under ancient fire."`
- [] T018 [P] Author `src/seeds/recipes/recipe_chi_fu.tres` — `recipe_id="recipe_chi_fu"`, `elements=[0,3]`, `tier=2`, `produces_biome=6` (DUNE), `codex_hint="Stone surrendered to the breath of wind."`
- [] T019 [P] Author `src/seeds/recipes/recipe_sui_ka.tres` — `recipe_id="recipe_sui_ka"`, `elements=[1,2]`, `tier=2`, `produces_biome=7` (HOT_SPRING), `codex_hint="Water that carries the memory of fire."`
- [] T020 [P] Author `src/seeds/recipes/recipe_sui_fu.tres` — `recipe_id="recipe_sui_fu"`, `elements=[1,3]`, `tier=2`, `produces_biome=8` (BOG), `codex_hint="Water and wind, slow and heavy together."`
- [] T021 [P] Author `src/seeds/recipes/recipe_ka_fu.tres` — `recipe_id="recipe_ka_fu"`, `elements=[2,3]`, `tier=2`, `produces_biome=9` (CINDER_HEATH), `codex_hint="Where fire and wind once raced each other."`
- [] T022 Write `tests/unit/seeds/test_seed_recipe_registry.gd` — GUT tests: all 10 Tier 1+2 recipes loaded (registry size == 10); Chi lookup returns STONE biome; Chi+Sui lookup returns CLAY; Sui+Chi lookup returns CLAY (order-independent); KU alone returns null (locked); Chi+KU returns null (KU locked); unknown element combo [0,1,2] returns null (no Tier 3 unlocked); after `unlock_recipe("recipe_chi_sui_ka")` with a manually-loaded test resource, that recipe becomes accessible

**Checkpoint**: `test_seed_recipe_registry.gd` passes. All 10 recipe .tres files load without errors.

---

## Phase 4: User Story 2, 3, 4 — Seed Growth Engine (Priority: P1)

**Goal**: Seeds can be planted at valid garden edges and bloom on explicit player tap.
Growing slot limit blocks planting when full. Pattern scanner fires on bloom.

**Independent Test**: In instant mode, plant a Stone seed at a valid edge hex — confirm
growing slot count drops by 1, the sprout glows immediately (READY state), tapping it
triggers the bloom, `bloom_confirmed` signal fires, pattern scanner receives it,
growing slot returns to available. Run `test_seed_growth_service.gd`.

- [] T023 Create `src/seeds/SeedInstance.gd` — `class_name SeedInstance extends RefCounted`; fields per data-model.md: `recipe_id: StringName`, `hex_coord: Vector2i`, `planted_at: float`, `growth_duration: float`, `state: int` (SeedState.Value, default GROWING); add `static func create(rid: StringName, coord: Vector2i, duration: float) -> SeedInstance`; add `func evaluate_growth() -> bool` that transitions GROWING→READY when `growth_duration <= 0.0` or `Time.get_unix_time_from_system() - planted_at >= growth_duration`, returns true on transition; use explicit `bool` return type annotation (not `:=`)
- [] T024 Create `src/seeds/SeedPouch.gd` — `class_name SeedPouch extends RefCounted`; fields: `seeds: Array[SeedRecipe]`, `capacity: int = 3`; methods: `is_full() -> bool`, `add(recipe: SeedRecipe) -> bool` (returns false if full), `remove_at(index: int) -> SeedRecipe`, `first() -> SeedRecipe` (null if empty), `size() -> int`
- [] T025 Create `src/seeds/GrowthSlotTracker.gd` — `class_name GrowthSlotTracker extends RefCounted`; fields: `active_seeds: Array[SeedInstance]`, `capacity: int = 3`; methods: `available_slots() -> int`, `is_full() -> bool`, `add(seed: SeedInstance) -> void`, `remove_bloomed(coord: Vector2i) -> void`, `get_at(coord: Vector2i) -> SeedInstance` (null if not found, use explicit `SeedInstance` return type), `get_ready_seeds() -> Array[SeedInstance]`
- [] T026 Implement `src/autoloads/seed_growth_service.gd` (replacing the stub from T002) — `class_name SeedGrowthServiceNode extends Node`; signals: `seed_planted(seed: SeedInstance)`, `seed_ready(seed: SeedInstance)`, `bloom_confirmed(coord: Vector2i, biome: int)`; owns a `SeedPouch` and a `GrowthSlotTracker`; implement `try_plant(coord: Vector2i, recipe: SeedRecipe) -> bool` — returns false if `_tracker.is_full()`, creates SeedInstance with `growth_duration=0.0` if `_mode==GrowthMode.Value.INSTANT` else duration from recipe tier table (Tier1=600s, Tier2=1800s, Tier3=7200s), adds to tracker, emits `seed_planted`; implement `try_bloom(coord: Vector2i) -> bool` — returns false if no READY seed at coord; transitions seed to BLOOMED, removes from tracker, calls `GameState.place_tile_from_seed(coord, biome)`, emits `bloom_confirmed`; implement `_evaluate_all()` — calls `evaluate_growth()` on all GROWING seeds, emits `seed_ready` for each newly READY seed; implement `_notification(what)` — call `_evaluate_all()` on `NOTIFICATION_APPLICATION_FOCUS_IN`; add a 60-second `Timer` child that calls `_evaluate_all()` on timeout; use `preload("res://src/seeds/SeedInstance.gd")` and `preload("res://src/seeds/GrowthSlotTracker.gd")` for typed dependencies
- [] T027 Implement `get_mode() -> int` and `set_mode(mode: int) -> void` in `seed_growth_service.gd` — `set_mode(INSTANT)` iterates all GROWING seeds and calls `evaluate_growth()` to immediately promote them to READY (emits `seed_ready` for each); `set_mode(REAL_TIME)` sets `_mode` only, no seed regression; store `_mode: int = GrowthMode.Value.REAL_TIME`
- [] T028 Update `project.godot` — confirm `SeedGrowthService` is registered pointing to `src/autoloads/seed_growth_service.gd`; confirm `GardenSettings` stub is also registered
- [] T029 Update `PatternScanService` (or whichever autoload calls `game_state.tile_placed.connect()`) — add a connection to `SeedGrowthService.bloom_confirmed` alongside or instead of `GameState.tile_placed`; the origin tile still fires via `GameState.tile_placed` directly, so retain that connection for the origin tile only
- [] T030 Write `tests/unit/seeds/test_seed_growth_service.gd` — GUT tests: `try_plant` in INSTANT mode immediately produces a READY seed; `try_plant` when slots full returns false and does not add to tracker; `try_bloom` on a READY seed emits `bloom_confirmed` with correct coord and biome; `try_bloom` on a GROWING seed returns false; `set_mode(INSTANT)` promotes all GROWING seeds to READY; slot count returns to available after bloom; `available_slots()` returns capacity minus active seed count

**Checkpoint**: `test_seed_growth_service.gd` passes. In instant mode, plant→bloom→pattern fires correctly end to end.

---

## Phase 5: User Story 9 — Growth Timing Modes + Mode Toggle Button (Priority: P1)

**Goal**: A visible HUD button switches between INSTANT and REAL_TIME mode immediately.
The button shows a clear visual state difference. INSTANT mode shows a badge.
Real-time mode uses wall-clock time for growth.

**Independent Test**: In the running game, tap the mode toggle button. Confirm mode switches
from REAL_TIME → INSTANT (⚡ badge appears; newly planted seeds are immediately READY).
Tap again → REAL_TIME (badge hidden; newly planted seeds show growing animation).
Close and reopen app in REAL_TIME — confirm seeds planted before close resume correctly.

- [] T031 Implement `src/autoloads/garden_settings.gd` (replacing the stub from T002) — `class_name GardenSettingsNode extends Node`; expose `var growth_mode: int = GrowthMode.Value.REAL_TIME`; add `signal growth_mode_changed(mode: int)`; add `func set_growth_mode(mode: int) -> void` that sets `growth_mode`, emits `growth_mode_changed`, and calls `SeedGrowthService.set_mode(mode)` via `get_node_or_null("/root/SeedGrowthService")`; use `preload("res://src/seeds/GrowthMode.gd")` for the enum
- [] T032 Create `src/ui/GrowthModeToggleButton.gd` — `class_name GrowthModeToggleButton extends Button`; in `_ready()`, connect `pressed` to `_on_pressed()`; connect to `GardenSettings.growth_mode_changed` signal via `get_node_or_null("/root/GardenSettings")`; implement `_on_pressed()` — reads current mode from `GardenSettings.growth_mode`, calls `GardenSettings.set_growth_mode()` with the opposite mode; implement `_update_display(mode: int)` — set button icon/text to ⚡ when `INSTANT`, clock symbol (or "RT") when `REAL_TIME`; call `_update_display` in `_ready()` and on mode change signal
- [] T033 Add `GrowthModeToggleButton` as a child node of the HUD scene (to be created in US1 Phase 6, or add to `scenes/UI/HUD.tscn` now as a placeholder anchor); anchor it to top-right corner of the screen; ensure it does not overlap Plant/Mix/Codex mode buttons; size: minimum 44×44px tap target per EX-007
- [] T034 Add a persistent `InstantModeBadge` Label or icon node to the HUD — visible only when `GrowthMode.INSTANT` is active (⚡ text, top corner, small); connect to `GardenSettings.growth_mode_changed` to show/hide; satisfies EX-007 ("immediately legible to a developer at a glance")
- [] T035 Manual validation: launch game in REAL_TIME mode; plant a Tier 1 seed and verify it shows growing animation but no READY glow; tap mode toggle → ⚡ badge appears → seed immediately shows READY glow; tap seed to bloom → tile appears; tap mode toggle again → REAL_TIME, badge hidden; plant another seed → growing animation resumes

**Checkpoint**: Mode toggle works. Badge appears and disappears correctly. Seeds respond to mode switch mid-growth.

---

## Phase 6: User Story 1 — Seed Alchemy Mixing UI (Priority: P1)

**Goal**: Player opens the Mix panel, selects 1–2 Godai elements, sees a preview of the
seed produced, taps confirm, and the seed appears in the pouch ready to plant.

**Independent Test**: Open Mix panel, tap Chi then Sui — preview shows "Clay Seed". Tap
Confirm — seed appears in pouch indicator. Tap Kū — it is visually locked. Open Mix
again with full pouch — Confirm button is disabled. Tap Chi alone — preview shows
"Stone Seed"; confirm produces Stone seed.

- [] T036 Create `src/spirits/SpiritGiftType.gd` — `class_name SpiritGiftType extends RefCounted`; define `enum Value { NONE=0, KU_UNLOCK=1, TIER3_RECIPE=2, POUCH_EXPAND=3, GROWING_SLOT_EXPAND=4, CODEX_REVEAL=5 }`
- [] T037 Implement `src/autoloads/seed_alchemy_service.gd` (replacing the stub from T002) — `class_name SeedAlchemyServiceNode extends Node`; signals: `element_unlocked(element_id: int)`, `recipe_discovered(recipe_id: StringName)`, `seed_added_to_pouch(recipe: SeedRecipe)`; owns a `SeedRecipeRegistry` instance; field `_unlocked_elements: Array[int] = [GodaiElement.Value.CHI, GodaiElement.Value.SUI, GodaiElement.Value.KA, GodaiElement.Value.FU]` (KU locked); implement `is_element_unlocked(element: int) -> bool`; implement `unlock_element(element: int) -> void` — adds to `_unlocked_elements`, emits `element_unlocked`; implement `lookup_recipe(elements: Array[int]) -> SeedRecipe` — validates all elements are unlocked, delegates to `_registry.lookup(elements)`, returns null if any element locked; implement `craft_seed(elements: Array[int]) -> bool` — calls `lookup_recipe`, returns false if null or pouch full; adds recipe to `SeedGrowthService` pouch via `get_node_or_null("/root/SeedGrowthService").get_pouch().add(recipe)`; emits `recipe_discovered` if first time; emits `seed_added_to_pouch`; expose `func get_pouch() -> SeedPouch` via the SeedGrowthService reference; use `preload` for all typed cross-script dependencies
- [] T038 Update `project.godot` — confirm `SeedAlchemyService` registered at `src/autoloads/seed_alchemy_service.gd`
- [] T039 Create `scenes/UI/SeedAlchemyPanel.tscn` + `src/ui/SeedAlchemyPanel.gd` — layout: five `Button` nodes for Chi, Sui, Ka, Fū, Kū (Kū button `disabled=true` initially and styled differently); two active slot labels showing selected elements; one locked slot label showing "🔒 a spirit can teach you this"; a preview label (initially "select elements"); a `ConfirmButton` (disabled until valid recipe found); a `ClearButton` that deselects all slots; wire element buttons to `_on_element_tapped(element_id)` which calls `SeedAlchemyService.is_element_unlocked()` and adds/removes from `_selected: Array[int]` (max 2 for now; reject duplicates with visual shake via `Tween`); on selection change, call `SeedAlchemyService.lookup_recipe(_selected)` and update preview label with recipe name or "unknown combination"; on ConfirmButton: call `SeedAlchemyService.craft_seed(_selected)`, clear slots; disable ConfirmButton when pouch full OR no valid recipe
- [] T040 Create `src/ui/HUDController.gd` + `scenes/UI/HUD.tscn` — three `Button` nodes: Plant (default active), Mix, Codex; a `PanelContainer` or `Control` node that parents `SeedAlchemyPanel` and `CodexPanel` (both hidden initially); wire each mode button to `_set_mode(mode_name: String)` which hides all panels, shows the relevant one (Mix → SeedAlchemyPanel, Codex → CodexPanel, Plant → neither), and marks the active button visually; anchor the three mode buttons at the bottom of the screen in a horizontal container with minimum 44px height; wire Kū button in SeedAlchemyPanel to `SeedAlchemyService.element_unlocked` signal to enable it when KU unlocks
- [] T041 Create `src/ui/SeedPouchDisplay.gd` — a small `Label` or icon visible in Plant mode showing current pouch contents (e.g. "1 seed ready" or a seed icon count); connects to `SeedAlchemyService.seed_added_to_pouch` to update; shown only when HUDController is in Plant mode
- [] T042 Update Plant mode tap handler (in `src/grid/PlacementController.gd` or equivalent) — on valid edge hex tap: check `SeedGrowthService.get_pouch().first()` is not null; if so, call `SeedGrowthService.try_plant(coord, pouch.first())`; if success, call `pouch.remove_at(0)`; update `SeedPouchDisplay`; if pouch is empty and slot tracker is full, show the "full" indicator on the edge hex
- [] T043 Manual validation per quickstart.md US1 steps: open Mix panel, select Chi+Sui, preview shows Clay, confirm adds to pouch; Kū locked; full pouch blocks confirm; Codex Seeds tab updates on first-time recipe

**Checkpoint**: Mix panel fully functional. HUD mode switching works. Seeds can be mixed, pouched, planted, and bloomed in one session.

---

## Phase 7: User Story 6 — Spirit Habitat Ecology (Priority: P2)

**Goal**: ~10 profiled spirits prefer specific biomes; disliked biomes cause immediate
re-targeting; tension visual appears when rival spirits are close; harmony event fires
once when partner spirits overlap long enough.

**Independent Test**: Summon Red Fox. Plant 6 Meadow tiles in one corner. Over 5+ wander
ticks, confirm Fox trends toward Meadow cluster. Run `test_spirit_ecology_service.gd`.

- [] T044 Modify `src/spirits/spirit_definition.gd` — add six new `@export` fields: `preferred_biomes: Array[int] = []`, `disliked_biomes: Array[int] = []`, `harmony_partner_id: StringName = &""`, `tension_partner_id: StringName = &""`, `gift_type: int = 0` (SpiritGiftType.Value.NONE), `gift_payload: StringName = &""`; add `@export_group("Habitat & Gift")` grouping for editor clarity; existing spirits with no habitat data default gracefully to empty arrays
- [] T045 Modify `src/spirits/spirit_wanderer.gd` — add `var _disliked_biomes: Array[int] = []`; in `setup()`, populate from `catalog_entry.get("disliked_biomes", [])` using the same pattern as the existing `preferred_biomes` population (lines 23–28); add `signal moved_to(spirit_id: String, coord: Vector2i)` at the top of the class; in `_process()`, when the wanderer reaches its target (`diff.length() < 0.1`), emit `moved_to(spirit_id, _world_to_coord(position))`; add helper `func _world_to_coord(world_pos: Vector2) -> Vector2i` using the inverse of `_coord_to_world`; after arriving at a tile, check if that tile's biome is in `_disliked_biomes` via `GameState.grid.get_tile(coord)` — if so, call `_pick_new_target()` immediately instead of waiting
- [] T046 Create `src/spirits/SpiritGiftProcessor.gd` — `class_name SpiritGiftProcessor extends RefCounted`; implement `static func process(spirit_id: String, definition: Dictionary) -> void` — reads `gift_type` and `gift_payload` from definition; dispatches: `KU_UNLOCK` → `SeedAlchemyService.unlock_element(GodaiElement.Value.KU)`; `TIER3_RECIPE` → `SeedAlchemyService.get_registry().unlock_recipe(gift_payload)`; `POUCH_EXPAND` → increment `SeedGrowthService._tracker.capacity`; `GROWING_SLOT_EXPAND` → increment `SeedGrowthService._pouch.capacity`; `CODEX_REVEAL` → `CodexService.force_reveal(gift_payload)`; `NONE` → no-op; all node access via `Engine.get_singleton()` or `get_node_or_null("/root/...")` pattern; use explicit type annotations throughout
- [] T047 Implement `src/autoloads/spirit_ecology_service.gd` (replacing the stub) — `class_name SpiritEcologyServiceNode extends Node`; signals: `tension_active(spirit_a_id: String, spirit_b_id: String)`, `tension_cleared(spirit_a_id: String, spirit_b_id: String)`, `harmony_event_fired(spirit_a_id: String, spirit_b_id: String, overlap_hexes: Array[Vector2i])`; field `_harmony_ticks: Dictionary` (pair_key → int), `_harmony_fired: Dictionary` (pair_key → bool), `_tension_active: Dictionary` (pair_key → bool), `_spirit_positions: Dictionary` (spirit_id → Vector2i); implement `func register_wanderer(wanderer: Node) -> void` — connects to `wanderer.moved_to`; implement `func on_spirit_moved(spirit_id: String, coord: Vector2i) -> void` — updates `_spirit_positions`; calls `_check_tension()` and `_check_harmony()`; implement `_check_tension()` — for each defined tension pair, compute axial distance between their positions; emit `tension_active/cleared` when crossing the threshold (default 5 hexes); implement `_check_harmony()` — for each defined harmony pair, if both spirits' wander bounds overlap (use `Rect2i.intersects()`), increment `_harmony_ticks[pair_key]`; when ticks reach 20, emit `harmony_event_fired` once and set `_harmony_fired[pair_key] = true`; implement `func harmony_count() -> int` returning `_harmony_fired.size()`; use `preload("res://src/grid/hex_utils.gd")` for `axial_distance`
- [] T048 Update `project.godot` — confirm `SpiritEcologyService` registered at `src/autoloads/spirit_ecology_service.gd`
- [] T049 Modify `src/spirits/spirit_service.gd` — after `_spawner.spawn(instance, entry)` in `_summon_spirit()`, add: `SpiritGiftProcessor.process(spirit_id, entry)`; find the newly spawned `SpiritWanderer` node via `_spawner`'s returned reference (or via `get_tree().get_nodes_in_group()` if wanderers are grouped) and call `SpiritEcologyService.register_wanderer(wanderer)`
- [] T050 [P] Author habitat data for **Koi Fish** in its spirit catalog entry or `.tres` — `preferred_biomes=[1]` (RIVER), `harmony_partner_id="spirit_blue_kingfisher"`, `gift_type=0` (NONE)
- [] T051 [P] Author habitat data for **Red Fox** — `preferred_biomes=[3,6]` (MEADOW, DUNE), `tension_partner_id="spirit_hare"`, `gift_type=0`
- [] T052 [P] Author habitat data for **White Heron** — `preferred_biomes=[1,8]` (RIVER, BOG), `gift_type=0`
- [] T053 [P] Author habitat data for **Mountain Goat** — `preferred_biomes=[0,6]` (STONE, DUNE), `gift_type=0`
- [] T054 [P] Author habitat data for **Boreal Wolf** — `preferred_biomes=[8]` (BOG), `tension_partner_id="spirit_tundra_lynx"`, `gift_type=0`
- [] T055 [P] Author habitat data for **Mist Stag** — `preferred_biomes=[8,11]` (BOG, VEIL_MARSH), `gift_type=1` (KU_UNLOCK), `gift_payload=""`
- [] T056 [P] Author habitat data for **Blue Kingfisher** — `preferred_biomes=[1]` (RIVER), `harmony_partner_id="spirit_koi_fish"`, `gift_type=0`
- [] T057 [P] Author habitat data for **River Otter** — `preferred_biomes=[1,8]` (RIVER, BOG), `gift_type=2` (TIER3_RECIPE), `gift_payload="recipe_chi_sui_fu"` (Mossy Delta — author this .tres as well)
- [] T058 [P] Author habitat data for **Meadow Lark** — `preferred_biomes=[3]` (MEADOW), `gift_type=4` (GROWING_SLOT_EXPAND), `gift_payload=""`
- [] T059 [P] Author habitat data for **Golden Bee** — `preferred_biomes=[3,6]` (MEADOW, DUNE), `gift_type=0`
- [] T060 Write `tests/unit/test_spirit_ecology_service.gd` — GUT tests: tension fires when two paired spirits are within 5 hexes; tension_cleared fires when they separate beyond 5 hexes; harmony fires after 20 accumulated ticks of overlap; harmony does NOT fire a second time after an additional 20 ticks; `harmony_count()` returns 1 after one fired pair; spirit with no tension/harmony partner produces no ecology events

**Checkpoint**: `test_spirit_ecology_service.gd` passes. Red Fox visually trends toward Meadow tiles in manual test.

---

## Phase 8: User Story 7 — The Codex (Priority: P2)

**Goal**: Codex panel shows all seeds, biomes, spirits, and structures with silhouette+hint
before discovery and full content after. Opens via Codex HUD button.

**Independent Test**: Open Codex → Seeds tab shows 4 Tier 1 recipes as known, all Tier 2
as silhouettes with hint text; Kū entries are fully hidden. Mix Chi+Ka → Codex Seeds
auto-updates to show Desert entry. Spirits tab shows all 30 with riddle text visible.
Reopen app (in-memory only) → discoveries retained for session.

- [] T061 Create `src/codex/CodexEntry.gd` — `class_name CodexEntry extends Resource`; fields: `entry_id: StringName`, `category: int` (CodexCategory enum defined in same file: `SEED=0, BIOME=1, SPIRIT=2, STRUCTURE=3`), `hint_text: String`, `full_name: String`, `full_description: String`, `always_hidden: bool = false` (true for Kū-element seeds)
- [] T062 Implement `src/autoloads/codex_service.gd` (replacing stub) — `class_name CodexServiceNode extends Node`; signal `entry_discovered(entry_id: StringName)`; on `_ready()`, scan `res://src/codex/entries/` for all `.tres` files and load as `CodexEntry` into `_entries: Dictionary` (entry_id → CodexEntry); maintain `_discovered: Dictionary` (entry_id → bool) in memory; implement `mark_discovered(entry_id: StringName) -> void` — sets discovered, emits signal if first time; implement `is_discovered(entry_id: StringName) -> bool`; implement `get_entries_by_category(category: int) -> Array[CodexEntry]`; implement `force_reveal(entry_id: StringName) -> void` (alias for `mark_discovered`)
- [] T063 Update `project.godot` — confirm `CodexService` registered
- [] T064 Wire discovery signals — in `SeedAlchemyService.craft_seed()`, after emitting `recipe_discovered`, call `CodexService.mark_discovered(recipe.recipe_id)`; in `SpiritService._summon_spirit()`, after summon, call `CodexService.mark_discovered(spirit_id)`; in `PatternScanService` or discovery router, on biome-discovery events, call `CodexService.mark_discovered(biome discovery id)`
- [] T065 Create `scenes/UI/CodexPanel.tscn` + `src/ui/CodexPanel.gd` — four `TabContainer` tabs (Seeds, Biomes, Spirits, Structures); each tab contains a `GridContainer` of `CodexEntryCard` mini-scenes; each card shows: if `always_hidden` → blank; if not discovered → shadowed silhouette icon + `hint_text`; if discovered → `full_name` + `full_description`; populate cards by calling `CodexService.get_entries_by_category(tab_index)` in `_ready()` and on `CodexService.entry_discovered` signal
- [] T066 Author `src/codex/entries/` `.tres` files for all 4 Tier 1 biomes — one per biome; `category=1` (BIOME); `hint_text` describes sensory quality; `full_name` = display name; mark as `discovered=false` by default in CodexService (biome entries are discovered on first bloom of that biome type via the discovery router wiring in T064)
- [] T067 [P] Author `src/codex/entries/` `.tres` files for 6 Tier 2 non-Kū biomes (CLAY, DESERT, DUNE, HOT_SPRING, BOG, CINDER_HEATH)
- [] T068 [P] Author `src/codex/entries/` `.tres` files for all 10 Tier 1+2 seed recipes — `category=0` (SEED); `hint_text` matches the `codex_hint` in the recipe resource; `always_hidden=false`; Kū-containing recipe entries have `always_hidden=true`
- [] T069 [P] Author `src/codex/entries/` `.tres` stub files for all 30 spirits — `category=2` (SPIRIT); `hint_text` = existing `riddle_text` from `SpiritDefinition`; `full_name` = spirit display name; `always_hidden=false` (riddle always visible, identity revealed on summon)
- [] T070 Wire `CodexPanel` into `HUDController` — in `HUDController._set_mode("codex")`, show `CodexPanel`; in `_set_mode("plant")` or `_set_mode("mix")`, hide it; confirm CodexPanel instance is a child of the HUD scene
- [] T071 Manual validation per quickstart.md US7 steps

**Checkpoint**: Codex opens via HUD button. Seeds tab updates live on recipe discovery. Spirits tab shows riddle for all 30. Kū entries are invisible.

---

## Phase 9: User Story 8 — Satori Moments (Priority: P3)

**Goal**: When all 4 base biomes are present AND 3 spirits are summoned, a Satori Moment
fires exactly once: camera pull-back, tile light overlay, resonant audio, fade. Growing
slot capacity increases by 1 as the unlock.

**Independent Test** (Instant mode): Use debug panel to call `SatoriService.trigger_debug()`.
Confirm sequence fires. Confirm growing slot capacity increased by 1. Call `trigger_debug()`
again — confirm no second sequence. Run `test_satori_service.gd`.

- [] T072 Create `src/satori/SatoriConditionSet.gd` — `class_name SatoriConditionSet extends Resource`; fields: `condition_id: StringName`, `requirements: Array[Dictionary]`, `unlock_type: int` (SpiritGiftType.Value), `unlock_payload: StringName`; note that `fired` state is tracked in-memory by SatoriService (not stored in the resource itself)
- [] T073 Create `src/satori/SatoriConditionEvaluator.gd` — `class_name SatoriConditionEvaluator extends RefCounted`; implement `static func evaluate(requirements: Array[Dictionary]) -> bool` — iterates each requirement Dictionary; for `type=="biome_present"`: checks `GameState.grid` has at least one tile with the specified biome value (get_tile() scan or a count method); for `type=="spirit_count_gte"`: checks `SpiritService` active instance count ≥ `count`; for `type=="harmony_count_gte"`: checks `SpiritEcologyService.harmony_count() >= count`; for `type=="tile_count_gte"`: checks total tile count ≥ count; returns false if any requirement fails; all node access via `Engine.get_main_loop().root.get_node_or_null("/root/...")`
- [] T074 Author `src/satori/conditions/satori_first_awakening.tres` — `condition_id="satori_first_awakening"`, `requirements=[{type:"biome_present",biome:0},{type:"biome_present",biome:1},{type:"biome_present",biome:2},{type:"biome_present",biome:3},{type:"spirit_count_gte",count:3}]`, `unlock_type=4` (GROWING_SLOT_EXPAND), `unlock_payload=""`
- [] T075 Implement `src/autoloads/satori_service.gd` (replacing stub) — `class_name SatoriServiceNode extends Node`; signal `satori_moment_fired(condition_id: StringName)`; on `_ready()`, scan `res://src/satori/conditions/` and load all `SatoriConditionSet` .tres files; maintain `_fired: Dictionary` (condition_id → bool) in memory; connect to `SeedGrowthService.bloom_confirmed` and `SpiritService.spirit_summoned`; on each signal, call `evaluate()` — loops all unfired condition sets, calls `SatoriConditionEvaluator.evaluate(requirements)`, fires sequence on first match; implement `func trigger_debug() -> void` — forces `_play_sequence("satori_first_awakening")` regardless of conditions (only effective in INSTANT mode check: `GardenSettings.growth_mode == GrowthMode.Value.INSTANT`); implement `func _apply_unlock(condition_set: SatoriConditionSet) -> void` — calls `SpiritGiftProcessor.process_gift(condition_set.unlock_type, condition_set.unlock_payload)`
- [] T076 Update `project.godot` — confirm `SatoriService` registered
- [] T077 Implement Satori sequence in `satori_service.gd` — `func _play_sequence(condition_id: StringName) -> void`: (1) mark condition as fired in `_fired`; (2) emit `satori_moment_fired`; (3) create a `CanvasLayer` overlay child node with a semi-transparent white `ColorRect` that fades in over 0.5s via `Tween`; (4) animate camera zoom-out over 2s via `Tween` on the main camera's `zoom` property; (5) start a 4s hold timer; (6) after hold, fade overlay out over 2s and restore camera zoom; (7) after full fade, call `_apply_unlock()`; (8) add tap-to-skip: connect a one-shot `InputEvent` check via `set_process_input(true)`, skip to step 6 if player taps after a 2s initial lock period; clean up CanvasLayer on completion
- [] T078 Write `tests/unit/test_satori_service.gd` — GUT tests: `biome_present` condition passes when GameState grid has that biome; `biome_present` fails when biome is absent; `spirit_count_gte` passes at threshold; `spirit_count_gte` fails below threshold; full condition set with all 5 requirements passes when all met; condition fires at most once (second call to evaluate() after firing does nothing); `trigger_debug()` can be called without error in a test environment
- [] T079 Manual validation per quickstart.md US8 steps

**Checkpoint**: `test_satori_service.gd` passes. Satori sequence fires once, growing slot capacity increases, second trigger is silently ignored.

---

## Final Phase: Polish & Cross-Cutting Validation

- [] T080 Run full GUT suite via `tests/gut_runner.tscn` — confirm all new tests pass and no pre-existing tests regressed vs T001 baseline
- [] T081 Verify HUD button layout — Plant, Mix, Codex, and GrowthModeToggle buttons are thumb-zone reachable (bottom or top anchored, ≥44px tap targets); verify no overlap between buttons and growing-seed tap targets on common screen sizes (375×812 portrait)
- [] T082 Verify GDScript compliance — open `Output` panel with the game running; confirm no `W0` warnings in any new `src/seeds/`, `src/codex/`, `src/satori/` file; confirm no `:=` used on Variant-returning calls in any new file (check `Dictionary.get()`, `Array.pop_front()`, `get_node_or_null()` call sites explicitly)
- [] T083 Verify autoload name collision — confirm no script `class_name` in the new autoload files matches its autoload key in `project.godot` (e.g. `seed_growth_service.gd` must have `class_name SeedGrowthServiceNode`, not `class_name SeedGrowthService`)
- [] T084 Manual full-session walkthrough (instant mode) per quickstart.md — complete all US1–US9 validation steps in sequence in a single game session without restarting; confirm the full loop (mix → plant → bloom → pattern → spirit → gift → Kū unlock → Kū seed → satori) completes without errors

---

## Dependency Graph

```
Phase 1 (Setup)
  └─► Phase 2 (BiomeType migration) ◄─ GATE: GUT must pass
        └─► Phase 3 (US5 — Recipes)
              └─► Phase 4 (US2+3+4 — Seed Growth)
                    └─► Phase 5 (US9 — Mode Toggle)
                          └─► Phase 6 (US1 — Mixing UI + HUD)
                                ├─► Phase 7 (US6 — Spirit Habitat) [can start after Phase 2]
                                ├─► Phase 8 (US7 — Codex) [needs Phase 6 for wiring]
                                └─► Phase 9 (US8 — Satori) [needs Phase 6+7]
                                      └─► Final Phase (Polish)
```

Spirit Habitat (Phase 7) can begin its data-authoring tasks (T050–T059) in parallel with
Phase 6 implementation. The ecology service (T047) can begin after Phase 2.

## Parallel Execution Examples

**Within Phase 3**: T012–T021 (all recipe .tres files) can be authored simultaneously.

**Within Phase 7**: T050–T059 (all habitat data authoring) can run in parallel after T044.

**Tests**: T004, T022, T030, T060, T078 can be written in parallel with their corresponding implementation tasks.

## Implementation Strategy (MVP Scope)

**MVP = Phases 1–5** (US5 + US2/3/4 + US9 mode toggle):
- BiomeType migration complete
- 10 seed recipes functional
- Seeds plant, grow, and bloom
- Pattern scanner fires at bloom
- Mode toggle button switches between INSTANT and REAL_TIME

This delivers the core ritual (plant → wait → bloom) and validates the architectural foundation before any UI or spirit work begins. Each subsequent phase adds a complete, independently testable layer.

## Task Summary

| Phase | User Story | Task Count |
|---|---|---|
| Setup | — | 2 |
| Foundational | BiomeType | 4 |
| Phase 3 | US5 — Elements & Recipes | 16 |
| Phase 4 | US2/3/4 — Seed Growth | 8 |
| Phase 5 | US9 — Mode Toggle | 5 |
| Phase 6 | US1 — Mixing UI + HUD | 8 |
| Phase 7 | US6 — Spirit Habitat | 17 |
| Phase 8 | US7 — Codex | 11 |
| Phase 9 | US8 — Satori | 8 |
| Polish | — | 5 |
| **Total** | | **84** |
