# Data Model: Alpha Endgame Kami Spine

## KuUnlockState

- `is_unlocked`: whether Ku is available
- `unlocked_by`: Mist Stag
- `charge_state`: current Ku charge/capacity if applicable
- `unlocked_at_island_id`: source island if relevant

## VoidTile

- `coord`: placed tile coordinate
- `created_by`: Ku Seed
- `separates_islands`: true when included in island membership evaluation
- `persistent_flags`: saved tile and separator state

## CalmWaterIsland

- `island_id`: local island identifier
- `water_tile_count`: must be at least 10
- `fire_based_tile_count`: must be 0
- `local_satori`: must be at least 1000
- `has_chi_ku_biome`: true after placement

## SuijinInvitation

- `kami_id`: `suijin`
- `required_island_state`: CalmWaterIsland
- `required_conditions`: 10 water tiles, 0 fire-based tiles, Satori 1000, Chi+Ku biome placed
- `arrival_state`: not invited, invited, present
- `discovery_id`: Codex/discovery entry
