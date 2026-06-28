# Satori Alpha Roadmap

This roadmap defines the path from the current game state toward a fun, playable alpha that can be tested through itch.io and Android. It is written as a player journey first and an implementation tracker second.

The alpha target is not "all spirits and all structures." The alpha target is one clear, satisfying route through the full Satori promise:

1. Start a new garden.
2. Shape Wind into Meadow Seed.
3. Plant Meadow and harvest Living Wood.
4. Meet Red Fox and understand that spirits need care.
5. Shape Living Wood and Fire Essence into Warm Hollow.
6. Place Warm Hollow as a Meadow dwelling and house Red Fox.
7. Upgrade the fox housing into Fox Den and understand why the home matters.
8. Build one or two useful island structures that visibly improve the island.
9. Follow clear Codex hints toward Mist Stag.
10. Unlock Ku through Mist Stag.
11. Use Ku Seed to place Void, separating islands cleanly.
12. Prepare a calm water island, place the Chi+Ku biome there, and invite Suijin.
13. Save, close, reopen, and continue safely.
14. Run acceptably as a Web build on itch.io and as an Android build.

More spirits, more structures, more island rules, advanced components, additional kamis, memories, and restoration paths are alpha-plus content unless they are needed to make this spine understandable and satisfying.

## Obvious Alpha Path

This is the route the alpha should gently lead testers through. It should not feel like a quest log, but the player should rarely wonder what kind of action would help.

| Beat | Player Sees | Player Does | World Responds | UX Requirement |
|------|-------------|-------------|----------------|----------------|
| 1. First breath | Empty garden, clear ritual affordance | Shape Wind/Fu into Meadow Seed | Meadow Seed appears in the pouch | The first ritual is discoverable without reading docs. |
| 2. First place | Plantable ground and selected seed | Plant Meadow | Meadow grows and becomes recognizable | Placement feedback makes irreversible action clear before commit. |
| 3. First harvest | Living Wood appears in Meadow | Tap/collect Living Wood | Material inventory updates | Harvest feedback is visible and satisfying, not silent. |
| 4. First visitor | Red Fox appears or is strongly hinted | Notice its state and island need | The island feels alive | Spirit name/state tells the player whether care is needed. |
| 5. First home | Warm Hollow hint appears | Shape Living Wood + Fire Essence | Warm Hollow form enters inventory | The Codex can stay poetic, but the UI must show enough practical next step. |
| 6. First care | Valid Meadow dwelling placement is readable | Place Warm Hollow on Meadow | Red Fox is automatically housed, Satori improves | Automatic housing and Satori feedback happen close to the action. |
| 7. First den | Fox Den upgrade is hinted from the housed Red Fox loop | Place the upgraded Fox Den | Red Fox migrates to Fox Den and grants double Red Fox Satori generation | The upgrade reads as care with a clear spirit-specific reward, not another generic structure. |
| 8. First choice | Two useful helper paths open | Build Dew Bowl and Wind Chime | Storage, soothing, invitation, and harvest behavior visibly improve | Each structure has an obvious use within one session. |
| 9. First mystery | Mist Stag path is hinted | Build toward its condition | Mist Stag appears only at the right era/state | The player knows this is a milestone, not random spawn luck. |
| 10. First void | Mist Stag grants Ku | Shape Ku Seed and place Void | Void separates islands | Ku unlock has ceremony and practical UI clarity. |
| 11. First kami | A calm water island can become sacred | Place Chi+Ku biome on an island with 10 water tiles, no fire-based tiles, and Satori 1000 | Suijin arrives and persists | The finale feels like an invitation, not a checklist trigger. |

If any beat needs debug knowledge, hidden recipe knowledge, or a lucky accident, that beat is not alpha-ready.

## UX Quality Bar

The alpha can be small, but it should feel intentional. A tester should be able to describe what happened in plain language:

