## SaveGameService — local save/load coordinator for the active garden session.
extends Node

const FORMAT_VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const SAVE_PATH: String = "user://saves/autosave.json"
const TEMP_PATH: String = "user://saves/autosave.tmp"
const BACKUP_PATH: String = "user://saves/autosave.backup.json"

signal save_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_completed(path: String)
signal load_failed(path: String, reason: String)

var _session_started: bool = false
var _save_dir: String = SAVE_DIR
var _save_path: String = SAVE_PATH
var _temp_path: String = TEMP_PATH
var _backup_path: String = BACKUP_PATH

func start_session() -> void:
	if _session_started:
		return
	_session_started = true
	load_game()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("tile_placed"):
		var callable := Callable(self, "_on_tile_placed")
		if not game_state.tile_placed.is_connected(callable):
			game_state.tile_placed.connect(callable)
	if not has_save():
		save_now("initial")

func has_save() -> bool:
	return FileAccess.file_exists(_save_path) or FileAccess.file_exists(_backup_path)

func get_save_path() -> String:
	return _save_path

func set_paths_for_testing(save_dir: String, save_path: String, temp_path: String, backup_path: String) -> void:
	_save_dir = save_dir
	_save_path = save_path
	_temp_path = temp_path
	_backup_path = backup_path

func load_game() -> bool:
	var payload: Dictionary = _read_payload(_save_path)
	var loaded_path: String = _save_path
	if payload.is_empty():
		payload = _read_payload(_backup_path)
		loaded_path = _backup_path
	if payload.is_empty():
		return false
	var version: int = int(payload.get("format_version", 0))
	if version <= 0 or version > FORMAT_VERSION:
		load_failed.emit(loaded_path, "unsupported_format_version")
		return false
	var game_state_data: Variant = payload.get("game_state", {})
	if not (game_state_data is Dictionary):
		load_failed.emit(loaded_path, "missing_game_state")
		return false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("restore_game_state"):
		load_failed.emit(loaded_path, "missing_game_state_node")
		return false
	var restored: bool = bool(game_state.restore_game_state(game_state_data as Dictionary))
	if not restored:
		load_failed.emit(loaded_path, "restore_failed")
		return false
	if not _restore_optional_service(payload, "seed_growth", "SeedGrowthService", "restore_seed_growth_state", loaded_path):
		return false
	if not _restore_optional_service(payload, "seed_alchemy", "SeedAlchemyService", "restore_seed_alchemy_state", loaded_path):
		return false
	if not _restore_optional_service(payload, "spirit_persistence", "SpiritPersistence", "restore_spirit_persistence_state", loaded_path):
		return false
	load_completed.emit(loaded_path)
	return true

func save_now(reason: String = "autosave") -> bool:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("serialize_game_state"):
		save_failed.emit(_save_path, "missing_game_state")
		return false
	if not _ensure_save_dir():
		save_failed.emit(_save_path, "save_dir_unavailable")
		return false
	var game_state_data: Variant = game_state.serialize_game_state()
	if not (game_state_data is Dictionary):
		save_failed.emit(_save_path, "serialize_failed")
		return false
	var payload: Dictionary = {
		"format_version": FORMAT_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"reason": reason,
		"game_state": game_state_data,
	}
	_add_optional_service_payload(payload, "seed_growth", "SeedGrowthService", "serialize_seed_growth_state")
	_add_optional_service_payload(payload, "seed_alchemy", "SeedAlchemyService", "serialize_seed_alchemy_state")
	_add_optional_service_payload(payload, "spirit_persistence", "SpiritPersistence", "serialize_spirit_persistence_state")
	var text: String = JSON.stringify(payload, "\t")
	var temp_file := FileAccess.open(_temp_path, FileAccess.WRITE)
	if temp_file == null:
		save_failed.emit(_save_path, "temp_open_failed_%d" % FileAccess.get_open_error())
		return false
	temp_file.store_string(text)
	temp_file.flush()
	temp_file = null
	if _read_payload(_temp_path).is_empty():
		_remove_file(_temp_path)
		save_failed.emit(_save_path, "temp_verify_failed")
		return false
	if not _promote_temp_save():
		_remove_file(_temp_path)
		save_failed.emit(_save_path, "promote_failed")
		return false
	save_completed.emit(_save_path)
	return true

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	save_now("tile_placed")

func _notification(what: int) -> void:
	if not _session_started:
		return
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save_now("app_background")

func _ensure_save_dir() -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	var relative_dir: String = _save_dir.replace("user://", "")
	var err: Error = dir.make_dir_recursive(relative_dir)
	return err == OK or err == ERR_ALREADY_EXISTS

func _add_optional_service_payload(payload: Dictionary, payload_key: String, node_name: String, method_name: String) -> void:
	var service: Node = get_node_or_null("/root/%s" % node_name)
	if service == null or not service.has_method(method_name):
		return
	var data: Variant = service.call(method_name)
	if data is Dictionary:
		payload[payload_key] = data

func _restore_optional_service(payload: Dictionary, payload_key: String, node_name: String, method_name: String, loaded_path: String) -> bool:
	if not payload.has(payload_key):
		return true
	var service: Node = get_node_or_null("/root/%s" % node_name)
	if service == null or not service.has_method(method_name):
		load_failed.emit(loaded_path, "missing_%s_node" % payload_key)
		return false
	var data: Variant = payload.get(payload_key, {})
	if not (data is Dictionary):
		load_failed.emit(loaded_path, "missing_%s" % payload_key)
		return false
	if not bool(service.call(method_name, data as Dictionary)):
		load_failed.emit(loaded_path, "%s_restore_failed" % payload_key)
		return false
	return true

func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return {}
	return parsed as Dictionary

func _promote_temp_save() -> bool:
	var live_exists: bool = FileAccess.file_exists(_save_path)
	if FileAccess.file_exists(_backup_path) and not _remove_file(_backup_path):
		return false
	if live_exists:
		if not _rename_file(_save_path, _backup_path):
			return false
	if _rename_file(_temp_path, _save_path):
		return true
	if live_exists and FileAccess.file_exists(_backup_path):
		_rename_file(_backup_path, _save_path)
	return false

func _rename_file(from_path: String, to_path: String) -> bool:
	var err: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(from_path),
		ProjectSettings.globalize_path(to_path)
	)
	return err == OK

func _remove_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var err: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return err == OK
