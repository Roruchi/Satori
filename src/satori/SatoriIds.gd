class_name SatoriIds
extends RefCounted

# Canonical StringName identifiers for cross-system wiring.
# Keep IDs centralized here to avoid drift between catalogs, UI, and services.

const KU_GUIDANCE_ENTRY_ID: StringName = &"ku_unlock_guidance"

const DISC_DEEP_STAND: StringName = &"disc_deep_stand"
const SPIRIT_MIST_STAG: StringName = &"spirit_mist_stag"

const RECIPE_CHI_SUI_FU: StringName = &"recipe_chi_sui_fu"
const RECIPE_SUI_FU: StringName = &"recipe_sui_fu"
const RECIPE_KU: StringName = &"recipe_ku"

const STATE_DISCOVERED: StringName = &"discovered"
const STATE_HINTED: StringName = &"hinted"

# Era identifiers used by progression systems and UI.
const ERA_STILLNESS: StringName = &"stillness"
const ERA_AWAKENING: StringName = &"awakening"
const ERA_FLOW: StringName = &"flow"
const ERA_SATORI: StringName = &"satori"

# Inclusive lower thresholds for era transitions.
const THRESHOLD_AWAKENING_MIN: int = 500
const THRESHOLD_FLOW_MIN: int = 1500
const THRESHOLD_SATORI_MIN: int = 5000

# Base progression values.
const BASE_SATORI_CAP: int = 250
const TIER1_CAP_INCREASE: int = 50
const TIER2_CAP_INCREASE: int = 250
const TIER3_CAP_INCREASE: int = 1000
