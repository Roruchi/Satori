# Satori Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-03

## Active Technologies
- GDScript (Godot 4.6) + Godot built-ins, existing `PatternScanService` autoload, `PatternMatcher`, `PatternDefinition`, GUT (`addons/gut/`) (006-tier1-biome-discoveries)
- Garden save file under `user://` including a persisted discovery log payload (006-tier1-biome-discoveries)
- GDScript on Godot 4.6 + Godot runtime only; GUT test framework in `addons/gut` (016-add-ku-aether)
- Existing JSON persistence files under `user://`; no new persistence guarantees added in this feature (016-add-ku-aether)
- GDScript on Godot 4.6 + Existing crafting UI/menu scripts under `src/ui`, recipe/crafting logic under `src/seeds` and related gameplay services, GUT (`addons/gut`) (019-seed-crafting-grid)
- Existing runtime/autoload state and current save flow; no new storage backend required in this phase (019-seed-crafting-grid)
- GDScript on Godot 4.6 + `src/autoloads/seed_alchemy_service.gd`, `src/seeds/SeedPouch.gd`, `src/ui/HUDController.gd`, `src/ui/SeedAlchemyPanel.gd`, `src/grid/PlacementController.gd`, `src/grid/GardenView.gd`, existing recipe/discovery services (020-craft-mode-buildings)
- Existing save/autoload state and discovery persistence; no new external storage backend (020-craft-mode-buildings)

- [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION] + [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION] (master)

## Project Structure

```text
backend/
frontend/
tests/
```

## Commands

cd src; pytest; ruff check .

## Code Style

[e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]: Follow standard conventions

## Recent Changes
- 020-craft-mode-buildings: Added GDScript on Godot 4.6 + `src/autoloads/seed_alchemy_service.gd`, `src/seeds/SeedPouch.gd`, `src/ui/HUDController.gd`, `src/ui/SeedAlchemyPanel.gd`, `src/grid/PlacementController.gd`, `src/grid/GardenView.gd`, existing recipe/discovery services
- 019-seed-crafting-grid: Added GDScript on Godot 4.6 + Existing crafting UI/menu scripts under `src/ui`, recipe/crafting logic under `src/seeds` and related gameplay services, GUT (`addons/gut`)
- 016-add-ku-aether: Added GDScript on Godot 4.6 + Godot runtime only; GUT test framework in `addons/gut`


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
