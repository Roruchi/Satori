# Terrain Tile Inventory

Terrain atlas: `res://assets/tiles/satori_terrain_tilesheet.png`

Format:
- 256 x 256 px cells
- 4 variants per biome row
- pointy-top hex mask with transparent corners
- modern pixelated postprocess from imagegen source sheets
- rows follow `BiomeType.Value` IDs for direct lookup

| Row | BiomeType.Value | Biome | Source sheet row |
| --- | ---: | --- | --- |
| 0 | 0 | `STONE` | `satori_terrain_source_stone_ember_wetlands_badlands.png` row 0 |
| 1 | 1 | `RIVER` | `satori_terrain_source_meadow_river_cloud_ridge.png` row 1 |
| 2 | 2 | `EMBER_FIELD` | `satori_terrain_source_stone_ember_wetlands_badlands.png` row 1 |
| 3 | 3 | `MEADOW` | `satori_terrain_source_meadow_river_cloud_ridge.png` row 0 |
| 4 | 4 | `WETLANDS` | `satori_terrain_source_stone_ember_wetlands_badlands.png` row 2 |
| 5 | 5 | `BADLANDS` | `satori_terrain_source_stone_ember_wetlands_badlands.png` row 3 |
| 6 | 6 | `WHISTLING_CANYONS` | `satori_terrain_source_canyons_terraces_frost_ashfall.png` row 0 |
| 7 | 7 | `PRISMATIC_TERRACES` | `satori_terrain_source_canyons_terraces_frost_ashfall.png` row 1 |
| 8 | 8 | `FROSTLANDS` | `satori_terrain_source_canyons_terraces_frost_ashfall.png` row 2 |
| 9 | 9 | `THE_ASHFALL` | `satori_terrain_source_canyons_terraces_frost_ashfall.png` row 3 |
| 10 | 10 | `SACRED_STONE` | `satori_terrain_source_sacred_moonlit_ember_shrine_ku.png` row 0 |
| 11 | 11 | `MOONLIT_POOL` | `satori_terrain_source_sacred_moonlit_ember_shrine_ku.png` row 1 |
| 12 | 12 | `EMBER_SHRINE` | `satori_terrain_source_sacred_moonlit_ember_shrine_ku.png` row 2 |
| 13 | 13 | `CLOUD_RIDGE` | `satori_terrain_source_meadow_river_cloud_ridge.png` row 2 |
| 14 | 14 | `KU` | `satori_terrain_source_sacred_moonlit_ember_shrine_ku.png` row 3 |

Generation pipeline:
1. Generate source texture sheets with imagegen.
2. Copy source sheets into `res://assets/tiles/source/imagegen/`.
3. Run `tools/build_terrain_hex_atlas.py`.
4. Inspect `res://assets/tiles/qa_contact_sheet.png`.
