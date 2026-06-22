# Satori — Rituals, Materials & Unlocks Reference

This reference supports [master_plan.md](master_plan.md). It describes the target direction for Satori's discovery systems: the crafting grid is no longer the design model. Player-facing creation happens through rituals, materials, spirits, island context and Codex hints.

The current implementation may still contain older `recipe_*`, `BiomeType` and crafting-grid terminology. Treat those as migration names until the code and catalog data are updated.

---

## Design Principles

* Rituals replace crafting-grid recipes.
* Essence is elemental intent, not generic currency.
* Materials are meaningful physical forms, not bulk resources.
* Spirits may assist rituals, but are never consumed.
* Structures are discovered forms, not shop purchases.
* Islands own their local matching, tension, restoration and god-spirit rules.
* Unlocks should prove understanding, not ask for large stacks.
* Every valid no-duplicate material + element combination should produce an unlock, hint, lesser form or state.
* Failed or tense actions should branch into new state, memory or restoration content.

---

## Element Language

| Player-Facing Element | Godai Name | Legacy Element ID | Ritual Verb | Basic Seed Result |
|-----------------------|------------|-------------------|-------------|-------------------|
| Earth | Chi | `CHI` / `0` | stabilize, protect, contain, anchor | Stonefield Seed |
| Water | Sui | `SUI` / `1` | soothe, heal, store, remember, flow | Pond Seed |
| Fire | Ka | `KA` / `2` | warm, activate, transform, energize | Hearth Seed |
| Wind | Fū | `FU` / `3` | invite, move, spread, call, open | Meadow Seed |
| Ku | Kū | `KU` / `4` | space, mystery, integration, islands | Island or shrine-related seed |

Early progression exposes Earth, Water, Fire and Wind. Ku is locked, dormant or mystery-only until a deep ritual path unlocks it.

---

## Ritual Grammar

Rituals have up to three slots.

Core rules:

* At least one slot must be essence.
* Each ritual slot must be unique.
* No duplicate materials, essences, components or spirit assistants are allowed.
* Later progression adds structures, components and spirit assistants as valid slots.
* Spirits are assistants, not ingredients, and are never consumed.
* Spirit assistants can replace elemental intent or resonate with matching essence in advanced rituals.
* Context can matter as much as input: island type, spirit state, Satori, placement and prior Codex discoveries may all gate results.
* Rituals create forms; placement and context give those forms their final role or variant.

Ritual result types:

| Slot Pattern | Primary Use | Example |
|--------------|-------------|---------|
| 1 essence | Basic biome seed | Wind Essence → Meadow Seed |
| 2 essences | Hybrid biome seed | Wind + Fire → Sungrass Seed |
| 1 material + 1 essence | Simple early form | Living Wood + Fire Essence → Warm Hollow |
| 2 materials + 1 essence | Physical structure | Living Wood + Spirit Stone + Fire Essence → Clay Hearth |
| 1 material + 2 essences | Infused structure or advanced variant | Living Wood + Fire Essence + Ku Essence → Foxfire Hollow structure |
| material + component + essence | Upgrade or advanced component | Living Wood + Tiny Shrine + Ku Essence → Sacred Grove Marker |
| component + essence + spirit | Spirit-specific structure | Tiny Shrine + Ku Essence + Red Fox → Foxfire Shrine |
| component + essence + elder spirit | Island or god-spirit ritual | Great Seal + Ku Essence + Elder Wind Spirit → Pagoda of Still Winds |

Fallbacks should be meaningful. If the right spirit or context is missing, a ritual can create a lesser form, memory, hint or partial discovery instead of doing nothing.

---

## Seed Rituals

### Basic Biomes

| `ritual_id` | Inputs | Produces | Biome | Progression |
|-------------|--------|----------|-------|-------------|
| `ritual_wind_seed` | Wind Essence | Meadow Seed | Meadow | Early |
| `ritual_fire_seed` | Fire Essence | Hearth Seed | Hearth | Early |
| `ritual_water_seed` | Water Essence | Pond Seed | Pond | Early |
| `ritual_earth_seed` | Earth Essence | Stonefield Seed | Stonefield | Early |
| `ritual_ku_seed` | Ku Essence | Island Seed or shrine-related seed | Island / Shrine path | Deep ritual unlock |

### Basic Hybrid Biomes

