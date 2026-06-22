# Quickstart: Spirit Happiness, Ritual Assistants and Components

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## Automated Validation

Run focused GUT suites after implementation:

```powershell
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs
```

Minimum tests to add:

- Red Fox becomes housed when valid Meadow Dwelling exists on the same island.
- Hare can be housed through the base Meadow dwelling path or a Hare variant.
- Housed spirit can transition to happy/assistant-ready after conditions are met.
- Unhoused spirit can transition to restless.
- Assistant-ready Red Fox appears as a ritual input.
- Assistant ritual success does not consume or despawn the spirit.
- Assistant availability revalidates on confirm.
- Component availability works for discovery-based and placed-structure components.
- Duplicate component or duplicate assistant inputs fail non-destructively.
- Mood state persists through save/load.
- Mist Stag can still be unlocked and still grants Ku.
- Ku unlock can still start a second island.
- Second island can still spawn island-local spirits.

## Manual Editor Flow

1. Create Meadow, invite Red Fox and obtain/place Warm Hollow as Meadow Dwelling.
2. Verify Red Fox becomes housed rather than requiring Fox Den as the only valid home.
3. Invite or debug-spawn Hare and verify Hare can also use Meadow Dwelling or Hare Hollow path.
4. Let a housed spirit reach happy/assistant-ready state through debug time acceleration or configured wait.
5. Open the ritual menu and verify assistant-ready spirits appear as selectable inputs.
6. Use Red Fox in an assistant ritual and verify the spirit remains in the garden.
7. Discover or place a component such as Wind Chime, then verify it appears as a component ritual input.
8. Move to another island context if available and verify island-local component requirements block correctly.

## End-to-End 10-Minute Loop Gate

This is the release gate for the three-feature migration. It may use debug time acceleration, but it should not require debug-only content grants unless the grant is explicitly replacing real elapsed time.

1. Start a fresh garden.
2. Create and place Meadow from Wind.
3. Let Meadow invite early spirits; verify Red Fox, Hare or another current Meadow spirit can appear.
4. Let Meadow generate Living Wood and harvest it.
5. Shape Living Wood + Fire Essence into Warm Hollow.
6. Place Warm Hollow on Meadow and verify Meadow Dwelling.
7. Verify a Meadow spirit can be housed and can become happier over time or through debug time acceleration.
8. Progress to the Mist Stag condition using current or migrated triggers.
9. Verify Mist Stag appears and unlocks Ku.
10. Use Ku to start a second island.
11. Create valid biome/spirit conditions on the second island.
12. Verify at least one new island-local spirit appears there.

Failure of any step means the migration is not complete, even if the individual ritual, material or assistant tests pass.

## UX Review

Mood and assistant UI should:

- Show why a spirit can or cannot assist without long rule text.
- Avoid making spirits feel consumable.
- Keep the ritual menu within the three-slot mental model.
- Use Codex hints for deeper assistant/component explanations.

## Regression Notes

- Existing spirit spawn patterns remain valid unless explicitly migrated later.
- Housing assignment should still prefer preferred-biome houses, then same-island houses.
- Mist Stag, Ku unlock, second island creation and second-island spirit spawning are hard regression gates.
- Any new assistant/component unlocks must be reflected in `specs/master/recipes.md`.
