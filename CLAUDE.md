# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

## Godot GDScript Guardrails (All Agents)

- Do **not** give an autoload singleton key the same name as a script `class_name` (e.g. autoload `PatternScanService` for script `class_name PatternScanScheduler`). Godot treats this as a parse error.
- In files where warnings are treated as errors, avoid `:=` when the right-hand side can be `Variant` (common examples: `Array.pop_front()`, `Dictionary.get()`, dynamic `Callable.call()`). Use explicit type annotations instead.
- Prefer `preload("res://...")` for cross-script dependencies used in typed contexts to avoid script registration/load-order surprises.
- After introducing new scripts or typed signals, run a parse/error check before finalizing changes.
