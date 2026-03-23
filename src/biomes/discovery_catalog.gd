class_name DiscoveryCatalog
extends RefCounted

var _entries: Dictionary = {}

func load_from_data(data: DiscoveryCatalogData) -> void:
	for entry in data.get_tier1_entries():
		_entries[entry["discovery_id"]] = entry

func lookup(discovery_id: String) -> Dictionary:
	return _entries.get(discovery_id, {})

func has_entry(discovery_id: String) -> bool:
	return _entries.has(discovery_id)

func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _entries.keys():
		ids.append(str(key))
	ids.sort()
	return ids
