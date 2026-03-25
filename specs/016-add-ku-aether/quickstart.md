# Quickstart: Mixable Ku Recipes

**Branch**: `016-add-ku-aether` | **Date**: 2026-03-25

## Goal

Verify Ku unlock progression, four Ku recipes, four deity spirits, four structures, and codex hint behavior.

## Prerequisites

1. Run from project root with Godot 4.6 available.
2. Use a clean play session or known baseline state.

## Unlock condition validation

1. Confirm Ku is initially disabled in Mix mode.
2. Trigger Deep Stand discovery conditions:
   - Meadow cluster (`biome = 3`) reaches size threshold 10.
   - Ember Field (`biome = 2`) is absent for that pattern.
3. Trigger Mist Stag summon conditions:
   - Bog cluster (`biome = 8`) reaches size threshold 5.
   - Deep Stand discovery is already unlocked.
4. Verify Mist Stag summon occurs and Ku becomes enabled in Mix mode.

Expected:
- Ku unlock follows Mist Stag gift path.
- No alternate unlock path is required.

## Ku recipe validation

1. In Mix mode, craft each pair:
   - Chi + Ku
   - Sui + Ku
   - Ka + Ku
   - Fu + Ku
2. Confirm each pair previews and crafts a distinct seed.
3. Try solo Ku and confirm it remains invalid.

Expected:
- Exactly four valid Ku pair recipes.
- Solo Ku remains non-craftable.

## Ku biome, deity, and structure mapping validation

1. Bloom each Ku seed at least once.
2. Verify each resulting biome maps to one unique deity spirit and one unique structure discovery path.
3. Verify no duplicate or missing mappings.

Expected:
- 4 Ku biomes, 4 deity spirits, 4 structures, one-to-one per biome.

## Codex hint validation

1. Before Ku unlock, open codex and inspect Ku guidance entry.
2. Confirm hint names Mist Stag and points directionally to progression.
3. Confirm hint does not expose exact numeric thresholds.
4. After Ku unlock, verify discovered-state text is shown.

Expected:
- Guided but non-checklist hinting pre-unlock.
- Clear discovered-state update post-unlock.

## Automated tests

```bash
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/seeds/test_seed_recipe_registry.gd
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_spirit_service.gd
godot --path . --headless -s tests/gut_runner.tscn -gtest=tests/unit/test_codex_service.gd
```

If a listed test file does not yet exist, create it during implementation tasks and run the relevant suite after creation.
