class_name StructureCatalogData
extends RefCounted

const DiscoveryCatalogDataScript = preload("res://src/biomes/discovery_catalog_data.gd")
const RitualRecipeCatalogScript = preload("res://src/seeds/RitualRecipeCatalog.gd")

const FRAME_RELATIVE_PATH: String = "frames/idle/down/frame_0000.png"

const _BUILDING_ASSET_FOLDERS: Dictionary = {
	"building_house": "house",
	"building_meadow_dwelling": "meadow_hollow",
	"building_scorched_hollow": "scorched_hollow",
	"building_stone_hollow": "stone_hollow",
	"building_wind_hollow": "warm_hollow",
	"building_fox_den": "fox_den",
}

const _FORM_EFFECTS: Dictionary = {
	"form_meadow_hollow": [{"type": "shelter_form", "params": {"family": "meadow"}}],
	"form_warm_hollow": [{"type": "shelter_form", "params": {"family": "wind"}}],
	"form_stone_hollow": [{"type": "shelter_form", "params": {"family": "stone"}}],
	"form_scorched_hollow": [{"type": "shelter_form", "params": {"family": "fire"}}],
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
	"building_meadow_dwelling": [{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "meadow"}}],
	"building_scorched_hollow": [{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "fire"}}],
	"building_stone_hollow": [{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "stone"}}],
	"building_wind_hollow": [{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "wind"}}],
	"building_reed_nest": [
		{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "water"}},
		{"type": "storage_cap", "params": {"target": "water_essence"}},
	],
	"building_fox_den": [
		{"type": "dwelling", "params": {"capacity": 1, "preferred_family": "meadow", "spirit_id": "spirit_red_fox", "upgraded": true}},
		{"type": "satori_rate_bonus", "params": {"per_minute": 1}},
	],
}

const _BUILDING_DESCRIPTIONS: Dictionary = {
	"building_house": "A basic one-spirit dwelling matched to the biome it was built on.",
	"building_meadow_dwelling": "Meadow house. Settles meadow spirits such as Red Fox, Meadow Lark, Hare, and Mist Stag.",
	"building_scorched_hollow": "Fire house. Settles fire-aspect spirits from Ember Field, Badlands, Ashfall, or Ember Shrine.",
	"building_stone_hollow": "Stone house. Settles stone spirits from Stone, Sacred Stone, Whistling Canyons, or other stone-aspect terrain.",
	"building_wind_hollow": "Wind house. Warm Hollow settles wind spirits from Cloud Ridge and other wind-aspect terrain.",
	"building_reed_nest": "Water house. Settles water spirits from River, Wetlands, Moonlit Pool, or other water-aspect terrain.",
	"building_fox_den": "Red Fox house. An upgraded meadow dwelling reserved for Red Fox and worth extra Satori.",
}

const _BUILDING_BUILD_HINTS: Dictionary = {
	"building_house": "Build by placing a normal house on a matching biome.",
	"building_meadow_dwelling": "Build: shape Meadow Hollow with Living Wood + Fire Essence, then place it on Meadow.",
	"building_scorched_hollow": "Build: shape Scorched Hollow with Ember Clay + Fire Essence + Living Wood, then place it on Ember Field, Ember Shrine, or Ashfall.",
	"building_stone_hollow": "Build: shape Stone Hollow with Spirit Stone + Earth Essence + Living Wood, then place it on Stone or Sacred Stone.",
	"building_wind_hollow": "Build: shape Warm Hollow with Living Wood + Fire Essence + Wind Essence, then place it on Cloud Ridge.",
	"building_reed_nest": "Build: shape Reed Nest with Reed Fiber + Water Essence, then place it on River, Wetlands, or Moonlit Pool.",
	"building_fox_den": "Build: shape Fox Den with Living Wood + housed Red Fox, then place it on Meadow or Badlands.",
}

