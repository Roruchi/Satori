<!--
Sync Impact Report
- Version change: template -> 1.0.0
- Modified principles:
	- Template Principle 1 -> I. Spec-Driven Delivery
	- Template Principle 2 -> II. Godot-Native Architecture
	- Template Principle 3 -> III. Testable Gameplay Systems
	- Template Principle 4 -> IV. Deterministic World Rules
	- Template Principle 5 -> V. Mobile Experience Budgets
- Added sections:
	- Technical Guardrails
	- Workflow & Review
- Removed sections:
	- None
- Templates requiring updates:
	- ✅ .specify/templates/plan-template.md
	- ✅ .specify/templates/spec-template.md
	- ✅ .specify/templates/tasks-template.md
	- ✅ specs/master/plan.md
	- ✅ specs/master/quickstart.md
	- ✅ .github/prompts/speckit.constitution.prompt.md (validated, no change required)
	- ✅ .github/prompts/speckit.plan.prompt.md (validated, no change required)
	- ✅ .github/prompts/speckit.specify.prompt.md (validated, no change required)
	- ✅ .github/prompts/speckit.tasks.prompt.md (validated, no change required)
- Follow-up TODOs:
	- None
-->

# Satori Constitution

## Core Principles

### I. Spec-Driven Delivery
Every material feature or workflow change MUST begin in the Speckit flow with a
numbered spec directory under `specs/`, then advance through clarification,
planning, tasks, and implementation. Plans MUST include a Constitution Check,
and tasks MUST stay traceable to independent user stories or explicitly shared
foundational work. This project already tracks delivery as sequential features,
so the constitution formalizes that structure instead of treating it as optional.

### II. Godot-Native Architecture
Runtime code MUST remain Godot-native: gameplay logic in GDScript under `src/`,
scene composition under `scenes/`, project wiring in `project.godot`, and only
cross-cutting state or services promoted to autoloads. External build systems,
package managers, or parallel architecture layers MUST NOT be introduced unless a
spec proves the engine cannot satisfy the requirement. This preserves the current
single-project workflow and keeps editor behavior, exports, and debugging aligned.

### III. Testable Gameplay Systems
Deterministic gameplay logic, persistence, discovery rules, and regression-prone
bug fixes MUST ship with executable validation. Automated coverage uses GUT under
`tests/`, while scene or interaction-heavy work MUST also define manual validation
through the in-editor game flow or debug harness. If a feature cannot be covered
with automation, the plan and tasks MUST state the manual verification path and
why automation is insufficient.

### IV. Deterministic World Rules
Core garden rules MUST remain data-driven, reproducible, and stable across saves.
Biome mixing, pattern matching, discovery triggering, and persistence behavior
MUST be encoded so the same garden state produces the same result without hidden
editor-only state. Production gameplay MUST preserve the project's permanence
model: no undo, no reset, and no rule bypasses outside explicitly debug-only
tooling. This protects the game's defining "Permanent Emergence" identity.

### V. Mobile Experience Budgets
Features MUST preserve the mobile-first experience and the performance budgets
already established by the project. Changes affecting input, rendering, scanning,
save/load, or UI MUST account for thumb-zone reachability, accessibility toggles,
stable 60 fps on mid-range mobile hardware, pattern scan targets, and startup or
restore time expectations. Features that threaten these budgets MUST document the
tradeoff and mitigation before implementation proceeds.

## Technical Guardrails

- Godot 4.6 is the baseline engine version unless a ratified amendment changes it.
- GUT is the project's automated test framework; new testing guidance MUST align
	with `addons/gut/` and `tests/gut_runner.tscn`.
- Autoload singleton names MUST NOT match a script `class_name`.
- In warnings-as-errors contexts, values returned as `Variant` MUST use explicit
	type annotations instead of inferred `:=` forms.
- Typed cross-script dependencies SHOULD prefer `preload("res://...")` when load
	order or registration timing could affect parsing.
- Performance-sensitive systems SHOULD favor sparse dictionaries, chunk-aware
	structures, and deferred or threaded work that does not block rendering.
- Accessibility-facing settings such as haptics, contrast, and audio controls
	MUST persist independently from garden-save data.

## Workflow & Review

- Each plan MUST document the affected runtime areas, validation strategy, and any
	impact on permanence, determinism, performance, or accessibility budgets.
- Each task list MUST include the concrete files touched in `src/`, `scenes/`,
	`tests/`, or `specs/`, plus the validation work required to prove completion.
- Reviews MUST reject changes that bypass Speckit artifacts, add unplanned engine
	complexity, weaken deterministic rules, or omit verification for game logic.
- Debug scenes, overlays, and instant-action tooling are allowed only when they
	stay excluded from release behavior or are explicitly gated for non-release use.
- Runtime guidance files such as `CLAUDE.md` and `project.godot` MUST be treated
	as operational sources of truth when they define engine or workflow constraints.

## Governance

This constitution supersedes conflicting local planning habits and template text.
Amendments MUST update this file and any affected templates or guidance artifacts
in the same change. Versioning follows semantic versioning: MAJOR for removing or
redefining a principle in a backward-incompatible way, MINOR for adding a new
principle or materially expanding governance, and PATCH for clarifications or
non-semantic wording changes. Compliance review is mandatory during planning and
again during implementation review; any justified exception MUST be recorded in
the plan's Complexity Tracking or equivalent decision log. Operational guidance in
`CLAUDE.md` remains subordinate to this constitution and should be updated when
project practice changes.

**Version**: 1.0.0 | **Ratified**: 2026-03-23 | **Last Amended**: 2026-03-23
