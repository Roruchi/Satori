# Research: Voxel Rendering and Mesh Merging (Feature 009)

All open research questions from the Phase 0 plan resolved here.

---

## R1 — Godot 4.6 Batching Strategy for Voxel Tiles

**Decision**: Use `MultiMeshInstance3D` per chunk, one instance per (biome, bitmask-variant, LOD-level) tuple.

**Rationale**: `MultiMeshInstance3D` is Godot 4's idiomatic batching primitive. It submits all instances of the same mesh in a single draw call, supports per-instance transform data, and integrates with the visibility system. Direct `RenderingServer` calls are unnecessary complexity for a tile count of ≤5,000. `GPUParticles3D` is not appropriate for static geometry.

**Chunk size**: 8×8 tiles (64 tiles per chunk). At 5,000 tiles this yields ~80 active chunks. An 8×8 chunk has at most 64 tiles; a `MultiMesh` rebuild on one chunk costs ≤1ms on mid-range hardware.

**Alternatives considered**:
- `RenderingServer` direct mesh push: lower-level, fragile, harder to debug.
- Single global `MultiMesh` per biome (no chunking): invalidates entire mesh on any placement → unacceptable cost for large gardens.

---

## R2 — Mesh Variant Representation (8-bit Bitmask)

**Decision**: Pre-author a small set of canonical mesh shapes (isolated, edge N/E/S/W, corner NE/NW/SE/SW, full-surround, etc.) as Godot `.tres` `ArrayMesh` resources. The `TileMeshLibrary` maps the 8-bit bitmask value to one of these canonical shapes via a lookup table, collapsing 256 raw bitmask values to ≈47 visually distinct configurations (the standard Wang tile / blob tile reduction).

**Rationale**: 256 separate mesh assets per biome is unmanageable for 10 biomes (2,560 assets). The Wang tile / blob autotile system reduces this to ≈47 canonical shapes. Mapping 256→47 is a compile-time table, not a runtime computation. Pre-authored meshes allow artists to iterate without code changes.

**Alternatives considered**:
- Procedural `ArrayMesh` generation at runtime: possible but requires a geometry algorithm per biome variant; deferred to a later enhancement.
- 4-bit (cardinal-only) bitmask: faster but produces visible corner seams; 8-bit is preferred per spec.

---

## R3 — Colorblind Palette Shader Strategy

**Decision**: Author one `ShaderMaterial` with a `uniform sampler2D` palette LUT (4×1 texture, one colour per biome "slot"). All tile meshes share a single material instance (via `next_pass` or material override). Toggling the palette swaps the LUT texture uniform — one `ShaderMaterial.set_shader_parameter` call per frame.

**Rationale**: A LUT texture swap is a sub-microsecond GPU state change. Using one shared `ShaderMaterial` means all instanced tiles update simultaneously with a single call. Biome colour is encoded as a per-instance custom data float (biome index 0–9), which indexes into the LUT row.

**Alternatives considered**:
- Per-tile material override: requires N material updates per frame — unacceptable.
- Vertex colour baking: makes the palette swap impossible without CPU mesh rebuild — rejected.

---

## R4 — Godot 4.6 LOD Strategy

**Decision**: Use `GeometryInstance3D.visibility_range_end` / `visibility_range_begin` properties on the `MultiMeshInstance3D` nodes, pairing a full-detail node and a low-detail node per chunk. The `LodController` sets the visibility range on each pair when the camera moves.

**Rationale**: Godot 4's built-in `MESH_LOD_*` automatic system works best for large, individual meshes. For a grid of small tiles, chunk-level visibility switching is simpler and has predictable performance. Two `MultiMeshInstance3D` nodes per chunk (full + LOD) means at most 2×80 = 160 nodes — trivial scene overhead.

**LOD distance**: configurable `lod_distance` export variable defaulting to 20 tile-units (640 px at TILE_SIZE=32). Chunks whose centre is beyond this distance switch to the low-detail mesh.

**Alternatives considered**:
- Manual per-tile LOD (individual nodes): too many nodes for 5,000 tiles.
- Godot automatic `lod_bias`: works per `GeometryInstance3D` but requires the mesh to have explicit LOD levels authored — adds authoring overhead.

---

## R5 — Safe Chunk Size and Rebuild Budget

**Decision**: 8×8 tile chunks (64 tiles/chunk).

**Budget analysis**: On a Snapdragon 778G, `MultiMesh.set_instance_transform()` for 64 entries + one draw call submit costs well under 1ms. A burst placement (e.g., 100 tiles in one frame) dirtys at most ⌈100/64⌉ = 2 chunks. Bitmask updates propagate to neighbours (up to 8 per tile), potentially dirtying 2–3 chunks. Total chunk rebuilds per frame burst: ≤6. At ≤1ms each, total cost ≤6ms — safely within the 16.7ms budget.

**Alternatives considered**:
- 16×16 chunks: fewer nodes, but a single Stone cluster merge on a 16×16 boundary forces a full 256-entry MultiMesh rebuild in one call.
- 4×4 chunks: too many nodes (>300 chunks for 5,000 tiles).

---

## R6 — Biome Transition Decoration Types (MVP)

**Decision**: Implement the following cross-biome transition pairs for MVP. Additional pairs are data-driven and can be added without code changes.

| Pair (sorted) | Decoration | Spawn location |
|---|---|---|
| FOREST ↔ WATER | Reed cluster (3 voxel reeds) | Water-side edge voxels |
| FOREST ↔ WATER | Muddy riverbank | Forest-side edge voxels |
| STONE ↔ WATER | Rocky shore | Water-side edge voxels |
| EARTH ↔ WATER | Sandy bank | Water-side edge voxels |
| FOREST ↔ EARTH | Fallen log / root | Earth-side edge voxels |

**Data structure**: A `BiomeTransitionLibrary` dictionary keyed by `[biome_a, biome_b]` (sorted) → `TransitionDecoration` resource (mesh + offset + count). Spawned as lightweight `MeshInstance3D` nodes parented to `VoxelGarden`.

**Alternatives considered**:
- Encoding transitions as extra bitmask bits: bitmask explosion (10×10 biome combos × 256 = 25,600 entries) — rejected.
- Hand-placing transition objects: not generative — rejected per problem statement.

---

## Summary Table

| Research Item | Decision |
|---|---|
| R1 Batching | `MultiMeshInstance3D` per 8×8 chunk per variant |
| R2 Mesh variants | Wang/blob reduction: 256→47 canonical meshes per biome |
| R3 Palette toggle | Shared LUT texture uniform swap via one `set_shader_parameter` call |
| R4 LOD | Chunk-level visibility range switching, 20-tile-unit default |
| R5 Chunk size | 8×8 tiles; ≤6 chunk rebuilds per burst frame |
| R6 Transitions | 5 biome-pair types for MVP; data-driven extension table |