| `ritual_id` | Inputs | Produces | Biome |
|-------------|--------|----------|-------|
| `ritual_wind_fire_seed` | Wind + Fire | Sungrass Seed | Sungrass Field |
| `ritual_wind_water_seed` | Wind + Water | Rain Meadow Seed | Rain Meadow |
| `ritual_wind_earth_seed` | Wind + Earth | Rooted Steppe Seed | Rooted Steppe |
| `ritual_fire_water_seed` | Fire + Water | Steam Spring Seed | Steam Spring |
| `ritual_fire_earth_seed` | Fire + Earth | Ember Crag Seed | Ember Crag |
| `ritual_water_earth_seed` | Water + Earth | Grove Seed | Grove |

### Ku Hybrid Biomes

| `ritual_id` | Inputs | Produces | Biome |
|-------------|--------|----------|-------|
| `ritual_wind_ku_seed` | Wind + Ku | Whisper Hollow Seed | Whisper Hollow |
| `ritual_fire_ku_seed` | Fire + Ku | Foxfire Hollow Seed | Foxfire Hollow |
| `ritual_water_ku_seed` | Water + Ku | Mist Pool Seed | Mist Pool |
| `ritual_earth_ku_seed` | Earth + Ku | Rune Garden Seed | Rune Garden |

---

## Materials

Materials define what kind of form can be shaped.

| Material | Source | Role Tags | Example Rituals |
|----------|--------|-----------|-----------------|
| Living Wood | Meadow | shelter, growth, soft structure | Warm Hollow, Dew Bowl, Root Network, Wind Chime, Meadow Dwelling, Fox Den variant, Hare Hollow variant, Tiny Shrine |
| Spirit Stone | Stonefield | foundation, anchors, basins, containment | Hearth Stone, Stone Basin, Foundation Marker, Resonance Cairn, Rune Marker |
| Ember Clay | Hearth | warmth, kilns, transformation, heat storage | Kiln Heart, Steam Bowl, Clay Anchor, Ember Bellows, Moonflame |
| Reed Fiber | Pond or marsh-like biome | softness, nests, comfort, flexible connection | Steam Weave, Reed Nest, Reed Mat, Reed Flute, Dream Hammock |
| Mist Thread | Mist Pool or Water + Ku biome | dreams, memory, soft paths, hidden connection | Whisper Path, Veil Gate, Dream Hammock |
| Rune Stone | Shrine or Earth + Ku biome | ritual law, seals, boundaries, advanced unlocks | Great Seal, Binding Marker, Memory Rune |
| Moon Resin | Ku-aligned island or Shrine biome | refinement, blessing, lacquer, sacred upgrade | Lacquered Pillar, Moonflame, Blessing Lacquer |
| Echo Crystal | Mountain, Wind + Earth biome or advanced island | resonance, signals, long-range adjacency, pattern memory | Resonance Bell, Echo Pool, Oracle Lens |
| Sungrass | Wind + Fire biome | speed, brightness, joy, fox movement, radiant path | Sun Kite, Foxfire Trail, Golden Dewbed |
| Ash Silk | Fire + Ku biome or late island state | protection, restoration after loss, gentle scars | Soothe Veil, Phoenix Wrap, Spirit Mantle |

---

## First 10 Minutes Critical Path

| Step | Player Action | World Result | Teaches |
|------|---------------|--------------|---------|
| 1 | Perform Wind ritual and plant Meadow Seed | Meadow blooms | Essence becomes seeds; seeds create biomes |
| 2 | Wait for Meadow output and harvest it | Living Wood enters inventory | Biomes generate materials; materials must be harvested |
| 3 | Let the Meadow invite life | Red Fox appears | Biomes invite spirits; spirits produce essence |
| 4 | Leave Red Fox unhoused long enough to notice need | Red Fox becomes restless | Spirits have needs; unrest affects Satori |
| 5 | Use Living Wood + Fire Essence | Warm Hollow discovered | Rituals create forms |
| 6 | Place Warm Hollow on a Meadow tile | Meadow Dwelling forms; Red Fox can become housed | Placement gives forms their role |
| 7 | Use Fire Essence or Wind + Fire | Hearth or Sungrass direction opens | Spirits unlock new biome directions |

The first crafted form is Warm Hollow. When placed on Meadow it becomes Meadow Dwelling. Fox Den and Hare Hollow are flavor or specialization paths for Meadow spirits, not the base housing category.

---

## Structure Rituals

### Early Living Wood Structures

Living Wood is the first material family. In the opening phase, every Living Wood + basic element ritual should give the player a meaningful structure.

