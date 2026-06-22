# Satori: Core Rulebook of Truth v0.1

## 1. High Concept

**Satori** is a 2D sandbox spirit ecosystem game that blends:

* **Pokopia-like warmth**: spirits, houses, care, cuteness, attachment.
* **Cascadia-like spatial play**: tile placement, adjacency, island-specific matching rules.
* **God-game discovery**: indirect control, rituals, koans, irreversible world changes, emergent unlocks.

The player does not build a city.

The player cultivates islands.

The goal is not to beat a fixed level, but to **unlock every form the world can take**: biomes, spirits, materials, structures, rituals, memories, island states, god spirits and restoration paths.

The core fantasy:

> I learn the language of the world.
> I shape places.
> Places invite spirits.
> Spirits reveal new possibilities.
> My choices cannot be undone, but every choice can become meaning.

---

## 2. Core Truths

### Truth 1: There Is No Undo

Nothing is simply reversed.

A placed biome, a changed island, an offended god, a discovered structure, a memory, a scar: all become part of the world’s history.

But “no undo” does not mean “punishment”.

Instead:

> Every meaningful action creates a state.
> Every state can unlock something.
> Harmony unlocks blessings.
> Tension unlocks conflict discoveries.
> Restoration unlocks wisdom.

The player cannot erase what happened.
The player can transform, reconcile, contain, restore, offer or integrate it.

### Truth 2: Essence Becomes Seeds, Seeds Become Places

Essence is not a generic currency.

Essence is **elemental intent**.

Essence is shaped through ritual into a **seed**.
Planting that seed on an empty tile creates a biome.

* Single essence rituals create basic biome seeds.
* Essence combinations create hybrid biome seeds.
* Ku essence eventually unlocks island seeds and deep ritual paths.

Examples:

#### Tier 1 — Single Element

The four basic elements are available early. Ku remains locked, dormant or non-selectable until the player discovers a deep ritual path.

| `ritual_id` | Element | Produces Seed | Biome | Codex Hint |
|-------------|---------|---------------|-------|------------|
| `ritual_wind_seed` | Wind / Fū | Meadow Seed | Meadow | "Grass that bends but does not break." |
| `ritual_fire_seed` | Fire / Ka | Hearth Seed | Hearth | "Where heat remembers the shape of fire." |
| `ritual_water_seed` | Water / Sui | Pond Seed | Pond | "It finds its own way through stone." |
| `ritual_earth_seed` | Earth / Chi | Stonefield Seed | Stonefield | "Cold and still, the bones of the earth." |
| `ritual_ku_seed` | Ku / Kū | Island Seed or shrine-related seed | Island / Shrine path | "Void made tangible; silence with form." |

#### Tier 2 — Two Basic Elements

| `ritual_id` | Elements | Produces Seed | Biome |
|-------------|----------|---------------|-------|
| `ritual_wind_fire_seed` | Wind + Fire | Sungrass Seed | Sungrass Field |
| `ritual_wind_water_seed` | Wind + Water | Rain Meadow Seed | Rain Meadow |
| `ritual_wind_earth_seed` | Wind + Earth | Rooted Steppe Seed | Rooted Steppe |
| `ritual_fire_water_seed` | Fire + Water | Steam Spring Seed | Steam Spring |
| `ritual_fire_earth_seed` | Fire + Earth | Ember Crag Seed | Ember Crag |
| `ritual_water_earth_seed` | Water + Earth | Grove Seed | Grove |

#### Tier 2 (+Kū) — Unlocked after Ku becomes selectable

Ku becomes selectable only after a discovery or spirit grants access to deep ritual space.

| `ritual_id` | Elements | Produces Seed | Biome |
|-------------|----------|---------------|-------|
| `ritual_wind_ku_seed` | Wind + Ku | Whisper Hollow Seed | Whisper Hollow |
| `ritual_fire_ku_seed` | Fire + Ku | Foxfire Hollow Seed | Foxfire Hollow |
| `ritual_water_ku_seed` | Water + Ku | Mist Pool Seed | Mist Pool |
| `ritual_earth_ku_seed` | Earth + Ku | Rune Garden Seed | Rune Garden |

### Truth 3: Biomes Invite Spirits and Generate Materials

Biomes are living habitats.

A biome does three main things:

1. It invites spirits.
2. It generates materials.
3. It allows the player to harvest those materials.

Materials appear naturally over time within biomes, but **the player must actively harvest them**.

Early harvesting is simple interaction (click/tap), but later this can become more visually expressive and satisfying:

* cutting living wood from a meadow,
* mining spirit stone from earth,
* gathering reeds from water,
* collecting glowing materials from magical biomes.

Automation structures can later assist or replace manual harvesting.

Example:

* Meadow generates Living Wood.
* Meadow invites Red Fox.
* Hearth generates Ember Clay.
* Pond generates Reed Fiber or Dew Pearl.
* Shrine generates Rune Stone or Moon Resin.

### Truth 4: Spirits Are Not Resources

Spirits are living ecosystem agents.

They:

