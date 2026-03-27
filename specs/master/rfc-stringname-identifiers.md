# RFC: StringName Identifier Canonicalization

- Status: Draft
- Authors: Copilot (proposed), project maintainers
- Date: 2026-03-27

## Summary

Adopt canonical `StringName` constants for cross-system IDs (recipes, discoveries, spirits, codex entries), while keeping integer biome values in hot-path runtime systems.

This RFC proposes a hybrid model:

1. Use `StringName` constants as the semantic identity for wiring and debugging.
2. Keep `int` IDs for tight loops and storage-heavy systems (`GridMap`, renderer palettes, pattern checks).
3. Validate all cross-file references at test/startup time to eliminate silent drift.

## Motivation

Current wiring mixes:

1. integer enums (`BiomeType.Value.*`)
2. ad-hoc string IDs in `.tres` resources
3. string literals in service/UI code

This increases cognitive load and can cause subtle mismatches (for example: spirit pattern data and UI/catalog expectations diverging).

## Goals

1. Improve readability and debugging by replacing scattered literals with canonical constants.
2. Reduce cross-file mismatch risk via centralized IDs.
3. Preserve runtime performance characteristics for tile/grid/render loops.
4. Enable incremental migration without breaking existing save/data formats.

## Non-Goals

1. Replace all integer enums with strings.
2. Rewrite all `.tres` resources in one pass.
3. Change save schema in this RFC.

## Proposal

### 1. Canonical ID Module

Add `src/satori/SatoriIds.gd` as the central source for key `StringName` IDs.

Example constants:

1. `KU_GUIDANCE_ENTRY_ID`
2. `DISC_DEEP_STAND`
3. `SPIRIT_MIST_STAG`
4. `RECIPE_CHI_SUI_FU`
5. `STATE_DISCOVERED`

### 2. Adoption Rule

Use `SatoriIds` constants in all GDScript code when comparing or emitting cross-system IDs.

Use raw strings only in data resources (`.tres`) where constants cannot be referenced directly.

### 3. Runtime Data Rule

Keep integer biome IDs for:

1. grid tile storage
2. renderer palette/index lookup
3. cluster/pathfinding/pattern hot loops

### 4. Validation Rule

Add/extend tests to verify that all resource IDs are present in central code catalogs and that expected cross-links exist.

## Performance Considerations

1. `StringName` in Godot is interned and optimized for repeated comparisons.
2. Hash/intern cost is paid once per unique ID; repeated equality checks are cheap.
3. Keeping `int` in hot paths avoids any regression for tile-scale operations.

Expected impact:

1. No meaningful regression in gameplay loops.
2. Improved diagnostics and lower defect rate from ID drift.

## Migration Plan

### Phase 1: Foundation (safe)

1. Introduce `SatoriIds.gd`.
2. Migrate high-value service/UI comparisons to constants.
3. Keep behavior identical.

### Phase 2: Coverage Expansion

1. Replace remaining high-frequency literal IDs in scripts.
2. Add targeted tests for ID link integrity.

### Phase 3: Tooling/Guardrails

1. Add test assertions for known pattern/discovery/spirit/recipe links.
2. Optionally add script-level lint checks for banned raw ID literals in selected folders.

## Backward Compatibility

1. Existing `.tres` files continue to work unchanged.
2. Existing save data remains valid.
3. Integer biome IDs remain stable.

## Risks

1. Partial migration may temporarily mix old/new styles.
2. Constants can drift if not kept synced with resource IDs.

Mitigation:

1. integrity tests in CI
2. update checklist for new content additions

## Acceptance Criteria

1. New code uses `SatoriIds` for cross-system IDs.
2. Core services/UI no longer duplicate key literals.
3. No runtime behavior regressions.
4. Tests catch mismatched IDs before merge.

## Initial Slice Implemented

This RFC is accompanied by an initial migration slice:

1. Added `src/satori/SatoriIds.gd`.
2. Adopted constants in `seed_alchemy_service.gd`, `codex_service.gd`, and `CodexPanel.gd` for Ku guidance IDs/states.

