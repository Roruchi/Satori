# Quickstart: Alpha Save Safety

## Focused Validation Commands

```powershell
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
.\tools\godot.ps1 -Command test -Test tests/unit/test_save_game_service.gd
.\tools\godot.ps1 -Command test -Test tests/unit/test_first_expansion_loop.gd
```

Add or update save-specific tests as implementation begins.

## Manual Checkpoints

1. Save/reload after first Meadow placement.
2. Save/reload after Living Wood harvest.
3. Save/reload after first dwelling.
4. Save/reload after helper structure and Satori change.
5. Save/reload after Ku unlock.
6. Save/reload after Ku Seed places Void and Void separates islands.
7. Save/reload after Chi+Ku biome is placed on a calm water island with at least 10 water tiles, no fire-based tiles, and Satori 1000.
8. Save/reload after Suijin invitation.
9. Confirm the menu-visible build version matches the save metadata.
10. Trigger background/close save on Android when Android spec is active.
11. Reload Web build after browser refresh when Web spec is active.
