# Satori — Unlocks & Recipes Reference

Quick reference for all discoverable content in the game, organised by unlock category.
Use this alongside the catalog data files to verify completeness at a glance.

---

## Biome Index

| ID | `BiomeType` Constant | Godai Name | Element(s) |
|----|----------------------|------------|------------|
| 0  | `STONE`              | Chi (地)   | CHI alone  |
| 1  | `RIVER`              | Sui (水)   | SUI alone  |
| 2  | `EMBER_FIELD`        | Ka (火)    | KA alone   |
| 3  | `MEADOW`             | Fū (風)    | FU alone   |
| 4  | `WETLANDS`           | —          | CHI + SUI  |
| 5  | `BADLANDS`           | —          | CHI + KA   |
| 6  | `WHISTLING_CANYONS`  | —          | CHI + FU   |
| 7  | `PRISMATIC_TERRACES` | —          | SUI + KA   |
| 8  | `FROSTLANDS`         | —          | SUI + FU   |
| 9  | `THE_ASHFALL`        | —          | KA + FU    |
| 10 | `SACRED_STONE`       | Chi + Kū   | CHI + KU |
| 11 | `MOONLIT_POOL`       | Sui + Kū   | SUI + KU |
| 12 | `EMBER_SHRINE`       | Ka + Kū    | KA + KU  |
| 13 | `CLOUD_RIDGE`        | Fū + Kū    | FU + KU  |
| 14 | `KU`                 | Kū (空)    | KU alone                         |

---

## Seed Recipes

Recipes are **order-independent** — `SeedRecipeRegistry` sorts element IDs before lookup.
Tier 3 recipes are hidden until a spirit grants a `TIER3_RECIPE` gift.

### Tier 1 — Single Element (always available)

| `recipe_id`   | Elements        | Produces Biome (ID) | Biome Name    | Codex Hint |
|---------------|-----------------|---------------------|---------------|------------|
| `recipe_chi`  | CHI (0)         | 0 — Stone           | Stone         | "Cold and still, the bones of the earth." |
| `recipe_sui`  | SUI (1)         | 1 — River           | River         | "It finds its own way through stone." |
| `recipe_ka`   | KA (2)          | 2 — Ember Field     | Ember Field   | "Where heat remembers the shape of fire." |
| `recipe_fu`   | FU (3)          | 3 — Meadow          | Meadow        | "Grass that bends but does not break." |
| `recipe_ku`   | KU (4)          | 14 — Ku             | Ku            | "Void made tangible; silence with form." |

### Tier 2 — Two Elements (always available)

| `recipe_id`      | Elements           | Produces Biome (ID) | Biome Name    | Codex Hint |
|------------------|--------------------|---------------------|---------------|------------|
| `recipe_chi_sui` | CHI (0) + SUI (1)  | 4 — Wetlands        | Wetlands      | "Earth softened by patient, standing water." |
| `recipe_chi_ka`  | CHI (0) + KA (2)   | 5 — Badlands        | Badlands      | "Earth baked until it cracks beneath the sun." |
| `recipe_chi_fu`  | CHI (0) + FU (3)   | 6 — Whistling Canyons | Whistling Canyons | "Stone carved hollow by the breath of wind." |
| `recipe_sui_ka`  | SUI (1) + KA (2)   | 7 — Prismatic Terraces | Prismatic Terraces | "Water that boils with the memory of fire." |
| `recipe_sui_fu`  | SUI (1) + FU (3)   | 8 — Frostlands      | Frostlands    | "Water frozen still by the piercing wind." |
| `recipe_ka_fu`   | KA (2) + FU (3)    | 9 — The Ashfall     | The Ashfall   | "Where wind carries the glowing bones of fire." |

### Tier 2 (+Kū) — Unlocked after Mist Stag is summoned *(spec 016)*

Kū (element 4) becomes selectable only after the Mist Stag grants `KU_UNLOCK`.

| `recipe_id`      | Elements           | Produces Biome (ID) | Biome Name    |
|------------------|--------------------|---------------------|---------------|
| `recipe_chi_ku`  | CHI (0) + KU (4)   | 10 — Sacred Stone   | Sacred Stone  |
| `recipe_sui_ku`  | SUI (1) + KU (4)   | 11 — Moonlit Pool   | Moonlit Pool  |
| `recipe_ka_ku`   | KA (2) + KU (4)    | 12 — Ember Shrine   | Ember Shrine  |
| `recipe_fu_ku`   | FU (3) + KU (4)    | 13 — Cloud Ridge    | Cloud Ridge   |