- "I made a meadow."
- "The meadow gave me wood."
- "A fox came because the island became livable."
- "The fox needed a home."
- "I made a warm hollow, housed the fox, and improved it into a fox den."
- "The island felt calmer when the fox had a home."
- "Mist Stag opened the strange Ku path."
- "Ku changed the island into something sacred."
- "The Endgame Island invited a kami."

To support that, every alpha-critical action needs:

- a visible affordance before the action,
- a readable confirmation after the action,
- a Codex or UI hint when the next step is not obvious,
- no silent failure,
- no accidental irreversible commitment,
- mobile-readable text and touch targets,
- save/load continuity after the action matters,
- no placeholder art, audio, icon, or UI assets on the primary alpha path or release shell.

Avoid abstract placeholder UI such as "Quest 1 complete" or "Unknown helper unlocked." Use world language backed by practical clarity: Meadow Seed, Living Wood, Red Fox, Warm Hollow, Dew Bowl, Wind Chime, Mist Stag, Ku, Endgame Island, Suijin.

## Current Baseline

The repo already contains the main pieces needed for an alpha spine:

- Godot 4.6 project with `scenes/TitleScreen.tscn` as the entry scene.
- Autoloads for game state, saving, discovery persistence, pattern scanning, spirit persistence, ritual crafting, seed growth, spirit ecology, Satori, Codex, and soundscape.
- CSV-backed ritual and material data in `data/discovery_editor/runtime/`.
- Early material families: Living Wood, Reed Fiber, Spirit Stone, and Ember Clay.
- Seed rituals for base, hybrid, and Ku-related biomes.
- Structure rituals for early forms such as Warm Hollow, Fox Den, Dew Bowl, Root Network, Wind Chime, Reed Nest, Stone Basin, Hearth Stone, and related family structures.
- Pattern, discovery, spirit, Satori, build-mode, persistence, and UI regression tests.
- Existing Web export preset targeting `build/web/index.html`.
- Playwright web smoke test coverage under `tests/playwright/`.

Known roadmap implications:

- The current `export_presets.cfg` has a Web preset only. Android export is a required phase, not already done.
- The bug checklist shows many gameplay regressions already fixed, but some visual/UI clarity items still need manual or scene-level validation.
- The worktree may contain active gameplay and UI changes. Roadmap work should remain scoped and avoid rewriting unrelated systems while those changes are in progress.

## Alpha Design Rule

For every phase, prefer a complete thin loop over broader content.

Required for alpha:

- One coherent first-session path.
- One reliable material harvest loop.
- One satisfying early spirit and housing loop.
- One clear Satori pressure and recovery loop.
- One Ku unlock path.
- One Endgame island proof.
- One Suijin invitation proof.
- One tested save/load path across restart.
- One itch.io Web build.
- One Android build that can be installed and played.

Deferrable until after alpha:

- Full 30-spirit content breadth.
- Full structure catalogue polish.
- Spirit assistants as a broad system.
- Advanced components.
- Full kami roster and restoration endgame.
- Perfect audio breadth.
- Perfect art for every form.
- Deep automation.

## Alpha Spec Tracker

Speckit package status tracks whether the specification artifacts exist. Alpha status tracks whether the playable alpha gate is currently proven by fresh evidence.

