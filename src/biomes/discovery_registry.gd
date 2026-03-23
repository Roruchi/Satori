class_name DiscoveryRegistry
extends RefCounted

var _discovery_ids: Dictionary = {}

func has_discovery(discovery_id: String) -> bool:
	return _discovery_ids.has(discovery_id)

func mark_discovery(discovery_id: String) -> void:
	_discovery_ids[discovery_id] = true

func mark_discoveries(discovery_ids: Array[String]) -> void:
	for discovery_id in discovery_ids:
		mark_discovery(discovery_id)

func mark_discoveries_atomically(discovery_ids: Array[String]) -> void:
	var pending: Dictionary = {}
	for discovery_id in discovery_ids:
		pending[discovery_id] = true
	for discovery_id in pending.keys():
		_discovery_ids[discovery_id] = true

func clear() -> void:
	_discovery_ids.clear()

func as_sorted_array() -> Array[String]:
	var keys: Array[String] = []
	for key in _discovery_ids.keys():
		keys.append(str(key))
	keys.sort()
	return keys
