# Quickstart: Voxel Rendering and Mesh Merging (Feature 009)

Developer runbook for implementing, testing, and validating feature 009.

---

## Prerequisites

- Godot 4.6 editor open on the `009-voxel-rendering-merging` branch.
- GUT addon present at `addons/gut/`.
- The existing garden runs without errors on `main`: open `scenes/Garden.tscn` and press F5.

---

## Step 1 — Run Existing Tests (Baseline)

```text
1. Open Godot editor.
2. Select Scene → Open → tests/gut_runner.tscn.
3. Press F5 (Run Current Scene).
4. Verify all existing tests pass before making any changes.
```

---

## Step 2 — Implement Core Rendering Layer

Create files in the order listed in `tasks.md`. The dependency order is:

```
BitmaskAutotiler
  └▶ TileMeshLibrary
       └▶ TileChunkRenderer
            └▶ VoxelRenderer (orchestrator)
                 ├▶ MountainClusterTracker
                 │    └▶ MountainMeshBuilder
                 ├▶ BiomeTransitionLayer
                 └▶ LodController
```

**Tip**: Implement and unit-test each layer before moving to the next.

---

## Step 3 — Manual Validation: Bitmask Autotiling (US1)

```text
1. Press F5 to run the garden.
2. Place a single Forest tile at any empty location.
   Expected: Tile shows the "isolated" voxel mesh (no connecting edges).
3. Place a second Forest tile adjacent (any cardinal direction).
   Expected: Both tiles update their mesh in the SAME frame to show
   the matching edge-connected variant (no single-frame stale state visible).
4. Surround the first tile on all 4 cardinal sides with Forest tiles.
   Expected: Centre tile updates to the 4-cardinal-connected variant.
5. Add diagonal Forest neighbours.
   Expected: Centre tile updates to the 8-bit variant.
```

---

## Step 4 — Manual Validation: Biome Transition Decorations

```text
1. Place a Forest tile, then a Water tile adjacent to it.
   Expected: On the shared edge, reed decoration voxels appear on the
   Water-side and a muddy riverbank appears on the Forest-side.
2. Place a Stone tile adjacent to a Water tile.
   Expected: Rocky shore decoration appears on the Water-side edge.
3. Place an Earth tile adjacent to a Water tile.
   Expected: Sandy bank decoration appears on the Water-side edge.
```

---

## Step 5 — Manual Validation: Mountain Cluster Merge (US2)

```text
1. Place 9 Stone tiles in a connected cluster.
   Expected: All 9 tiles show individual Stone voxel meshes.
2. Place the 10th Stone tile connected to the cluster.
   Expected: ALL 9 individual meshes disappear and ONE unified Mountain
   mesh replaces them in the SAME render frame. No frame exists where
   both individual and Mountain meshes are visible simultaneously.
3. Place an 11th Stone tile touching the cluster.
   Expected: Mountain mesh re-merges to include all 11 tiles in the
   same frame.
4. Start fresh. Build two separate Stone clusters of 8 tiles each.
   Place a bridging Stone tile (17-tile cluster).
   Expected: Both separate clusters and the bridge tile merge into a
   single Mountain mesh in the same frame.
```

---

## Step 6 — Manual Validation: LOD and Performance (US3)

```text
1. Open the debug harness scene (to be created as part of tasks).
2. Load or procedurally generate a 5,000-tile garden.
3. Enable the Godot Profiler (Debugger → Profiler).
4. Pan slowly across the full garden for 60 seconds.
   Expected: Frame time sustained at ≤16.7ms.
5. Zoom out to maximum camera distance.
   Expected: Distant chunks switch to LOD mesh variants (fewer voxels
   visible on tiles far from the camera).
```

---

## Step 7 — Manual Validation: Colorblind Palette Toggle (US4)

```text
1. With Forest, Water, Stone, and Earth tiles all visible on screen,
   open Settings and toggle "Colorblind Palette" ON.
   Expected: ALL tile colours change to the high-contrast variant in
   the same frame; no tile retains the standard colour.
2. Toggle the setting OFF.
   Expected: All tiles revert to standard colours in the same frame.
3. Place a new tile while the colorblind palette is active.
   Expected: The new tile renders in the high-contrast variant from
   the first frame — no flash of standard colour.
```

---

## Step 8 — Automated Tests

Run the new GUT test suites:

```text
1. Open tests/gut_runner.tscn.
2. Run all tests.
3. Verify the following suites pass:
   - test_bitmask_autotiler.gd
   - test_mountain_cluster.gd
   - test_biome_transition.gd
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Tile shows no mesh | `TileMeshLibrary` not initialised | Ensure `VoxelRenderer._ready()` calls `_init_library()` before connecting signals |
| Mountain mesh appears one frame late | `cluster_merged` signal not connected before `_process` | Connect signal in `_ready()`, not `_process()` |
| Colorblind palette only updates new tiles | Shared material not set | Confirm all `MultiMeshInstance3D` nodes share the same `ShaderMaterial` instance |
| Bitmask does not include diagonal | Wrong bitmask bit order | Check `BitmaskAutotiler` bit layout matches the contract in `data-model.md` |
| Reed decoration spawns in wrong position | Offset not applied in tile-space | Decoration offset should be in local tile units, then converted to world-space |
