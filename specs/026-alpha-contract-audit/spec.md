# Feature Specification: Alpha Contract and State Audit

**Feature Branch**: `026-alpha-contract-audit`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: User request to break the alpha roadmap into completeable Speckit specs and track alpha completion in priority order.

## Clarifications

- The alpha finale is `Mist Stag -> Ku -> Void-separated island -> Chi+Ku calm-water island condition -> Suijin`.
- This spec does not implement gameplay. It creates the authoritative alpha checklist, evidence model, and current-state audit that later alpha specs must use.
- Existing dirty worktree changes are not assumed complete until verified by this audit.

## User Scenarios & Testing

### User Story 1 - Freeze Alpha Acceptance (Priority: P1)

As the developer, I can open one checklist and see exactly what must be true before alpha testing starts.

**Why this priority**: Later implementation work needs a stable target and must not drift back to expansion-only or broad content completion.

**Independent Test**: Review `docs/alpha-roadmap.md` and the alpha checklist, then confirm every roadmap phase maps to one spec and one measurable exit gate.

**Acceptance Scenarios**:

1. **Given** the roadmap, **When** the checklist is created, **Then** it names the alpha finale as Ku, Void island separation, Chi+Ku calm-water island condition, and Suijin.
2. **Given** a later spec, **When** its exit gates are reviewed, **Then** they trace to the alpha checklist.

### User Story 2 - Audit Current Game State (Priority: P1)

As the developer, I can run a repeatable audit and know which alpha gates are already proven, incomplete, or unverified.

**Why this priority**: Current code may already satisfy parts of the roadmap, but alpha completion needs evidence rather than assumptions.

**Independent Test**: Execute the audit quickstart and record findings with command/manual evidence.

**Acceptance Scenarios**:

1. **Given** the current worktree, **When** the audit runs, **Then** each alpha-critical loop step is marked Proven, Incomplete, Blocked, or Unverified.
2. **Given** an unverified item, **When** it is listed, **Then** it is assigned to the correct follow-up alpha spec.

### User Story 3 - Preserve Priority Order (Priority: P2)

As the developer, I can see the implementation order from first audit to external alpha readiness.

**Why this priority**: The alpha should become playable through a stable spine before content breadth or release polish.

**Independent Test**: Inspect the roadmap tracker and verify the specs are sorted by priority and dependency.

**Acceptance Scenarios**:

1. **Given** multiple alpha specs, **When** roadmap tracking is updated, **Then** Phase 0 through Phase 8 remain ordered.
2. **Given** a lower-priority spec, **When** it depends on an earlier gate, **Then** that dependency is explicit.

## Edge Cases

- Existing tests pass but do not exercise the full alpha path.
- A dirty worktree contains promising changes that cannot be safely interpreted without implementation review.
- A platform build works locally but lacks persistence or asset coverage.

## Requirements

### Functional Requirements

- **FR-001**: The roadmap MUST contain an alpha spec tracker ordered by priority.
- **FR-002**: The audit MUST include the full loop from new game through Suijin invitation via the Chi+Ku calm-water island condition.
- **FR-003**: Each alpha gate MUST have an evidence field that can point to command output, tests, manual playtest notes, or source files.
- **FR-004**: Unverified existing behavior MUST NOT be marked complete.
- **FR-005**: Follow-up work MUST be assigned to exactly one owning alpha spec unless it is intentionally shared infrastructure.

### Experience & Runtime Constraints

- **EX-001**: The audit MUST preserve permanent-emergence rules and flag any debug-only exception.
- **EX-002**: Mobile input and layout gates MUST be tracked even when audited from desktop.
- **EX-003**: Validation MUST include parse, boot smoke, focused GUT suites, and platform smoke checks where applicable.

### Key Entities

- **Alpha Gate**: A measurable condition required for alpha.
- **Audit Finding**: Evidence-backed status for one alpha gate.
- **Spec Tracker Row**: Roadmap row linking a phase to a Speckit spec and implementation status.

## Success Criteria

- **SC-001**: Every roadmap phase maps to a numbered spec.
- **SC-002**: Every alpha-critical gate has a status and owner.
- **SC-003**: No alpha gate is marked complete without direct evidence.
- **SC-004**: The roadmap can be used as the priority-ordered implementation board.