| Priority | Roadmap Phase | Owning Spec | Speckit Package | Alpha Status | Alpha Completion Gate |
|----------|---------------|-------------|-----------------|--------------|-----------------------|
| 1 | Phase 0 - Alpha Contract and State Audit | [026-alpha-contract-audit](../specs/026-alpha-contract-audit/spec.md) | Drafted | Verified | Alpha checklist, current-state audit, and evidence-backed gate ownership are complete. |
| 2 | Phase 1 - Playable First Session | [027-playable-first-session](../specs/027-playable-first-session/spec.md) | Drafted | Verified | Fresh save reaches Meadow, Living Wood, Red Fox, Warm Hollow, automatically housed Red Fox in a Meadow dwelling, and save/load. Evidence: `specs/027-playable-first-session/evidence.md`. |
| 3 | Phase 2 - First Island Fun Loop | [028-first-island-fun-loop](../specs/028-first-island-fun-loop/spec.md) | Drafted | Verified | First island supports Red Fox care, upgraded Fox Den, HUD/hover/Codex Satori feedback, Dew Bowl and Wind Chime, invalid-action clarity, and save/load. Evidence: `specs/028-first-island-fun-loop/evidence.md`. |
| 4 | Phase 3 - Full Alpha Endgame Spine | [029-alpha-endgame-kami-spine](../specs/029-alpha-endgame-kami-spine/spec.md) | Drafted | Verified | Fresh save unlocks Ku, uses Void to separate islands, places Chi+Ku biome on a calm Satori 1000 water island, invites Suijin, and persists the result. Evidence: `specs/029-alpha-endgame-kami-spine/evidence.md`. |
| 5 | Phase 4 - Save Safety and Testable Builds | [030-alpha-save-safety](../specs/030-alpha-save-safety/spec.md) | Drafted | Verified | First-session, first-island, and endgame/kami states round-trip with schema/version safety. Evidence: `specs/030-alpha-save-safety/evidence.md`. |
| 6 | Phase 5 - itch.io Web Alpha | [031-itch-web-alpha](../specs/031-itch-web-alpha/spec.md) | Drafted | Blocked | Local Web build exports, runs, saves across reload, and packages correctly, but a restricted itch.io page URL, uploaded HTML build, and smoke on the actual itch.io page are still required. Evidence: `specs/031-itch-web-alpha/evidence.md`. |
| 7 | Phase 6 - Android Alpha | [032-android-alpha](../specs/032-android-alpha/spec.md) | Drafted | Not Started | Android build installs, touch flow is playable, and background/resume preserves save state. |
| 8 | Phases 7-8 - Alpha Content and External Readiness | [033-alpha-content-readiness](../specs/033-alpha-content-readiness/spec.md) | Drafted | Not Started | Included content is wired and tester brief, known issues, versioning, Web playthrough, and Android playthrough are ready. |

Status rules:

- `Not Started`: no current evidence proves the alpha gate.
- `In Progress`: implementation or validation work is underway.
- `Blocked`: progress is waiting on a specific unresolved dependency.
- `Verified`: the spec exit gates pass with current command/manual evidence.

## Phase 0 - Alpha Contract and State Audit

Spec: [026-alpha-contract-audit](../specs/026-alpha-contract-audit/spec.md)  
Alpha status: Verified

Goal: freeze what "playable alpha" means and confirm the current branch state before changing systems.

Deliverables:

- Write a short alpha checklist in `specs/master/quickstart.md` or a linked checklist doc.
- Run a state audit of the active gameplay spine:
  - new game and title flow,
  - ritual menu,
  - seed pouch,
  - planting and growth,
  - material spawn and harvest,
  - spirit spawn,
  - house/structure project placement,
  - Satori feedback,
  - Mist Stag and Ku unlock,
  - Endgame island creation,
  - Suijin invitation,
  - save/load.
- Reconcile the current dirty worktree before larger roadmap implementation work. Keep unrelated art/data/UI changes intact.

Exit gates:

- The alpha-critical path is listed as a manual playtest script.
- Current automated baseline is known: parse, boot smoke, focused GUT suites, and web smoke where possible.
- Any broken alpha-critical step is assigned to Phase 1 or Phase 2.

## Phase 1 - Playable First Session

Spec: [027-playable-first-session](../specs/027-playable-first-session/spec.md)  
Alpha status: Verified

Goal: make the first 10 minutes readable and fun without needing developer knowledge.

Player outcome:

- I can start the game, shape Wind into Meadow Seed, plant Meadow, harvest Living Wood, meet Red Fox, make Warm Hollow, place it as housing, and see the fox housed automatically.

Implementation focus:

