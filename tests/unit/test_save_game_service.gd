extends GutTest

const GameStateScript = preload("res://src/autoloads/GameState.gd")
const SaveGameServiceScript = preload("res://src/autoloads/save_game_service.gd")

const TEST_DIR: String = "user://test_saves"
const TEST_SAVE: String = "user://test_saves/autosave_test.json"
const TEST_TEMP: String = "user://test_saves/autosave_test.tmp"
const TEST_BACKUP: String = "user://test_saves/autosave_test.backup.json"

var _root_game_state: Node = null
var _original_state: Dictionary = {}

func before_each() -> void:
	_cleanup_test_files()
	_root_game_state = get_tree().root.get_node_or_null("/root/GameState")
	if _root_game_state != null and _root_game_state.has_method("serialize_game_state"):
		_original_state = _root_game_state.serialize_game_state()

func after_each() -> void:
	if _root_game_state != null and _root_game_state.has_method("restore_game_state") and not _original_state.is_empty():
		_root_game_state.restore_game_state(_original_state)
	_cleanup_test_files()

func test_game_state_roundtrip_preserves_tiles_and_metadata() -> void:
	var source: Node = GameStateScript.new()
	source._ready()
	source.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.MEADOW, true)
	var tile: GardenTile = source.grid.get_tile(Vector2i(1, 0))
	tile.metadata["string_name_value"] = &"living_wood"
	tile.metadata["nested"] = {"coord": Vector2i(-2, 3)}

	var serialized: Dictionary = source.serialize_game_state()
	var restored: Node = GameStateScript.new()
	assert_true(restored.restore_game_state(serialized))

	var restored_tile: GardenTile = restored.grid.get_tile(Vector2i(1, 0))
	assert_not_null(restored_tile)
	assert_eq(restored_tile.biome, BiomeType.Value.MEADOW)
	assert_true(restored_tile.locked)
	assert_eq(str(restored_tile.metadata.get("string_name_value", "")), "living_wood")
	var nested: Dictionary = restored_tile.metadata.get("nested", {})
	assert_eq(nested.get("coord", Vector2i.ZERO), Vector2i(-2, 3))
	source.free()
	restored.free()

func test_save_service_writes_to_user_save_path_and_loads_game_state() -> void:
	if _root_game_state == null:
		fail_test("GameState autoload is required for save service integration")
		return
	var service: Node = SaveGameServiceScript.new()
	add_child_autofree(service)
	service.set_paths_for_testing(TEST_DIR, TEST_SAVE, TEST_TEMP, TEST_BACKUP)

	_root_game_state.restore_game_state(_state_with_tiles([Vector2i.ZERO]))
	_root_game_state.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.RIVER)

	assert_true(service.save_now("unit_test"))
	assert_true(FileAccess.file_exists(TEST_SAVE))

	_root_game_state.restore_game_state(_state_with_tiles([Vector2i.ZERO]))
	assert_true(service.load_game())
	var loaded_tile: GardenTile = _root_game_state.grid.get_tile(Vector2i(1, 0))
	assert_not_null(loaded_tile)
	assert_eq(loaded_tile.biome, BiomeType.Value.RIVER)

func _state_with_tiles(coords: Array[Vector2i]) -> Dictionary:
	var tiles: Array[Dictionary] = []
	for coord: Vector2i in coords:
		var metadata: Dictionary = {}
		if coord == Vector2i.ZERO:
			metadata = {
				"is_origin_shrine": true,
				"shrine_buildable": false,
				"shrine_built": true,
				"build_discovery_id": "disc_origin_shrine",
			}
		tiles.append({
			"coord": [coord.x, coord.y],
			"biome": BiomeType.Value.STONE,
			"locked": false,
			"metadata": metadata,
		})
	return {"selected_biome": BiomeType.Value.STONE, "tiles": tiles}

func _cleanup_test_files() -> void:
	_remove_file(TEST_SAVE)
	_remove_file(TEST_TEMP)
	_remove_file(TEST_BACKUP)

func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
