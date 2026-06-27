# Research: Alpha Save Safety

## Decision: Save safety blocks external alpha

**Rationale**: Permanent gardens make data loss the highest-risk alpha failure.

## Decision: Test progression checkpoints, not only raw serialization

**Rationale**: A generic save file may load while still losing gameplay meaning. Checkpoints must include first session, first island, and endgame/kami state.

## Decision: Version before external testers

**Rationale**: Alpha testers will create real saves. The project needs a schema guard before builds leave the dev machine.

## Decision: Use visible zero-based alpha build versioning

**Rationale**: External tester reports need an exact build identity. The alpha uses zero-based SemVer with alpha prerelease and build metadata, shown in the menu, for example `0.1.0-alpha+20260627.1`.

## Decision: Preserve confirmed active projects

**Rationale**: Build/project countdowns are meaningful irreversible progress. Save/load must preserve confirmed active projects and may not silently refund, cancel, duplicate, or complete them.

## Decision: Verify platform save paths during implementation

**Rationale**: Canonical paths can differ by Godot export target. The alpha requirement is that desktop, Web, and Android each use a tested `user://` persistence path and document the observed platform behavior during validation.
