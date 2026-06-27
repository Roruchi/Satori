# Research: Alpha Contract and State Audit

## Decision: Treat the roadmap as the alpha source of truth

**Rationale**: The roadmap captures the user-corrected finale: Mist Stag unlocks Ku, Ku Seed places Void that separates islands, and Suijin is invited by placing the Chi+Ku biome on an island with at least 10 water tiles, no fire-based tiles, and local Satori 1000. Specs should decompose that roadmap rather than reopen the product direction.

**Alternatives considered**:

- Use `specs/master/tasks.md` as the alpha source: rejected because it describes a broader F01-F13 full game plan.
- Use the existing `025-rain-kami-path` as-is: rejected because it must be aligned to the Void-separated calm-water island finale.

## Decision: Separate specification completion from alpha implementation completion

**Rationale**: Creating Speckit artifacts is planning progress, not playable alpha progress. Roadmap tracking needs both states.

**Status terms**:

- `Spec Drafted`: Speckit artifacts exist.
- `Not Started`: implementation has not been audited or begun for alpha acceptance.
- `In Progress`: implementation tasks are underway.
- `Verified`: exit gates have current evidence.

## Decision: Audit from current worktree without cleaning it

**Rationale**: The repo currently has many local gameplay/data/UI changes. The audit must preserve those changes and inspect only what is needed.

## Decision: Use existing validation conventions

**Rationale**: Repo memory and docs point to `tools/godot.ps1` for parse, boot, GUT, and web export helpers. Scene-heavy flows still require manual validation.

## Resolved Implementation Decisions

- First alpha kami: Suijin.
- Island separation: Ku Seed places Void; placed Void separates islands.
- Suijin invitation: place the Chi+Ku biome on an island with at least 10 water tiles, no fire-based tiles, and local Satori 1000.
- Save/build versioning: zero-based SemVer with alpha prerelease and build metadata, e.g. `0.1.0-alpha+20260627.1`, visible in the menu.
