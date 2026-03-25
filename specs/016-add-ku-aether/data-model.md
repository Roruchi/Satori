# Data Model: Mixable Ku Recipes

**Branch**: `016-add-ku-aether` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)

## KuPairRecipe (existing `SeedRecipe` resource extension)

Represents one valid Ku pairing recipe.

Fields:
- `recipe_id: StringName`
- `elements: Array[int]` (must be two elements, one is Ku)
- `tier: int` (must be `2`)
- `produces_biome: int` (one Ku biome enum)
- `spirit_unlock_id: StringName` (empty for these Tier 2 recipes)
- `codex_hint: String`

Validation:
- Exactly four recipe IDs are added: `recipe_chi_ku`, `recipe_sui_ku`, `recipe_ka_ku`, `recipe_fu_ku`.
- `elements` must be unique and sorted for key consistency.
- Solo Ku (`[KU]`) never resolves to a recipe.

## KuBiomeOutcome (existing biome enum + recipe output mapping)

Represents one biome produced from a Ku pairing.

Fields:
- `biome_id: int`
- `seed_recipe_id: StringName`
- `display_name: String`
- `codex_entry_id: StringName`

Required mappings:
- `recipe_chi_ku` -> `SACRED_STONE`
- `recipe_sui_ku` -> `VEIL_MARSH`
- `recipe_ka_ku` -> `EMBER_SHRINE`
- `recipe_fu_ku` -> `CLOUD_RIDGE`

Validation:
- One-to-one recipe-to-biome mapping.
- No overlap with existing non-Ku recipe outputs.

## KuDeitySpirit (existing spirit catalog entry)

Represents one new deity spirit tied to a Ku biome.

Fields:
- `spirit_id: String`
- `display_name: String` (direct Shinto deity reference)
- `riddle_text: String`
- `pattern_id: String`
- `preferred_biomes: Array[int]`
- `gift_type: int`
- `gift_payload: StringName`
- `codex_entry_id: StringName`

Validation:
- Exactly 4 new deity spirits.
- One deity spirit per Ku biome.
- Naming and codex text use respectful tone.

## KuStructureDiscovery (existing pattern + codex structure entry)

Represents one place-of-worship discovery associated with a Ku biome.

Fields:
- `discovery_id: String`
- `pattern_type: int`
- `required_biomes: Array[int]`
- `size_threshold: int`
- `prerequisite_ids: Array[String]`
- `codex_entry_id: StringName`

Validation:
- Exactly 4 new structures.
- One structure mapped to each Ku biome.

## KuCodexHintState (existing codex entry content behavior)

Represents pre-unlock and post-unlock guidance text behavior.

Fields:
- `entry_id: StringName`
- `category: CodexEntry.Category`
- `hint_text: String` (pre-unlock)
- `full_name: String`
- `full_description: String`

Validation:
- Pre-unlock hint explicitly names Mist Stag.
- Pre-unlock hint avoids exact numeric thresholds.
- Post-unlock text distinguishes discovered state from hinted state.

## Unlock chain reference model

`DeepStandDiscovery` -> `MistStagSummon` -> `KuElementUnlocked`

Concrete conditions in current resources:
- Deep Stand: MEADOW cluster size 10, forbidden EMBER_FIELD.
- Mist Stag: BOG cluster size 5, prerequisite `disc_deep_stand`.
- Ku unlock: Mist Stag gift type `KU_UNLOCK`.

State transitions:
1. `KU_LOCKED` -> `KU_UNLOCKED` on Mist Stag summon gift.
2. `KU_UNLOCKED` + valid pair -> `KU_RECIPE_CRAFTABLE`.
3. `KU_RECIPE_CRAFTABLE` + bloom -> `KU_BIOME_DISCOVERABLE`.
4. `KU_BIOME_DISCOVERABLE` -> deity/structure discovery progression.
