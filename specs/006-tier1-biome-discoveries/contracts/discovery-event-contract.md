# Contract: Discovery Event Pipeline (MVP)

## Scope

Defines the runtime contract between pattern scanning, persistence, and UI/audio presentation for Tier 1 discoveries.

## Producer

- `PatternScanService` (autoload) re-emits discovery events from `PatternMatcher`.

Signal:

```gdscript
signal discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i])
```

## Consumer Responsibilities

### Persistence Consumer

Input:
- `discovery_id`
- `triggering_coords`

Behavior:
- If `discovery_id` already exists in persisted discovery set, ignore.
- Otherwise append one `DiscoveryLogEntry` with timestamp and coords.
- Flush/save according to garden save policy.

### Presentation Consumer

Input:
- `discovery_id`

Lookup:
- Resolve metadata (`display_name`, `flavor_text`, `audio_key`) via discovery catalog.

Behavior:
- Enqueue one notification item per event.
- Display queue items sequentially (single active notification).
- Trigger stinger playback per item without blocking visual flow.

## Ordering and Idempotency

- Producer emits discoveries in deterministic `discovery_id` order for same-pass multi-trigger events.
- Consumers must preserve incoming order.
- Duplicate IDs from subsequent scans must be suppressed before enqueueing and before persistence append.

## Error Handling

- Missing metadata for an emitted `discovery_id`: log warning; show fallback text using ID.
- Missing/unplayable audio for `audio_key`: log warning; continue visual notification.
- Persistence write failure: surface runtime error and retry on next save opportunity without emitting duplicate UI for already-shown event in the same session.
