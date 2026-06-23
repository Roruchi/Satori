class_name RitualRecipeCatalog
extends RefCounted

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")

const DEFAULT_RITUAL_CSV_PATH: String = "res://data/discovery_editor/rituals.csv"
const DEFAULT_MATERIAL_CSV_PATH: String = "res://data/discovery_editor/materials.csv"

class RitualEntry extends RefCounted:
	var ritual_id: StringName = &""
	var friendly_name: String = ""
	var result_kind: StringName = &""
	var result_id: StringName = &""
	var discovery_id: StringName = &""
	var input_keys: Array[String] = []
	var required_elements: Array[int] = []
	var required_material_counts: Dictionary = {}
	var placement_rules: Dictionary = {}
	var codex_hint: String = ""
	var unlock_text: String = ""
	var assets_folder: String = ""

var _form_entries: Array[RitualEntry] = []
var _seed_entries: Array[RitualEntry] = []
var _forms_by_result_id: Dictionary = {}
var _material_name_to_id: Dictionary = {}

func _init(ritual_csv_path: String = DEFAULT_RITUAL_CSV_PATH, material_csv_path: String = DEFAULT_MATERIAL_CSV_PATH) -> void:
	_load_material_names(material_csv_path)
	_load_rituals(ritual_csv_path)

func get_form_entries() -> Array[RitualEntry]:
	return _form_entries.duplicate()

func get_seed_entries() -> Array[RitualEntry]:
	return _seed_entries.duplicate()

func get_required_material_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	for entry: RitualEntry in _form_entries:
		for material_variant: Variant in entry.required_material_counts.keys():
			var material_id: StringName = StringName(str(material_variant))
			if seen.has(material_id):
				continue
			seen[material_id] = true
			ids.append(material_id)
	return ids

func lookup_form(input_keys: Array[String]) -> RitualEntry:
	return _lookup_entry(_form_entries, input_keys)

func lookup_seed(input_keys: Array[String]) -> RitualEntry:
	return _lookup_entry(_seed_entries, input_keys)

func _lookup_entry(entries: Array[RitualEntry], input_keys: Array[String]) -> RitualEntry:
	var normalized: Array[String] = input_keys.duplicate()
	normalized.sort()
	var key: String = _key_for_inputs(normalized)
	for entry: RitualEntry in entries:
		if _key_for_inputs(entry.input_keys) == key:
			return entry
	return null

func is_placeable_form(result_id: StringName) -> bool:
	return _forms_by_result_id.has(result_id)

func resolve_form_placement(result_id: StringName, target_biome: int) -> StringName:
	var entry_variant: Variant = _forms_by_result_id.get(result_id, null)
	if not (entry_variant is RitualEntry):
		return result_id
	var entry: RitualEntry = entry_variant as RitualEntry
	return StringName(str(entry.placement_rules.get(target_biome, "")))

func get_form_entry(result_id: StringName) -> RitualEntry:
	var entry_variant: Variant = _forms_by_result_id.get(result_id, null)
	if entry_variant is RitualEntry:
		return entry_variant as RitualEntry
	return null