const _BUILDING_HOVER_SUMMARIES: Dictionary = {
	"building_house": "Biome-matched dwelling",
	"building_meadow_dwelling": "Meadow dwelling",
	"building_scorched_hollow": "Fire dwelling",
	"building_stone_hollow": "Stone dwelling",
	"building_wind_hollow": "Wind dwelling",
	"building_reed_nest": "Water dwelling",
	"building_fox_den": "Red Fox dwelling",
}

const _BUILDING_HOVER_HINTS: Dictionary = {
	"building_meadow_dwelling": "Build: Meadow Hollow",
	"building_scorched_hollow": "Build: Scorched Hollow",
	"building_stone_hollow": "Build: Stone Hollow",
	"building_wind_hollow": "Build: Warm Hollow",
	"building_reed_nest": "Build: Reed Nest",
	"building_fox_den": "Build: Fox Den",
}

const _EFFECT_DESCRIPTIONS: Dictionary = {
	"auto_harvest": "Effect: auto-harvests nearby material nodes.",
	"blessing": "Effect: supports blessing and fire-Ku ritual paths.",
	"boundary": "Effect: marks a named ritual boundary.",
	"calming": "Effect: calms rain-fire recovery patterns.",
	"dream_path": "Effect: supports memory and dream paths.",
	"dwelling": "Effect: houses one compatible spirit.",
	"essence_generator": "Effect: generates Ku charges over time.",
	"invite_speed": "Effect: improves water-wind invitation paths.",
	"material_spawn_speed": "Effect: speeds nearby material growth.",
	"production_cycle": "Effect: supports fire production cycles.",
	"recovery": "Effect: supports steam recovery paths.",
	"satori_rate_bonus": "Effect: adds bonus Satori while occupied.",
	"shelter_form": "Effect: becomes a biome-specific dwelling when placed.",
	"soft_connection": "Effect: extends soft adjacency for patterns.",
	"spirit_dwelling_upgrade": "Effect: upgrades a specific spirit's home.",
	"stability": "Effect: stabilizes nearby structure patterns.",
	"storage_cap": "Effect: increases matching essence storage.",
	"tension_hint": "Effect: reveals fire-water tension hints.",
	"visitor_hint": "Effect: attracts rare visitor hints.",
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

func get_hover_lines(structure_id: String) -> Array[String]:
	var entry: Dictionary = get_entry(structure_id)
	if entry.is_empty():
		return []
	var lines: Array[String] = []
	var summary: String = str(entry.get("hover_summary", ""))
	if summary.is_empty():
		summary = _first_effect_summary(entry.get("effects", []))
	if not summary.is_empty():
		lines.append(summary)
	var hint: String = str(entry.get("hover_hint", ""))
	if not hint.is_empty() and not lines.has(hint):
		lines.append(hint)
	return lines

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
		var discovery_id: String = str(entry.discovery_id)
		if not discovery_id.is_empty():
			_add_entry(entries_by_id, _make_entry(discovery_id, entry.friendly_name, folder_name, form_effects))
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
		"description": str(_BUILDING_DESCRIPTIONS.get(structure_id, "")),
		"build_hint": str(_BUILDING_BUILD_HINTS.get(structure_id, "")),
		"hover_summary": str(_BUILDING_HOVER_SUMMARIES.get(structure_id, "")),
		"hover_hint": str(_BUILDING_HOVER_HINTS.get(structure_id, "")),
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

func _effect_lines(value: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (value is Array):
		return lines
	for effect_variant: Variant in value as Array:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant as Dictionary
		var effect_type: String = str(effect.get("type", ""))
		var line: String = str(_EFFECT_DESCRIPTIONS.get(effect_type, ""))
		if line.is_empty():
			continue
		lines.append(line)
	return lines

func _first_effect_summary(value: Variant) -> String:
	var effect_lines: Array[String] = _effect_lines(value)
	if effect_lines.is_empty():
		return ""
	var line: String = effect_lines[0]
	if line.begins_with("Effect: "):
		line = line.substr("Effect: ".length())
	if line.ends_with("."):
		line = line.substr(0, line.length() - 1)
	return line.capitalize()

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
