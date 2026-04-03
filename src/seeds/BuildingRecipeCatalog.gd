class_name BuildingRecipeCatalog
extends RefCounted

class RecipeEntry extends RefCounted:
	var recipe_id: StringName = &""
	var building_type_key: StringName = &""
	var footprint_id: StringName = &""
	var discovery_entry_id: StringName = &""

var _catalog: Dictionary = {}

func _init() -> void:
	# CHI=0, SUI=1, KA=2, FU=3, KU=4
	register(&"building_house", &"building_house", &"fp_single", &"disc_building_house", [0, 0, 0])
	register(&"building_granary", &"building_granary", &"fp_single", &"disc_building_granary", [3, 3, 3])
	register(&"building_watchtower", &"building_watchtower", &"fp_single", &"disc_building_watchtower", [0, 0, 1])
	register(&"building_pavilion", &"building_pavilion", &"fp_single", &"disc_building_pavilion", [1, 1, 2])
	register(&"building_forge", &"building_forge", &"fp_single", &"disc_building_forge", [2, 2, 2])

func register(recipe_id: StringName, building_type_key: StringName, footprint_id: StringName, discovery_entry_id: StringName, normalized_tokens: Array[int]) -> void:
	var key: String = _catalog_key(normalized_tokens)
	var entry: RecipeEntry = RecipeEntry.new()
	entry.recipe_id = recipe_id
	entry.building_type_key = building_type_key
	entry.footprint_id = footprint_id
	entry.discovery_entry_id = discovery_entry_id
	_catalog[key] = entry

func lookup(normalized_tokens: Array[int]) -> RecipeEntry:
	var key: String = _catalog_key(normalized_tokens)
	var entry_variant: Variant = _catalog.get(key, null)
	if entry_variant is RecipeEntry:
		return entry_variant as RecipeEntry
	return null

func has_recipe(normalized_tokens: Array[int]) -> bool:
	return lookup(normalized_tokens) != null

func _catalog_key(tokens: Array[int]) -> String:
	var sorted: Array[int] = tokens.duplicate()
	sorted.sort()
	var parts: Array[String] = []
	for token: int in sorted:
		parts.append(str(token))
	return "|".join(parts)
