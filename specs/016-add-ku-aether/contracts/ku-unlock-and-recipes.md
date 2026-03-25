# Contract: Ku Unlock and Recipe Invariants

## Purpose

Defines non-negotiable behavior between spirit unlock flow, alchemy service, and recipe registry for Ku support.

## Unlock contract

1. Ku starts locked by default.
2. Ku unlock event source is Mist Stag summon gift (`SpiritGiftType.KU_UNLOCK`).
3. Unlock call path remains:
   - `SpiritService` summons Mist Stag.
   - `SpiritGiftProcessor` processes `gift_type = KU_UNLOCK`.
   - `SeedAlchemyService.unlock_element(KU)` is invoked exactly once per unlock state.

## Unlock prerequisite contract

These conditions are part of progression design and must remain true unless a future spec changes them:
1. `disc_deep_stand` discovery must be obtainable first.
2. Mist Stag summon depends on:
   - `required_biomes = [8]` (BOG)
   - `size_threshold = 5`
   - `prerequisite_ids = ["disc_deep_stand"]`

## Recipe contract

1. Supported Ku recipes are exactly:
   - `recipe_chi_ku`
   - `recipe_sui_ku`
   - `recipe_ka_ku`
   - `recipe_fu_ku`
2. All are Tier 2 recipes with exactly two unique elements.
3. Solo Ku and undefined Ku combinations return null from recipe lookup.
4. Existing non-Ku recipes remain unchanged.

## Codex hint contract

1. Pre-unlock hint text must:
   - Name Mist Stag.
   - Provide directional progression guidance.
   - Avoid exact numeric thresholds.
2. Post-unlock codex state must clearly indicate progression has been achieved.

## Non-goals contract

1. This feature does not introduce new save/load persistence guarantees.
2. This feature does not add alternate Ku unlock triggers.
