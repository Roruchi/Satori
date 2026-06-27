# Feature Specification: Alpha Content and External Readiness

**Feature Branch**: `033-alpha-content-readiness`  
**Created**: 2026-06-26  
**Status**: Draft  
**Input**: Alpha roadmap Phases 7 and 8.

## Clarifications

- This spec owns the final content pass and closed-alpha handoff materials.
- It must not expand scope beyond the alpha spine unless content is needed for fun or clarity.
- The primary alpha path and release shell must not ship placeholder art, audio, icon, or UI assets. Placeholder assets are allowed for non-primary content if that content is hidden, gated, or clearly outside the intended tester route.
- The obvious alpha path receives polish before optional catalog breadth: first ritual, Red Fox, Meadow dwelling, upgraded Fox Den migration with Red-Fox-only double Satori generation, Dew Bowl, Wind Chime, Mist Stag, Ku Seed, Void island separation, Chi+Ku calm-water island, and Suijin invitation.
- Build version is displayed in the menu using zero-based SemVer with alpha prerelease and build metadata, for example `0.1.0-alpha+20260627.1`.

## User Scenarios & Testing

### User Story 1 - Add Enough Variety (Priority: P1)

As a tester, I can play the obvious alpha path and still find meaningful actions beyond the first dwelling.

**Independent Test**: Manual playtest after first island plus content data checks.

**Acceptance Scenarios**:

1. **Given** the first island is stable, **When** I continue playing, **Then** I can pursue upgraded Fox Den migration with Red-Fox-only double Satori generation, Dew Bowl, Wind Chime, Mist Stag, Ku Seed, Void island separation, Chi+Ku calm-water island preparation, and Suijin invitation without placeholder-facing gaps on that primary path.

### User Story 2 - Avoid Broken-Looking Gaps (Priority: P1)

As a tester, I do not see buttons, recipes, or Codex entries that look available but are broken.

**Independent Test**: UI/data audit and manual playtest.

**Acceptance Scenarios**:

1. **Given** content not included in alpha, **When** I browse normal UI, **Then** it is hidden, gated, or clearly not available.

### User Story 3 - Prepare External Testers (Priority: P1)

As the developer, I can invite testers with clear instructions and known issues.

**Independent Test**: Review tester brief, known issues, version display, and build notes.

**Acceptance Scenarios**:

1. **Given** Web and Android builds, **When** tester notes are reviewed, **Then** they explain what to try, what is out of scope, and how to report bugs.

## Requirements

- **FR-001**: Alpha content pass MUST include only content that supports current systems cleanly.
- **FR-002**: Included spirits and structures MUST be wired to Codex, save/load, and validation.
- **FR-003**: Missing broader content MUST not appear as broken functionality.
- **FR-004**: Tester instructions MUST explain scope, controls, known issues, and bug reporting.
- **FR-005**: Build version MUST be visible in the menu using `0.x.y-alpha+<build_id>` format.
- **FR-006**: The primary alpha path and release shell MUST contain no placeholder art, audio, icon, or UI assets; non-primary placeholder assets are allowed when hidden, gated, or outside the intended tester route.
- **FR-007**: The obvious path MUST receive polish before optional spirits, structures, or biomes are added.
- **FR-008**: Included alpha variety MUST cover upgraded Fox Den, Dew Bowl, and Wind Chime as the first housing/helper structure sequence.

### Experience & Runtime Constraints

- **EX-001**: Content MUST respect permanent-emergence rules.
- **EX-002**: Tester-facing UI and instructions MUST work for Web and Android testers.
- **EX-003**: Added content MUST not regress alpha performance or save/load.

### Key Entities

- **AlphaContentItem**: Included spirit, structure, material, or Codex chain.
- **PolishSurface**: Primary-path or release-shell title, menu, HUD, Codex, gameplay, audio, icon, and feedback surface requiring final-enough assets.
- **KnownIssue**: Tester-visible issue with severity and workaround.
- **TesterBrief**: External alpha instructions.

## Success Criteria

- **SC-001**: Testers can play beyond first island without immediately exhausting meaningful actions.
- **SC-002**: No known out-of-scope content appears as a broken alpha feature.
- **SC-003**: Web and Android tester handoff docs are ready.
