class_name CodexServiceNode
extends Node

signal entry_discovered(entry_id: StringName)

const CodexEntryScript = preload("res://src/codex/CodexEntry.gd")
const SpiritCatalogDataScript = preload("res://src/spirits/spirit_catalog_data.gd")
const DiscoveryCatalogDataScript = preload("res://src/biomes/discovery_catalog_data.gd")
const SatoriIds = preload("res://src/satori/SatoriIds.gd")

var _entries: Dictionary = {}
var _discovered: Dictionary = {}
var _structure_ids: Dictionary = {}

func _ready() -> void:
	_load_static_entries()
	_register_discovery_entries()
	_register_spirit_entries()
	_register_structure_entries()

func _load_static_entries() -> void:
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

func _register_spirit_entries() -> void:
	var catalog_data: SpiritCatalogData = SpiritCatalogDataScript.new()
	for raw_entry: Dictionary in catalog_data.get_entries():
		var spirit_id: StringName = StringName(str(raw_entry.get("spirit_id", "")))
		if spirit_id == StringName("") or _entries.has(spirit_id):
			continue
		var display_name: String = str(raw_entry.get("display_name", _humanize_id(str(spirit_id))))
		var riddle_text: String = str(raw_entry.get("riddle_text", ""))
		_register_dynamic_entry(
			spirit_id,
			CodexEntryScript.Category.SPIRIT,
			riddle_text if not riddle_text.is_empty() else "Summon this spirit by completing its pattern.",
			display_name,
			"A spirit that can be summoned in your garden."
		)

func _register_discovery_entries() -> void:
	var discovery_data: DiscoveryCatalogData = DiscoveryCatalogDataScript.new()
	for meta: Dictionary in discovery_data.get_tier1_entries():
		var discovery_id: StringName = StringName(str(meta.get("discovery_id", "")))
		if discovery_id == StringName("") or _entries.has(discovery_id):
			continue
		_register_dynamic_entry(
			discovery_id,
			CodexEntryScript.Category.BIOME,
			str(meta.get("flavor_text", "")),
			str(meta.get("display_name", _humanize_id(str(discovery_id)))),
			"A biome landmark discovered through pattern matching."
		)
	for meta: Dictionary in discovery_data.get_tier2_entries():
		var discovery_id_t2: StringName = StringName(str(meta.get("discovery_id", "")))
		if discovery_id_t2 == StringName("") or _entries.has(discovery_id_t2):
			continue
		_structure_ids[discovery_id_t2] = true
		_register_dynamic_entry(
			discovery_id_t2,
			CodexEntryScript.Category.STRUCTURE,
			str(meta.get("flavor_text", "")),
			str(meta.get("display_name", _humanize_id(str(discovery_id_t2)))),
			"A landmark structure discovered through biome arrangement."
		)
	for meta: Dictionary in discovery_data.get_tier3_entries():
		var discovery_id_t3: StringName = StringName(str(meta.get("discovery_id", "")))
		if discovery_id_t3 == StringName("") or _entries.has(discovery_id_t3):
			continue
		_structure_ids[discovery_id_t3] = true
		_register_dynamic_entry(
			discovery_id_t3,
			CodexEntryScript.Category.STRUCTURE,
			str(meta.get("flavor_text", "")),
			str(meta.get("display_name", _humanize_id(str(discovery_id_t3)))),
			"A landmark structure discovered through biome arrangement."
		)

func _register_structure_entries() -> void:
	_register_structure_entries_from_dir("res://src/biomes/patterns/tier2/")
	_register_structure_entries_from_dir("res://src/biomes/patterns/tier3/")

func _register_structure_entries_from_dir(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path: String = "%s%s" % [dir_path, filename]
			var resource: Resource = load(path)
			if resource != null:
				var discovery_id: String = str(resource.get("discovery_id"))
				if not discovery_id.is_empty():
					_structure_ids[StringName(discovery_id)] = true
					if not _entries.has(StringName(discovery_id)):
						var full_name: String = _humanize_id(discovery_id)
						_register_dynamic_entry(
							StringName(discovery_id),
							CodexEntryScript.Category.STRUCTURE,
							"Discover this structure by arranging the right biome pattern.",
							full_name,
							"A landmark structure discovered through biome arrangement."
						)
		filename = dir.get_next()
	dir.list_dir_end()

func _register_dynamic_entry(entry_id: StringName, category: int, hint: String, full_name: String, description: String) -> void:
	var entry: CodexEntry = CodexEntryScript.new()
	entry.entry_id = entry_id
	entry.category = category
	entry.hint_text = hint
	entry.full_name = full_name
	entry.full_description = description
	entry.always_hidden = false
	_entries[entry_id] = entry

func _humanize_id(raw_id: String) -> String:
	return raw_id.replace("_", " ").capitalize()

func _infer_category_for_unknown_entry(entry_id: StringName) -> int:
	if str(entry_id).begins_with("spirit_"):
		return CodexEntryScript.Category.SPIRIT
	if _structure_ids.has(entry_id):
		return CodexEntryScript.Category.STRUCTURE
	if str(entry_id).begins_with("disc_"):
		return CodexEntryScript.Category.BIOME
	if str(entry_id).begins_with("biome_"):
		return CodexEntryScript.Category.BIOME
	if str(entry_id).begins_with("seed_recipe_"):
		return CodexEntryScript.Category.SEED
	return CodexEntryScript.Category.STRUCTURE

func mark_discovered(entry_id: StringName) -> void:
	if not _entries.has(entry_id):
		var inferred_category: int = _infer_category_for_unknown_entry(entry_id)
		_register_dynamic_entry(
			entry_id,
			inferred_category,
			"Discover this entry through gameplay.",
			_humanize_id(str(entry_id)),
			"Discovered during your garden journey."
		)
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

func is_entry_hinted(entry_id: StringName) -> bool:
	if not _entries.has(entry_id):
		return false
	return not is_discovered(entry_id)

func get_ku_guidance_state() -> StringName:
	return SatoriIds.STATE_DISCOVERED if is_discovered(SatoriIds.KU_GUIDANCE_ENTRY_ID) else SatoriIds.STATE_HINTED

func force_reveal(entry_id: StringName) -> void:
	mark_discovered(entry_id)
