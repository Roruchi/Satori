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

func test_save_service_roundtrips_discovery_and_satori_state() -> void:
	var root: Node = get_tree().root
	var discovery: Node = root.get_node_or_null("/root/DiscoveryPersistence")
	var satori: SatoriServiceNode = root.get_node_or_null("/root/SatoriService") as SatoriServiceNode
	if discovery == null or not discovery.has_method("serialize_discovery_persistence_state"):
		fail_test("DiscoveryPersistence autoload with save hooks is required")
		return
	if satori == null:
		fail_test("SatoriService autoload is required")
		return
	var original_discovery_variant: Variant = discovery.call("serialize_discovery_persistence_state")
	var original_discovery: Dictionary = original_discovery_variant as Dictionary
	var original_satori: Dictionary = satori.serialize_satori_state()
	var service: Node = SaveGameServiceScript.new()
	add_child_autofree(service)
	service.set_paths_for_testing(TEST_DIR, TEST_SAVE, TEST_TEMP, TEST_BACKUP)

	discovery.call("restore_discovery_persistence_state", {"entries": []})
	var payload: DiscoveryPayload = DiscoveryPayload.create("disc_fox_den", [Vector2i(2, 0)], {"display_name": "Fox Den"})
	discovery.call("record_discovery", payload)
	satori.set_satori_for_testing(123)

	assert_true(service.save_now("discovery_satori_roundtrip"))
	discovery.call("restore_discovery_persistence_state", {"entries": []})
	satori.set_satori_for_testing(0)
	assert_true(service.load_game())
	var restored_ids_variant: Variant = discovery.call("get_discovered_ids")
	var restored_ids: Array = restored_ids_variant as Array
	assert_true(restored_ids.has("disc_fox_den"))
	assert_eq(satori.get_current_satori(), 123)

	discovery.call("restore_discovery_persistence_state", original_discovery)
	satori.restore_satori_state(original_satori)

func test_save_service_roundtrips_seed_alchemy_ku_unlock() -> void:
	var root: Node = get_tree().root
	var alchemy: SeedAlchemyServiceNode = root.get_node_or_null("/root/SeedAlchemyService") as SeedAlchemyServiceNode
	if alchemy == null:
		fail_test("SeedAlchemyService autoload is required")
		return
	var original_alchemy: Dictionary = alchemy.serialize_seed_alchemy_state()
	var service: Node = SaveGameServiceScript.new()
	add_child_autofree(service)
	service.set_paths_for_testing(TEST_DIR, TEST_SAVE, TEST_TEMP, TEST_BACKUP)

	alchemy.restore_seed_alchemy_state({})
	alchemy.unlock_element(GodaiElement.Value.KU)
	alchemy.set_element_charge_for_testing(GodaiElement.Value.KU, 2)

	assert_true(service.save_now("ku_unlock_roundtrip"))
	alchemy.restore_seed_alchemy_state({})
	assert_false(alchemy.is_ku_unlocked())
	assert_true(service.load_game())
	assert_true(alchemy.is_ku_unlocked())
	assert_eq(alchemy.get_element_charge(GodaiElement.Value.KU), 2)

	alchemy.restore_seed_alchemy_state(original_alchemy)

func test_game_state_roundtrip_preserves_void_island_separation() -> void:
	var source: Node = GameStateScript.new()
	source._ready()
	source.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.KU)
	source.place_tile_from_seed(Vector2i(2, 0), BiomeType.Value.RIVER)
	var source_left_island: String = str(source.grid.get_island_id(Vector2i.ZERO))
	var source_right_island: String = str(source.grid.get_island_id(Vector2i(2, 0)))
	assert_false(source_left_island.is_empty())
	assert_false(source_right_island.is_empty())
	assert_ne(source_left_island, source_right_island)

	var restored: Node = GameStateScript.new()
	assert_true(restored.restore_game_state(source.serialize_game_state()))
	assert_eq(restored.grid.get_island_id(Vector2i(1, 0)), "")
	assert_eq(str(restored.grid.get_island_id(Vector2i.ZERO)), source_left_island)
	assert_eq(str(restored.grid.get_island_id(Vector2i(2, 0))), source_right_island)
	assert_ne(str(restored.grid.get_island_id(Vector2i.ZERO)), str(restored.grid.get_island_id(Vector2i(2, 0))))

	source.free()
	restored.free()

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
