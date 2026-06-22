# Archive: Ritual and Material Migration

**Archived**: 2026-06-22

This archive preserves the old crafting-grid and craft-mode planning trail while
removing those specs from the active implementation queue.

## Archived Specs

| Spec | Reason Archived | Superseded By |
|------|-----------------|---------------|
| `019-seed-crafting-grid` | Defined the 3x3 crafting grid for seed recipes. The new direction replaces grid crafting with unique ritual slots. | `022-ritual-menu-slots` |
| `020-craft-mode-buildings` | Defined craft-mode building recipes and build-mode retirement. The new direction replaces building recipes with ritual forms and placement context. | `022-ritual-menu-slots`, `023-biome-natural-materials` |
| `021-first-session-clarity` | Useful UX intent, but structure-craft feedback is now reframed around the 10-minute ritual/material loop. | `022-ritual-menu-slots`, `023-biome-natural-materials`, `024-spirit-assistants-components` |

## Active Direction

Use these active specs for current implementation:

- `022-ritual-menu-slots`
- `023-biome-natural-materials`
- `024-spirit-assistants-components`
- `specs/master/master_plan.md`
- `specs/master/recipes.md`

## Regression Gate

The migration is only complete when the first expansion loop remains playable:

1. Create Meadow from Wind.
2. Generate and harvest Living Wood.
3. Shape Living Wood + Fire Essence into Warm Hollow.
4. Place Warm Hollow as Meadow Dwelling.
5. Invite and house a Meadow spirit.
6. Unlock Mist Stag.
7. Unlock Ku.
8. Start a second island.
9. Invite new island-local spirits there.