| Structure | Discovery Inputs | Effect | Codex Direction |
|-----------|------------------|--------|-----------------|
| Warm Hollow | Living Wood + Fire Essence | Base shelter-form. Its final role is decided by placement and spirit context | "A warm hollow is still a hollow, whoever comes to rest there." |
| Dew Bowl | Living Wood + Water Essence | Increases Wind Essence storage cap; later may soothe visiting spirits | "A bowl of dew teaches the wind where to rest." |
| Root Network | Living Wood + Earth Essence | Increases material generation speed for nearby Meadow tiles; later may route harvested materials toward storage | "Roots do not hurry by running. They hurry by already being there." |
| Wind Chime | Living Wood + Wind Essence | Grants freedom/flow; improves invite speed and can auto-harvest nearby Living Wood from Meadow tiles | "The meadow has a voice only wind can teach it." |
| Fox Den variant | Meadow Dwelling + Fire Essence + Red Fox | Red Fox-specialized dwelling or later upgrade | "The fox does not ask for walls. It asks for a warm hollow." |
| Hare Hollow variant | Meadow Dwelling + Earth Essence + Hare | Hare-specialized dwelling or later upgrade | "Four soft steps return to one hidden hollow." |
| Tiny Shrine | Living Wood + Ku Essence | Increases rare visitors; opens deeper ritual hints | "A small shrine is not small to a spirit that has nowhere to bow." |

#### Warm Hollow Placement Outcomes

| Placement / Context | Outcome | Notes |
|---------------------|---------|-------|
| Warm Hollow on Meadow | Meadow Dwelling | Houses Meadow-preferred spirits such as Red Fox, Hare, Meadow Lark, Golden Bee or Field Mouse |
| Warm Hollow on Fire / Hearth biome | Scorched Hollow | Fire-touched shelter; opens Foxfire tension path, may unsettle soft Meadow spirits |
| Warm Hollow with Red Fox present | Fox Den variant | Red Fox-specialized upgrade path |
| Warm Hollow with Hare present | Hare Hollow variant | Needs Earth or Water support if heat pressure is high |
| Warm Hollow near Water support | Steam-Softened Shelter | Recovery/soothing path for overheated shelter |
| Warm Hollow near Earth support | Rooted Hollow | Safer shelter; reduces fire-tension risk |

### Early Reed Fiber Structures

Reed Fiber is the first Water material family. It turns elements into comfort, flow control and soft connection.

| Structure | Discovery Inputs | Effect | Codex Direction |
|-----------|------------------|--------|-----------------|
| Steam Weave | Reed Fiber + Fire Essence | Converts small Fire/Water tension into productive Steam hints; later supports Steam Spring paths | "A reed can hold warmth without becoming ash." |
| Reed Nest | Reed Fiber + Water Essence | Houses or comforts Water-preferred spirits; increases Water Essence storage cap | "A reed bends so another may rest." |
| Reed Mat | Reed Fiber + Earth Essence | Stabilizes wet or marsh edges; reduces placement friction around Pond/Wetlands clusters | "Soft ground becomes kind when it learns where feet will fall." |
| Reed Flute | Reed Fiber + Wind Essence | Calls Water/Wind spirits faster; improves invitation around Pond, Rain Meadow or Wetlands | "A hollow reed is not empty. It is waiting for breath." |
| Dream Hammock | Reed Fiber + Ku Essence | Deep ritual comfort structure; supports dream, memory or Mist Thread paths | "Sleep is a bridge when the mist chooses to hold it." |

### Early Spirit Stone Structures

Spirit Stone is the first Stone/Earth material family. It turns elements into containment, foundation and resonance.

| Structure | Discovery Inputs | Effect | Codex Direction |
|-----------|------------------|--------|-----------------|
| Hearth Stone | Spirit Stone + Fire Essence | Stores warmth; increases Fire Essence storage cap or makes nearby Fire structures more reliable | "Stone remembers heat after flame has moved on." |
| Stone Basin | Spirit Stone + Water Essence | Contains water; calms nearby spirits and helps Rain-Fire recovery paths | "Water rests more deeply when stone agrees to hold it." |
| Foundation Marker | Spirit Stone + Earth Essence | Increases local structure stability and supports larger footprints | "A foundation is a promise the island can stand on." |
| Resonance Cairn | Spirit Stone + Wind Essence | Extends adjacency or signal range; helps distant structures count as softly connected | "Wind circles stone until distance learns to listen." |
| Rune Marker | Spirit Stone + Ku Essence | Deep boundary component; opens seal, memory and sacred-placement rituals | "A marked stone is a boundary that has learned its name." |

