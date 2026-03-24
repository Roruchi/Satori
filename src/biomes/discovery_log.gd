class_name DiscoveryLog
extends RefCounted

var entries: Array[Dictionary] = []
var _discovered_ids: Dictionary = {}

func has_discovery(discovery_id: String) -> bool:
	return _discovered_ids.has(discovery_id)

func append_entry(payload: DiscoveryPayload) -> void:
	if has_discovery(payload.discovery_id):
		return
	var entry: Dictionary = {
		"discovery_id": payload.discovery_id,
		"display_name": payload.display_name,
		"trigger_timestamp": payload.trigger_timestamp,
		"triggering_coords": _serialize_coords(payload.triggering_coords),
	}
	entries.append(entry)
	_discovered_ids[payload.discovery_id] = true

func as_id_array() -> Array[String]:
	var ids: Array[String] = []
	for entry in entries:
		ids.append(str(entry["discovery_id"]))
	return ids

func serialize() -> Dictionary:
	return {"entries": entries.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	entries.clear()
	_discovered_ids.clear()
	var raw_entries: Array = data.get("entries", [])
	for raw_entry in raw_entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate()
			entries.append(entry)
			_discovered_ids[str(entry.get("discovery_id", ""))] = true

func _serialize_coords(coords: Array[Vector2i]) -> Array:
	var result: Array = []
	for coord in coords:
		result.append([coord.x, coord.y])
	return result
