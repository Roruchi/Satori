class_name StructureCatalogData
extends RefCounted

const DiscoveryCatalogDataScript = preload("res://src/biomes/discovery_catalog_data.gd")
const RitualRecipeCatalogScript = preload("res://src/seeds/RitualRecipeCatalog.gd")

const FRAME_RELATIVE_PATH: String = "frames/idle/down/frame_0000.png"

const _BUILDING_ASSET_FOLDERS: Dictionary = {
	"building_house": "house",
	"building_meadow_dwelling": "meadow_dwelling",
	"building_scorched_hollow": "scorched_hollow",
	"building_fox_den": "fox_den",
}

const _FORM_EFFECTS: Dictionary = {
	"form_warm_hollow": [{"type": "shelter_form", "params": {"contextual_role": true}}],
	"form_fox_den": [{"type": "spirit_dwelling_upgrade", "params": {"spirit_id": "spirit_red_fox", "counts_as": "fire"}}],
	"form_dew_bowl": [{"type": "storage_cap", "params": {"target": "wind_essence"}}],
	"form_root_network": [{"type": "material_spawn_speed", "params": {"material_id": "living_wood", "radius": 1}}],
	"form_wind_chime": [{"type": "auto_harvest", "params": {"material_id": "living_wood", "radius": 1}}],
	"form_tiny_shrine": [
		{"type": "visitor_hint", "params": {"rarity": "rare"}},
		{"type": "essence_generator", "params": {"element": "ku", "interval_seconds": 120}},
	],
	"form_steam_weave": [{"type": "tension_hint", "params": {"theme": "fire_water"}}],
	"form_reed_nest": [
		{"type": "dwelling", "params": {"preferred_family": "water"}},
		{"type": "storage_cap", "params": {"target": "water_essence"}},
	],
	"form_reed_mat": [{"type": "stability", "params": {"biome_family": "wet_edges"}}],
	"form_reed_flute": [{"type": "invite_speed", "params": {"theme": "water_wind"}}],
	"form_dream_hammock": [{"type": "dream_path", "params": {"theme": "memory"}}],
	"form_hearth_stone": [{"type": "storage_cap", "params": {"target": "fire_essence"}}],
	"form_stone_basin": [{"type": "calming", "params": {"theme": "rain_fire_recovery"}}],
	"form_foundation_marker": [{"type": "stability", "params": {"scope": "local_structure"}}],
	"form_resonance_cairn": [{"type": "soft_connection", "params": {"extends_adjacency": true}}],
	"form_rune_marker": [{"type": "boundary", "params": {"theme": "seal_memory"}}],
	"form_kiln_heart": [{"type": "material_spawn_speed", "params": {"material_id": "ember_clay", "radius": 1}}],
	"form_steam_bowl": [{"type": "recovery", "params": {"theme": "steam"}}],
	"form_clay_anchor": [{"type": "stability", "params": {"biome_family": "heated_structures"}}],
	"form_ember_bellows": [{"type": "production_cycle", "params": {"theme": "fire"}}],
	"form_moonflame": [{"type": "blessing", "params": {"theme": "fire_ku"}}],
}

const _BUILDING_EFFECTS: Dictionary = {
	"building_house": [{"type": "dwelling", "params": {"capacity": 1}}],
	"building_meadow_dwelling": [{"type": "dwelling", "params": {"capacity": 1, "preferred_biome": "meadow"}}],
	"building_scorched_hollow": [{"type": "dwelling", "params": {"capacity": 1, "pressure": "fire"}}],
	"building_fox_den": [
		{"type": "dwelling", "params": {"capacity": 1, "preferred_biome": "meadow", "spirit_id": "spirit_red_fox", "upgraded": true}},
		{"type": "satori_rate_bonus", "params": {"per_minute": 1}},
	],
}

func get_all_entries() -> Array[Dictionary]:
	var entries_by_id: Dictionary = {}
	var house_effects: Array[Dictionary] = _effects_array_from_variant(_BUILDING_EFFECTS["building_house"])
	_add_entry(entries_by_id, _make_entry(
		"building_house",
		"House",
		"house",
		house_effects
	))
	_add_discovery_entries(entries_by_id)
	_add_ritual_structure_entries(entries_by_id)
	var entries: Array[Dictionary] = []
	for id_variant: Variant in entries_by_id.keys():
		var entry_variant: Variant = entries_by_id[id_variant]
		if entry_variant is Dictionary:
			entries.append((entry_variant as Dictionary).duplicate(true))
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("structure_id", "")) < str(b.get("structure_id", ""))
	)
	return entries

func get_entries_by_id() -> Dictionary:
	var by_id: Dictionary = {}
	for entry: Dictionary in get_all_entries():
		by_id[str(entry.get("structure_id", ""))] = entry.duplicate(true)
	return by_id

func get_entry(structure_id: String) -> Dictionary:
	var by_id: Dictionary = get_entries_by_id()
	var entry_variant: Variant = by_id.get(structure_id, {})
	if entry_variant is Dictionary:
		return (entry_variant as Dictionary).duplicate(true)
	return {}

func get_asset_path(structure_id: String) -> String:
	var entry: Dictionary = get_entry(structure_id)
	return str(entry.get("asset_path", ""))

func get_sprite_frames_path(structure_id: String) -> String:
	var entry: Dictionary = get_entry(structure_id)
	return str(entry.get("sprite_frames_path", ""))

