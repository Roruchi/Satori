# Contract: Alpha Gate Tracking

## Purpose

Defines how roadmap gates are tracked and promoted to `Verified`.

## Contract

- Each alpha gate has exactly one owning spec.
- Each gate has a status in `docs/alpha-roadmap.md`.
- `Verified` requires current evidence from command output, tests, manual playtest notes, or source inspection.
- Missing or indirect evidence keeps the gate below `Verified`.
- The alpha finale gate must remain: Ku unlocked, Void separates islands, Chi+Ku biome placed on a qualifying calm water island, Suijin invited.

## Validation

- Roadmap tracker contains all owning specs.
- No gate is marked `Verified` without evidence notes.