- Make the title-to-garden flow short and calm.
- Make Wind/Fu -> Meadow Seed the obvious first ritual without turning the Codex into a recipe wiki.
- Make the seed pouch, selected seed, plantable ground, and growth state visually obvious.
- Add a first-session "First Bloom" pacing rule: the first Meadow should produce its first Living Wood quickly through normal play, with visible growth feedback and no debug-only grants.
- Make Living Wood harvest feedback immediate: the player should see what was gained and where it went.
- Make Red Fox arrival and need state readable without opening a debug overlay.
- Make Warm Hollow creation, valid Meadow dwelling placement, and automatic Red Fox housing feel like a natural answer to Red Fox needing care.
- Keep irreversible placement clear before confirmation.

Minimum content:

- Wind/Fu seed into Meadow.
- Meadow produces Living Wood.
- Red Fox appears as the first spirit.
- Living Wood plus Fire Essence creates Warm Hollow.
- Warm Hollow becomes a Meadow dwelling when placed on Meadow.
- Red Fox automatically uses the valid dwelling when it is placed.

Exit gates:

- A new player can complete Wind -> Meadow -> Living Wood -> Red Fox -> Warm Hollow -> Meadow dwelling -> housed Red Fox without external instructions.
- No alpha-critical UI label clips or overlaps on a mobile-like viewport.
- The first-session path survives save/load.
- Focused tests pass for ritual menu, seed pouch, seed growth, material harvesting, structure placement, and early spirit service.

## Phase 2 - First Island Fun Loop

Spec: [028-first-island-fun-loop](../specs/028-first-island-fun-loop/spec.md)  
Alpha status: Verified

Goal: turn the first island from a demo into a repeatable play loop.

Player outcome:

- I can care for Red Fox, place the upgraded Fox Den, see Red Fox migrate there, get double Red Fox Satori generation, build useful island helpers, and understand why the island is healthier afterward.

Implementation focus:

- Make Red Fox housed/restless/happy state visible enough to act on.
- Make the upgraded Fox Den explicit as the first housing improvement after basic Red Fox housing: when placed, Red Fox migrates there and grants double Red Fox Satori generation.
- Make Satori changes understandable as harmony pressure and recovery, not just a number.
- Make structure projects clear:
  - what form I have,
  - where it can be placed,
  - whether the current project is valid,
  - why invalid placement failed.
- Ensure no duplicate ritual slots are accepted.
- Keep "spirits are not consumed" clear anywhere spirit-specific rituals appear.
- Verify structures draw above overlays and remain inspectable.

Minimum content:

- Red Fox dwelling loop.
- Upgraded Fox Den loop.
- Dew Bowl for storage/soothing clarity.
- Wind Chime for invitation/harvest clarity.
- One water material family path after the Meadow path that supports Suijin's calm-water island condition, such as Reed Fiber -> Reed Nest if it fits the final content data.
- At least one meaningful Satori-positive action and one visible Satori-pressure state.

Exit gates:

- Player can keep the first island stable through Red Fox care, Fox Den migration/double Red Fox Satori generation, and one helper-structure interaction.
- Invalid rituals and invalid structure projects explain what to change.
- Build/project flows do not allow accidental deletion or hidden irreversible mistakes.
- Save/load preserves active spirits, houses, structures, Satori state, materials, seeds, and discovered Codex entries.

## Phase 3 - Full Alpha Endgame Spine

Spec: [029-alpha-endgame-kami-spine](../specs/029-alpha-endgame-kami-spine/spec.md)  
Alpha status: Verified

Goal: prove the game has a beginning, middle, and endgame invitation step.

Player outcome:

- I can follow the island's hints from Red Fox care into Mist Stag, unlock Ku, open the Endgame Island, and invite Suijin without debug tools.

Implementation focus:

- Preserve or refine the Mist Stag unlock path.
- Make Ku unlock feel like a milestone, not a random new button.
- Ensure Ku recipes are locked before unlock and readable after unlock.
- Make Ku Seed create Void, and make placed Void separate islands clearly.
- Make the Suijin invitation explicit, ceremonial, and safe: place the Chi+Ku biome on an island with at least 10 water tiles, no fire-based tiles, and local Satori 1000.
- Ensure the Suijin invitation is island-local and does not break first-island state.
- Add Codex hints for the current next goal when the player is stuck.