### Early Ember Clay Structures

Ember Clay is the first Fire material family. It turns elements into transformation, heat handling and production.

| Structure | Discovery Inputs | Effect | Codex Direction |
|-----------|------------------|--------|-----------------|
| Kiln Heart | Ember Clay + Fire Essence | Speeds Fire-material generation and unlocks transformation-oriented crafting paths | "Clay remembers fire and teaches warmth to stay." |
| Steam Bowl | Ember Clay + Water Essence | Converts excess heat into steam; supports Steam Spring, recovery and Rain-Fire tension paths | "Boiling is not anger when the bowl knows patience." |
| Clay Anchor | Ember Clay + Earth Essence | Stabilizes heated structures; reduces quenching/collapse risk around Fire clusters | "Warmth stays gentle when earth gives it a shape." |
| Ember Bellows | Ember Clay + Wind Essence | Speeds Fire structure production cycles and spreads warmth influence through adjacent tiles | "Wind does not only scatter flame. It can teach it to breathe." |
| Moonflame | Ember Clay + Ku Essence | Deep Fire-Ku component; supports blessing, Ash Silk and sacred transformation paths | "A moonlit ember burns without needing to devour." |

### Material Family Examples

| Structure or Component | Discovery Inputs | Notes |
|------------------------|------------------|-------|
| Rain Basin upgrade | Stone Basin + Reed Fiber + Water Essence | Stronger calming structure for Rain recovery paths |
| Rooted Foundation upgrade | Foundation Marker + Living Wood + Earth Essence | Stabilizes larger structures and island clusters |
| Clay Hearth upgrade | Kiln Heart + Spirit Stone + Fire Essence | Enables stronger transformation-oriented Fire structures |
| Soft Nest upgrade | Reed Nest + Living Wood + Water Essence | Improves Water-spirit comfort and housing quality |
| Resonance Bell | Echo Crystal + Spirit Stone + Wind Essence | Supports long-range adjacency and signal patterns |
| Great Seal | Rune Stone + Moon Resin + Ku Essence | Advanced boundary component for god or island rituals |
| Lacquered Pillar | Moon Resin + Living Wood + Earth Essence | Endgame component candidate |

### Automation Structures

| Structure | Discovery Inputs | Effect | Island Interaction |
|-----------|------------------|--------|--------------------|
| Root Gatherer | Living Wood + Spirit Stone + Wind Essence | Automatically collects Living Wood from nearby Meadow | Good on Meadow Island; neutral on production islands; harmful on Shrine Island unless sanctified |
| Sanctified Harvester | Root Gatherer + Ku Essence + Tiny Shrine | Quieter automation with lower sacred-island Satori penalty | Intended for Shrine or memory-heavy islands |

Automation is a midgame transition. It exists because gardens become too large to harvest by hand, not because early play should be idle.

---

## Spirits and Assistants

Spirits are living ecosystem agents.

Spirit states:

* Visiting
* Housed
* Happy
* Restless
* Unhappy
* Wandering
* Dormant
* Elder
* Assistant-ready

Assistant examples:

| Spirit | Counts As | Example Assistant Ritual |
|--------|-----------|--------------------------|
| Red Fox | Fire | Living Wood + Earth Essence + Red Fox → Cozy Fox Den |
| Crane Spirit | Wind | Mist Thread + Wind component + Crane Spirit → Whisper Path variant |
| Frog Spirit | Water | Stone Basin + Ku Essence + Frog Spirit → Rain Kami invitation path |
| Tanuki | Earth | Foundation component + Earth Essence + Tanuki → Hidden Storehouse |
| Bell Spirit | Ku | Tiny Shrine + Ku Essence + Bell Spirit → Memory Bell |

---

## Island and God-Spirit Ritual Context

All matching rules are island-local.