### Tier 3 — Spirit-Taught (locked until spirit grants recipe)

| Elements                    | Produces Biome  | Taught By          | `gift_payload`       |
|-----------------------------|-----------------|--------------------|-----------------------|
| CHI (0) + SUI (1) + FU (3)  | Mossy Delta     | River Otter        | `recipe_chi_sui_fu`  |
| CHI (0) + SUI (1) + KA (2)  | Obsidian Shore  | Stone Serpent      | *(planned)*          |
| SUI (1) + FU (3) + KU (4)   | Mist Valley     | Mist Stag          | *(planned)*          |
| KA (2) + FU (3) + KU (4)    | Wildfire Veil   | Ember Fox          | *(planned)*          |
| CHI (0) + FU (3) + KU (4)   | Ancient Crag    | Mountain Golem     | *(planned)*          |
| KA (2) + SUI (1) + CHI (0)  | Ash Flat        | Sun-Lizard         | *(planned)*          |

### Growth Durations

| Tier          | Real-Time Duration |
|---------------|--------------------|
| Tier 1        | 10 minutes         |
| Tier 2        | 30 minutes         |
| Tier 3        | 2 hours            |
| Wild Seed     | 1 hour             |

---

## Tier 1 Discoveries (Biome Pattern Unlocks)

Discovered by the `PatternMatcher` when tile arrangements match a `PatternDefinition`.

| `discovery_id`            | Display Name          | Pattern Type       | Key Trigger                                              |
|---------------------------|-----------------------|--------------------|----------------------------------------------------------|
| `disc_river`              | The River             | CLUSTER            | ≥10 River tiles                                          |
| `disc_deep_stand`         | The Deep Stand        | CLUSTER            | ≥10 Meadow tiles, no adjacent Ember Field                |
| `disc_glade`              | The Glade             | SHAPE              | Meadow centre surrounded by Stone (N/S/E/W)              |
| `disc_mirror_archipelago` | Mirror Archipelago    | RATIO_PROXIMITY    | ≥5 River + ≥5 Meadow within radius 4                     |
| `disc_barren_expanse`     | Barren Expanse        | CLUSTER            | ≥25 Meadow tiles, no River                               |
| `disc_great_reef`         | Great Reef            | RATIO_PROXIMITY    | ≥15 River + ≥3 Ember Field within radius 5               |
| `disc_lotus_pond`         | Lotus Pond            | SHAPE              | River centre surrounded by Meadow (N/S/E/W)              |
| `disc_mountain_peak`      | The Mountain Peak     | CLUSTER            | ≥10 Stone tiles                                          |
| `disc_boreal_forest`      | Boreal Forest         | RATIO_PROXIMITY    | ≥5 Meadow + ≥5 Frostlands within radius 3                |
| `disc_peat_bog`           | The Peat Bog          | CLUSTER            | ≥20 Wetlands tiles                                       |
| `disc_obsidian_expanse`   | Obsidian Expanse      | COMPOUND           | The Ashfall cluster + ≥3 River within radius 2; needs `disc_river` first  |
| `disc_waterfall`          | The Waterfall         | COMPOUND           | River + Mountain Peak prereqs + ≥1 Ember Field in radius 1 |

**Audio keys** follow the pattern `stinger_<suffix>` (e.g. `stinger_river`, `stinger_deep_stand`).

### Tier 1 Building Class (Dwelling / House Discoveries)

All Tier 1 discoveries in `DiscoveryCatalogData` are tagged as `effect_type = dwelling` with:

- `cap_increase` metadata in catalog, but **game cap progression now uses unique discovery count**
- `housing_capacity = +1`
- `is_unique = false` (repeatable)

This means they function as repeatable house-class structure unlocks in progression terms. Houses do not directly add cap.

### Build-Mode Houses (Player-Placed)

| Buildable | Repeatable | Satori Cap Increase | Spirit Housing |
|-----------|------------|---------------------|----------------|
| Any completed non-shrine build tile (`is_building_complete = true` and `shrine_built = false`) | Yes | 0 | +1 house slot per tile |

These are the normal houses spirits can bind to. They are separate from shrine/landmark structures.

---

## Tier 1 and Tier 2 Structural Landmarks