Minimum content:

- Mist Stag as the Ku-gating spirit.
- Ku unlock at the intended progression point.
- Ku Seed that places Void and separates islands.
- Chi+Ku biome placement on a calm water island with Satori 1000.
- Suijin with a clear invitation condition, visible arrival, and persistent state.
- At least one spirit, material, or Satori behavior that proves the Endgame island has local rules.

Exit gates:

- End-to-end playtest invites Suijin from a fresh save by placing the Chi+Ku biome on an island with 10 water tiles, no fire-based tiles, and Satori 1000.
- Mist Stag cannot spawn too early.
- Ku unlock persists after restart.
- Void-separated island state and invited kami persist after restart.
- Suijin logic stays scoped to the qualifying island.
- Pattern scans remain duplicate-safe and performant enough for the alpha garden size.

## Phase 4 - Save Safety and Testable Builds

Spec: [030-alpha-save-safety](../specs/030-alpha-save-safety/spec.md)  
Alpha status: Verified

Goal: make alpha testing safe enough that testers do not lose gardens or hit obvious platform blockers.

Player outcome:

- I can play, leave, come back, and trust my garden is still there.

Implementation focus:

- Atomic save and load path for:
  - tiles,
  - seeds,
  - materials,
  - discoveries,
  - spirits,
  - houses,
  - structures,
  - Satori,
  - unlocks,
  - active project state.
- Autosave on meaningful progress and app lifecycle events.
- Cold start loads into a playable state quickly enough for mobile testing.
- Add a visible save/load failure path rather than silent corruption.
- Maintain schema versioning before external testers create real saves.
- Use zero-based SemVer with alpha prerelease and build metadata for external alpha saves/builds, such as `0.1.0-alpha+20260627.1`, and show that version in the menu.

Exit gates:

- Fresh save, mid-session save, and restart round trips pass.
- Background/close save behavior is manually checked on Android.
- Web build persistence is manually checked in a browser profile used like itch.io.
- Save migration guard exists before alpha testers receive builds.

## Phase 5 - itch.io Web Alpha

Spec: [031-itch-web-alpha](../specs/031-itch-web-alpha/spec.md)  
Alpha status: Blocked

Goal: ship a browser-playable alpha build for easy tester access.

Player outcome:

- I can open the itch.io page, start the game, play the alpha spine, and come back later on the same browser.

Implementation focus:

- Keep or update the existing `Web` export preset.
- Verify all runtime CSV data and material/structure/spirit assets are included.
- Exclude tests, editor caches, tools, specs, and debug-only flows from release export.
- Decide whether to enable Progressive Web App behavior for itch.io. It is currently disabled.
- Add web-specific loading and focus behavior if needed.
- Run Playwright smoke against the exported build.

Exit gates:

- `build/web/index.html` loads locally.
- Title screen appears.
- New game starts.
- First ritual and first placement work.
- Save persists across page reload in the same browser.
- Itch.io upload package is reproducible from documented commands.
- A restricted itch.io page exists, the current Web package is uploaded as an HTML/browser-playable build, and the actual itch.io URL passes title, new-game, first ritual, first placement, and same-browser reload smoke.

## Phase 6 - Android Alpha

Spec: [032-android-alpha](../specs/032-android-alpha/spec.md)  
Alpha status: Not Started

Goal: create an installable Android build that proves the mobile-first design.

Player outcome:

- I can install the Android build, play with touch, background the app, reopen it, and continue.

Implementation focus:

- Add an Android export preset.
- Configure package id `com.lunaverse.satori`, version code, version name, title-emblem icon, no orientation lock, and signing approach.
- Confirm export templates are installed and documented.
- Validate touch:
  - pan,
  - zoom,
  - tap,
  - long press or placement confirmation,
  - ritual menu slots,
  - build/project confirmation,
  - Codex and settings.
