class_name SpiritCatalog
extends RefCounted

var _entries: Dictionary = {}

func load_from_data(data: SpiritCatalogData) -> void:
	for entry in data.get_entries():
		_entries[entry["spirit_id"]] = entry

func lookup(spirit_id: String) -> Dictionary:
	if not _entries.has(spirit_id):
		return {}
	return _entries[spirit_id] as Dictionary

func has_entry(spirit_id: String) -> bool:
	return _entries.has(spirit_id)

func get_all_spirit_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _entries.keys():
		ids.append(str(key))
	ids.sort()
	return ids
