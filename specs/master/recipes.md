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
| 10 | `SACRED_STONE`       | Chi + Kū   | CHI + KU *(planned — spec 016)* |
| 11 | `MOONLIT_POOL`       | Sui + Kū   | SUI + KU *(planned — spec 016)* |
| 12 | `EMBER_SHRINE`       | Ka + Kū    | KA + KU *(planned — spec 016)*  |
| 13 | `CLOUD_RIDGE`        | Fū + Kū    | FU + KU *(planned — spec 016)*  |

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

### Tier 2 — Two Elements (always available)

| `recipe_id`      | Elements           | Produces Biome (ID) | Biome Name    | Codex Hint |
|------------------|--------------------|---------------------|---------------|------------|
| `recipe_chi_sui` | CHI (0) + SUI (1)  | 4 — Wetlands        | Wetlands      | "Earth softened by patient, standing water." |
| `recipe_chi_ka`  | CHI (0) + KA (2)   | 5 — Badlands        | Badlands      | "Earth baked until it cracks beneath the sun." |
| `recipe_chi_fu`  | CHI (0) + FU (3)   | 6 — Whistling Canyons | Whistling Canyons | "Stone carved hollow by the breath of wind." |
| `recipe_sui_ka`  | SUI (1) + KA (2)   | 7 — Prismatic Terraces | Prismatic Terraces | "Water that boils with the memory of fire." |
| `recipe_sui_fu`  | SUI (1) + FU (3)   | 8 — Frostlands      | Frostlands    | "Water frozen still by the piercing wind." |
| `recipe_ka_fu`   | KA (2) + FU (3)    | 9 — The Ashfall     | The Ashfall   | "Where wind carries the glowing bones of fire." |

### Tier 2 (+Kū) — Unlocked after Mist Stag is summoned *(planned — spec 016)*

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

---

## Tier 2 Structural Landmarks

| `discovery_id`            | Display Name          | Pattern Type       | Key Trigger                                                            |
|---------------------------|-----------------------|--------------------|------------------------------------------------------------------------|
| `disc_origin_shrine`      | Origin Shrine         | SHAPE (anchored)   | Stone at grid `(0,0)` + River at N/S/E/W — coordinate-locked           |
| `disc_bridge_of_sighs`    | Bridge of Sighs       | SHAPE              | Ember Field → River → Ember Field in a 3-tile line                     |
| `disc_lotus_pagoda`       | Lotus Pagoda          | CLUSTER            | ≥4 Wetlands tiles (2×2 square)                                         |
| `disc_monks_rest`         | Monk's Rest           | SHAPE              | Meadow centre enclosed by 6 Stone tiles                                |
| `disc_star_gazing_deck`   | Star-Gazing Deck      | COMPOUND           | ≥20 Ember Field; needs `disc_mountain_peak` first                      |
| `disc_sun_dial`           | Sun-Dial              | RATIO_PROXIMITY    | Ember Field with ≥5 Meadow neighbours within radius 1                  |
| `disc_whale_bone_arch`    | Whale-Bone Arch       | SHAPE              | The Ashfall in a U-shape (5 tiles)                                     |
| `disc_echoing_cavern`     | Echoing Cavern        | SHAPE              | 6 Ember Field tiles around an empty centre cell                        |
| `disc_bamboo_chime`       | Bamboo Chime          | SHAPE              | 5 Frostlands tiles in a straight line                                  |
| `disc_floating_pavilion`  | Floating Pavilion     | SHAPE              | Single Wetlands tile with no adjacent land biomes                      |

**Audio keys** follow the pattern `stinger_<suffix>` (e.g. `stinger_origin_shrine`).

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

### Spirit Catalog (30 spirits)

