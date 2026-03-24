## DiscoveryPersistence — autoload singleton for discovery log persistence.
extends Node

const SAVE_PATH: String = "user://garden_discoveries.json"

var _log: DiscoveryLog

func _ready() -> void:
	_log = DiscoveryLog.new()
	_load()

func get_log() -> DiscoveryLog:
	return _log

func record_discovery(payload: DiscoveryPayload) -> void:
	if _log.has_discovery(payload.discovery_id):
		return
	_log.append_entry(payload)
	_save()

func get_discovered_ids() -> Array[String]:
	return _log.as_id_array()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		RuntimeLogger.warn("DiscoveryPersistence", "Failed to open save file: %s" % SAVE_PATH)
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		RuntimeLogger.warn("DiscoveryPersistence", "Invalid discovery save data format")
		return
	_log.deserialize(parsed as Dictionary)

func _save() -> void:
	var data: Dictionary = _log.serialize()
	var json_text: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		RuntimeLogger.warn("DiscoveryPersistence", "Failed to write save file: %s" % SAVE_PATH)
		return
	file.store_string(json_text)
	file.close()