| Island | Theme | Materials | Example Rules |
|--------|-------|-----------|---------------|
| Meadow Island | openness, first homes, invitation, fox/hare relationship | Living Wood, later Sungrass | Housed spirits near Meadow score; Meadow Dwelling near Meadow and Hearth scores; overcrowding reduces Satori |
| Rain Island | calm, flow, recovery, memory | Reed Fiber, Mist Thread, Dew Pearl | Water biomes like being connected; Fire near Rain Shrine creates tension; Stone Basin helps recovery |
| Ember Island | warmth, transformation, foxfire, active rituals | Ember Clay, Ash Silk, Sungrass | Fire clusters score; too much Water creates quenching tension unless transformed into Steam |
| Shrine Island | silence, memory, Ku, sacred patterns | Rune Stone, Moon Resin | Ku structures score; noisy automation harms harmony unless sanctified |

God spirits define island vows. Conflict does not instantly fail the player; it creates a state.

Example:

* Rain Kami becomes Uneasy when Fire enters Rain Island.
* Rain Kami becomes Offended if Fire touches Rain Shrine.
* Continued tension can make Rain Kami withdraw.
* Withdrawal opens restoration, memory and reconciliation paths.

---

## Codex Hints

The Codex hints before it explains.

| Hint Level | Style | Example |
|------------|-------|---------|
| 1 | Poetic | "The fox circles the wood, but does not sleep beneath open sky." |
| 2 | Directed | "The fox wants warmth, not only shelter." |
| 3 | Practical | "Try shaping Living Wood with warm intent while the Red Fox is near." |
| 4 | Explicit and optional | "Ritual suggestion: Living Wood, Fire Essence." |

Level 4 hints should require a deliberate meditate-style action.

---

## Current Implemented Catalog Snapshot

This section mirrors the current code catalog so `recipes.md` remains a complete unlockable reference while the design migrates toward rituals and materials.

Primary code sources:

* `src/seeds/recipes/*.tres`
* `src/seeds/BuildingRecipeCatalog.gd`
* `src/biomes/discovery_catalog_data.gd`
* `src/biomes/patterns/**/*.tres`
* `src/spirits/spirit_catalog_data.gd`

### Current Housing Rule

Current code does not require species-specific houses. `SpiritService` collects completed non-shrine building tiles, then assigns spirits to houses on the same island. It tries preferred-biome houses first, then any available house on that island.

Design implication: Fox Den should not be the base Meadow house. Meadow Dwelling is the base category; Fox Den and Hare Hollow are spirit-specific variants or upgrades.

### Current Seed Recipes

| `recipe_id` | Tier | Elements | Produces Current Biome | Unlock |
|-------------|------|----------|------------------------|--------|
| `recipe_chi` | 1 | CHI / Earth | Stone | early |
| `recipe_sui` | 1 | SUI / Water | River | early |
| `recipe_ka` | 1 | KA / Fire | Ember Field | early |
| `recipe_fu` | 1 | FU / Wind | Meadow | early |
| `recipe_ku` | 1 | KU | Ku | currently implemented; target design treats Ku as deep unlock |
| `recipe_chi_sui` | 2 | CHI + SUI | Wetlands | early/current |
| `recipe_chi_ka` | 2 | CHI + KA | Badlands | early/current |
| `recipe_chi_fu` | 2 | CHI + FU | Whistling Canyons | early/current |
| `recipe_sui_ka` | 2 | SUI + KA | Prismatic Terraces | early/current |
| `recipe_sui_fu` | 2 | SUI + FU | Frostlands | early/current |
| `recipe_ka_fu` | 2 | KA + FU | The Ashfall | early/current |
| `recipe_chi_ku` | 2 | CHI + KU | Sacred Stone | requires Ku access in target design |
| `recipe_sui_ku` | 2 | SUI + KU | Moonlit Pool | requires Ku access in target design |
| `recipe_ka_ku` | 2 | KA + KU | Ember Shrine | requires Ku access in target design |
| `recipe_fu_ku` | 2 | FU + KU | Cloud Ridge | requires Ku access in target design |

### Current Craftable Building Recipes

These are registered in `BuildingRecipeCatalog.gd`. They are current implementation unlockables, but their token patterns use duplicates and therefore conflict with the target ritual rule that no slot can duplicate another slot. Treat this table as migration input, not final ritual grammar.

| `recipe_id` | Building | Current Tokens | Discovery Entry | Migration Note |
|-------------|----------|----------------|-----------------|----------------|
| `building_house` | House | CHI + CHI + FU | `disc_building_house` | replace with distinct ritual inputs |
| `building_granary` | Granary | SUI + SUI + CHI | `disc_building_granary` | replace with distinct ritual inputs |
| `building_watchtower` | Watchtower | FU + FU + CHI | `disc_building_watchtower` | replace with distinct ritual inputs |
| `building_pavilion` | Pavilion | FU + FU + SUI | `disc_building_pavilion` | replace with distinct ritual inputs |
| `building_forge` | Forge | KA + KA + CHI | `disc_building_forge` | replace with distinct ritual inputs |

