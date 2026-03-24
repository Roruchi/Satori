# Quickstart: Hexagonal Tile System (014-hex-tiles)

## Overview

This feature replaces the square-tile grid with a hexagonal-tile grid throughout
Satori. The change touches coordinates, neighbor lookup, rendering, pattern matching,
and save compatibility. It does **not** change biome types, mixing rules, discovery IDs,
or the overall architecture.

## Key Concept: Axial Coordinates

All tile positions are stored as `Vector2i(q, r)` where `q` and `r` are axial
hex coordinates (pointy-top orientation). The helper `HexUtils` script centralises
all math.

```gdscript
const HexUtils = preload("res://src/grid/hex_utils.gd")

# Get all 6 neighbors of a tile
var neighbors: Array[Vector2i] = HexUtils.get_neighbors(tile.coord)

# Convert a tile coord to its pixel centre
# 2D GardenView uses TILE_RADIUS = 20.0 (circumradius, px)
# 3D renderers use TILE_RADIUS = 1.0 (world units)
var centre: Vector2 = HexUtils.axial_to_pixel(tile.coord, 20.0)

# Convert a mouse position back to the nearest hex coord
var hex: Vector2i = HexUtils.pixel_to_axial(mouse_pos, 20.0)
```

## Where Things Live

```
src/grid/
  hex_utils.gd            ← NEW: pure hex math (no node, no autoload)
  TileData.gd             ← coord type unchanged (Vector2i), semantics now axial
  GridMap.gd              ← adjacency check updated to 6 hex offsets
  GardenView.gd           ← draws hexagons via draw_polygon() instead of draw_rect()
  PlacementController.gd  ← pixel→hex hit-test via HexUtils.pixel_to_axial()
  spatial_query.gd        ← get_cardinal_neighbors() → get_hex_neighbors()

src/rendering/
  bitmask_autotiler.gd    ← 6-bit hex bitmask, 64→13 canonical lookup table
  tile_render_state.gd    ← bitmask8 renamed bitmask6; canonical range 0–12
  tile_chunk_renderer.gd  ← chunk assignment via axial int-division
  biome_transition_layer.gd ← uses hex neighbor offsets
  mountain_cluster_tracker.gd ← uses hex neighbor offsets
  voxel_renderer.gd       ← axial↔world coord via HexUtils

src/biomes/matchers/
  cluster_matcher.gd      ← BFS uses hex neighbors
  shape_matcher.gd        ← offset templates now hex axial offsets
  ratio_proximity_matcher.gd ← uses axial_distance() from HexUtils
  compound_matcher.gd     ← delegates to updated matchers (no direct change)
```

## Hex Neighbor Offsets (reference)

```gdscript
# In HexUtils or any script that needs them:
const HEX_NEIGHBORS: Array[Vector2i] = [
    Vector2i( 1,  0),   # E
    Vector2i(-1,  0),   # W
    Vector2i( 0,  1),   # SE
    Vector2i( 0, -1),   # NW
    Vector2i( 1, -1),   # NE
    Vector2i(-1,  1),   # SW
]
```

## Rendering a Hexagon in GardenView

The helper `_hex_polygon(center, radius)` in `GardenView.gd` returns a
`PackedVector2Array` of 6 vertices for a pointy-top hex. `TILE_RADIUS = 20.0`.

```gdscript
# In GardenView._draw_tile():
var center: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
var pts: PackedVector2Array = _hex_polygon(center, TILE_RADIUS)
draw_colored_polygon(pts, color)
var border: PackedVector2Array = PackedVector2Array(pts)
border.append(pts[0])
draw_polyline(border, color.darkened(0.25), 1.0)

# Vertex angle formula (starting from top vertex, CW):
# angle[i] = deg_to_rad(-90.0 + 60.0 * i)
```

## Bitmask Canonical Lookup (how it works)

`BitmaskAutotiler` pre-builds a 64-element lookup table lazily on first use:

```gdscript
static var _canonical_table: Array[int] = []   # built once, index: raw 0–63 → canonical 0–12

# to_canonical(raw) calls _build_canonical_table() on first call, then returns:
_canonical_table[raw & 0x3F]
```

The table is built by computing the D6-minimum of each raw value (12 transforms:
6 rotations × 1 reflection), collecting the 13 unique minimums in sorted order,
then mapping each raw value to its position in that sorted list.

`TileMeshLibrary` then resolves `(biome, canonical_0_to_12)` → `Mesh`.

## Save Compatibility

`DiscoveryPersistence` (and any future map-save code) must write `version: 2` on save.
On load, if `version` is absent or less than 2, show the incompatible-save UI and
redirect to new game. Do **not** attempt to interpret old `Vector2i` coords as axial.

## Running Tests

```bash
# In the Godot editor: open tests/gut_runner.tscn and press Play.
# Key new test files for this feature:
#   tests/unit/test_hex_utils.gd         ← neighbor offsets, pixel↔axial round-trips
#   tests/unit/test_hex_bitmask.gd       ← 64→13 canonical mapping
#   tests/unit/test_hex_placement.gd     ← adjacency validation on hex grid
#   tests/unit/test_hex_cluster.gd       ← BFS cluster matching on hex
```

## Common Pitfalls

- **Do not use `floori(coord.x / TILE_SIZE)` for hit-testing** — this was the square
  approach. Always go through `HexUtils.pixel_to_axial(pos, TILE_RADIUS)` (cube-rounding).
- **`get_mesh()` takes canonical, not raw bitmask** — `TileMeshLibrary.get_mesh(biome, canonical, lod)`
  now takes the pre-computed canonical index (0–12). Call `BitmaskAutotiler.to_canonical(raw)` first.
- **Chunk node position is `Vector3.ZERO`** — tile world positions are absolute, computed
  via `HexUtils.axial_to_pixel(coord, 1.0)` → `Vector3(px.x, 0, px.y)`. Do not offset chunk nodes.
- **3D TILE_RADIUS = 1.0** (`tile_chunk_renderer.gd`, `mountain_mesh_builder.gd`, `biome_transition_layer.gd`);
  **2D TILE_RADIUS = 20.0** (`GardenView.gd`, `PlacementController.gd`).
- **Bitmask bit order matters** — the 6-bit bitmask must use a consistent direction
  order (E=0, W=1, SE=2, NW=3, NE=4, SW=5) across autotiler, mesh library, and tests.
- **`:=` inference on `HexUtils` returns** — `HexUtils` functions return typed values
  (`Array[Vector2i]`, `Vector2`, `Vector2i`); use explicit type annotations in
  warnings-as-errors contexts to avoid `Variant` inference.
- **`class_name` on HexUtils** — `hex_utils.gd` must NOT declare a `class_name` if
  it might be loaded before dependent scripts register. Use `preload()` at call-sites.
