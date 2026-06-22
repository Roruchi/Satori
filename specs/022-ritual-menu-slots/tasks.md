# Tasks: Ritual Menu and Slot-Based Creation

**Input**: Design documents from `specs/022-ritual-menu-slots/`
**Prerequisites**: `spec.md`, `plan.md`, `data-model.md`, `contracts/ritual-attempt-contract.md`

## Phase 1: Ritual Resolver Foundation

- [x] T001 Add a `RitualAttemptResult` contract object for success and failure outcomes.
- [x] T002 Add canonical ritual input identities for early essences and temporary Living Wood.
- [x] T003 Normalize ritual slots as order-insensitive keys and reject duplicate identities before lookup.
- [x] T004 Reject attempts with no filled slot or no essence without mutating inventory, charges or materials.

## Phase 2: Seed and Form Outputs

- [x] T005 Route one- and two-essence rituals through the existing seed registry.
- [x] T006 Preserve Ku lock checks for ritual seed inputs.
- [x] T007 Add Living Wood + Fire Essence -> Warm Hollow as a no-duplicate form ritual.
- [x] T008 Commit ritual outputs only after place inventory insertion succeeds.
- [x] T009 Make legacy duplicate-token building recipes non-successful in the player-facing resolver path.

## Phase 3: Player UI

- [x] T010 Replace the 9-cell creation grid scene with three ritual slots.
- [x] T011 Add duplicate-prevention behavior when selecting slot inputs.
- [x] T012 Add material selection for Living Wood with visible availability.
- [x] T013 Replace affected UI copy with ritual, essence, seed, form and material language.
- [x] T014 Keep panel sizing usable without horizontal scrolling on small/mobile layouts.

## Phase 4: Placement Context

- [x] T015 Store Warm Hollow in the existing place inventory as a placeable form.
- [x] T016 Resolve Warm Hollow on Meadow to Meadow Dwelling at placement confirmation.
- [x] T017 Resolve Warm Hollow on Fire/Hearth to Scorched Hollow at placement confirmation.
- [x] T018 Block form placement on invalid or empty targets without consuming inventory.

## Phase 5: Validation and Docs

- [x] T019 Add GUT coverage for order-insensitive ritual resolution.
- [x] T020 Add GUT coverage for duplicate rejection and non-destructive failure.
- [x] T021 Add GUT coverage for Wind Essence -> Meadow Seed.
- [x] T022 Add GUT coverage for Living Wood + Fire Essence -> Warm Hollow.
- [x] T023 Add GUT coverage for Warm Hollow Meadow and Fire placement outcomes.
- [x] T024 Update migration-sensitive tests and recipe docs to reflect the no-duplicate ritual path.
- [x] T025 Run focused GUT suites and headless parse validation.
