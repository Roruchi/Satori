## SaveGameService — local save/load coordinator for the active garden session.
extends Node

const FORMAT_VERSION: int = 1
const BUILD_VERSION_SETTING: String = "application/config/version"
const FALLBACK_BUILD_VERSION: String = "0.1.0-alpha+local"
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
var _last_failure_kind: String = ""
var _last_failure_reason: String = ""
var _last_failure_path: String = ""
var _last_status_message: String = ""
var _is_loading: bool = false

func start_session() -> bool:
	if _session_started:
		return _last_failure_kind.is_empty()
	_session_started = true
	_connect_autosave_triggers()
	var had_save: bool = has_save()
	var loaded: bool = load_game()
	if had_save and not loaded:
		return false
	if not has_save():
		save_now("initial")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(_save_path) or FileAccess.file_exists(_backup_path)

func get_save_path() -> String:
	return _save_path

func get_build_version() -> String:
	if ProjectSettings.has_setting(BUILD_VERSION_SETTING):
		var version_variant: Variant = ProjectSettings.get_setting(BUILD_VERSION_SETTING)
		var version: String = str(version_variant)
		if not version.is_empty():
			return version
	return FALLBACK_BUILD_VERSION

func get_last_failure_message() -> String:
	return _last_status_message

func get_last_failure_reason() -> String:
	return _last_failure_reason

func get_observed_save_environment() -> Dictionary:
	return {
		"save_dir": _save_dir,
		"save_path": _save_path,
		"global_save_dir": ProjectSettings.globalize_path(_save_dir),
		"global_save_path": ProjectSettings.globalize_path(_save_path),
		"os_name": OS.get_name(),
		"is_web": OS.has_feature("web"),
		"is_android": OS.has_feature("android"),
	}

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
	var version: int = int(payload.get("schema_version", payload.get("format_version", 0)))
	if version <= 0 or version > FORMAT_VERSION:
		_emit_load_failed(loaded_path, "unsupported_format_version")
		return false
	var game_state_data: Variant = payload.get("game_state", {})
	if not (game_state_data is Dictionary):
		_emit_load_failed(loaded_path, "missing_game_state")
		return false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("restore_game_state"):
		_emit_load_failed(loaded_path, "missing_game_state_node")
		return false
	_is_loading = true
	var restored: bool = bool(game_state.restore_game_state(game_state_data as Dictionary))
	if not restored:
		_is_loading = false
		_emit_load_failed(loaded_path, "restore_failed")
		return false
	if not _restore_optional_service(payload, "seed_growth", "SeedGrowthService", "restore_seed_growth_state", loaded_path):
		_is_loading = false
		return false
	if not _restore_optional_service(payload, "seed_alchemy", "SeedAlchemyService", "restore_seed_alchemy_state", loaded_path):
		_is_loading = false
		return false
	if not _restore_optional_service(payload, "discovery_persistence", "DiscoveryPersistence", "restore_discovery_persistence_state", loaded_path):
		_is_loading = false
		return false
	if not _restore_optional_service(payload, "spirit_persistence", "SpiritPersistence", "restore_spirit_persistence_state", loaded_path):
		_is_loading = false
		return false
	if not _restore_optional_service(payload, "satori", "SatoriService", "restore_satori_state", loaded_path):
		_is_loading = false
		return false
	_is_loading = false
	_clear_failure_state()
	load_completed.emit(loaded_path)
	return true

func save_now(reason: String = "autosave") -> bool:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("serialize_game_state"):
		_emit_save_failed(_save_path, "missing_game_state")
		return false
	if not _ensure_save_dir():
		_emit_save_failed(_save_path, "save_dir_unavailable")
		return false
	var game_state_data: Variant = game_state.serialize_game_state()
	if not (game_state_data is Dictionary):
		_emit_save_failed(_save_path, "serialize_failed")
		return false
	var payload: Dictionary = {
		"format_version": FORMAT_VERSION,
		"schema_version": FORMAT_VERSION,
		"build_version": get_build_version(),
		"version": {
			"schema_version": FORMAT_VERSION,
			"build_version": get_build_version(),
		},
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"reason": reason,
		"game_state": game_state_data,
	}
	_add_optional_service_payload(payload, "seed_growth", "SeedGrowthService", "serialize_seed_growth_state")
	_add_optional_service_payload(payload, "seed_alchemy", "SeedAlchemyService", "serialize_seed_alchemy_state")
	_add_optional_service_payload(payload, "discovery_persistence", "DiscoveryPersistence", "serialize_discovery_persistence_state")
	_add_optional_service_payload(payload, "spirit_persistence", "SpiritPersistence", "serialize_spirit_persistence_state")
	_add_optional_service_payload(payload, "satori", "SatoriService", "serialize_satori_state")
	var text: String = JSON.stringify(payload, "\t")
	var temp_file: FileAccess = FileAccess.open(_temp_path, FileAccess.WRITE)
	if temp_file == null:
		_emit_save_failed(_save_path, "temp_open_failed_%d" % FileAccess.get_open_error())
		return false
	temp_file.store_string(text)
	temp_file.flush()
	temp_file = null
	if _read_payload(_temp_path).is_empty():
		_remove_file(_temp_path)
		_emit_save_failed(_save_path, "temp_verify_failed")
		return false
	if not _promote_temp_save():
		_remove_file(_temp_path)
		_emit_save_failed(_save_path, "promote_failed")
		return false
	_clear_failure_state()
	save_completed.emit(_save_path)
	return true

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	_save_from_autosave("tile_placed")

