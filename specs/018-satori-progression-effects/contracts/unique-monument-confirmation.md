# Contract: Unique Monument Confirmation

## Purpose

Define mandatory pre-confirmation behavior for build-once Tier 3 monuments.

## Resource metadata contract

1. Structure definitions support `is_unique: bool`.
2. Tier 3 monuments in this RFC set `is_unique = true`.
3. Non-unique structures keep existing repeatable behavior.

## Confirmation guard contract

1. Before Bell confirmation is offered/finalized for a matched blueprint:
   - Query active structure manager/registry for existing count of the same unique structure ID.
2. If `is_unique == true` and existing count `> 0`:
   - Reject confirmation.
   - Prevent Bell appearance/activation for that match.
   - Route blocked feedback to UI (red-highlight/blocked state).

## Build success contract

1. If no existing instance exists, unique monument can be built once.
2. On successful build:
   - Register active instance.
   - Apply cap increase and monument-specific effects.
3. Any later matching blueprint attempt for that same monument must be blocked by the confirmation guard.

## Failure feedback contract

1. Blocked unique attempts must be visible to players before confirmation action.
2. Rejection must be deterministic and not consume unrelated resources.
3. If design calls for dissolve behavior, it happens only as part of blocked unique handling and does not create a built instance.

## Validation checkpoints

1. First monument build succeeds.
2. Second build attempt for same monument is blocked 100% of attempts.
3. Non-unique structures remain unaffected.

## Implementation sync notes

- Unique metadata fields are present on structure definitions (`PatternDefinition.is_unique`) and tier3 resources.
- Guard behavior is implemented in both:
  - `src/biomes/pattern_matcher.gd` (scan/emit blocking via `discovery_blocked` signal)
  - `src/grid/PlacementController.gd` (pre-confirmation build-path guard using `SatoriService.can_build_structure`)
- Blocked feedback routing:
  - `src/biomes/pattern_scan_scheduler.gd` forwards `discovery_blocked`
  - `src/grid/GardenView.gd` renders blocked-state pulse/highlight for attempted duplicate unique monuments