func _add_discovery_entries(entries_by_id: Dictionary) -> void:
	var catalog_data: DiscoveryCatalogData = DiscoveryCatalogDataScript.new()
	var all_entries: Array[Dictionary] = []
	all_entries.append_array(catalog_data.get_tier1_entries())
	all_entries.append_array(catalog_data.get_tier2_entries())
	all_entries.append_array(catalog_data.get_tier3_entries())
	for meta: Dictionary in all_entries:
		var discovery_id: String = str(meta.get("discovery_id", ""))
		if discovery_id.is_empty():
			continue
		var display_name: String = str(meta.get("display_name", discovery_id))
		var folder_name: String = _folder_name_from_id(discovery_id)
		var effects: Array[Dictionary] = _effects_from_legacy(
			str(meta.get("effect_type", "")),
			_dictionary_from_variant(meta.get("effect_params", {})),
			int(meta.get("housing_capacity", 0))
		)
		_add_entry(entries_by_id, _make_entry(discovery_id, display_name, folder_name, effects))

func _add_ritual_structure_entries(entries_by_id: Dictionary) -> void:
	var ritual_catalog: RitualRecipeCatalog = RitualRecipeCatalogScript.new()
	for entry: RitualRecipeCatalog.RitualEntry in ritual_catalog.get_form_entries():
		var form_id: String = str(entry.result_id)
		if form_id.is_empty():
			continue
		var folder_name: String = _folder_name_from_asset_folder(entry.assets_folder, form_id)
		var form_effects: Array[Dictionary] = _effects_for_form(form_id)
		_add_entry(entries_by_id, _make_entry(form_id, entry.friendly_name, folder_name, form_effects))
		for biome_variant: Variant in entry.placement_rules.keys():
			var building_id: String = str(entry.placement_rules[biome_variant])
			if building_id.is_empty():
				continue
			var building_folder: String = str(_BUILDING_ASSET_FOLDERS.get(building_id, folder_name))
			var building_effects: Array[Dictionary] = _effects_for_building(building_id, form_effects)
			_add_entry(entries_by_id, _make_entry(
				building_id,
				_display_name_from_structure_id(building_id),
				building_folder,
				building_effects
			))

func _add_entry(entries_by_id: Dictionary, entry: Dictionary) -> void:
	var structure_id: String = str(entry.get("structure_id", ""))
	if structure_id.is_empty():
		return
	if entries_by_id.has(structure_id):
		var existing: Dictionary = (entries_by_id[structure_id] as Dictionary).duplicate(true)
		if str(existing.get("asset_path", "")).is_empty() and not str(entry.get("asset_path", "")).is_empty():
			existing["asset_path"] = entry["asset_path"]
			existing["sprite_frames_path"] = entry["sprite_frames_path"]
			existing["asset_folder"] = entry["asset_folder"]
		if not (existing.get("effects", []) is Array) or (existing.get("effects", []) as Array).is_empty():
			existing["effects"] = (entry.get("effects", []) as Array).duplicate(true)
		entries_by_id[structure_id] = existing
		return
	entries_by_id[structure_id] = entry

func _make_entry(structure_id: String, display_name: String, folder_name: String, effects: Array[Dictionary]) -> Dictionary:
	var normalized_folder: String = folder_name
	if normalized_folder.is_empty():
		normalized_folder = _folder_name_from_id(structure_id)
	var asset_folder: String = "res://assets/structures/%s" % normalized_folder
	return {
		"structure_id": structure_id,
		"display_name": display_name,
		"asset_folder": asset_folder,
		"asset_path": "%s/%s" % [asset_folder, FRAME_RELATIVE_PATH],
		"sprite_frames_path": "%s/sprite_frames.tres" % asset_folder,
		"effects": effects.duplicate(true),
	}

func _effects_for_form(form_id: String) -> Array[Dictionary]:
	var effects_variant: Variant = _FORM_EFFECTS.get(form_id, [])
	return _effects_array_from_variant(effects_variant)

func _effects_for_building(building_id: String, form_effects: Array[Dictionary]) -> Array[Dictionary]:
	var effects_variant: Variant = _BUILDING_EFFECTS.get(building_id, null)
	if effects_variant is Array:
		return _effects_array_from_variant(effects_variant)
	return form_effects.duplicate(true)

func _effects_from_legacy(effect_type: String, effect_params: Dictionary, housing_capacity: int) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if not effect_type.is_empty():
		var params: Dictionary = effect_params.duplicate(true)
		if effect_type == "dwelling" and housing_capacity > 0 and not params.has("capacity"):
			params["capacity"] = housing_capacity
		effects.append({"type": effect_type, "params": params})
	if housing_capacity > 0 and effect_type != "dwelling":
		effects.append({"type": "housing", "params": {"capacity": housing_capacity}})
	return effects

func _effects_array_from_variant(value: Variant) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if not (value is Array):
		return effects
	for effect_variant: Variant in value as Array:
		if effect_variant is Dictionary:
			effects.append((effect_variant as Dictionary).duplicate(true))
	return effects

func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

func _folder_name_from_asset_folder(raw_folder: String, fallback_id: String) -> String:
	var folder: String = raw_folder.strip_edges()
	folder = folder.replace("\\", "/")
	if folder.begins_with("res://assets/structures/"):
		return folder.replace("res://assets/structures/", "")
	if folder.begins_with("assets/structures/"):
		return folder.replace("assets/structures/", "")
	return _folder_name_from_id(fallback_id)

func _folder_name_from_id(structure_id: String) -> String:
	var folder: String = structure_id
	for prefix: String in ["disc_", "building_", "form_"]:
		if folder.begins_with(prefix):
			folder = folder.substr(prefix.length())
			break
	return folder

func _display_name_from_structure_id(structure_id: String) -> String:
	return _folder_name_from_id(structure_id).replace("_", " ").capitalize()
