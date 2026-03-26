## Test Suite: Island Labelling (GridMap.compute_island_ids)
##
## GUT unit tests for the BFS island-labelling algorithm introduced by the
## Ku Tile Placement feature.  Covers FR-004, FR-005, FR-006.
## Run via: godot --path . --headless -s addons/gut/gut_cmdln.gd
##          -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

extends GutTest

const _GardenGridScript = preload("res://src/grid/GridMap.gd")

# Hex neighbor offsets for pointy-top axial coordinates.
# E(1,0), W(-1,0), SE(0,1), NW(0,-1), NE(1,-1), SW(-1,1)
const _NEIGHBOR_E:  Vector2i = Vector2i(1, 0)
const _NEIGHBOR_W:  Vector2i = Vector2i(-1, 0)
const _NEIGHBOR_SE: Vector2i = Vector2i(0, 1)


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# T008 / US1 — KU tile has no island_id
# ---------------------------------------------------------------------------

func test_ku_tile_has_no_island_id() -> void:
	var grid: RefCounted = _make_grid()
	# Place origin Stone tile first so we have adjacency.
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	# Place a Ku tile adjacent to origin.
	var ku_coord: Vector2i = _NEIGHBOR_E
	grid.place_tile(ku_coord, BiomeType.Value.KU)
	var ku_tile: GardenTile = grid.get_tile(ku_coord)
	assert_eq(str(ku_tile.metadata.get("island_id", "")), "",
		"KU tile must have empty island_id")
	assert_eq(grid.get_island_id(ku_coord), "",
		"get_island_id() must return empty string for a KU coord")


# ---------------------------------------------------------------------------
# T012 / US2 — single island: all tiles share one id
# ---------------------------------------------------------------------------

func test_single_island_all_same_id() -> void:
	var grid: RefCounted = _make_grid()
	var c0: Vector2i = Vector2i.ZERO
	var c1: Vector2i = _NEIGHBOR_E          # (1, 0)
	var c2: Vector2i = _NEIGHBOR_SE         # (0, 1)
	grid.place_tile(c0, BiomeType.Value.STONE)
	grid.place_tile(c1, BiomeType.Value.STONE)
	grid.place_tile(c2, BiomeType.Value.STONE)

	var id0: String = grid.get_island_id(c0)
	var id1: String = grid.get_island_id(c1)
	var id2: String = grid.get_island_id(c2)
	assert_true(id0.length() > 0, "Origin must have a non-empty island_id")
	assert_eq(id1, id0, "Tile at (1,0) must share island_id with origin")
	assert_eq(id2, id0, "Tile at (0,1) must share island_id with origin")


func test_ku_splits_two_groups() -> void:
	# Layout (axial): Stone(0,0) — Ku(1,0) — Stone(2,0)
	# Ku is the E-neighbour of origin; Stone(2,0) is E-neighbour of Ku.
	var grid: RefCounted = _make_grid()
	var left:  Vector2i = Vector2i.ZERO          # (0,0)
	var ku:    Vector2i = _NEIGHBOR_E            # (1,0)
	var right: Vector2i = Vector2i(2, 0)          # (2,0)

	grid.place_tile(left,  BiomeType.Value.STONE)
	grid.place_tile(ku,    BiomeType.Value.KU)
	grid.place_tile(right, BiomeType.Value.STONE)

	var id_left:  String = grid.get_island_id(left)
	var id_right: String = grid.get_island_id(right)
	var id_ku:    String = grid.get_island_id(ku)

	assert_true(id_left.length() > 0,  "Left stone must have a non-empty island_id")
	assert_true(id_right.length() > 0, "Right stone must have a non-empty island_id")
	assert_ne(id_left, id_right,       "Ku tile must split left and right into different islands")
	assert_eq(id_ku, "",               "Ku tile itself must have empty island_id")


