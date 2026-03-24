# Contract: Tile Mesh Variant Lookup

**Owner**: `src/rendering/tile_mesh_library.gd`
**Consumers**: `TileChunkRenderer`, `VoxelRenderer`

---

## Purpose

`TileMeshLibrary` is the authoritative source for converting a `(biome, raw_bitmask_8bit)` pair into a renderable `Mesh` resource. It decouples mesh asset management from tile placement logic.

---

## API

### `get_mesh(biome: int, bitmask8: int, lod: bool) -> Mesh`

Returns the `Mesh` resource for the given biome and raw 8-bit bitmask.

**Parameters**:
- `biome`: A valid `BiomeType.Value` integer (0–9). `NONE` (-1) is not valid.
- `bitmask8`: Integer in range `[0, 255]`. Internally mapped to the canonical Wang index.
- `lod`: `true` returns the reduced-detail mesh; `false` returns full detail.

**Returns**: A non-null `Mesh`. Falls back to the default isolated mesh for the biome if no variant is registered.

**Guarantees**:
- Never returns `null`.
- Same inputs always produce the same output (deterministic / pure function).
- Thread-safe for read access after initialisation.

**Errors**: `push_error` and return fallback mesh if `biome` is out of range.

---

### `get_transition_mesh(biome_a: int, biome_b: int) -> TransitionDecorationData`

Returns the decoration data resource for a biome-pair edge, or `null` if no transition is defined for this pair.

**Parameters**:
- `biome_a`, `biome_b`: Two different `BiomeType.Value` integers. Internally sorted so `biome_a ≤ biome_b`.

**Returns**: A `TransitionDecorationData` resource or `null`.

---

## Invariants

- The library MUST be initialised before any call to `get_mesh`.
- Canonical bitmask mapping is fixed at compile time; it MUST NOT change between frames.
- Adding new mesh assets MUST NOT require changes to caller code.

---

## Versioning

This contract is stable. Breaking changes (removing a method, changing return types) require a spec amendment and migration task.