| `discovery_id`            | Display Name          | Pattern Type       | Key Trigger                                                            | Repeatable | Catalog `cap_increase` |
|---------------------------|-----------------------|--------------------|------------------------------------------------------------------------|------------|------------------------|
| `disc_origin_shrine`      | Origin Shrine         | Build recipe       | Build mode: select Meadow and place on any non-Ku tile; once per island | Yes (`is_unique = false`) | +250 |
| `disc_wayfarer_torii`     | Wayfarer Torii        | Build recipe (Tier 1) | Build mode: rotatable **U** on any non-Ku biome tile group (ritual selector: Stone/Chi) | One per biome type (+ multi-color biome types) | +100 |
| `disc_bridge_of_sighs`    | Bridge of Sighs       | SHAPE              | Ember Field → River → Ember Field in a 3-tile line                     | Yes (`is_unique = false`) | +250 |
| `disc_lotus_pagoda`       | Lotus Pagoda          | CLUSTER            | ≥4 Wetlands tiles (2×2 square)                                         | Yes (`is_unique = false`) | +250 |
| `disc_monks_rest`         | Monk's Rest           | SHAPE              | Meadow centre enclosed by 6 Stone tiles                                | Yes (`is_unique = false`) | +250 |
| `disc_star_gazing_deck`   | Star-Gazing Deck      | COMPOUND           | ≥20 Ember Field; needs `disc_mountain_peak` first                      | Yes (`is_unique = false`) | +250 |
| `disc_sun_dial`           | Sun-Dial              | RATIO_PROXIMITY    | Ember Field with ≥5 Meadow neighbours within radius 1                  | Yes (`is_unique = false`) | +250 |
| `disc_whale_bone_arch`    | Whale-Bone Arch       | SHAPE              | The Ashfall in a U-shape (5 tiles)                                     | Yes (`is_unique = false`) | +250 |
| `disc_echoing_cavern`     | Echoing Cavern        | SHAPE              | 6 Ember Field tiles around an empty centre cell                        | Yes (`is_unique = false`) | +250 |
| `disc_bamboo_chime`       | Bamboo Chime          | SHAPE              | 5 Frostlands tiles in a straight line                                  | Yes (`is_unique = false`) | +250 |
| `disc_floating_pavilion`  | Floating Pavilion     | SHAPE              | Single Wetlands tile with no adjacent land biomes                      | Yes (`is_unique = false`) | +250 |
| `disc_iwakura_sanctum`    | Iwakura Sanctum       | CLUSTER            | ≥4 Sacred Stone tiles *(spec 016)*                                     | Yes (`is_unique = false`) | +250 |
| `disc_misogi_spring_shrine` | Misogi Spring Shrine | CLUSTER           | ≥4 Moonlit Pool tiles *(spec 016)*                                     | Yes (`is_unique = false`) | +250 |
| `disc_eternal_kagura_hall` | Eternal Kagura Hall  | CLUSTER            | ≥4 Ember Shrine tiles *(spec 016)*                                     | Yes (`is_unique = false`) | +250 |

### Repeatable Cap-Increase Structures (Quick View)

| Group | Example IDs | Repeatable | Cap Gain Each |
|-------|-------------|------------|---------------|
| Unique discovery unlocks (`disc_*`) | Any discovery ID recorded once | N/A | +50 once per unique discovery |

Cap rule in game:

- Houses do not increase cap.
- Structures do not stack cap directly from placement count.
- Each unique discovery (`disc_*`) increases cap by +50 exactly once.

### Structure Build Recipes (Selector vs Target Biome)

| Structure | Ritual Selector (selected biome) | Target Placement Biome | Shape | Resulting Variant |
|-----------|----------------------------------|------------------------|-------|-------------------|
| Wayfarer Torii (`disc_wayfarer_torii`) | Stone / Chi | Any non-Ku biome (single or multi-color biome IDs) | Rotatable U (3 tiles) | Biome-scoped Torii (e.g. water torii, meadow torii, stone torii, ember torii) |
| Origin Shrine (`disc_origin_shrine`) | Meadow / Fu | Any non-Ku biome | Single tile build project | One origin shrine per island |
| Lotus Pagoda (`disc_lotus_pagoda`) | Meadow / Fu | Wetlands | 2x2 / parallelogram (4 tiles) | Wetland pagoda |

Wayfarer Torii biome rule:

- A single Wayfarer Torii is allowed per biome type (Stone, River, Meadow, Ember Field, and multi-color biome IDs).
- If biome changes/merges create two Torii on the same biome type, one is removed automatically.
- Discovery-state changes that do not change tile biome (for example Meadow related discovery overlays such as Deep Stand) do not remove a valid Torii.

**Audio keys** follow the pattern `stinger_<suffix>` (e.g. `stinger_origin_shrine`).

---