func test_connected_around_ku_is_one_island() -> void:
	# Build a ring of Stone tiles around a Ku tile so the ring is still
	# connected without passing through the Ku tile.
	# Layout:  (0,0) Stone, (1,0) Ku, (0,1) Stone, (1,-1) Stone
	# (0,0)—(0,1) are connected (SE neighbour), (0,0)—(1,-1) are connected (NE).
	# Neither path crosses the Ku tile.
	var grid: RefCounted = _make_grid()
	var c_origin: Vector2i = Vector2i.ZERO
	var c_ku:     Vector2i = _NEIGHBOR_E           # (1,0)
	var c_se:     Vector2i = _NEIGHBOR_SE          # (0,1) — SE of origin
	var c_ne:     Vector2i = Vector2i(1, -1)        # NE of origin

	grid.place_tile(c_origin, BiomeType.Value.STONE)
	grid.place_tile(c_ku,     BiomeType.Value.KU)
	grid.place_tile(c_se,     BiomeType.Value.STONE)
	grid.place_tile(c_ne,     BiomeType.Value.STONE)

	var id_origin: String = grid.get_island_id(c_origin)
	var id_se:     String = grid.get_island_id(c_se)
	var id_ne:     String = grid.get_island_id(c_ne)

	assert_true(id_origin.length() > 0, "Origin must have island_id")
	assert_eq(id_se, id_origin, "SE tile connected through non-Ku path must share island_id")
	assert_eq(id_ne, id_origin, "NE tile connected through non-Ku path must share island_id")


func test_island_id_is_canonical_coord() -> void:
	# Build a small cluster: (0,0), (1,0), (0,1).
	# Canonical = lexicographically smallest by x then y = (0,0).
	# Expected island_id = "0,0".
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	grid.place_tile(_NEIGHBOR_E,   BiomeType.Value.STONE)
	grid.place_tile(_NEIGHBOR_SE,  BiomeType.Value.STONE)

	var id: String = grid.get_island_id(Vector2i.ZERO)
	assert_eq(id, "0,0", "Island ID must equal the canonical coord string '0,0'")

	# The other tiles in the same component must have the same id.
	assert_eq(grid.get_island_id(_NEIGHBOR_E),  "0,0")
	assert_eq(grid.get_island_id(_NEIGHBOR_SE), "0,0")


func test_island_id_updates_after_new_tile_placed() -> void:
	# Build two Stone groups separated by a Ku tile so we can assert
	# they receive distinct island IDs:
	#   Stone(0,0) — Ku(1,0) — Stone(2,0)
	# Stone(2,0) is placed via the Ku tile's adjacency so it passes validation.
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, 0),  BiomeType.Value.KU)
	grid.place_tile(Vector2i(2, 0),  BiomeType.Value.STONE)

	var id_left:  String = grid.get_island_id(Vector2i.ZERO)
	var id_right: String = grid.get_island_id(Vector2i(2, 0))
	assert_ne(id_left, id_right, "Left and right Stone groups are separated by Ku — must differ")


func test_only_non_ku_tiles_get_island_id() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	grid.place_tile(_NEIGHBOR_E,   BiomeType.Value.KU)
	grid.place_tile(_NEIGHBOR_SE,  BiomeType.Value.RIVER)

	# Origin and SE River are not connected (the Ku tile sits between them
	# if we check hex adjacency — actually (0,0) and (0,1) are SE neighbours
	# directly, so they ARE connected without going through (1,0)).
	# Verify Ku has no id regardless.
	assert_eq(grid.get_island_id(_NEIGHBOR_E), "",
		"A KU tile must never receive an island_id")

	# Both Stone and River (which ARE adjacent via origin→SE) share one island.
	var id_stone: String = grid.get_island_id(Vector2i.ZERO)
	var id_river: String = grid.get_island_id(_NEIGHBOR_SE)
	assert_true(id_stone.length() > 0, "Stone tile must have an island_id")
	assert_eq(id_river, id_stone,
		"River adjacent to Stone must share the same island_id")
