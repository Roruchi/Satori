# Data Model: Alpha Save Safety

## SaveSnapshot

- `version`: SaveVersion and producing build version
- `tiles`: placed tile and biome state
- `inventory`: seeds, materials, forms
- `discoveries`: Codex/discovery state
- `spirits`: active spirits and bindings
- `structures`: houses, helper structures, active projects
- `satori`: local/world Satori state
- `unlocks`: Ku and other progression flags
- `endgame`: Void-separated islands, Chi+Ku calm-water island state, Satori threshold, and Suijin state

## SaveVersion

- `schema_version`: save schema identifier
- `build_version`: zero-based SemVer alpha version with build metadata, such as `0.1.0-alpha+20260627.1`
- `created_at`: save timestamp where available
- `migration_status`: supported, migrated, unsupported

## ActiveProjectState

- `project_id`: stable project identifier
- `kind`: dwelling, structure, island action, or other project type
- `state`: confirmed, active, completed, blocked
- `remaining_time`: countdown or progress remaining
- `inputs`: consumed inputs required to avoid refunds/duplication

## AutosaveTrigger

- `trigger_id`: progress event id
- `source`: system that requested save
- `debounce_policy`: immediate or deferred
- `required`: whether failure must surface

## SaveLoadResult

- `ok`: success flag
- `error_code`: optional reason
- `message_id`: player-facing feedback
- `recovered_snapshot`: fallback state if available
