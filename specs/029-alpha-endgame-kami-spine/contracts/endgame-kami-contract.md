# Contract: Endgame Kami Acceptance

## Purpose

Defines the alpha finale contract.

## Contract

From a fresh save, normal play can reach:

1. Mist Stag Ku-gating milestone.
2. Ku unlock.
3. Ku Seed places Void.
4. Placed Void separates islands.
5. Chi+Ku biome placement on an island with at least 10 water tiles, no fire-based tiles, and Satori 1000.
6. Suijin invitation on that qualifying island.

The kami invitation must:

- be island-local,
- not trigger on islands with fewer than 10 water tiles, any fire-based tile, or Satori below 1000,
- not duplicate on repeated scans,
- persist after restart.

## Validation

- Focused GUT tests for gating, scope, duplicate safety, and persistence.
- Full manual endgame script recorded in `quickstart.md`.