| # | `spirit_id`             | Display Name       | Pattern Trigger (summary)                              | Gift                         | Harmony / Tension       |
|---|-------------------------|--------------------|--------------------------------------------------------|------------------------------|-------------------------|
| 1 | `spirit_red_fox`        | Red Fox            | Meadow triangle (3 tiles)                              | None                         | Tension: Hare           |
| 2 | `spirit_mist_stag`      | Mist Stag          | ≥5 Frostlands + `disc_deep_stand` prereq               | **KU_UNLOCK** (1)            | —                       |
| 3 | `spirit_emerald_snake`  | Emerald Snake      | Stone 7-tile line                                      | None                         | —                       |
| 4 | `spirit_owl_of_silence` | Owl of Silence     | Stone cluster with ≥1 Prismatic Terraces neighbour             | None                         | —                       |
| 5 | `spirit_tree_frog`      | Tree Frog          | Stone cluster with ≥1 Wetlands neighbour                   | None                         | —                       |
| 6 | `spirit_white_heron`    | White Heron        | River 5-tile line                                      | None                         | —                       |
| 7 | `spirit_koi_fish`       | Koi Fish           | River 2×2 square                                       | None                         | Harmony: Blue Kingfisher|
| 8 | `spirit_river_otter`    | River Otter        | ≥10 River tiles                                        | **TIER3_RECIPE** → `recipe_chi_sui_fu` | —          |
| 9 | `spirit_blue_kingfisher`| Blue Kingfisher    | ≥3 River tiles                                         | None                         | Harmony: Koi Fish       |
|10 | `spirit_dragonfly`      | Dragonfly          | River with ≥4 Meadow neighbours                        | None                         | —                       |
|11 | `spirit_mountain_goat`  | Mountain Goat      | ≥5 Stone + `disc_mountain_peak` prereq                 | None                         | —                       |
|12 | `spirit_stone_golem`    | Stone Golem        | ≥9 Stone tiles                                         | None                         | —                       |
|13 | `spirit_granite_ram`    | Granite Ram        | ≥20 Ember Field tiles                                  | None                         | —                       |
|14 | `spirit_sun_lizard`     | Sun Lizard         | Ember Field with ≥4 Meadow neighbours                  | None                         | —                       |
|15 | `spirit_rock_badger`    | Rock Badger        | ≥3 The Ashfall tiles                                  | None                         | —                       |
|16 | `spirit_golden_bee`     | Golden Bee         | ≥10 Meadow tiles                                       | None                         | —                       |
|17 | `spirit_jade_beetle`    | Jade Beetle        | ≥15 Stone tiles                                        | None                         | —                       |
|18 | `spirit_meadow_lark`    | Meadow Lark        | ≥3 Meadow + `disc_glade` prereq                        | **GROWING_SLOT_EXPAND** (4)  | —                       |
|19 | `spirit_field_mouse`    | Field Mouse        | Meadow adjacent to ≥1 Stone, ≥1 River, ≥1 Ember Field | None                         | —                       |
|20 | `spirit_hare`           | Hare               | Meadow 4-tile line                                        | None                         | Tension: Red Fox        |
|21 | `spirit_marsh_frog`     | Marsh Frog         | Wetlands 7-tile line                                       | None                         | —                       |
|22 | `spirit_peat_salamander`| Peat Salamander    | ≥5 Wetlands + `disc_peat_bog` prereq                       | None                         | —                       |
|23 | `spirit_swamp_crane`    | Swamp Crane        | Wetlands with ≥1 River + ≥1 Stone within radius 2          | None                         | —                       |
|24 | `spirit_murk_crocodile` | Murk Crocodile     | River with ≥4 Wetlands neighbours                          | None                         | —                       |
|25 | `spirit_mud_crab`       | Mud Crab           | ≥3 Wetlands + `disc_great_reef` prereq                     | None                         | —                       |
|26 | `spirit_frost_owl`      | Frost Owl          | ≥3 Frostlands + `disc_boreal_forest` prereq                 | None                         | —                       |
|27 | `spirit_boreal_wolf`    | Boreal Wolf        | ≥10 Frostlands + `disc_boreal_forest` prereq                  | None                         | Tension: Tundra Lynx    |
|28 | `spirit_tundra_lynx`    | Tundra Lynx        | ≥5 Frostlands + `disc_river` prereq                        | None                         | —                       |
|29 | `spirit_ice_cavern_bat` | Ice Cavern Bat     | ≥5 Frostlands + `disc_great_reef` prereq                   | None                         | —                       |
|30 | `spirit_sky_whale`      | Sky Whale          | ≥1 000 total tiles, all 4 macro-groups within ±15 % of 25 % each | None        | —                       |

---

## Progression Milestones

| Unlock Event                  | Trigger                                                      | Effect                     |
|-------------------------------|--------------------------------------------------------------|----------------------------|
| **Kū Unlocked**               | Mist Stag summoned (`KU_UNLOCK` gift)                        | Kū selectable in Mix UI; opens Tier 2 (+Kū) recipes |
| **First Tier 3 Recipe**       | River Otter summoned (`TIER3_RECIPE` gift)                   | `recipe_chi_sui_fu` unlocked in registry |
| **Extra Growing Slot (Satori)**| All 4 base biomes present + ≥3 spirits summoned             | +1 growing slot capacity   |
| **Extra Growing Slot (Lark)** | Meadow Lark summoned (`GROWING_SLOT_EXPAND` gift)            | +1 growing slot capacity   |
| **Sky Whale (Prestige)**      | 1 000 tiles, macro-groups balanced                           | Capstone discovery event   |

---

## Notes

- Biome IDs 10–13 (`SACRED_STONE`, `MOONLIT_POOL`, `EMBER_SHRINE`, `CLOUD_RIDGE`) are reserved in the enum but have no `.tres` recipe files yet — implementation is tracked in **spec 016**.
- The Tier 3 recipes for Stone Serpent, Mist Stag, Ember Fox, Mountain Golem, and Sun-Lizard are specced but not yet implemented.
- All catalog sources of truth: `src/seeds/recipes/*.tres`, `src/biomes/discovery_catalog_data.gd`, `src/spirits/spirit_catalog_data.gd`.