func _notification(what: int) -> void:
	if not _session_started:
		return
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_save_from_autosave("app_background")

func _connect_autosave_triggers() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	_connect_signal_2(game_state, "tile_placed", "_on_tile_placed")
	_connect_signal_2(game_state, "bloom_confirmed", "_on_autosave_2", "bloom_confirmed")
	_connect_signal_3(game_state, "material_node_harvested", "material_harvested")
	_connect_signal_4(game_state, "structure_essence_generated", "structure_essence_generated")

	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	_connect_signal_1(growth, "seed_planted", "seed_planted")
	_connect_signal_1(growth, "seed_ready", "seed_ready")
	_connect_signal_2(growth, "bloom_confirmed", "_on_autosave_2", "seed_bloom_confirmed")
	_connect_signal_0(growth, "pouch_updated", "pouch_updated")

	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	_connect_signal_1(alchemy, "element_unlocked", "element_unlocked")
	_connect_signal_1(alchemy, "seed_added_to_pouch", "seed_added_to_pouch")
	_connect_signal_2(alchemy, "material_count_changed", "_on_autosave_2", "material_count_changed")
	_connect_signal_3(alchemy, "shrine_charge_collected", "shrine_charge_collected")

	var discovery: Node = get_node_or_null("/root/DiscoveryPersistence")
	_connect_signal_1(discovery, "discovery_recorded", "discovery_recorded")

	var spirits: Node = get_node_or_null("/root/SpiritPersistence")
	_connect_signal_1(spirits, "spirit_instance_recorded", "spirit_instance_recorded")

	var satori: Node = get_node_or_null("/root/SatoriService")
	_connect_signal_2(satori, "satori_changed", "_on_autosave_2", "satori_changed")
	_connect_signal_1(satori, "era_changed", "era_changed")

func _connect_signal_0(node: Node, signal_name: String, reason: String) -> void:
	if node == null or not node.has_signal(signal_name):
		return
	var callable: Callable = Callable(self, "_on_autosave_0").bind(reason)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _connect_signal_1(node: Node, signal_name: String, reason: String) -> void:
	if node == null or not node.has_signal(signal_name):
		return
	var callable: Callable = Callable(self, "_on_autosave_1").bind(reason)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _connect_signal_2(node: Node, signal_name: String, method_name: String, reason: String = "") -> void:
	if node == null or not node.has_signal(signal_name):
		return
	var callable: Callable
	if reason.is_empty():
		callable = Callable(self, method_name)
	else:
		callable = Callable(self, method_name).bind(reason)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _connect_signal_3(node: Node, signal_name: String, reason: String) -> void:
	if node == null or not node.has_signal(signal_name):
		return
	var callable: Callable = Callable(self, "_on_autosave_3").bind(reason)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _connect_signal_4(node: Node, signal_name: String, reason: String) -> void:
	if node == null or not node.has_signal(signal_name):
		return
	var callable: Callable = Callable(self, "_on_autosave_4").bind(reason)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _on_autosave_0(reason: String) -> void:
	_save_from_autosave(reason)

func _on_autosave_1(_a: Variant, reason: String) -> void:
	_save_from_autosave(reason)

func _on_autosave_2(_a: Variant, _b: Variant, reason: String) -> void:
	_save_from_autosave(reason)

func _on_autosave_3(_a: Variant, _b: Variant, _c: Variant, reason: String) -> void:
	_save_from_autosave(reason)

func _on_autosave_4(_a: Variant, _b: Variant, _c: Variant, _d: Variant, reason: String) -> void:
	_save_from_autosave(reason)

func _save_from_autosave(reason: String) -> void:
	if _is_loading:
		return
	save_now(reason)

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
		_emit_load_failed(loaded_path, "missing_%s_node" % payload_key)
		return false
	var data: Variant = payload.get(payload_key, {})
	if not (data is Dictionary):
		_emit_load_failed(loaded_path, "missing_%s" % payload_key)
		return false
	if not bool(service.call(method_name, data as Dictionary)):
		_emit_load_failed(loaded_path, "%s_restore_failed" % payload_key)
		return false
	return true

func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
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

func _emit_save_failed(path: String, reason: String) -> void:
	_set_failure_state("save", path, reason)
	save_failed.emit(path, reason)

func _emit_load_failed(path: String, reason: String) -> void:
	_set_failure_state("load", path, reason)
	load_failed.emit(path, reason)

func _set_failure_state(kind: String, path: String, reason: String) -> void:
	_last_failure_kind = kind
	_last_failure_path = path
	_last_failure_reason = reason
	_last_status_message = _player_message_for_failure(kind, reason)

func _clear_failure_state() -> void:
	_last_failure_kind = ""
	_last_failure_path = ""
	_last_failure_reason = ""
	_last_status_message = ""

func _player_message_for_failure(kind: String, reason: String) -> String:
	if kind == "load":
		match reason:
			"unsupported_format_version":
				return "This garden save is from an unsupported alpha version."
			"missing_game_state", "missing_game_state_node", "restore_failed":
				return "This garden save could not be loaded safely."
			_:
				return "This garden save could not be loaded."
	match reason:
		"save_dir_unavailable", "temp_verify_failed", "promote_failed":
			return "The garden could not be saved. Your previous save was kept."
		_:
			if reason.begins_with("temp_open_failed"):
				return "The garden could not be saved. Your previous save was kept."
			return "The garden could not be saved."
