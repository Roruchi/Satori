## Test Suite: MountainClusterTracker
##
## GUT unit tests for src/rendering/mountain_cluster_tracker.gd
## Run via tests/gut_runner.tscn

extends GutTest

const _MountainClusterTracker = preload("res://src/rendering/mountain_cluster_tracker.gd")

var _tracker: Node


func before_each() -> void:
	_tracker = _MountainClusterTracker.new()
	add_child(_tracker)


func after_each() -> void:
	_tracker.queue_free()
	_tracker = null


# ---------------------------------------------------------------------------
# Single tile and cluster creation
# ---------------------------------------------------------------------------

func test_single_stone_tile_creates_singleton_cluster() -> void:
	_tracker.register_tile(Vector2i.ZERO)
	var cluster: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	assert_not_null(cluster, "A cluster must be created for a registered Stone tile")
	assert_eq(cluster.members.size(), 1, "Singleton cluster must have exactly 1 member")


func test_two_adjacent_stone_tiles_merge_into_one_cluster() -> void:
	_tracker.register_tile(Vector2i.ZERO)
	_tracker.register_tile(Vector2i(1, 0))
	var c0: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	var c1: RefCounted = _tracker.get_cluster_for_coord(Vector2i(1, 0))
	assert_not_null(c0)
	assert_not_null(c1)
	assert_eq(c0.id, c1.id, "Adjacent tiles must belong to the same cluster")
	assert_eq(c0.members.size(), 2, "Merged cluster must have 2 members")


func test_two_non_adjacent_stone_tiles_form_separate_clusters() -> void:
	_tracker.register_tile(Vector2i.ZERO)
	_tracker.register_tile(Vector2i(5, 5))
	var c0: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	var c1: RefCounted = _tracker.get_cluster_for_coord(Vector2i(5, 5))
	assert_not_null(c0)
	assert_not_null(c1)
	assert_ne(c0.id, c1.id, "Non-adjacent tiles must be in separate clusters")


# ---------------------------------------------------------------------------
# Cluster merge threshold
# ---------------------------------------------------------------------------

func test_10th_tile_emits_cluster_merged_signal() -> void:
	watch_signals(_tracker)
	# Place 9 tiles in a line
	for x in range(9):
		_tracker.register_tile(Vector2i(x, 0))
	assert_signal_not_emitted(_tracker, "cluster_merged",
		"cluster_merged must NOT fire before 10 tiles")
	# Place the 10th
	_tracker.register_tile(Vector2i(9, 0))
	assert_signal_emitted(_tracker, "cluster_merged",
		"cluster_merged must fire when cluster reaches 10 tiles")


func test_cluster_not_merged_before_10_tiles() -> void:
	for x in range(9):
		_tracker.register_tile(Vector2i(x, 0))
	var cluster: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	assert_false(cluster.merged, "Cluster must not be merged with fewer than 10 tiles")


func test_cluster_is_merged_at_10_tiles() -> void:
	for x in range(10):
		_tracker.register_tile(Vector2i(x, 0))
	var cluster: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	assert_true(cluster.merged, "Cluster must be marked merged at 10+ tiles")


func test_bridging_tile_merges_two_clusters() -> void:
	watch_signals(_tracker)
	# First cluster: tiles at x=0–7 (8 tiles)
	for x in range(8):
		_tracker.register_tile(Vector2i(x, 0))
	# Second cluster: tiles at x=9–16 (8 tiles), leaving gap at x=8
	for x in range(9, 17):
		_tracker.register_tile(Vector2i(x, 0))
	# Bridge tile at x=8 connects both clusters into one 17-tile cluster
	_tracker.register_tile(Vector2i(8, 0))
	assert_signal_emitted(_tracker, "cluster_merged",
		"Bridging tile creating 17-tile cluster must emit cluster_merged")
	var cluster: RefCounted = _tracker.get_cluster_for_coord(Vector2i.ZERO)
	assert_eq(cluster.members.size(), 17,
		"Bridged cluster must contain all 17 members")


# ---------------------------------------------------------------------------
# Chunk coordinate helpers
# ---------------------------------------------------------------------------

func test_chunk_coord_for_origin_tile() -> void:
	var chunk: Vector2i = _tile_to_chunk_coord(Vector2i.ZERO)
	assert_eq(chunk, Vector2i.ZERO)


func test_chunk_coord_for_tile_7_7() -> void:
	var chunk: Vector2i = _tile_to_chunk_coord(Vector2i(7, 7))
	assert_eq(chunk, Vector2i.ZERO, "Tile (7,7) is still in chunk (0,0)")

func test_chunk_coord_for_tile_8_0() -> void:
	var chunk: Vector2i = _tile_to_chunk_coord(Vector2i(8, 0))
	assert_eq(chunk, Vector2i(1, 0), "Tile (8,0) starts chunk (1,0)")


func test_chunk_coord_negative_tiles() -> void:
	# Tile (-1, -1) should be in chunk (-1, -1) (integer floor division)
	var chunk: Vector2i = _tile_to_chunk_coord(Vector2i(-1, -1))
	assert_eq(chunk, Vector2i(-1, -1))


## Helper: replicates the chunk coordinate formula used in TileChunkRenderer.
## Uses integer floor division by 8, matching tile_chunk_renderer.gd's tile_to_chunk().
static func _tile_to_chunk_coord(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / 8.0), floori(float(tile.y) / 8.0))
