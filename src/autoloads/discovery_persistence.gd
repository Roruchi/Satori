## DiscoveryPersistence — autoload singleton for discovery log persistence.
extends Node

const SAVE_PATH: String = "user://garden_discoveries.json"

signal discovery_recorded(discovery_id: String)

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
	discovery_recorded.emit(payload.discovery_id)
	_save()

func get_discovered_ids() -> Array[String]:
	return _log.as_id_array()

func _load() -> void:
	pass  # DISABLED for testing — re-enable when save/load is ready

func _save() -> void:
	pass  # DISABLED for testing — re-enable when save/load is ready