## Tier 3 Monument Discoveries

Tier 3 monuments are unique (one per garden) and grant Satori cap +1000.

| `discovery_id`            | Display Name          | Pattern Type | Key Trigger                      | Effect            |
|---------------------------|-----------------------|--------------|----------------------------------|-------------------|
| `disc_heavenwind_torii`   | Heavenwind Torii      | CLUSTER      | ≥4 Cloud Ridge tiles *(spec 016)*| Great Torii burst |
| `disc_pagoda_of_the_five` | Pagoda of the Five    | CLUSTER      | ≥4 Moonlit Pool tiles            | Pagoda passive +5/min, 4 spirit slots |
| `disc_void_mirror`        | Void Mirror           | CLUSTER      | ≥4 River tiles                   | Void Mirror multiplier ×1.5 |
| `disc_great_torii`        | Great Torii           | CLUSTER      | ≥4 Cloud Ridge tiles *(⚠ trigger shared with Heavenwind Torii — see note)* | Great Torii burst |

**Note**: `disc_heavenwind_torii` and `disc_great_torii` currently share the same trigger condition (≥4 Cloud Ridge). This is a known gap to be resolved in a future spec.

**Audio keys** follow the pattern `stinger_<suffix>` (e.g. `stinger_heavenwind_torii`).

---

## Spirit Animals

Spirits are summoned when the garden matches a spirit's `PatternDefinition`. Spirits with a non-zero `gift_type` grant a permanent unlock on first summon.

### Gift Types

| Value | Constant              | Effect                                        |
|-------|-----------------------|-----------------------------------------------|
| 0     | `NONE`                | No gift — visual/audio event only             |
| 1     | `KU_UNLOCK`           | Unlocks Kū element in the Seed Mix UI         |
| 2     | `TIER3_RECIPE`        | Unlocks a tier 3 seed recipe (`gift_payload`) |
| 3     | `POUCH_EXPAND`        | +1 Seed Pouch capacity                        |
| 4     | `GROWING_SLOT_EXPAND` | +1 Growing Slot capacity                      |
| 5     | `CODEX_REVEAL`        | Force-reveals a Codex entry (`gift_payload`)  |

### Spirit Catalog (34 spirits)

