# Research: Hexagonal Tile System (014-hex-tiles)

## Decision 1: Hex Coordinate System

**Decision:** Axial coordinates (q, r) stored as `Vector2i(q, r)`.

**Rationale:**
- Axial coords give O(1) neighbor lookup via fixed offset table — same as the current
  square system's `[Vector2i(1,0), ...]` pattern, so every call-site change is mechanical.
- `Vector2i` is already the grid's coordinate type (`GardenTile.coord`,
  `GardenGrid` dictionary key), so no type-signature breaks propagate to autoloads,
  signals, or persistence — only the *semantic* meaning of the stored values changes.
- Cube coordinates (q, r, s where q+r+s=0) are mathematically richer but the third
  component is always derivable (`s = -q - r`), making storage in `Vector2i` lossless.
- Offset coordinates (odd-r / even-r) are intuitive but make neighbor arithmetic
  row-parity-dependent, causing branching throughout spatial_query, autotiler, and
  every pattern matcher.

**Alternatives considered:**
- *Cube (3-axis) storage*: Clean math but requires `Vector3i`; would break every
  typed call-site that touches coordinates.
- *Offset (odd-r)*: Familiar row/column look but parity conditionals in every
  neighbor function — higher ongoing maintenance cost.

---

## Decision 2: Hex Orientation

**Decision:** Pointy-top hexagons (vertex pointing up / down, flat sides on left / right).

**Rationale:**
- Standard convention for strategy / exploration games; natural fit for maps that
  scroll vertically.
- Axial neighbor offsets for pointy-top are:
  `[Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)]`
  — six clean values, no parity logic.
- Pixel ↔ axial conversion (tile radius `R`):
  - `pixel_x = R * sqrt(3) * (q + r / 2.0)`
  - `pixel_y = R * 1.5 * r`
  - Inverse: `q = (pixel_x * sqrt(3)/3 - pixel_y / 3) / R`,
    `r = pixel_y * 2/3 / R` (then round to nearest axial hex via cube-rounding).

**Alternatives considered:**
- *Flat-top*: Suits hexagons stacked in columns; neighbourhood offsets are equally
  clean but the vertical scroll convention favours pointy-top.

---

## Decision 3: Bitmask Strategy — 6-bit Hex Autotiling

**Decision:** Replace the current 8-bit Wang-blob system (47 canonical square forms)
with a 6-bit hex bitmask (64 raw states → **13 canonical forms** under D6 symmetry).

**Rationale:**
- The current `BitmaskAutotiler` already abstracts the bitmask→canonical mapping;
  the change is localised to that one script plus the mesh library.
- A hex tile has 6 possible same-biome neighbours. Each neighbour is either present (1)
  or absent (0) → 2⁶ = 64 raw bitmask values.
- The dihedral group D6 (6-fold rotation + 1 reflection = 12 transformations) partitions
  the 64 raw states into **13 equivalence classes** (canonical forms 0–12):

  | Index | Name               | Neighbor count | Description                           |
  |-------|--------------------|---------------|---------------------------------------|
  | 0     | Island             | 0             | No matching neighbours                |
  | 1     | Tip                | 1             | One neighbour                         |
  | 2     | Straight           | 2 (opposite)  | Neighbours at 180° (line continuation)|
  | 3     | Bend               | 2 (adjacent)  | Neighbours at 60°                     |
  | 4     | Y-branch           | 3 (every-other)| Alternating — Y / tristar             |
  | 5     | Arc                | 3 (consecutive)| Three in a row                        |
  | 6     | T-shape            | 3 (skip-1)    | Two consecutive + one across gap      |
  | 7     | Nub                | 4 (skip-2)    | Four, skipping two opposite           |
  | 8     | Flat               | 4 (consecutive)| Four in a row                        |
  | 9     | Wide-T             | 4 (skip-1)    | Four with one gap                     |
  | 10    | Pinch              | 5 (missing 1) | All but one                           |
  | 11    | Full               | 6             | All six neighbours present            |
  | 12    | Cross              | 4 (opposite pairs, skip-1 each side) | Special 4-neighbour form |

  (Canonical index assignment is arbitrary; the mesh library maps index → mesh resource.)
- Fewer canonical forms (13 vs 47) means fewer mesh assets to author per biome,
  which reduces art scope significantly.
- Corner-dependency normalisation from the square bitmask becomes irrelevant for hex
  (there are no diagonal neighbours to demote).

**Alternatives considered:**
- *Keep 8-bit bitmask on hex*: Diagonal neighbours don't exist on a hex grid, so the
  high bits would always be zero — wastes the existing canonical-mapping table and
  forces the autotiler to carry dead code.
- *No bitmask / single mesh per biome*: Simpler but eliminates autotile variety;
  borders between biomes would look monotone.

---

## Decision 4: Shape Pattern Migration

**Decision:** Define hex shape patterns as sets of **axial-coordinate offsets relative
to an anchor tile** (same structural approach as the current square patterns, just with
new offset values). Existing pattern resources are replaced, not migrated.

**Rationale:**
- The current `PatternDefinition` resource stores a list of `Vector2i` offsets for
  shape templates. The type does not change — only the values stored in `.tres` files.
- Square-specific patterns (L-shapes, plus signs, rows) have no hex equivalents;
  new hex-native patterns (hex rings, triangles, parallelograms) are richer and more
  interesting for gameplay.
- Since this is an early-development project with no locked player progress, replacing
  pattern resources is acceptable. The `DiscoveryRegistry` keyed on discovery IDs
  (not coordinate patterns) means IDs can be preserved across the redesign.

**Alternatives considered:**
- *Automated square-to-hex offset projection*: The geometries are not equivalent; a
  mechanical projection would produce misaligned or degenerate patterns.

---

## Decision 5: Chunk System

**Decision:** Retain the 8×8 chunk footprint concept. Chunk assignment uses integer
division on axial coordinates: `chunk_coord = Vector2i(floori(q / 8.0), floori(r / 8.0))`.

**Rationale:**
- Chunk boundaries are only used for MultiMesh batching and LOD grouping, not for
  gameplay logic. The exact shape does not need to be a regular hex region.
- Axial integer-division chunks are axis-aligned rectangles in axial space, which keep
  the chunk assignment O(1) and require no changes to chunk boundary data structures.
- The slight non-uniformity in world-space footprint (axial rectangles are parallelograms
  in pixel space) is invisible to players and inconsequential for LOD.

**Alternatives considered:**
- *Hex-region chunks (radius-4 hex ring)*: Geometrically clean but makes chunk
  assignment and neighbour-chunk enumeration non-trivial; not justified for batching.

---

## Decision 6: Save Compatibility

**Decision:** Treat existing saves as incompatible. `GardenTile.coord` values in any
existing save file encoded square-grid positions; they are not valid axial hex coords.
On load, detect the format version mismatch and route the player to a new-game flow
with a clear UI message.

**Rationale:**
- The project has no published release; no player data is at risk.
- A format-version field (already a good practice for any save system) makes future
  migrations tractable without special-casing the square-to-hex transition.
- Attempting a mathematical projection of square positions to hex positions would
  produce an ill-shaped, sparse garden — a worse experience than starting fresh.

**Alternatives considered:**
- *Coordinate projection*: Square (x, y) → axial (q, r) = (x, y) is numerically valid
  but the square arrangement in hex-space has diagonal "staircase" gaps incompatible
  with the hex adjacency rules.
