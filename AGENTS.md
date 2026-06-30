# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project

**Satori** is a Godot 4.6 game project. All game code is written in GDScript (`.gd`), scenes use `.tscn`, and resources use `.tres`/`.res`. The engine is configured with Jolt Physics (3D) and Forward Plus rendering via Direct3D 12.

## Engine & Development

- **Open in Godot:** Launch `project.godot` with Godot 4.6+
- **Run the game:** Press F5 in the Godot editor, or `godot --path . --headless` for headless runs
- **Export:** Use the Godot editor Export dialog; no build scripts exist yet
- **No package manager or lint toolchain** — GDScript is interpreted by the engine; there is no separate compile/lint step outside Godot

## Speckit Workflow

This repo uses **Speckit** (v0.3.2) for specification-driven, AI-assisted feature development. The standard workflow is:

1. `/speckit.specify` — write or update a feature spec
2. `/speckit.clarify` — resolve ambiguities in the spec
3. `/speckit.plan` — generate a technical design/plan
4. `/speckit.tasks` — break the plan into ordered tasks
5. `/speckit.implement` — execute the tasks
6. `/speckit.checklist` — validate completion

Supporting commands: `/speckit.analyze` (consistency check), `/speckit.constitution` (edit project principles), `/speckit.taskstoissues` (GitHub issues).

Helper PowerShell scripts live in `.specify/scripts/powershell/` — run them with `pwsh` or `powershell`:
- `check-prerequisites.ps1` — verify tooling is set up
- `create-new-feature.ps1` — scaffold a new feature branch
- `update-agent-context.ps1` — refresh agent context files

Branch names follow **sequential numbering** (configured in `.specify/init-options.json`).

## Repository Conventions

- Line endings: **LF** (enforced via `.gitattributes`)
- Encoding: **UTF-8**
- `.godot/` directory is gitignored (editor cache)

## Satori Agent Operating Rules

- Use `tools/godot.ps1` as the normal validation entrypoint. For gameplay/code changes, run `-Command parse`, then focused GUT with `-Command test -Test "res://..."`, and run `-Command boot` when autoloads, startup, scenes, persistence, or UI initialization changed.
- In fresh worktrees, repair Godot state before blaming gameplay code: run a headless editor import if `.godot` cache/global classes are missing. If Godot cannot write to normal user directories, redirect `APPDATA` and `LOCALAPPDATA` to a workspace-local `.codex-godot-home` and rerun validation sequentially.
- Keep recipes, CSVs, specs, and runtime data in sync. When rituals, materials, recipes, tile unlocks, structure effects, or discovery data change, update the matching runtime CSVs, catalog scripts, viewer/export tooling, `specs/master/recipes.md`, and owning spec docs in the same change. No doc/spec/data drift is allowed; treat drift as a blocking issue before validation or handoff.
- Concrete gameplay requests should become playable behavior, not metadata-only edits. Wire mechanics through existing services/data/UI paths, add focused coverage, and verify the player-visible loop.
- Treat UX requirements as acceptance criteria. Slot-first ritual flow, clear inventory-vs-overworld material presentation, readable unlock requirements, compact debug overlays, and immediate layout after mode switches are part of done, not optional polish.
- Preserve established design invariants unless the user explicitly changes them: no duplicate ritual inputs, 2-token recipes stay reserved for mixed seeds, building placement consumes real inventory/resources, ritual spirit inputs require active housed spirits, and progression gates such as Mist Stag/Ku/second-island unlocks should not be loosened silently.

## Godot GDScript Guardrails (All Agents)

- Do **not** give an autoload singleton key the same name as a script `class_name` (e.g. autoload `PatternScanService` for script `class_name PatternScanScheduler`). Godot treats this as a parse error.
- In files where warnings are treated as errors, avoid `:=` when the right-hand side can be `Variant` (common examples: `Array.pop_front()`, `Dictionary.get()`, dynamic `Callable.call()`). Use explicit type annotations instead.
- Prefer `preload("res://...")` for cross-script dependencies used in typed contexts to avoid script registration/load-order surprises.
- After introducing new scripts or typed signals, run a parse/error check before finalizing changes.