func _load_material_names(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.size() <= 1 and str(values[0]).strip_edges().is_empty():
			continue
		var row: Dictionary = _row_from_csv(headers, values)
		var name: String = str(row.get("Name", "")).strip_edges()
		var material_id: String = str(row.get("Material ID", "")).strip_edges()
		if name.is_empty() or material_id.is_empty():
			continue
		_material_name_to_id[name.to_lower()] = StringName(material_id)
	file.close()

func _load_rituals(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.size() <= 1 and str(values[0]).strip_edges().is_empty():
			continue
		var row: Dictionary = _row_from_csv(headers, values)
		var result_kind: StringName = StringName(str(row.get("Result Kind", "")).strip_edges())
		var type_name: String = str(row.get("Type", "")).strip_edges()
		var entry: RitualEntry = _entry_from_row(row)
		if entry == null or entry.result_id == &"":
			continue
		if result_kind == &"seed" or type_name.to_lower() == "seed":
			_seed_entries.append(entry)
		elif result_kind == &"form" or type_name.to_lower() == "structure":
			_form_entries.append(entry)
			_forms_by_result_id[entry.result_id] = entry
	file.close()

func _entry_from_row(row: Dictionary) -> RitualEntry:
	var entry: RitualEntry = RitualEntry.new()
	entry.ritual_id = StringName(str(row.get("Ritual ID", "")).strip_edges())
	entry.friendly_name = str(row.get("Friendly Name", "")).strip_edges()
	entry.result_kind = StringName(str(row.get("Result Kind", "form")).strip_edges())
	entry.result_id = StringName(str(row.get("Result ID", "")).strip_edges())
	entry.discovery_id = StringName(str(row.get("Discovery ID", "")).strip_edges())
	entry.codex_hint = str(row.get("Codex Hint 1", "")).strip_edges()
	entry.unlock_text = str(row.get("Unlock text", "")).strip_edges()
	entry.assets_folder = str(row.get("Assets Folder", "")).strip_edges()
	entry.placement_rules = _parse_placement_rules(str(row.get("Placement Rules", "")))

	for column: String in ["Component1", "Component2", "Component3"]:
		var component: String = str(row.get(column, "")).strip_edges()
		if component.is_empty():
			continue
		var key: String = _input_key_for_component(component)
		if key.is_empty():
			continue
		entry.input_keys.append(key)
		if key.begins_with("essence:"):
			var element: int = _element_for_essence_component(component)
			if element != -1:
				entry.required_elements.append(element)
		elif key.begins_with("material:"):
			var material_id: StringName = StringName(key.replace("material:", ""))
			entry.required_material_counts[material_id] = int(entry.required_material_counts.get(material_id, 0)) + 1
	entry.input_keys.sort()
	return entry

func _row_from_csv(headers: PackedStringArray, values: PackedStringArray) -> Dictionary:
	var row: Dictionary = {}
	for index: int in range(headers.size()):
		var header: String = str(headers[index]).strip_edges()
		var value: String = ""
		if index < values.size():
			value = str(values[index]).strip_edges()
		row[header] = value
	return row

func _input_key_for_component(component: String) -> String:
	var lower: String = component.to_lower()
	var essence_name: String = lower.replace(" essence", "") if lower.ends_with(" essence") else lower
	var essence_key: String = _essence_key_name(essence_name)
	if _is_known_essence_key(essence_key):
		return "essence:%s" % essence_key
	if lower.ends_with(" essence"):
		return ""
	var material_variant: Variant = _material_name_to_id.get(lower, null)
	if material_variant != null:
		return "material:%s" % str(material_variant)
	return ""

func _element_for_essence_component(component: String) -> int:
	var lower: String = component.to_lower().replace(" essence", "")
	match _essence_key_name(lower):
		"earth":
			return GodaiElementScript.Value.CHI
		"water":
			return GodaiElementScript.Value.SUI
		"fire":
			return GodaiElementScript.Value.KA
		"wind":
			return GodaiElementScript.Value.FU
		"ku":
			return GodaiElementScript.Value.KU
		_:
			return -1

func _essence_key_name(name: String) -> String:
	match name:
		"chi", "earth":
			return "earth"
		"sui", "water":
			return "water"
		"ka", "fire":
			return "fire"
		"fu", "fū", "wind":
			return "wind"
		"ku", "kū":
			return "ku"
		_:
			return name

func _is_known_essence_key(key: String) -> bool:
	return key == "earth" or key == "water" or key == "fire" or key == "wind" or key == "ku"

func _parse_placement_rules(raw: String) -> Dictionary:
	var rules: Dictionary = {}
	for part: String in raw.split(";"):
		var trimmed: String = part.strip_edges()
		if trimmed.is_empty():
			continue
		var pieces: PackedStringArray = trimmed.split("=")
		if pieces.size() != 2:
			continue
		var biome: int = _biome_id_for_name(str(pieces[0]).strip_edges())
		var result: String = str(pieces[1]).strip_edges()
		if biome == BiomeTypeScript.Value.NONE or result.is_empty():
			continue
		rules[biome] = StringName(result)
	return rules

func _biome_id_for_name(name: String) -> int:
	match name.to_lower():
		"stone":
			return BiomeTypeScript.Value.STONE
		"river":
			return BiomeTypeScript.Value.RIVER
		"ember field":
			return BiomeTypeScript.Value.EMBER_FIELD
		"meadow":
			return BiomeTypeScript.Value.MEADOW
		"wetlands":
			return BiomeTypeScript.Value.WETLANDS
		"badlands":
			return BiomeTypeScript.Value.BADLANDS
		"whistling canyons":
			return BiomeTypeScript.Value.WHISTLING_CANYONS
		"prismatic terraces":
			return BiomeTypeScript.Value.PRISMATIC_TERRACES
		"frostlands":
			return BiomeTypeScript.Value.FROSTLANDS
		"the ashfall":
			return BiomeTypeScript.Value.THE_ASHFALL
		"sacred stone":
			return BiomeTypeScript.Value.SACRED_STONE
		"moonlit pool":
			return BiomeTypeScript.Value.MOONLIT_POOL
		"ember shrine":
			return BiomeTypeScript.Value.EMBER_SHRINE
		"cloud ridge":
			return BiomeTypeScript.Value.CLOUD_RIDGE
		"ku", "kū":
			return BiomeTypeScript.Value.KU
		_:
			return BiomeTypeScript.Value.NONE

func _key_for_inputs(keys: Array[String]) -> String:
	return "|".join(keys)
