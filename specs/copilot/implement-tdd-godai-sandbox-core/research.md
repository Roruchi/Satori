# Research Notes — Godai Sandbox Core (v6.0) Phase A

## Decision 1: Implement Kusho counters as a standalone RefCounted domain model
- **Decision**: Create `src/autoloads/kusho_pool.gd` as `class_name KushoPool` with explicit APIs for consume/add/cap-state/depletion checks.
- **Rationale**: This isolates deterministic resource behavior for unit testing and avoids risky broad wiring changes during an incremental phase.
- **Alternatives considered**:
  - Add counters directly into `HUDController`: rejected because it couples domain logic to UI and hinders testability.
  - Add a new autoload immediately: rejected in this phase to avoid cross-scene integration risk before core logic is validated.

## Decision 2: Apply Keisu resonance as temporary pitch scaling in SoundscapeEngine
- **Decision**: Add a 5-second resonance timer and lerped pitch scale applied each frame to neutral, biome, spirit, and stinger players.
- **Rationale**: `SoundscapeEngine` is already responsible for global procedural music behavior; pitch modulation belongs in this orchestrator.
- **Alternatives considered**:
  - Trigger one-shot stinger only: rejected because requirement calls for a decay period influencing background procedural pitch.
  - Create separate resonance manager autoload: rejected as unnecessary complexity for a single bounded effect.

## Decision 3: Validate via targeted GUT unit tests
- **Decision**: Add `tests/unit/test_kusho_pool.gd` and extend `tests/unit/test_soundscape_engine.gd`.
- **Rationale**: Keeps testing deterministic and aligned with existing CI command.
- **Alternatives considered**:
  - Manual-only testing: rejected due to constitution requirement for deterministic gameplay/system automation.