### Current Discovery Unlocks

#### Tier 1 Dwelling / Pattern Discoveries

These are currently `effect_type = dwelling` with `housing_capacity = 1`.

| `discovery_id` | Display Name | Current Trigger Summary | Notes |
|----------------|--------------|-------------------------|-------|
| `disc_river` | The River | ≥10 River tiles | dwelling |
| `disc_deep_stand` | The Deep Stand | ≥10 Meadow tiles, no adjacent Ember Field | dwelling |
| `disc_glade` | The Glade | Meadow center surrounded by Stone N/S/E/W | dwelling |
| `disc_mirror_archipelago` | Mirror Archipelago | ≥5 River + ≥5 Meadow within radius 4 | dwelling |
| `disc_barren_expanse` | Barren Expanse | ≥25 Meadow tiles, no River | dwelling |
| `disc_great_reef` | Great Reef | ≥15 River + ≥3 Ember Field within radius 5 | dwelling |
| `disc_lotus_pond` | Lotus Pond | River center surrounded by Meadow N/S/E/W | dwelling |
| `disc_mountain_peak` | The Mountain Peak | ≥10 Stone tiles | dwelling |
| `disc_boreal_forest` | Boreal Forest | ≥5 Meadow + ≥5 Frostlands within radius 3 | dwelling |
| `disc_peat_bog` | The Peat Bog | ≥20 Wetlands tiles | dwelling |
| `disc_obsidian_expanse` | Obsidian Expanse | The Ashfall cluster + ≥3 River within radius 2; requires `disc_river` | dwelling |
| `disc_waterfall` | The Waterfall | River + Mountain Peak prerequisites + ≥1 Ember Field nearby | dwelling |
| `disc_wayfarer_torii` | Wayfarer Torii | current catalog tier 1 structure | `effect_type = swiftness` |

#### Tier 2 Structural Discoveries

| `discovery_id` | Display Name | Current Trigger Summary | Current Effect |
|----------------|--------------|-------------------------|----------------|
| `disc_origin_shrine` | Origin Shrine | origin shrine pattern/build path | `dropoff` |
| `disc_bridge_of_sighs` | Bridge of Sighs | Ember Field → River → Ember Field line | `swiftness` |
| `disc_lotus_pagoda` | Lotus Pagoda | ≥4 Wetlands tiles | `storage` |
| `disc_monks_rest` | Monk's Rest | Meadow center enclosed by Stone shape | `tending_boost` |
| `disc_star_gazing_deck` | Star-Gazing Deck | Ember Field compound; requires `disc_mountain_peak` | `storage` |
| `disc_sun_dial` | Sun-Dial | Ember Field with nearby Meadow | `tending_boost` |
| `disc_whale_bone_arch` | Whale-Bone Arch | The Ashfall U-shape | `swiftness` |
| `disc_echoing_cavern` | Echoing Cavern | Ember Field ring around empty center | `dropoff` |
| `disc_bamboo_chime` | Bamboo Chime | Frostlands line | `guidance_lantern` |
| `disc_floating_pavilion` | Floating Pavilion | isolated Wetlands tile | `dropoff` |
| `disc_iwakura_sanctum` | Iwakura Sanctum | ≥4 Sacred Stone tiles | `swiftness` |
| `disc_misogi_spring_shrine` | Misogi Spring Shrine | ≥4 Moonlit Pool tiles | `guidance_lantern` |
| `disc_eternal_kagura_hall` | Eternal Kagura Hall | ≥4 Ember Shrine tiles | `tending_boost` |

#### Tier 3 Monument Discoveries

| `discovery_id` | Display Name | Current Trigger Summary | Current Effect |
|----------------|--------------|-------------------------|----------------|
| `disc_heavenwind_torii` | Heavenwind Torii | ≥4 Cloud Ridge tiles | `great_torii`, burst 500 |
| `disc_pagoda_of_the_five` | Pagoda of the Five | ≥4 Moonlit Pool tiles | `pagoda_passive`, +4 housing capacity |
| `disc_void_mirror` | Void Mirror | ≥4 River tiles | `void_mirror`, multiplier 1.5 |
| `disc_great_torii` | Great Torii | ≥4 Cloud Ridge tiles | `great_torii`, burst 500 |

