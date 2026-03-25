# Research: Spirit Animal System

## Decision: Spirit patterns via existing PatternDefinition engine
- **Decision**: Extend the existing PatternMatcher/PatternDefinition engine with spirit-prefixed pattern IDs rather than building a parallel evaluation engine.
- **Rationale**: Zero engine complexity added; patterns are data-driven (.tres files); the discovery registry already de-duplicates per garden session.
- **Alternatives considered**: Custom SpiritConditionEvaluator — rejected because it would duplicate the cluster/shape/compound matching logic already proven in feature 005.

## Decision: Waypoint-based wander within Rect2i bounds
- **Decision**: Spirit entities pick a random hex coordinate inside their Rect2i wander bounds, move toward it, then pick another. No NavigationServer or A*.
- **Rationale**: Spirits wander only within a bounded tile region; the region changes shape only on cluster expansion. Full path-finding adds runtime cost without gameplay value for this bounded case.
- **Alternatives considered**: Godot NavigationServer3D — rejected because it requires baked navigation meshes that can't be dynamically updated at tile-placement time on mobile hardware at 60 fps.

## Decision: Riddle hints via SpiritRiddleEvaluator partial-match scan
- **Decision**: After each tile placement, `SpiritService._evaluate_riddle_hints()` scans all unsummoned spirit patterns for partial satisfaction using `SpiritRiddleEvaluator`.
- **Rationale**: Riddle hints are P1 in the spec. Scanning all 29 patterns per tile placement is O(tiles * patterns) worst-case but each pattern check is O(tiles) so total is bounded.
- **Alternatives considered**: Streaming partial-match in PatternMatcher — rejected to keep PatternMatcher single-responsibility.

## Decision: SkyWhaleEvaluator separate from PatternMatcher
- **Decision**: Sky Whale is triggered by a global balance check in `SkyWhaleEvaluator.evaluate()` called from `SpiritService._on_tile_placed()` rather than via a PatternDefinition .tres.
- **Rationale**: The Sky Whale condition is a global garden property (total tiles + biome ratios), not a local pattern. No PatternDefinition type can express this.
- **Alternatives considered**: New PatternType.GLOBAL — rejected to avoid modifying the pattern engine for a single use case.

## Decision: SpiritPersistence as separate autoload (not extending DiscoveryPersistence)
- **Decision**: Add `SpiritPersistence` autoload parallel to `DiscoveryPersistence`.
- **Rationale**: Spirit state (wander bounds, spawn coord) is structurally different from discovery log entries. Keeping them separate avoids coupling two different concerns.
- **Alternatives considered**: Adding spirit data to DiscoveryPersistence — rejected because it would change the save format for existing gardens.

## Decision: PatternScanScheduler hydrates from SpiritPersistence on startup
- **Decision**: `PatternScanScheduler._ready()` hydrates the discovery registry with summoned spirit IDs from `SpiritPersistence`, alongside existing discovery IDs.
- **Rationale**: Without this, spirit patterns would re-trigger on each session restart because the pattern registry starts empty.
- **Alternatives considered**: SpiritService re-summoning from persistence (without registry hydration) — rejected because PatternMatcher would still fire the signal before SpiritService restores its state.