- Validate safe-area and phone aspect ratios.
- Check performance with debug overlay disabled in release.
- Check Android app lifecycle save on background and resume.

Exit gates:

- Debug APK installs and launches on a physical device or emulator.
- Release-like Android build can be produced with documented steps.
- First-session and full alpha endgame spine are touch-playable.
- No critical UI element is unreachable or clipped on common phone ratios.
- Background and resume preserve the garden.

## Phase 7 - Alpha Content Pass

Spec: [033-alpha-content-readiness](../specs/033-alpha-content-readiness/spec.md)  
Alpha status: Not Started

Goal: add enough variety to make testers want to keep playing after the spine works.

Player outcome:

- The game feels like a small but real world rather than a mechanical test.

Implementation focus:

- Add only content that supports current systems cleanly.
- Prefer one polished chain per material family over many shallow recipes.
- Give each included spirit a visible reason to exist:
  - habitat,
  - need,
  - gift,
  - housing preference,
  - Codex hint,
  - Satori interaction.
- Give each included structure a visible use:
  - house,
  - storage,
  - production,
  - calming,
  - invitation,
  - Endgame island or kami progression.

Exit gates:

- Testers can play beyond the first island without exhausting meaningful actions immediately.
- Included spirits and structures are wired into Codex, save/load, and tests.
- Content gaps are visible as "not yet available" or absent, not broken buttons.

## Phase 8 - External Alpha Readiness

Spec: [033-alpha-content-readiness](../specs/033-alpha-content-readiness/spec.md)  
Alpha status: Not Started

Goal: prepare a small closed alpha on itch.io and Android.

Deliverables:

- Tester instructions:
  - what to try,
  - what is expected to work,
  - what is not in scope yet,
  - how to report bugs,
  - where save files live if relevant.
- Known issues list.
- Build version visible in the menu.
- Crash/blocker triage checklist.
- Feedback questions focused on fun:
  - Did you know what to do next?
  - Did any irreversible action feel unfair?
  - Did spirits feel worth caring about?
  - Did Satori feel understandable?
  - Did the path from Ku to Endgame Island feel special?
  - Did you understand why the Endgame Island invited Suijin?

Exit gates:

- itch.io restricted page or draft page is ready.
- Android install path is documented.
- At least one full fresh-save playthrough invites Suijin on an Endgame island on Web.
- At least one full fresh-save playthrough invites Suijin on an Endgame island on Android.
- Known blockers are fixed or explicitly called out before inviting testers.

## Suggested Phase Order

1. Phase 0 - Alpha Contract and State Audit
2. Phase 1 - Playable First Session
3. Phase 2 - First Island Fun Loop
4. Phase 3 - Full Alpha Endgame Spine
5. Phase 4 - Save Safety and Testable Builds
6. Phase 5 - itch.io Web Alpha
7. Phase 6 - Android Alpha
8. Phase 7 - Alpha Content Pass
9. Phase 8 - External Alpha Readiness

Phase 7 can overlap with Phases 5 and 6 only after the alpha spine is stable. Content breadth should not hide broken progression, saving, or mobile controls.

## Alpha Cut Line

Ship the first closed alpha when these are true:

- A fresh player can unlock Ku, place Void to separate islands, and invite Suijin with the Chi+Ku calm-water-island condition without debug tools.
- The game can be closed and reopened without losing alpha-critical state.
- Web build works well enough for itch.io testers.
- Android build works well enough for touch-first testing.
- The first island has enough spirit and structure variety to be fun for at least one session.
- Missing broader content does not look like broken functionality.
- The primary alpha path and release shell contain no placeholder assets.

Do not delay alpha for:

- all spirits,
- all structures,
- all kamis beyond the first,
- all restoration paths,
- final audio,
- final art,
- full automation,
- full Codex completion.

Do delay alpha for:

- save/load loss,
- progression dead ends,
- unclear first-session actions,
- accidental irreversible actions,
- broken touch controls,
- Web or Android build failure,
- UI that blocks play on phone screens,
- placeholder assets on the primary alpha path or release shell.
