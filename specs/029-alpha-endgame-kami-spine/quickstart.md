# Quickstart: Alpha Endgame Kami Spine

## Focused Validation Commands

```powershell
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
.\tools\godot.ps1 -Command test -Test tests/unit/spirits/test_spirit_service.gd
.\tools\godot.ps1 -Command test -Test tests/unit/test_satori_service.gd
.\tools\godot.ps1 -Command test -Test tests/unit/test_first_expansion_loop.gd
```

Add new focused tests for Void-separated islands and Suijin invitation when implementation begins.

## Manual Endgame Script

1. Start from a fresh save.
2. Complete first-session loop.
3. Stabilize first island enough to reach the Ku gate.
4. Trigger Mist Stag.
5. Confirm Ku unlocks and Ku recipes become available.
6. Shape Ku Seed and place Void.
7. Confirm Void separates islands.
8. Build a qualifying calm water island with at least 10 water tiles, no fire-based tiles, and Satori 1000.
9. Place the Chi+Ku biome on that island.
10. Confirm Suijin arrives once.
11. Save, quit, reload.
12. Confirm Ku, Void island separation, Chi+Ku biome placement, and Suijin state persist.

## Completion Evidence

The spec is verified only after the manual endgame script and focused automated checks both pass.
