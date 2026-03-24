# Data Model: Hexagonal Tile System (014-hex-tiles)

## HexCoord (value object — stored as Vector2i)

Represents a tile position in the axial hex coordinate system.

| Field | Type     | Description                                  |
|-------|----------|----------------------------------------------|
| q     | int      | Axial column axis (the x component of Vector2i) |
| r     | int      | Axial row axis (the y component of Vector2i)    |

**Invariants:**
- No validation on q/r range; the grid is unbounded (sparse dictionary).
- Two coordinates are equal when both q and r are equal.
- Cube coordinate `s` is always derivable as `-q - r` (not stored).

**Neighbor offsets (pointy-top, axial):**
```
HEX_NEIGHBORS := [
  Vector2i( 1,  0),   # E
  Vector2i(-1,  0),   # W
  Vector2i( 0,  1),   # SE
  Vector2i( 0, -1),   # NW
  Vector2i( 1, -1),   # NE
  Vector2i(-1,  1),   # SW
]
```

---

## GardenTile (unchanged structure, updated coord semantics)

Represents one tile on the garden map. Stored in the sparse grid keyed by its
axial coord.

| Field    | Type       | Description                                              |
|----------|------------|----------------------------------------------------------|
| coord    | Vector2i   | Axial hex coordinate (q, r)                              |
| biome    | int        | BiomeType.Value enum                                     |
| locked   | bool       | True after mixing; tile cannot be replaced               |
| metadata | Dictionary | Extensible bag: discovery_ids, spirit_id, etc.           |

**Note:** The field type (`Vector2i`) does not change. Only the interpretation of
stored values changes from square-grid (x, y) to axial hex (q, r). This is the
root cause of save incompatibility — see Decision 6 in research.md.

---

## GardenGrid (unchanged interface, updated adjacency logic)

Sparse dictionary-backed map of all placed tiles.

| Field         | Type      | Description                                |
|---------------|-----------|--------------------------------------------|
| _tiles        | Dictionary| Vector2i → GardenTile                     |
| garden_bounds | Rect2i    | Bounding box in axial space (approx.)      |
| total_count   | int       | Number of tiles placed                     |

**Changed behaviour:**
- `is_placement_valid(coord)` now checks hex adjacency (6 offsets) instead of
  cardinal adjacency (4 offsets).
- Bounds tracking (`garden_bounds`) continues to use Rect2i as an axial-space
  approximation; it is used only for iteration hints, not for player display.

---

## HexUtils (new pure-utility script)

Stateless functions for hex math. No node, no autoload, no class_name — accessed
via `preload("res://src/grid/hex_utils.gd")`.

| Function                                  | Returns   | Description                                     |
|-------------------------------------------|-----------|-------------------------------------------------|
| `get_neighbors(coord: Vector2i) → Array[Vector2i]` | Array | Returns 6 neighbor coords           |
| `axial_to_pixel(coord: Vector2i, radius: float) → Vector2` | Vector2 | Hex centre in screen space |
| `pixel_to_axial(px: Vector2, radius: float) → Vector2i` | Vector2i | Nearest hex to pixel pos |
| `axial_distance(a: Vector2i, b: Vector2i) → int` | int | Hex distance (cube-derived)         |
| `axial_to_cube(coord: Vector2i) → Vector3i` | Vector3i | For distance/rounding helpers      |
| `cube_round(cube: Vector3) → Vector3i`     | Vector3i  | Round fractional cube to nearest hex |
| `axial_ring(center: Vector2i, radius: int) → Array[Vector2i]` | Array | All coords at exact distance |

**Pixel ↔ axial formulas (pointy-top, tile_radius R):**
```
axial_to_pixel:
  x = R * sqrt(3) * (q + r / 2.0)
  y = R * 1.5 * r

pixel_to_axial (via fractional cube → cube_round → axial):
  fq = (px.x * sqrt(3)/3 - px.y / 3) / R
  fr = (px.y * 2.0/3.0) / R
  → cube_round(Vector3(fq, fr, -fq-fr)) → drop s → Vector2i(q, r)
```

---

## HexBitmask (value in TileRenderState)

Encodes same-biome neighbour presence around a hex tile.

| Bit | Direction | Offset          |
|-----|-----------|-----------------|
| 0   | E         | Vector2i( 1, 0) |
| 1   | W         | Vector2i(-1, 0) |
| 2   | SE        | Vector2i( 0, 1) |
| 3   | NW        | Vector2i( 0,-1) |
| 4   | NE        | Vector2i( 1,-1) |
| 5   | SW        | Vector2i(-1, 1) |

Raw value range: 0–63. Canonical form range: 0–12.

**Canonical mapping (D6 symmetry reduction):**

| Canonical | Pop-count | Bit pattern examples           |
|-----------|-----------|--------------------------------|
| 0         | 0         | 0b000000                       |
| 1         | 1         | 0b000001, 0b000010, … (×6)     |
| 2         | 2 (opp.)  | 0b000011, 0b001100, 0b110000   |
| 3         | 2 (adj.)  | 0b000110, 0b001001, … (×6)     |
| 4         | 3 (alt.)  | 0b010101, 0b101010             |
| 5         | 3 (cons.) | 0b000111, 0b001110, … (×6)     |
| 6         | 3 (skip1) | 0b001011, …  (×6)              |
| 7         | 4 (skip2) | 0b010011, … (×6)               |
| 8         | 4 (cons.) | 0b001111, 0b011110, … (×6)     |
| 9         | 4 (skip1) | 0b010111, … (×6)               |
| 10        | 4 (opp.)  | 0b110011, … (×3)               |
| 11        | 5         | 0b011111, 0b101111, … (×6)     |
| 12        | 6         | 0b111111                       |

The full 64→13 lookup table is computed once at startup in `BitmaskAutotiler` and
stored as a 64-element `Array[int]`.

---

## TileRenderState (updated field range)

| Field       | Type      | Change from current                                   |
|-------------|-----------|-------------------------------------------------------|
| coord       | Vector2i  | Now axial hex coord                                   |
| biome       | int       | Unchanged                                             |
| bitmask6    | int       | **Renamed** from bitmask8; range 0–63 (was 0–255)    |
| canonical   | int       | Range 0–12 (was 0–46)                                 |
| chunk_id    | Vector2i  | Axial integer-division chunk (unchanged structure)    |
| in_mountain | bool      | Unchanged                                             |

---

## PatternDefinition (updated resource fields)

| Field       | Type              | Change                                                 |
|-------------|-------------------|--------------------------------------------------------|
| id          | String            | Unchanged                                              |
| type        | PatternType enum  | Unchanged (CLUSTER, SHAPE, RATIO_PROXIMITY, COMPOUND) |
| offsets     | Array[Vector2i]   | Values updated to axial hex offsets; type unchanged   |
| …           | …                 | All other fields unchanged                            |

Shape pattern `.tres` resource files are replaced to encode hex offset templates.

---

## Save Format Version

A `version` field is added to the top-level save dictionary.

| Field   | Type   | Value after this feature |
|---------|--------|--------------------------|
| version | int    | 2 (was implicitly 1)     |

On load: if `version < 2` or `version` key absent → incompatible → new-game prompt.
