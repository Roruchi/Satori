## Test Suite: BiomeTransitionLayer
##
## GUT unit tests for src/rendering/biome_transition_layer.gd
## Updated for 6-directional hex adjacency.
## Run via tests/gut_runner.tscn

extends GutTest

const _BiomeTransitionLayer = preload("res://src/rendering/biome_transition_layer.gd")
const _GardenGridScript = preload("res://src/grid/GridMap.gd")

var _layer: Node


func before_each() -> void:
	_layer = _BiomeTransitionLayer.new()
	add_child(_layer)


func after_each() -> void:
	_layer.queue_free()
	_layer = null


func _make_grid() -> RefCounted:
	return _GardenGridScript.new()


# ---------------------------------------------------------------------------
# BiomeTransitionLayer.get_transition
# ---------------------------------------------------------------------------

func test_forest_water_pair_returns_non_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.FOREST, BiomeType.Value.WATER)
	assert_not_null(data,
		"FOREST↔WATER pair must have a registered transition decoration")


func test_forest_forest_pair_returns_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.FOREST, BiomeType.Value.FOREST)
	assert_null(data, "Same-biome pair must return null (no self-transition)")


func test_stone_water_pair_returns_non_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.STONE, BiomeType.Value.WATER)
	assert_not_null(data, "STONE↔WATER pair must have a registered transition")


func test_earth_water_pair_returns_non_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.EARTH, BiomeType.Value.WATER)
	assert_not_null(data, "EARTH↔WATER pair must have a registered transition")


func test_forest_earth_pair_returns_non_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.FOREST, BiomeType.Value.EARTH)
	assert_not_null(data, "FOREST↔EARTH pair must have a registered transition")


func test_pair_lookup_is_commutative() -> void:
	var ab: Resource = _layer.get_transition(BiomeType.Value.FOREST, BiomeType.Value.WATER)
	var ba: Resource = _layer.get_transition(BiomeType.Value.WATER, BiomeType.Value.FOREST)
	assert_eq(ab, ba,
		"Transition lookup must be commutative: (FOREST,WATER) == (WATER,FOREST)")


func test_unregistered_pair_returns_null() -> void:
	var data: Resource = _layer.get_transition(BiomeType.Value.SWAMP, BiomeType.Value.TUNDRA)
	assert_null(data, "Unregistered biome pair must return null")


# ---------------------------------------------------------------------------
# BiomeTransitionLayer.on_tile_placed — hex edge decoration spawning
# ---------------------------------------------------------------------------

func test_decorations_spawned_for_forest_water_hex_adjacency() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	# E hex neighbor
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	_layer.on_tile_placed(Vector2i(1, 0), grid)
	assert_true(_layer.get_child_count() > 0,
		"Decoration nodes must be spawned when FOREST and WATER are hex-adjacent")


func test_decorations_spawned_for_se_hex_neighbor() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	# SE hex neighbor (0,1)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.WATER)
	_layer.on_tile_placed(Vector2i(0, 1), grid)
	assert_true(_layer.get_child_count() > 0,
		"Decoration must spawn for FOREST↔WATER across the SE hex edge")


func test_no_decorations_for_same_biome_adjacency() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	_layer.on_tile_placed(Vector2i(1, 0), grid)
	assert_eq(_layer.get_child_count(), 0,
		"No decoration nodes should be spawned for same-biome hex adjacency")


func test_same_edge_not_decorated_twice() -> void:
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	_layer.on_tile_placed(Vector2i(1, 0), grid)
	var count_after_first: int = _layer.get_child_count()
	_layer.on_tile_placed(Vector2i(1, 0), grid)
	assert_eq(_layer.get_child_count(), count_after_first,
		"Calling on_tile_placed twice must not double-spawn decorations for the same hex edge")


func test_no_decoration_for_square_diagonal_non_hex_neighbor() -> void:
	# (1,1) is a square diagonal — NOT a hex neighbor; should not trigger transitions
	var grid: RefCounted = _make_grid()
	grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 1), BiomeType.Value.WATER)
	_layer.on_tile_placed(Vector2i(1, 1), grid)
	assert_eq(_layer.get_child_count(), 0,
		"Square-diagonal (1,1) is not a hex neighbor; no decoration must spawn")
