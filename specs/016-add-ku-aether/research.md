# Research: Mixable Ku Recipes

**Branch**: `016-add-ku-aether` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)

## 1. Ku unlock path and conditions

**Decision**: Keep the Ku unlock source unchanged and tied to Mist Stag summon gift processing.

**Rationale**: This aligns with clarified spec decisions and existing service wiring (`SpiritGiftProcessor` -> `SeedAlchemyService.unlock_element(KU)`), minimizing regression risk.

**Alternatives considered**:
- Move Ku unlock to Satori sequence: rejected because it conflicts with clarified progression choice.
- Add a new parallel unlock trigger: rejected because it weakens progression clarity and adds balancing overhead.

## 2. Explicit unlock prerequisite chain used for planning

**Decision**: Preserve and document the concrete chain:
1. Discover `disc_deep_stand`.
2. Summon Mist Stag (`spirit_mist_stag`).
3. Mist Stag gift unlocks Ku.

**Rationale**: The request explicitly asked for specific unlocks and unlock conditions in the plan. Existing pattern resources already encode these conditions.

**Alternatives considered**:
- Hide prerequisites in planning docs: rejected because implementation tasks need testable, explicit conditions.

## 3. Ku recipe extension strategy

**Decision**: Add four Tier 2 Ku pairing recipes as data resources under `src/seeds/recipes/` and keep solo Ku invalid.

**Rationale**: Existing `SeedRecipeRegistry` already supports data-driven loading; this is the lowest-risk extension path and keeps existing behavior for invalid combinations.

**Alternatives considered**:
- Hardcode Ku cases in service logic: rejected because it duplicates registry behavior and increases maintenance cost.

## 4. Deity content approach

**Decision**: Implement four direct Shinto deity spirit entries (one per Ku biome), with respectful codex tone and non-caricatured descriptions.

**Rationale**: This is a clarified requirement. Respectful representation is handled through neutral educational tone, avoiding parody/stereotype framing.

**Alternatives considered**:
- Use inspired fictional deities: rejected by clarification.
- Keep only animal spirits: rejected by feature goal.

## 5. Codex hint specificity

**Decision**: Pre-unlock codex hints will explicitly name Mist Stag and directional progression, but avoid exact numeric thresholds.

**Rationale**: Balances player guidance with discovery pacing and matches clarified UX constraints.

**Alternatives considered**:
- Full checklist with thresholds: rejected by clarification.
- Poetic-only hints with no named target: rejected due to discoverability issues.

## 6. Persistence behavior

**Decision**: Do not add new persistence guarantees in this feature.

**Rationale**: Clarified scope selects current behavior unchanged. Planning and tests must validate that feature work does not accidentally alter save/load semantics.

**Alternatives considered**:
- Persist all Ku progression state now: rejected as out-of-scope.
- Reset Ku every run intentionally: rejected because this would be a behavior change.

## 7. Runtime and test strategy

**Decision**: Cover deterministic logic with GUT tests and cover progression UX with manual quickstart.

**Rationale**: Recipe and unlock logic are deterministic and fit unit tests; codex hint readability and discovery feel require manual validation.

**Alternatives considered**:
- Manual-only validation: rejected due to regression risk in recipe/unlock wiring.
