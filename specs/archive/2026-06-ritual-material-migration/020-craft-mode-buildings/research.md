# Research: Craft Mode Building Placement

## Decision 1: Keep pattern matching in SeedAlchemyService and add building-craft attempt path
- Decision: Extend the existing craft-grid flow so building outputs are resolved from normalized slot patterns in `SeedAlchemyServiceNode`, while keeping seed-only logic intact and adding a building-specific attempt result contract.
- Rationale: The current architecture already centralizes discovery, inventory-full handling, and craft feedback in one service, so extending it preserves deterministic behavior and avoids UI-level rule duplication.
- Alternatives considered:
  - Add a separate BuildingAlchemyService autoload: rejected due to duplicated normalization, discovery, and feedback pipelines.
  - Resolve building patterns directly in `SeedAlchemyPanel`: rejected because UI should not own authoritative game rules.

## Decision 2: Use one shared inventory model with exact-type stacking and cap 99
- Decision: Move to a unified 8-slot inventory where building items stack only by exact building type key, each stack capped at 99, and overflow creates a new same-type stack when another slot is free.
- Rationale: Matches clarified feature behavior while preserving finite-inventory pressure and predictable failure semantics.
- Alternatives considered:
  - Unlimited stack sizes: rejected because it weakens slot pressure and obscures failure conditions.
  - Fail when matched stack hits 99 even with free slots: rejected as unintuitive and punishing.

## Decision 3: Retire build mode and route building placement through inventory selection
- Decision: Remove Build tab/mode checks from HUD and placement input routing, then introduce inventory-selected building placement sessions with explicit confirm/cancel.
- Rationale: Aligns with spec FR-001 and keeps one canonical placement pathway driven by crafted items.
- Alternatives considered:
  - Keep hidden build-mode internals behind Craft UI: rejected because it leaves legacy state branches and regression risk.
  - Auto-place on selection without explicit confirmation: rejected due to existing confirm/cancel expectations.

## Decision 4: Represent building placement as footprint-validated session state
- Decision: Add a placement session model that tracks selected building type, candidate anchor, candidate footprint tiles, and validity state before confirm/cancel.
- Rationale: Supports one-tile and multi-tile structures with deterministic blocking and clear UX feedback.
- Alternatives considered:
  - Validate only anchor tile and defer footprint conflicts until commit: rejected because failure-at-confirm is harder to understand.
  - Per-building hardcoded placement logic in controller: rejected due to poor extensibility and testability.

## Decision 5: Validation strategy combines targeted GUT and manual in-editor checks
- Decision: Add GUT tests for pattern-discovery rules, full-inventory/no-consumption behavior, exact-type stack behavior (including cap rollover), and placement confirm/cancel footprint rules; keep manual verification for mobile-friendly interactions and mode-retirement UI behavior.
- Rationale: Deterministic logic is automation-friendly while interaction feel and readability require manual checks.
- Alternatives considered:
  - Manual-only validation: rejected because regression-prone logic already has test scaffolding.
  - Full UI automation for pointer/touch behavior: rejected as disproportionate for this scope in current test harness.