* produce essence,
* have needs,
* can be housed,
* can become happy, restless, offended or dormant,
* affect Satori,
* may later assist rituals.

A spirit is never consumed.

When used in a ritual, a spirit acts as an **assistant**, not as an ingredient.

### Truth 5: Materials Create Forms

Materials are not mundane resources.

A material is a **physical form with meaning**.

Examples:

* Living Wood = living shelter, growth, soft structures.
* Spirit Stone = foundation, stability, anchors.
* Ember Clay = warmth, transformation, kilns.
* Reed Fiber = softness, nests, connection.
* Rune Stone = ritual law, seals, boundaries.

Materials become meaningful through rituals.

### Truth 6: Structures Are Discovered Forms

Structures are not bought from a recipe list.

They are discovered through rituals.

A structure can:

* house spirits,
* modify biome behavior,
* automate material harvesting,
* influence Satori,
* become a component in later rituals,
* anchor island states,
* support god spirit conditions.

### Truth 7: The Codex Teaches Through Koans

The Codex is not a wiki.

It is a living book of koans, hints, memories and world-truths.

The Codex does not say:

> Living Wood + Fire Essence = Warm Hollow

It says:

> The fox does not ask for walls.
> It asks for a warm hollow.

After discovery, the Codex may reveal practical information.

The Codex teaches the player how the world thinks.

### Truth 8: Islands Are Local Rule Containers

All matching rules are island-specific.

A god spirit only judges its own island.

A Fire biome on Ember Island may be harmonious.
A Fire biome on Rain Island may create tension.
A Fire biome elsewhere does not anger Rain Kami.

Each island has:

* local Satori,
* unique matching rules,
* unique spirits,
* unique materials,
* unique god spirit paths,
* harmony discoveries,
* tension discoveries,
* restoration discoveries.

### Truth 9: Satori Measures Harmony, Not Victory

Satori is the harmony of a local ecosystem.

There may be:

* Island Satori
* World Satori

High Satori unlocks harmony paths.
Low or unstable Satori can unlock tension paths.
Restored Satori can unlock deeper paths.

Satori is not only “score”.
It is the world’s emotional and spiritual health.

### Truth 10: The Goal Is to Unlock Everything

The sandbox goal is completion through discovery.

The player aims to unlock:

* all biomes,
* all hybrid biomes,
* all materials,
* all spirits,
* all houses,
* all structures,
* all spirit states,
* all island states,
* all god spirits,
* all memories,
* all restoration paths,
* all Codex entries.

The game should never be about grinding huge stacks.

Endgame should ask for mastery of meaning, placement and harmony.

---

## 3. The Core Game Loop

### Primary Loop

1. Player gains essence.
2. Player uses essence in rituals to create seeds.
3. Player plants seeds on empty tiles to create biomes.
4. Biomes generate materials.
5. Player actively harvests materials from biomes.
6. Biomes invite spirits.
7. Spirits generate new essence.
8. Materials and essence are used in rituals.
9. Rituals discover structures.
10. Structures house spirits, automate materials or shape island harmony or provide other bonuses (like energy cap).
11. Housed and happy spirits increase Satori.
12. Satori unlocks deeper discoveries, island paths and god spirits.

### Compact Loop

> Essence becomes seeds.
> Seeds become biomes.
> Biomes create materials.
> Materials are harvested.
> Biomes invite spirits.
> Spirits create essence.
> Materials create structures.
> Structures house spirits.
> Housed spirits create Satori.
> Satori unlocks deeper forms.

---

## 4. The First 10 Minutes

### Starting State

The player begins with:

* empty sandbox grid,
* a single Shrine of Origin,
* 3/3 of each basic element (Wind, Fire, Water, Earth),
* Ku locked, dormant or represented only as mystery,
* Shrine of Origin generates 1 random unlocked element every 30 seconds,
* no structures,
* no spirits,
* no Codex entries except the first whisper.

### Step 1: Create Meadow

1a perform the ritual
1b plant the seed
1c the meadow blooms

Action:

* Use Wind Essence in the ritual.

Result:

* Meadow is created.

Codex:

> Wind touches emptiness,
> and emptiness becomes meadow.

Mechanic taught:

* Essence becomes seeds.
* Seeds create biomes.

### Step 2: Meadow Generates Living Wood

The Meadow begins producing Living Wood.

Player must harvest the Living Wood manually.

Codex:

> Where the meadow breathes,
> wood grows with a heartbeat.

Mechanic taught:

* Biomes generate materials.
* Materials must be harvested.

### Step 3: Red Fox Appears

The Meadow invites Red Fox.

Red Fox:

* element: Fire
* state: visiting
* housing: none
* mood: curious, restless
* produces: Fire Essence

Codex:

> A red tail arrives before the hearth is built.

Mechanic taught:

* Biomes invite spirits.
* Spirits produce essence.
* Spirits have needs.

### Step 4: Red Fox Becomes Restless

If Red Fox remains unhoused for too long:

* local Satori decreases slightly,
* Codex gives stronger hint.

Codex:

> A red tail does not fear the meadow.
> It fears a night without a hollow.

