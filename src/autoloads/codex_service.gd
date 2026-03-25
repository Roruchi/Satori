class_name CodexServiceNode
extends Node

signal entry_discovered(entry_id: StringName)

var _entries: Dictionary = {}
var _discovered: Dictionary = {}

func _ready() -> void:
	var dir: DirAccess = DirAccess.open("res://src/codex/entries/")
	if dir == null:
		return
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path: String = "res://src/codex/entries/%s" % filename
			var resource: Resource = load(path)
			if resource is CodexEntry:
				var entry: CodexEntry = resource as CodexEntry
				_entries[entry.entry_id] = entry
		filename = dir.get_next()
	dir.list_dir_end()

func mark_discovered(entry_id: StringName) -> void:
	if not _entries.has(entry_id):
		push_warning("CodexService received unknown entry_id: %s" % str(entry_id))
		return
	if bool(_discovered.get(entry_id, false)):
		return
	_discovered[entry_id] = true
	entry_discovered.emit(entry_id)

func is_discovered(entry_id: StringName) -> bool:
	return bool(_discovered.get(entry_id, false))

func get_entries_by_category(category: int) -> Array[CodexEntry]:
	var entries: Array[CodexEntry] = []
	for value in _entries.values():
		var entry: CodexEntry = value as CodexEntry
		if entry != null and entry.category == category:
			entries.append(entry)
	return entries

func force_reveal(entry_id: StringName) -> void:
	mark_discovered(entry_id)
