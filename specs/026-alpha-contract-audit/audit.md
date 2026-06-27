# Alpha Contract Audit Evidence

Run date: 2026-06-27
Worktree: `C:\Users\roelv\.codex\worktrees\d48f\Satori`
Mainline: `origin/master`

## Baseline

| Check | Result | Evidence |
|-------|--------|----------|
| Worktree state | Proven clean detached worktree | `git status --short --branch` returned `## HEAD (no branch)` with no file changes. `git worktree list --porcelain` showed this worktree at the same commit as local `master` (`b516698dab1a518b2577a4bee356e3babdb1118f`). |
| Godot import/cache | Proven after one-time ignored cache generation | Fresh worktree had no `.godot` cache. Initial parse failed on unresolved global classes and unimported PNGs. `Godot_v4.6.1-stable_win64_console.exe --headless --editor --quit --path .` regenerated global classes/imports. It reported three corrupt non-runtime viewer screenshot PNG imports under `data/discovery_editor/viewer/screenshots/`. |
| Parse validation | Proven | `.\tools\godot.ps1 -Command parse` passed after import/cache generation. Only known ObjectDB shutdown warning remained. |
| Boot smoke | Proven | `.\tools\godot.ps1 -Command boot` passed: `res://scenes/Garden.tscn loaded and core autoloads are present.` |
| Focused GUT baseline | Proven | 10 focused suites passed: ritual menu slots, seed recipe registry, seed growth service, biome material harvesting, building placement session, Satori service, save game service, island labelling, Kusho pool, and spirit service. Total: 116 tests passed. |

## Focused GUT Suites

| Suite | Result | Alpha evidence |
|-------|--------|----------------|
| `res://tests/unit/seeds/test_ritual_menu_slots.gd` | 12/12 passed | Duplicate ritual rejection, Wind/Fu -> Meadow Seed, Living Wood + Fire -> Warm Hollow, Red Fox + Living Wood -> Fox Den, Reed/Water paths. |
| `res://tests/unit/seeds/test_seed_recipe_registry.gd` | 8/8 passed | Ku recipes are locked before unlock and valid after unlock; duplicate/undefined Ku combos fail. |
| `res://tests/unit/seeds/test_seed_growth_service.gd` | 6/6 passed | Planting/growth behavior and Mist Stag gift -> Ku unlock flow. |
| `res://tests/unit/test_biome_material_harvesting.gd` | 16/16 passed | Meadow Living Wood timing/harvest, first-session Warm Hollow path, Dew Bowl capacity, Wind Chime auto-harvest. |
| `res://tests/unit/test_building_placement_session.gd` | 14/14 passed | Warm Hollow placement, invalid placement non-consumption, placement cancel preservation. |
| `res://tests/unit/test_satori_service.gd` | 18/18 passed | Housed/unhoused pressure, upgraded house Satori rate, island-local structure effects. |
| `res://tests/unit/test_save_game_service.gd` | 2/2 passed | Basic game-state save/load round trip. |
| `res://tests/unit/test_island_labelling.gd` | 7/7 passed | Ku tiles split island membership and stay outside island ids. |
| `res://tests/unit/test_kusho_pool.gd` | 3/3 passed | Ku charge consumption, clamping, depletion. |
| `res://tests/unit/spirits/test_spirit_service.gd` | 30/30 passed | Red Fox summon, Mist Stag era gating, Ku unlock once, housing binding, Fox Den rebinding, island-local spirit scope. |

## Alpha Spine Audit

| Step | Result | Evidence | Owner |
|------|--------|----------|-------|
| Start a new garden | Unverified | Boot smoke proves `Garden.tscn` loads and core autoloads exist. Title-to-new-game UX was not manually playtested in this run. | `027-playable-first-session` |
| Perform first ritual | Proven mechanically, UX unverified | Ritual slot tests prove Wind/Fu shapes Meadow Seed and duplicates are rejected. Discoverability from normal UI remains a manual/mobile UX gate. | `027-playable-first-session` |
| Plant and grow Meadow | Proven mechanically, UX unverified | Seed growth tests prove planting and growth behavior. Normal-play feedback and mobile readability remain Phase 1 gates. | `027-playable-first-session` |
| Harvest Living Wood | Proven mechanically, UX unverified | Material harvesting tests prove Meadow produces Living Wood and harvesting updates inventory. Feedback visibility remains Phase 1. | `027-playable-first-session` |
| Invite Red Fox | Proven mechanically, UX unverified | Spirit service tests prove Red Fox discovery creates an active instance. Red Fox need/state visibility remains Phase 1. | `027-playable-first-session` |
| Shape and place first dwelling | Proven mechanically, UX unverified | Ritual and placement tests prove Warm Hollow creation, Meadow dwelling resolution, and invalid placement non-consumption. Automatic visible Red Fox housing remains Phase 1/2 validation. | `027-playable-first-session` |
| See Satori pressure and recovery | Proven mechanically, UX unverified | Satori service tests prove housed/unhoused pressure and upgraded-house rate behavior. HUD/hover/Codex clarity remains Phase 2. | `028-first-island-fun-loop` |
| Unlock Mist Stag and Ku | Partially proven | Spirit and seed tests prove Mist Stag cannot spawn too early and Ku unlock is idempotent. Fresh-save milestone path and persistence remain Phase 3. | `029-alpha-endgame-kami-spine` |
| Place Void to separate islands | Partially proven | Island labelling tests prove Ku tiles split island membership. Normal Ku Seed -> Void placement and persistence remain Phase 3. | `029-alpha-endgame-kami-spine` |
| Place Chi+Ku biome on qualifying calm water island | Unverified | Chi+Ku recipe data exists, but qualifying island condition tests and full normal-play flow are not implemented. | `029-alpha-endgame-kami-spine` |
| Invite Suijin | Incomplete | Current Phase 3 tasks still require Suijin invitation implementation, island-local duplicate safety, visible arrival, and persistence. | `029-alpha-endgame-kami-spine` |
| Save, restart, and continue | Partially proven | Save service tests prove basic game-state round trip. First-session, island loop, endgame/kami, Web reload, and Android lifecycle persistence remain owned by later specs. | `030-alpha-save-safety` |

## Follow-up Ownership

- `027-playable-first-session`: normal fresh-save title-to-garden flow, first ritual discoverability, Meadow/harvest feedback, Red Fox readable need state, Warm Hollow placement clarity, automatic housed Red Fox visibility, first-session save/load.
- `028-first-island-fun-loop`: Red Fox care loop, Fox Den migration clarity and reward, Satori HUD/hover/Codex feedback, Dew Bowl/Wind Chime visible usefulness, invalid action clarity.
- `029-alpha-endgame-kami-spine`: fresh-save Mist Stag -> Ku milestone, Ku persistence, Ku Seed -> Void normal placement, Void persistence, Chi+Ku calm-water island condition, visible island-local Suijin invitation and persistence.
- `030-alpha-save-safety`: schema/version guard, alpha-critical round trips, Web reload persistence, Android background/resume persistence.
- `031-itch-web-alpha`: local Web export/load/reload smoke and reproducible itch package.
- `032-android-alpha`: Android export preset, install/launch, touch/safe-area, background/resume.
- `033-alpha-content-readiness`: wired alpha content, tester brief, known issues, versioning, external playthrough readiness.

## Exit Gate Decision

Phase 0 is Verified for its audit contract: the alpha-critical path is documented, current automated baseline is known, and incomplete or unverified gates are assigned to owning follow-up specs. Later roadmap phases remain below Verified because full normal-play and platform evidence is not yet present.
