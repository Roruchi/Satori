# Contract: Ku Content Mapping

## Purpose

Defines one-to-one mapping requirements for Ku recipes, biomes, deity spirits, and worship structures.

## Mapping table

| Ku Recipe ID | Biome ID | Deity Spirit ID (direct reference) | Structure Discovery ID |
|---|---|---|---|
| `recipe_chi_ku` | `SACRED_STONE` | `spirit_oyamatsumi` | `disc_iwakura_sanctum` |
| `recipe_sui_ku` | `MOONLIT_POOL` | `spirit_suijin` | `disc_misogi_spring_shrine` |
| `recipe_ka_ku` | `EMBER_SHRINE` | `spirit_kagutsuchi` | `disc_eternal_kagura_hall` |
| `recipe_fu_ku` | `CLOUD_RIDGE` | `spirit_fujin` | `disc_heavenwind_torii` |

## Required cardinality

1. Exactly 4 new Ku biomes are craftable from Ku pairings.
2. Exactly 4 new deity spirits exist, one per Ku biome.
3. Exactly 4 new structures exist, one per Ku biome.
4. No Ku biome is shared by multiple new deity spirits in this feature.
5. No Ku biome is missing a structure mapping.

## Content tone constraints

1. Deity names are direct Shinto references, presented respectfully.
2. Codex and flavor text must avoid parody or dismissive framing.
3. Structure naming should align with sacred-place themes and not conflict with existing IDs.

## Validation checkpoints

1. Recipe lookup returns all 4 Ku mappings after Ku unlock.
2. Discovery catalogs contain all mapped spirit and structure IDs.
3. Codex entries exist for each mapped biome, spirit, and structure.
4. Manual quickstart run verifies end-to-end visibility for each mapping row.

## Implementation sync notes

- Added spirit entries and pattern resources for:
  - `spirit_oyamatsumi`, `spirit_suijin`, `spirit_kagutsuchi`, `spirit_fujin`
- Added structure metadata and tier2 patterns for:
  - `disc_iwakura_sanctum`, `disc_misogi_spring_shrine`, `disc_eternal_kagura_hall`, `disc_heavenwind_torii`
- Added codex entries for all four new deity spirits and all four new structures.
