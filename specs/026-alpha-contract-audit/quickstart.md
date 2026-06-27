# Quickstart: Alpha Contract and State Audit

## 1. Confirm Roadmap Tracker

1. Open `docs/alpha-roadmap.md`.
2. Confirm the alpha finale says: unlock Ku, place Void to separate islands, place the Chi+Ku biome on an island with 10 water tiles, no fire-based tiles, and Satori 1000, then invite Suijin.
3. Confirm every roadmap phase maps to a numbered spec.

## 2. Capture Baseline Commands

Run from the repo root when ready to audit implementation:

```powershell
git -c safe.directory=C:/Repo/Personal/Games/Satori status --short --branch
.\tools\godot.ps1 -Command parse
.\tools\godot.ps1 -Command boot
```

Add focused GUT runs for the owning specs as implementation work begins.

## 3. Manual Alpha Spine Audit

Record whether a fresh save can:

1. Start a new garden.
2. Perform first ritual.
3. Plant and grow Meadow.
4. Harvest Living Wood.
5. Invite Red Fox.
6. Shape and place first dwelling.
7. See Satori pressure and recovery.
8. Unlock Mist Stag and Ku.
9. Place Void to separate islands.
10. Place the Chi+Ku biome on a qualifying calm water island.
11. Invite Suijin.
12. Save, restart, and continue.

## 4. Update Status

For each item, update the roadmap tracker as:

- `Not Started`
- `In Progress`
- `Blocked`
- `Verified`

Do not mark an item `Verified` without current evidence.