Known current gap: `disc_heavenwind_torii` and `disc_great_torii` share the same trigger condition.

### Current Spirit Unlocks

All 34 spirits below are present in `SpiritCatalogData`. Preferred biomes are used by current housing assignment and wandering behavior.

| `spirit_id` | Display Name | Tier | Current Pattern Trigger | Preferred Biomes | Gift | Relationship |
|-------------|--------------|------|-------------------------|------------------|------|--------------|
| `spirit_red_fox` | Red Fox | 1 | 3 Meadow tiles in a triangle | Meadow, Badlands | None | Tension: Hare |
| `spirit_mist_stag` | Mist Stag | 2 | Wetlands compound; requires `disc_deep_stand` | Meadow, Wetlands | `KU_UNLOCK` | - |
| `spirit_emerald_snake` | Emerald Snake | 1 | 7 Stone tiles in a line | Stone | None | - |
| `spirit_owl_of_silence` | Owl of Silence | 1 | Stone with Prismatic Terraces proximity | Stone, Ember Field, Prismatic Terraces | None | - |
| `spirit_tree_frog` | Tree Frog | 1 | Stone with Wetlands proximity | Stone, River, Wetlands | None | - |
| `spirit_white_heron` | White Heron | 1 | 5 River tiles in a line | River, Wetlands | None | - |
| `spirit_koi_fish` | Koi Fish | 1 | 2x2 River square | River | None | Harmony: Blue Kingfisher |
| `spirit_river_otter` | River Otter | 1 | ≥10 River tiles | River, Wetlands | `TIER3_RECIPE` → `recipe_chi_sui_fu` | - |
| `spirit_blue_kingfisher` | Blue Kingfisher | 1 | ≥3 River tiles | River | None | Harmony: Koi Fish |
| `spirit_dragonfly` | Dragonfly | 1 | River with nearby Meadow | River, Meadow, Wetlands | None | - |
| `spirit_mountain_goat` | Mountain Goat | 1 | Stone compound; requires `disc_mountain_peak` | Stone, Whistling Canyons | None | - |
| `spirit_stone_golem` | Stone Golem | 1 | ≥9 Stone tiles | Stone | None | - |
| `spirit_granite_ram` | Granite Ram | 1 | ≥20 Ember Field tiles | Ember Field | None | - |
| `spirit_sun_lizard` | Sun Lizard | 1 | Ember Field with nearby Meadow | Ember Field, Badlands, The Ashfall | None | - |
| `spirit_rock_badger` | Rock Badger | 1 | ≥3 The Ashfall tiles | Ember Field, Prismatic Terraces, The Ashfall | None | - |
| `spirit_golden_bee` | Golden Bee | 1 | ≥10 Meadow tiles | Meadow, Whistling Canyons | None | - |
| `spirit_jade_beetle` | Jade Beetle | 1 | ≥15 Stone tiles | Stone, Meadow | None | - |
| `spirit_meadow_lark` | Meadow Lark | 1 | Meadow compound; requires `disc_glade` | Meadow | `GROWING_SLOT_EXPAND` | - |
| `spirit_field_mouse` | Field Mouse | 1 | Meadow touching Stone, River and Ember Field | Stone, River, Meadow, Wetlands | None | - |
| `spirit_hare` | Hare | 1 | 4 Meadow tiles in a line | Meadow, Stone | None | - |
| `spirit_marsh_frog` | Marsh Frog | 1 | 7 Wetlands tiles in a line | Wetlands, River | None | - |
| `spirit_peat_salamander` | Peat Salamander | 1 | Wetlands compound; requires `disc_peat_bog` | Wetlands, River | None | - |
| `spirit_swamp_crane` | Swamp Crane | 1 | Wetlands with nearby River and Stone | Wetlands, River, Stone | None | - |
| `spirit_murk_crocodile` | Murk Crocodile | 1 | River with nearby Wetlands | Wetlands, River | None | - |
| `spirit_mud_crab` | Mud Crab | 1 | Wetlands compound; requires `disc_great_reef` | Wetlands, River | None | - |
| `spirit_frost_owl` | Frost Owl | 1 | Frostlands compound; requires `disc_boreal_forest` | Frostlands, Stone | None | - |
| `spirit_boreal_wolf` | Boreal Wolf | 1 | Frostlands compound; requires `disc_boreal_forest` | Frostlands | None | Tension: Tundra Lynx |
| `spirit_tundra_lynx` | Tundra Lynx | 1 | Frostlands compound; requires `disc_river` | Frostlands, River | None | - |
| `spirit_ice_cavern_bat` | Ice Cavern Bat | 1 | Frostlands compound; requires `disc_great_reef` | Frostlands, Stone | None | - |
| `spirit_sky_whale` | Sky Whale | 4 | 1,000 total tiles balanced across macro-groups | Stone, River, Ember Field, Meadow, Wetlands, Badlands, Whistling Canyons, Prismatic Terraces, Frostlands, The Ashfall | None | - |
| `spirit_oyamatsumi` | Ōyamatsumi | 3 | ≥5 Sacred Stone; requires `disc_iwakura_sanctum` | Sacred Stone | None | - |
| `spirit_suijin` | Suijin | 3 | ≥5 Moonlit Pool; requires `disc_misogi_spring_shrine` | Moonlit Pool | None | - |
| `spirit_kagutsuchi` | Kagutsuchi | 3 | ≥5 Ember Shrine; requires `disc_eternal_kagura_hall` | Ember Shrine | None | - |
| `spirit_fujin` | Fūjin | 3 | ≥5 Cloud Ridge; requires `disc_heavenwind_torii` | Cloud Ridge | None | - |

