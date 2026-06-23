# Feature Spec: Rain Kami Path

## Scope

Add the first playable Rain path after the first expansion loop:

1. Shape a Reed Nest from Reed Fiber and Water Essence.
2. Place it as a water dwelling on a second-island rain biome.
3. Invite Rain Kami Suijin from a small rain cluster after the Reed Nest discovery.

This slice deliberately excludes spirit assistants, assistant components, mood/tension systems, and deployment automation.

## User Stories

### Story 1: Shape a Rain Dwelling

As a player with access to harvested biome material, I can use the ritual menu to combine Reed Fiber with Water Essence and create a Reed Nest form.

Acceptance:
- Reed Fiber appears as a selectable ritual material.
- Reed Fiber + Water Essence previews and creates `form_reed_nest`.
- The ritual consumes one Reed Fiber and one Water Essence.
- The Reed Nest discovery is recorded for pattern prerequisites.

### Story 2: Place the Reed Nest

As a player expanding into rain terrain, I can place the Reed Nest on River, Wetlands, or Moonlit Pool to create `building_reed_nest`.

Acceptance:
- `form_reed_nest` resolves to `building_reed_nest` on valid water/rain biomes.
- Invalid biomes reject the form.
- The structure is visible and labelled as Reed Nest.

### Story 3: Invite Rain Kami Suijin

As a player who has reached the second island, I can gather a small rain cluster and invite Rain Kami Suijin without spirit assistants.

Acceptance:
- Suijin requires `disc_reed_nest`.
- Suijin can appear from a River cluster in the Awakening era.
- Suijin remains a deity/shrine path and does not require assistant components.

## Non-Goals

- No spirit assistant system.
- No Rain mood, offense, dormancy, or withdrawal state.
- No Frog Spirit dependency.
- No GitHub Pages or deployment pipeline.
- No full Rain Island economy.

## Success Criteria

- A focused regression can execute the path: Reed Fiber -> Reed Nest -> second-island River cluster -> Rain Kami Suijin.
- Existing first expansion loop remains intact.