Mechanic taught:

* Unhoused spirits may reduce Satori.
* Spirits need homes.

### Step 5: First Structure Ritual

Player has:

* Living Wood
* Fire Essence
* Red Fox present

Early ritual:

* Living Wood + Fire Essence → Warm Hollow

Context:

* placement on Meadow turns Warm Hollow into Meadow Dwelling

Alternative later version with spirit assistant:

* Living Wood + Earth Essence + Red Fox → Cozy Fox Den
* Living Wood + Earth Essence + Hare → Hare Hollow

First discovery Codex:

> The fox does not ask for walls.
> It asks for a warm hollow.

After discovery:

> When living wood accepted warmth,
> the hollow waited to learn where it belonged.

Mechanic taught:

* Materials and essence discover structures.
* Each ritual slot must be unique.
* No duplicate materials, essences, components or spirit assistants are allowed.
* Structures solve spirit needs.

### Step 6: Place Warm Hollow

Warm Hollow is the first shelter-form. When placed on Meadow, it becomes a **Meadow Dwelling**. Fox Den and Hare Hollow are later variants or flavor specializations, not the base housing category.

Structures are always placed **on top of biomes**, not on empty tiles.

* Small structures occupy **1 tile**.
* Larger structures can occupy **multiple tiles** (up to 5 tiles or more depending on type).

Player places the Warm Hollow directly on a Meadow tile.

Result:

* Red Fox (a Meadow-aligned spirit) becomes housed.
* Satori increases.
* Red Fox produces Fire Essence more reliably.

Mechanic taught:

* Rituals create forms.
* Structures are layered onto biomes.
* Placement and context give forms their final role.
* Structures have size and spatial footprint.
* Structures house spirits based on biome alignment.
* Housed spirits increase Satori.
* Placement matters through relationships and space usage.

### Step 7: Next Unlock

Red Fox produces Fire Essence.

Player can now create:

* Fire Essence ritual → Hearth Seed → Hearth
* Wind + Fire ritual → Sungrass Seed → Sungrass Field

Codex hint:

> Warmth does not end the meadow.
> It teaches the grass to glow.

Mechanic taught:

* Spirits unlock new biome directions.
* Essence combinations create hybrid biome seeds.

### Migration Test Goal: First Expansion Loop

The ritual/material migration is not complete until the following loop is still playable in the editor:

1. Create Meadow from Wind.
2. Let Meadow generate Living Wood.
3. Harvest Living Wood.
4. Shape Living Wood + Fire Essence into Warm Hollow.
5. Place Warm Hollow on Meadow and form Meadow Dwelling.
6. Invite and house at least one Meadow spirit, such as Red Fox or Hare.
7. Progress to Mist Stag through its current or migrated discovery path.
8. Mist Stag unlocks Ku.
9. Use Ku to start a second island.
10. Create valid conditions on the second island and invite new island-local spirits.

This loop is the regression gate for the new direction. Individual systems are not considered done if they pass in isolation but break spirit discovery, housing, Ku unlocks or second-island play.

---

## 5. Elements: Godai Language

Elements are verbs.
They define the intent of a ritual or biome.

### Wind

Role:

* invite,
* move,
* spread,
* speed,
* call,
* open paths.

Koan:

> Wind does not keep.
> It calls, carries, and opens the way.

Gameplay:

* creates Meadow seeds,
* improves invitation,
* expands influence,
* supports movement and adjacency.

### Fire

Role:

* warm,
* activate,
* transform,
* energize,
* intensify.

Koan:

> Fire does not ask what a thing is.
> It asks what it may become.

Gameplay:

* creates Hearth seeds,
* supports fox spirits,
* activates kilns,
* transforms materials,
* creates tension on Water islands.

### Water

Role:

* soothe,
* heal,
* store,
* remember,
* grow,
* flow.

Koan:

> Water wins by staying.
> It remembers the shape of every wound.

Gameplay:

* creates Pond seeds,
* calms spirits,
* supports recovery,
* stores essence,
* transforms Fire tension into Steam paths.

### Earth

Role:

* stabilize,
* protect,
* contain,
* anchor,
* shelter,
* boundary.

Koan:

> Earth is the kindness of a boundary.

Gameplay:

* creates Stonefield seeds,
* supports houses,
* contains conflict,
* anchors islands,
* prevents collapse.

### Ku

Role:

* space,
* emptiness,
* mystery,
* integration,
* islands,
* deep rituals,
* god paths.

Koan:

> Emptiness is not nothing.
> It is room for the next island.

Gameplay:

* creates island seeds,
* enables deep rituals,
* creates memories,
* integrates contradictions,
* opens god spirit paths.

---

## 6. Materials: Form Language

Materials are nouns.
They define what kind of thing can be shaped.

### Living Wood

Source:

* Meadow

Role:

* living structures,
* houses,
* growth,
* soft shelter.

Koan:

> Living Wood does not become furniture.
> It becomes a promise to shelter life.

Example rituals:

* Living Wood + Fire → Warm Hollow
* Living Wood + Water → Dew Bowl
* Living Wood + Earth → Root Network
* Living Wood + Wind → Wind Chime
* Living Wood + Ku → Tiny Shrine

### Spirit Stone

Source:

* Stonefield

Role:

* foundations,
* anchors,
* basins,
* containment,
* stability.

Koan:

> Stone does not move,
> but spirits rest easier when it listens.

Example rituals:

* Spirit Stone + Reed Fiber + Water → Stone Basin
* Spirit Stone + Living Wood + Earth → Foundation Marker
* Spirit Stone + Rune Stone + Ku → Rune Marker
* Spirit Stone + Living Wood + Earth → Rooted Foundation

### Ember Clay

Source:

* Hearth

Role:

* warmth,
* kilns,
* transformation,
* heat storage.

Koan:

> Clay remembers fire
> and teaches warmth to stay.

Example rituals:

* Ember Clay + Spirit Stone + Fire → Kiln Heart
* Ember Clay + Spirit Stone + Fire → Clay Hearth
* Ember Clay + Water + Spirit Stone → Steam Bowl

### Reed Fiber

Source:

* Pond or marsh-like biome

Role:

* softness,
* nests,
* comfort,
* flexible connections.

Koan:

> A reed bends
> so another may rest.

Example rituals:

* Reed Fiber + Living Wood + Water → Reed Nest
* Reed Fiber + Living Wood + Water → Soft Nest
* Reed Fiber + Wind + Living Wood → Reed Flute

### Mist Thread

Source:

* Mist Pool or Water + Ku biome

Role:

* dreams,
* memory,
* soft paths,
* hidden connections.

Koan:

> Mist cannot be held,
> unless it chooses to become a thread.

Example rituals:

* Mist Thread + Wind + Echo Crystal → Whisper Path
* Mist Thread + Ku + Spirit Stone → Veil Gate
* Mist Thread + Water + Reed Fiber → Dream Hammock

### Rune Stone

Source:

* Shrine or Earth + Ku biome

Role:

* ritual law,
* seals,
* boundaries,
* advanced unlocks.

Koan:

> A rune is a stone
> that learned how to say no.

Example rituals:

* Rune Stone + Moon Resin + Ku → Great Seal
* Rune Stone + Earth + Spirit Stone → Binding Marker
* Rune Stone + Water + Spirit Stone → Memory Rune

### Moon Resin

Source:

* Ku-aligned island or Shrine biome

Role:

* refinement,
* blessing,
* lacquer,
* sacred upgrades.

Koan:

> Resin is patience
> made visible by moonlight.

Example rituals:

* Moon Resin + Living Wood + Earth → Lacquered Pillar
* Moon Resin + Fire + Ember Clay → Moonflame
* Moon Resin + Ku + Tiny Shrine → Blessing Lacquer

### Echo Crystal

Source:

* Mountain, Wind + Earth biome, or advanced island

Role:

* resonance,
* signals,
* long-range adjacency,
* memory of patterns.

Koan:

> The crystal does not speak first.
> It remembers what was called.

Example rituals:

* Echo Crystal + Spirit Stone + Wind → Resonance Bell
* Echo Crystal + Water + Spirit Stone → Echo Pool
* Echo Crystal + Ku + Rune Stone → Oracle Lens

### Sungrass

Source:

* Wind + Fire biome

Role:

* speed,
* brightness,
* joy,
* fox movement,
* radiant pathways.

Koan:

> Some grass grows upward.
> Sungrass grows toward laughter.

Example rituals:

* Sungrass + Wind + Living Wood → Sun Kite
* Sungrass + Fire + Red Fox → Foxfire Trail
* Sungrass + Water + Reed Fiber → Golden Dewbed

### Ash Silk

Source:

* Fire + Ku biome or late island state

Role:

* protection,
* transformation after loss,
* scars made gentle.

Koan:

> Ash is not the end of fire.
> Silk is what remains when burning learns tenderness.

Example rituals:

* Ash Silk + Water + Spirit Stone → Soothe Veil
* Ash Silk + Fire + Ember Clay → Phoenix Wrap
* Ash Silk + Ku + Tiny Shrine → Spirit Mantle

---

## 7. Biomes

Biomes are created by planting seeds generated through rituals.

### Basic Biomes

* Wind ritual → Meadow Seed → Meadow
* Fire ritual → Hearth Seed → Hearth
* Water ritual → Pond Seed → Pond
* Earth ritual → Stonefield Seed → Stonefield
* Ku ritual → Island Seed / Shrine-related creation

### Hybrid Biomes

* Wind + Fire ritual → Sungrass Seed → Sungrass Field
* Wind + Water ritual → Rain Meadow Seed → Rain Meadow
* Wind + Earth ritual → Rooted Steppe Seed → Rooted Steppe
* Wind + Ku ritual → Whisper Hollow Seed → Whisper Hollow
* Fire + Water ritual → Steam Spring Seed → Steam Spring
* Fire + Earth ritual → Ember Crag Seed → Ember Crag
* Fire + Ku ritual → Foxfire Hollow Seed → Foxfire Hollow
* Water + Earth ritual → Grove Seed → Grove
* Water + Ku ritual → Mist Pool Seed → Mist Pool
* Earth + Ku ritual → Rune Garden Seed → Rune Garden