---

## Legacy Migration Notes

The previous `recipes.md` described the implemented crafting-grid era. The target design above intentionally supersedes that framing.

Deprecated or migration-bound concepts:

* "Crafting grid" and "resonance grid" are no longer the core design language.
* Seed creation is ritual-driven, not slot-position-driven.
* The current `recipe_*` naming can stay as internal compatibility until a catalog migration is planned.
* Existing `BiomeType` constants can remain temporarily, but target biome names should follow the new ritual language.
* Existing spirit catalog entries remain useful content, but their triggers should eventually move toward island-local needs, materials, Satori states and Codex discoveries.

### Legacy Biome Mapping

| Legacy Biome / Constant | Old Role | Target Direction |
|-------------------------|----------|------------------|
| `STONE` | Earth single-element biome | Stonefield |
| `RIVER` | Water single-element biome | Pond or water-path biome |
| `EMBER_FIELD` | Fire single-element biome | Hearth |
| `MEADOW` | Wind single-element biome | Meadow |
| `WETLANDS` | Earth + Water hybrid | Grove, marsh path or Rain Island material source |
| `BADLANDS` | Earth + Fire hybrid | Ember Crag or tension-state variant |
| `WHISTLING_CANYONS` | Earth + Wind hybrid | Rooted Steppe or Echo Crystal path |
| `PRISMATIC_TERRACES` | Water + Fire hybrid | Steam Spring or transformation variant |
| `FROSTLANDS` | Water + Wind hybrid | Rain Meadow, mist or cold-state variant |
| `THE_ASHFALL` | Fire + Wind hybrid | Sungrass Field or Ash Silk tension variant |
| `SACRED_STONE` | Earth + Ku hybrid | Rune Garden or sacred Earth variant |
| `MOONLIT_POOL` | Water + Ku hybrid | Mist Pool |
| `EMBER_SHRINE` | Fire + Ku hybrid | Foxfire Hollow |
| `CLOUD_RIDGE` | Wind + Ku hybrid | Whisper Hollow |
| `KU` | Ku alone | Island seed or shrine-related deep ritual |

These mappings are design targets, not immediate code changes.

### Resolved Consistency Decisions

* Ku is not an ordinary starting element; early play uses Wind, Fire, Water and Earth.
* The first crafted shelter-form is Warm Hollow; Meadow Dwelling, Fox Den and Hare Hollow are placement/context outcomes.
* All ritual slots must be unique.
* Duplicate materials, essences, components and spirit assistants are never allowed inside one ritual.
* Spirit assistants can still resonate with matching essence when a ritual explicitly calls for that relationship.
* Spirits assist rituals without being consumed.
* Structures are placed on biomes, not empty tiles.

---

## Sources to Reconcile During Implementation

When the design migration reaches code, reconcile this file against:

* `src/seeds/recipes/*.tres`
* `src/seeds/BuildingRecipeCatalog.gd`
* `src/biomes/discovery_catalog_data.gd`
* `src/spirits/spirit_catalog_data.gd`
* existing specs that mention the seed crafting grid, especially `specs/019-seed-crafting-grid/`
