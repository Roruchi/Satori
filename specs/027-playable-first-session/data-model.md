# Data Model: Playable First Session

## FirstSessionStep

- `step_id`: stable id, e.g. `first_ritual`
- `trigger`: game state that activates the step
- `completion_condition`: state that completes the step
- `hint_text_id`: optional Codex/HUD hint id

## StarterRitual

- `ritual_id`: existing ritual catalog id
- `inputs`: essence/material inputs
- `result_id`: seed or form id
- `locked_reason`: optional failure guidance

## FirstBloomState

- `biome_id`: Meadow for the alpha first session
- `first_material_id`: Living Wood
- `pacing_mode`: first-session acceleration, not debug grant
- `completion_condition`: Living Wood is visible and harvestable

## FirstDwellingState

- `form_id`: Warm Hollow
- `valid_biomes`: Meadow
- `resolved_building_id`: Meadow dwelling
- `housed_spirit_id`: Red Fox when auto-housed
- `housing_state`: unavailable, available, auto_housed, visible