| # | `spirit_id`             | Display Name       | Pattern Trigger (summary)                              | Gift                         | Tier | Harmony / Tension       |
|---|-------------------------|--------------------|--------------------------------------------------------|------------------------------|------|-------------------------|
| 1 | `spirit_red_fox`        | Red Fox            | Meadow triangle (3 tiles)                              | None                         | 1    | Tension: Hare           |
| 2 | `spirit_mist_stag`      | Mist Stag          | ≥5 Wetlands + `disc_deep_stand` prereq                 | **KU_UNLOCK** (1)            | 2    | —                       |
| 3 | `spirit_emerald_snake`  | Emerald Snake      | Stone 7-tile line                                      | None                         | 1    | —                       |
| 4 | `spirit_owl_of_silence` | Owl of Silence     | Stone cluster with ≥1 Prismatic Terraces neighbour | None                         | 1    | —                       |
| 5 | `spirit_tree_frog`      | Tree Frog          | Stone cluster with ≥1 Wetlands neighbour           | None                         | 1    | —                       |
| 6 | `spirit_white_heron`    | White Heron        | River 5-tile line                                      | None                         | 1    | —                       |
| 7 | `spirit_koi_fish`       | Koi Fish           | River 2×2 square                                       | None                         | 1    | Harmony: Blue Kingfisher|
| 8 | `spirit_river_otter`    | River Otter        | ≥10 River tiles                                        | **TIER3_RECIPE** → `recipe_chi_sui_fu` | 1 | —         |
| 9 | `spirit_blue_kingfisher`| Blue Kingfisher    | ≥3 River tiles                                         | None                         | 1    | Harmony: Koi Fish       |
|10 | `spirit_dragonfly`      | Dragonfly          | River with ≥4 Meadow neighbours                        | None                         | 1    | —                       |
|11 | `spirit_mountain_goat`  | Mountain Goat      | ≥5 Stone + `disc_mountain_peak` prereq                 | None                         | 1    | —                       |
|12 | `spirit_stone_golem`    | Stone Golem        | ≥9 Stone tiles                                         | None                         | 1    | —                       |
|13 | `spirit_granite_ram`    | Granite Ram        | ≥20 Ember Field tiles                                  | None                         | 1    | —                       |
|14 | `spirit_sun_lizard`     | Sun Lizard         | Ember Field with ≥4 Meadow neighbours                  | None                         | 1    | —                       |
|15 | `spirit_rock_badger`    | Rock Badger        | ≥3 The Ashfall tiles                                   | None                         | 1    | —                       |
|16 | `spirit_golden_bee`     | Golden Bee         | ≥10 Meadow tiles                                       | None                         | 1    | —                       |
|17 | `spirit_jade_beetle`    | Jade Beetle        | ≥15 Stone tiles                                        | None                         | 1    | —                       |
|18 | `spirit_meadow_lark`    | Meadow Lark        | ≥3 Meadow + `disc_glade` prereq                        | **GROWING_SLOT_EXPAND** (4)  | 1    | —                       |
|19 | `spirit_field_mouse`    | Field Mouse        | Meadow adjacent to ≥1 Stone, ≥1 River, ≥1 Ember Field | None                         | 1    | —                       |
|20 | `spirit_hare`           | Hare               | Meadow 4-tile line                                     | None                         | 1    | Tension: Red Fox        |
|21 | `spirit_marsh_frog`     | Marsh Frog         | Wetlands 7-tile line                                   | None                         | 1    | —                       |
|22 | `spirit_peat_salamander`| Peat Salamander    | ≥5 Wetlands + `disc_peat_bog` prereq                   | None                         | 1    | —                       |
|23 | `spirit_swamp_crane`    | Swamp Crane        | Wetlands with ≥1 River + ≥1 Stone within radius 2      | None                         | 1    | —                       |
|24 | `spirit_murk_crocodile` | Murk Crocodile     | River with ≥4 Wetlands neighbours                      | None                         | 1    | —                       |
|25 | `spirit_mud_crab`       | Mud Crab           | ≥3 Wetlands + `disc_great_reef` prereq                 | None                         | 1    | —                       |
|26 | `spirit_frost_owl`      | Frost Owl          | ≥3 Frostlands + `disc_boreal_forest` prereq            | None                         | 1    | —                       |
|27 | `spirit_boreal_wolf`    | Boreal Wolf        | ≥10 Frostlands + `disc_boreal_forest` prereq           | None                         | 1    | Tension: Tundra Lynx    |
|28 | `spirit_tundra_lynx`    | Tundra Lynx        | ≥5 Frostlands + `disc_river` prereq                    | None                         | 1    | —                       |
|29 | `spirit_ice_cavern_bat` | Ice Cavern Bat     | ≥5 Frostlands + `disc_great_reef` prereq               | None                         | 1    | —                       |
|30 | `spirit_sky_whale`      | Sky Whale          | ≥1 000 total tiles, all 4 macro-groups within ±15 % of 25 % each | None | 4 | —                  |
|31 | `spirit_oyamatsumi`     | Ōyamatsumi         | ≥5 Sacred Stone + `disc_iwakura_sanctum` prereq        | None                         | 3    | — *(spec 016)*          |
|32 | `spirit_suijin`         | Suijin             | ≥5 Moonlit Pool + `disc_misogi_spring_shrine` prereq   | None                         | 3    | — *(spec 016)*          |
|33 | `spirit_kagutsuchi`     | Kagutsuchi         | ≥5 Ember Shrine + `disc_eternal_kagura_hall` prereq    | None                         | 3    | — *(spec 016)*          |
|34 | `spirit_fujin`          | Fūjin              | ≥5 Cloud Ridge + `disc_heavenwind_torii` prereq        | None                         | 3    | — *(spec 016)*          |

---

## Progression Milestones

| Unlock Event                  | Trigger                                                      | Effect                     |
|-------------------------------|--------------------------------------------------------------|----------------------------|
| **Kū Unlocked**               | Mist Stag summoned (`KU_UNLOCK` gift)                        | Kū selectable in Mix UI; opens Tier 2 (+Kū) recipes |
| **Sky Whale (Prestige)**      | 1 000 tiles, macro-groups balanced                           | Capstone discovery event   |

---

## Notes

- Biome IDs 10–13 (`SACRED_STONE`, `MOONLIT_POOL`, `EMBER_SHRINE`, `CLOUD_RIDGE`) and their recipes are fully implemented as part of **spec 016**.
- `disc_heavenwind_torii` and `disc_great_torii` both trigger on ≥4 Cloud Ridge tiles; their trigger conditions need differentiation in a future spec.
- All catalog sources of truth: `src/seeds/recipes/*.tres`, `src/biomes/discovery_catalog_data.gd`, `src/spirits/spirit_catalog_data.gd`.
