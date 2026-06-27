# Data Model: First Island Fun Loop

## IslandLoopState

- `island_id`: local island key
- `satori_value`: current local Satori
- `active_spirits`: spirits currently present on the island
- `structures`: completed structures on the island
- `housing_upgrades`: upgraded spirit homes such as Fox Den
- `warnings`: active player-facing issues

## FoxDen

- `form_id`: Fox Den form or upgrade source
- `building_id`: upgraded Red Fox dwelling
- `required_state`: Red Fox housed in valid first dwelling
- `migration_rule`: Red Fox migrates automatically when Fox Den is placed
- `effect_type`: double Satori generation for Red Fox only
- `feedback_id`: displayed explanation

## DewBowl

- `form_id`: Dew Bowl form
- `building_id`: placed Dew Bowl structure
- `effect_type`: storage and soothing
- `feedback_id`: displayed explanation

## WindChime

- `form_id`: Wind Chime form
- `building_id`: placed Wind Chime structure
- `effect_type`: invitation and harvest support
- `feedback_id`: displayed explanation

## InvalidActionFeedback

- `action_type`: ritual, placement, project confirmation
- `reason`: duplicate, locked, missing input, invalid biome, invalid project
- `message`: actionable player-facing guidance
