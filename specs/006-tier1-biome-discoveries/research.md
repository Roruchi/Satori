# Research: Tier 1 Biome Cluster Discoveries (MVP)

**Branch**: `006-tier1-biome-discoveries` | **Date**: 2026-03-23

## Discovery Persistence Strategy

**Decision**: Persist discovery log entries inside garden save data as a deterministic dictionary/array payload, loaded on startup before any discovery scan processing.

**Rationale**:
- The current code already keeps in-memory discovery suppression via `DiscoveryRegistry`; persistence needs to hydrate this state at session start.
- Storing discovery log alongside garden state preserves deterministic replay: same saved garden -> same suppression set.
- Startup hydration before scan execution prevents duplicate notification/audio firing on reload.

**Alternatives considered**:
- Separate discovery save file (rejected: consistency risk and dual-file recovery complexity).
- Runtime-only registry with no persistence (rejected: violates FR-006 and user story 2).

## Discovery Metadata Placement

**Decision**: Keep pattern-matching data in `PatternDefinition` resources and add a lightweight Tier 1 discovery metadata catalog keyed by `discovery_id` for display/flavor/audio fields.

**Rationale**:
- Existing `PatternDefinition` is already stable and focused on matching logic.
- A metadata catalog avoids overloading matching resources with pure presentation content.
- Key-based lookup keeps the scan pipeline unchanged and supports localized text/audio swaps later.

**Alternatives considered**:
- Add UI/audio fields directly to each `PatternDefinition` (rejected for MVP: couples match logic to presentation and increases resource churn).
- Hardcode metadata in UI script (rejected: brittle and not data-driven).

## Notification Queue Ownership

**Decision**: Implement a dedicated discovery notification queue controller in UI-facing code that subscribes to `PatternScanService.discovery_triggered` and serializes display events.

**Rationale**:
- Queue behavior is presentation concern; pattern scanning should emit events, not manage UX timing.
- Sequential queue guarantees FR-007 and avoids simultaneous overlays.
- Isolated queue logic is easy to test via signal-driven unit/integration tests.

**Alternatives considered**:
- Queue within `PatternMatcher` (rejected: mixes gameplay detection with presentation timing).
- Rely on one toast timer overwrite (rejected: drops events when dual triggers occur).

## Audio Triggering and Mute Tolerance

**Decision**: Trigger stinger playback per queued discovery through a dedicated audio playback path; playback failure or mute state must not block visual notification progression.

**Rationale**:
- FR-003 and story 3 require per-discovery unique stingers.
- UI notification remains the authoritative player feedback; audio is additive.
- Decoupling queue progression from successful playback handles silent devices and missing asset fallback safely.

**Alternatives considered**:
- Make audio playback a hard precondition for queue advancement (rejected: could deadlock UX on mute/missing asset).
- Single shared stinger for all Tier 1 events (rejected: violates uniqueness criteria).

## Deterministic Multi-Discovery Ordering

**Decision**: Preserve deterministic ordering by discovery ID for emitted discoveries and consume notifications in that emitted order.

**Rationale**:
- Existing matcher already sorts emitted discovery payloads by `discovery_id`.
- Deterministic event ordering simplifies tests and replay behavior.
- Stable ordering avoids non-deterministic queue behavior during dual-trigger placements.

**Alternatives considered**:
- First-found traversal order (rejected: sensitive to dictionary iteration and scan implementation details).
- Timestamp-at-emit ordering (rejected: same-frame dual triggers provide no meaningful distinction).

## Unresolved Items

None. All planning-time clarifications required for MVP scope are resolved.
