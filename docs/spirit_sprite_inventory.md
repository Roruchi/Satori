# Spirit Sprite Inventory

Generated on 2026-06-25 from `src/spirits/spirit_catalog_data.gd`.

## Coverage

- Catalog spirits: 34
- Existing full sprite set before this pass: `spirit_red_fox`
- Spirits missing sprites before this pass: 33
- Batch source art: `assets/spirits/source_batches/`
- Per-spirit loader target: `assets/spirits/<spirit_id>/sprite_frames.tres`

The red fox remains the full-art reference: 64x64 top-down frames, `idle`,
`walk`, and `sleep` in four directions. The new batch pass creates static
first-pass `idle_down` sprites so each missing spirit can render through the
same `SpiritWanderer` resource path, while leaving room for later animated
upgrades.

## Batch Map

| Batch | Cell | Spirit ID | Display Name |
|---|---|---|---|
| 01 | top_left | `spirit_blue_kingfisher` | Blue Kingfisher |
| 01 | top_right | `spirit_boreal_wolf` | Boreal Wolf |
| 01 | bottom_left | `spirit_dragonfly` | Dragonfly |
| 01 | bottom_right | `spirit_emerald_snake` | Emerald Snake |
| 02 | top_left | `spirit_field_mouse` | Field Mouse |
| 02 | top_right | `spirit_frost_owl` | Frost Owl |
| 02 | bottom_left | `spirit_fujin` | Fujin |
| 02 | bottom_right | `spirit_golden_bee` | Golden Bee |
| 03 | top_left | `spirit_granite_ram` | Granite Ram |
| 03 | top_right | `spirit_hare` | Hare |
| 03 | bottom_left | `spirit_ice_cavern_bat` | Ice Cavern Bat |
| 03 | bottom_right | `spirit_jade_beetle` | Jade Beetle |
| 04 | top_left | `spirit_kagutsuchi` | Kagutsuchi |
| 04 | top_right | `spirit_koi_fish` | Koi Fish |
| 04 | bottom_left | `spirit_marsh_frog` | Marsh Frog |
| 04 | bottom_right | `spirit_meadow_lark` | Meadow Lark |
| 05 | top_left | `spirit_mist_stag` | Mist Stag |
| 05 | top_right | `spirit_mountain_goat` | Mountain Goat |
| 05 | bottom_left | `spirit_mud_crab` | Mud Crab |
| 05 | bottom_right | `spirit_murk_crocodile` | Murk Crocodile |
| 06 | top_left | `spirit_owl_of_silence` | Owl of Silence |
| 06 | top_right | `spirit_oyamatsumi` | Oyamatsumi |
| 06 | bottom_left | `spirit_peat_salamander` | Peat Salamander |
| 06 | bottom_right | `spirit_river_otter` | River Otter |
| 07 | top_left | `spirit_rock_badger` | Rock Badger |
| 07 | top_right | `spirit_sky_whale` | Sky Whale |
| 07 | bottom_left | `spirit_stone_golem` | Stone Golem |
| 07 | bottom_right | `spirit_suijin` | Rain Kami Suijin |
| 08 | top_left | `spirit_sun_lizard` | Sun Lizard |
| 08 | top_right | `spirit_swamp_crane` | Swamp Crane |
| 08 | bottom_left | `spirit_tree_frog` | Tree Frog |
| 08 | bottom_right | `spirit_tundra_lynx` | Tundra Lynx |
| 09 | full | `spirit_white_heron` | White Heron |