## 8. Spirits

Spirits are living beings with needs, essence output and Satori impact.

### Spirit States

A spirit may be:

* Visiting
* Housed
* Happy
* Restless
* Unhappy
* Wandering
* Dormant
* Elder
* Assistant-ready

### Housing Rule

Unhoused spirits are not instantly bad.

They first visit.
If ignored, they become restless.
Restless spirits may reduce Satori.

Housed spirits increase Satori when their needs are met.

### Spirit Assistant Rule

Later in progression, housed spirits can assist rituals.

They occupy one ritual slot.

Spirits are not consumed.

A spirit assistant counts as embodied elemental intent. Depending on the ritual, that intent can replace an essence slot or resonate with matching essence.

Example:

* Red Fox counts as Fire.
* Crane Spirit counts as Wind.
* Frog Spirit counts as Water.
* Tanuki counts as Earth.
* Bell Spirit counts as Ku.

### Red Fox

Element:

* Fire

First invited by:

* Meadow

Produces:

* Fire Essence

Needs:

* warm shelter,
* meadow or hearth adjacency,
* later: foxfire structures.

Early state:

* curious but restless if unhoused.

First house:

* Meadow Dwelling
* Fox Den

Koan:

> A red tail arrives before the hearth is built.

Housing koan:

> The fox does not ask for walls.
> It asks for a warm hollow.

Future assistant ritual:

* Living Wood + Earth Essence + Red Fox → Cozy Fox Den
* Sungrass + Fire Essence + Red Fox → Foxfire Trail
* Tiny Shrine + Ku Essence + Red Fox → Foxfire Shrine

## 9. Ritual System

### Ritual Core Rules

Rituals have up to 3 slots.

At least 1 slot must be essence.

Each ritual slot must be unique.

No duplicate materials, essences, components or spirit assistants are allowed. A specific input identity can appear only once in a ritual.

Every valid no-duplicate material + element pairing should produce something: a structure, component, capacity increase, automation helper, hint, lesser form or island state. Early play should feel generous because one new material can immediately be explored through the four basic elements.

Early slots may contain:

* essence,
* materials.

Later slots may contain:

* structures/components,
* spirit assistants.

### Ritual Categories

#### 1 Material + 1 Essence

Creates simple early forms.

Example:

* Living Wood + Fire Essence → Warm Hollow

#### 2 Materials + 1 Essence

Creates physical structures.

Example:

* Living Wood + Spirit Stone + Fire Essence → Clay Hearth

#### 1 Material + 2 Essences

Creates infused structures or advanced variants.

Example:

* Living Wood + Fire Essence + Ku Essence → Foxfire Hollow structure

#### Material + Structure/Component + Essence

Creates upgrades or advanced components.

Example:

* Living Wood + Tiny Shrine + Ku Essence → Sacred Grove Marker

#### Structure/Component + Essence + Spirit

Creates spirit-specific advanced structures.

Example:

* Tiny Shrine + Ku Essence + Red Fox → Foxfire Shrine

#### Component + Essence + Elder Spirit

Creates island or god-spirit rituals.

Example:

* Great Seal + Ku Essence + Elder Wind Spirit → Pagoda of Still Winds

### Components

A component is a discovered structure or ritual form that can later be used inside rituals.

A component is not always a separate inventory item.

It can be:

* a discovered structure,
* a placed structure,
* a symbolic form learned by the player,
* a ritual memory.

Examples:

* Wind Chime
* Tiny Shrine
* Rune Marker
* Great Seal
* Resonance Bell
* Fox Den
* Foxfire Shrine
* Lacquered Pillar

Components let endgame scale without requiring huge resource numbers.

Bad endgame:

* 50 Living Wood + 25 Spirit Stone + Fire Essence

Good endgame:

* Lacquered Pillar + Great Seal + Ku Essence
* plus island context
* plus happy spirit requirement
* plus Satori threshold

## 10. Structures

Structures are discovered through rituals and placed on islands.

### Structure Roles

A structure can:

* house spirits,
* increase Satori,
* reduce unhappiness,
* improve material production,
* automate harvesting,
* modify adjacency,
* contain tension,
* become a component,
* anchor island identity,
* support god spirit requirements.

### Early Structures

#### Warm Hollow

Discovery:

* Living Wood + Fire Essence
* Later variants: Living Wood + Earth Essence + Red Fox; Living Wood + Earth Essence + Hare

Effect:

* creates a base shelter-form,
* becomes Meadow Dwelling when placed on Meadow,
* becomes Scorched Hollow when placed on Fire/Hearth,
* can specialize into Fox Den, Hare Hollow or other spirit variants.

Koan:

> When living wood accepted warmth,
> the hollow waited to learn where it belonged.

Placement outcomes:

* On Meadow → Meadow Dwelling.
* On Fire/Hearth → Scorched Hollow.
* With Red Fox → Fox Den path.
* With Hare → Hare Hollow path, safest with Earth or Water support.
* Near Water support → Steam-Softened Shelter.
* Near Earth support → Rooted Hollow.

#### Dew Bowl

Discovery:

* Living Wood + Water Essence

Effect:

* increases Wind Essence storage cap,
* later may soothe visiting spirits.

Koan:

> A bowl of dew
> teaches the wind where to rest.

#### Root Network

Discovery:

* Living Wood + Earth Essence

Effect:

* increases material generation speed for nearby Meadow tiles,
* later may route harvested materials toward storage.

Koan:

> Roots do not hurry by running.
> They hurry by already being there.

#### Wind Chime

Discovery:

* Living Wood + Wind Essence

Effect:

* increases invite speed,
* can auto-harvest nearby Living Wood from Meadow tiles,
* may become Wind component.

Koan:

> The meadow has a voice
> only wind can teach it.

#### Tiny Shrine

Discovery:

* Living Wood + Ku Essence

Effect:

* increases rare visitor chance,
* unlocks deeper ritual hints,
* may unlock spirit assistants.

Koan:

> A small shrine is not small
> to a spirit that has nowhere to bow.

## 11. Automation

Automation becomes interesting once material needs expand across islands.

Auto-harvesting is not just convenience.
It is a midgame transition.

The player’s garden grows too large to manually collect everything.

### Automation Principles

Automation buildings:

* are discovered through rituals,
* must be placed on islands,
* obey island-specific matching rules,
* may improve or harm Satori depending on island identity.

Example:

#### Root Gatherer

Discovery:

* Living Wood + Spirit Stone + Wind Essence

Effect:

* automatically collects Living Wood from nearby Meadow.

Island interactions:

* good on Meadow Island,
* neutral on production islands,
* harmful on Shrine Island unless sanctified.

Koan:

> The root does not mind being gathered
> if the hand remembers to sing.

#### Sanctified Harvester

Discovery:

* Root Gatherer + Ku Essence + Tiny Shrine

Effect:

* quieter automation,
* allowed on sacred islands with less Satori penalty.

Koan:

> Even work may bow.

## 12. Islands

Ku unlocks islands.

An island is a local ecosystem puzzle with its own rules.

### Island Properties

Each island has:

* island type,
* local Satori,
* unique spirits,
* unique materials,
* matching rules,
* tension rules,
* restoration rules,
* god spirit path,
* Codex mysteries.

### Island Examples

#### Meadow Island

Theme:

* openness,
* first homes,
* invitation,
* fox relationship.

Materials:

* Living Wood
* later Sungrass, if hybridized

Spirits:

* Red Fox
* Breeze spirits
* Crane-like spirits later

Matching rules:

* housed spirits near Meadow score Satori,
* Wind Chime touching multiple Meadow tiles scores,
* Meadow Dwelling near Meadow and Hearth scores,
* overcrowding reduces Satori.

God path:

* Wind-related elder or Meadow guardian.

#### Rain Island

Theme:

* calm,
* flow,
* recovery,
* memory.

Materials:

* Reed Fiber
* Mist Thread
* Dew Pearl

Spirits:

* Frog Spirit
* Koi Spirit
* Rain Deer
* Rain Kami

Matching rules:

* Water biomes like being connected,
* Fire near Rain Shrine creates tension,
* Stone Basin calms nearby spirits,
* Reed Nest near Pond houses Frog Spirit.

Harmony path:

* Rain Kami invitation.

Tension path:

* Fire conflict reveals Steam Spring, Storm Frog, Rain-Fire Memory.

Recovery path:

* Reconciliation Shrine.

#### Ember Island

Theme:

* warmth,
* transformation,
* foxfire,
* active rituals.

Materials:

* Ember Clay
* Ash Silk
* Sungrass

Spirits:

* Red Fox variants
* Salamander Spirit
* Lantern Oni
* Flame Kami

Matching rules:

* Fire biomes score in clusters,
* Foxfire structures boost Satori,
* too much Water creates quenching tension unless transformed into Steam.

#### Shrine Island

Theme:

* silence,
* memory,
* Ku,
* rare spirits,
* sacred patterns.

Materials:

* Rune Stone
* Moon Resin

Spirits:

* Bell Spirit
* Paper Crane Spirit
* Moon Moth
* Kitsune
* Ku Kami or Satori Kami

Matching rules:

* Ku structures score,
* restless spirits heavily reduce Satori,
* noisy automation harms harmony unless sanctified,
* memories placed respectfully unlock deep rituals.

## 13. God Spirits

God spirits are not normal spirits.

They define an island vow.

They do not judge the whole world.
They judge only their island.

### God Spirit States

* Present
* Uneasy
* Offended
* Withdrawn
* Dormant
* Restored
* Departed as Memory

Conflict does not instantly fail the player.

Conflict creates a state.

Example:

Rain Kami dislikes exposed Fire.

If player adds Fire to Rain Island:

* Rain Kami becomes Uneasy.
* If Fire touches Rain Shrine, Rain Kami becomes Offended.
* If tension continues, Rain Kami withdraws.
* If ignored, Rain Kami becomes Dormant or leaves a Memory.
* Restoration path unlocks.

### God Spirits as Unlock Goals

God spirits require island-specific ecosystems.

Example:

#### Rain Kami

Requires:

* Rain Island,
* connected Water biomes,
* housed Water spirits,
* no exposed Fire near Rain Shrine,
* sufficient Island Satori.

Ritual:

* Stone Basin + Ku Essence + Frog Spirit
* Advanced Rain component + Ku Essence + Rain spirit

Unlocks:

* Rain blessing,
* rare Water spirits,
* advanced Water-Ku rituals.

#### Flame Kami

Requires:

* Ember Island,
* Fire cluster,
* happy Fire spirits,
* Foxfire Shrine,
* controlled transformation structures,
* sufficient Island Satori.

Unlocks:

* Flame blessing,
* Ash Silk,
* Phoenix-style restoration paths.

#### Ku Kami / Satori Kami

Requires:

* Shrine Island,
* memories from multiple island types,
* no restless spirits,
* high World Satori,
* Great Seal.

Unlocks:

* deepest rituals,
* island integration,
* final completion paths.

## 14. Island States and No Undo

Island changes create states.

### State Types

#### Harmony State

The island matches its vow.

Unlocks:

* blessings,
* god spirits,
* rare happy spirits,
* advanced structures.

#### Tension State

The island contains a meaningful conflict.

Unlocks:

* hybrid materials,
* conflict spirits,
* warning Codex entries,
* transformation paths.

#### Recovery State

A damaged or tense island is being healed.

Unlocks:

* reconciliation structures,
* memories,
* restoration spirits,
* deeper Codex entries.

#### Dormant State

A god or island has withdrawn.

Unlocks:

* dormant relics,
* restoration chains,
* memory rituals.

#### Memory State

An irreversible event has become part of the world’s history.

Unlocks:

* memory-based rituals,
* Ku paths,
* god integration.

### Rule

No action should be undoable.
But every action should be metabolizable.

Meaning:

* player cannot erase consequences,
* but consequences can be transformed into new content.

## 15. Codex

The Codex is the primary guidance system.

It uses koans to hint at discoveries.

### Codex Rules

* It appears when the player touches part of a truth.
* It hints before revealing.
* It becomes practical after discovery.
* It tracks unresolved mysteries.
* It warns before irreversible changes.
* It can escalate hints if the player is stuck.

### Hint Levels

#### Level 1: Poetic

The fox circles the wood,
but does not sleep beneath open sky.

#### Level 2: Directed

The fox wants warmth, not only shelter.

#### Level 3: Practical

Try shaping Living Wood with warm intent while the Red Fox is near.

#### Level 4: Explicit, Optional

Ritual suggestion: Living Wood, Fire Essence.

Level 4 should require a “meditate” action or similar.

### Codex Entry Example: The Restless Fox

Before discovery:

> A red tail does not fear the meadow.
> It fears a night without a hollow.

When player has Living Wood and Fire Essence:

> The hollow is almost a home.
> It waits for warmth.

After discovery:

> When living wood accepted warmth,
> the hollow waited to learn where it belonged.

Revealed:

* Warm Hollow discovered.
* Placing Warm Hollow on Meadow creates Meadow Dwelling.
* Meadow Dwelling houses Meadow-preferred spirits such as Red Fox and Hare.

### Codex Entry Example: Fire on Rain Island

Before action warning:

> The Rain Kami will remember this flame.

After tension:

> The Rain Kami does not hate flame.
> It hates flame that forgets to bow.

Recovery hint:

> Do not remove the flame.
> Teach it to kneel in a bowl of stone.

Practical meaning:

Fire must be contained, transformed or moved away from the sacred cluster.
Stone Basin or Earth boundary may help.

## 16. Unlock Philosophy

Unlocks should come from discovery, not grind.

### Unlock Types

* Biome unlock
* Hybrid biome unlock
* Material unlock
* Spirit unlock
* Structure unlock
* Component unlock
* Island unlock
* God spirit unlock
* Memory unlock
* State unlock
* Restoration unlock
* Codex unlock
* Automation unlock

### Good Unlock

A good unlock answers:

What did the player understand?

Example:

Warm Hollow unlock means:

* player learned Meadow creates Living Wood,
* Fire creates warmth,
* materials and essence create forms,
* placement gives a form its role.

### Bad Unlock

Avoid:

* arbitrary level gates,
* giant material costs,
* recipe shop unlocks,
* “collect 50 wood” endgame costs.

### Endgame Unlocks

Endgame should require:

* specific island state,
* specific god or elder spirit,
* specific component,
* high Satori,
* matching placement pattern,
* Codex mystery resolved.

Example:

#### Pagoda of Still Winds

Ritual:

* Lacquered Pillar + Ku Essence + Elder Wind Spirit

Context requirements:

* Meadow adjacent to Shrine,
* Resonance Bell built nearby,
* Tiny Shrine discovered,
* at least 3 housed spirits in the island cluster,
* Island Satori above threshold.

Effect:

* increases Satori cap,
* invites elder spirits,
* reduces unhappiness decay,
* unlocks Wind-Ku rituals.

## 17. Design Constraints

### Keep Resource Quantities Low

Avoid large costs.

Prefer:

* specific components,
* island context,
* spirit states,
* Satori thresholds,
* placement patterns.

Bad:

* 50 Living Wood + 25 Spirit Stone

Good:

* Lacquered Pillar + Great Seal + Ku Essence + happy elder spirit + island condition

### Keep Early Game Simple

First 10 minutes should teach:

* essence creates biome,
* biome creates material,
* biome invites spirit,
* spirit produces essence,
* spirit needs home,
* ritual discovers structure,
* structure houses spirit,
* housed spirit increases Satori.

Do not introduce:

* multiple islands,
* god spirits,
* spirit assistants,
* component rituals,
* advanced automation,
* harsh penalties.

### Keep Matching Local

Matching rules are island-specific.

A spirit or god reacts to its island.

Global balance should be handled through World Satori and completion, not through universal restrictions.

### Make Every Failure a Branch

There should be no dead invalid state.

Instead of:

* Nothing happens.

Use:

* The wood warms, but does not yet know what shape to take.

Instead of:

* Wrong biome.

Use:

* This island has learned tension.

Instead of:

* God spirit lost forever.

Use:

* The god has withdrawn. A restoration path opens.

## 18. Implementation Model: High-Level Entities

### Resource

Types:

* Essence
* Material
* Memory
* Component, if components are inventory-based

Fields:

* id
* name
* type
* element tags
* material tags
* description
* Codex text

### Essence

Fields:

* element: Wind / Fire / Water / Earth / Ku

Used for:

* biome creation,
* rituals,
* island unlocks,
* structure activation.

### Material

Fields:

* source biome
* role tags
* related element tags
* discovery matrix

Example tags:

* shelter
* foundation
* warmth
* memory
* boundary
* invitation

### Biome

Fields:

* element identity
* material output
* invite table
* island interactions
* adjacency interactions
* Codex entries

### Spirit

Fields:

* element
* preferred biomes
* disliked island states
* housing needs
* essence output
* mood state
* assistant availability
* Codex entries

### Structure

Fields:

* discovered by ritual
* placement rules
* housing capacity
* Satori effects
* automation effects
* component identity
* island matching interactions

### Island

Fields:

* type
* local grid
* local Satori
* matching rules
* unique spirits
* unique materials
* god spirit path
* state
* memories
* Codex mysteries

### Ritual

Fields:

* slots: 3
* requires at least 1 essence
* all slots unique; no duplicate input identities
* input types allowed by progression
* context requirements
* priority
* result
* fallback result
* Codex hint

### Codex Entry

Fields:

* id
* title
* trigger conditions
* koan text
* hint level
* revealed practical info
* related discovery
* unresolved mystery status

## 19. Example Data: Warm Hollow
Discovery

Inputs:

* Living Wood
* Fire Essence

Slot rule:

* no duplicate inputs

Result:

* Warm Hollow

Placement result:

* On Meadow → Meadow Dwelling
* On Fire/Hearth → Scorched Hollow
* With Red Fox → Fox Den path
* With Hare → Hare Hollow path

Codex before:

> The fox circles the wood,
> but does not sleep beneath open sky.

Codex closer:

> The hollow is almost a home.
> It waits for warmth.

Codex after:

> When living wood accepted warmth,
> the hollow waited to learn where it belonged.

Effects:

* creates a shelter-form,
* teaches that placement determines structure role,
* can house Meadow-preferred spirits after becoming Meadow Dwelling.

## 20. Example Data: Rain-Fire Tension

Trigger:

* Player places Fire biome on Rain Island.

If Fire is far from shrine:

* Rain Kami becomes Uneasy.
* Island Satori minor penalty.
* Steam-related Codex entry appears.

If Fire touches Rain Shrine:

* Rain Kami becomes Offended.
* Rain blessing disabled.
* Strong Codex warning appears.

Codex:

> The Rain Kami does not hate flame.
> It hates flame that forgets to bow.

Recovery hint:

> Teach the flame to kneel in a bowl of stone.

Possible recovery:

* Stone Basin + Water Essence + Rain Memory → Reconciliation Shrine

Possible unlocks:

* Steam Spring
* Storm Frog
* Rain-Fire Memory
* Reconciliation Shrine

## 21. North Star

Satori should feel like learning a sacred ecosystem language.

The player should not think:

> What recipe do I need?

The player should think:

> What does this island want?
> What does this spirit need?
> What does this material become when touched by this element?
> What happens if I create harmony?
> What happens if I create tension?
> What can be restored?

The game is about discovery, care, placement and consequence.

Final design mantra:

> Essence creates places.
> Biomes invite life.
> Materials remember form.
> Spirits reveal desire.
> Structures make promises.
> Islands keep vows.
> Satori remembers everything.
