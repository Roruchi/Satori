class_name SeedPouchDisplay
extends Label

signal building_item_selected(type_key: StringName)

const _BIOME_NAMES: Dictionary = {
	BiomeType.Value.STONE: "Stone",
	BiomeType.Value.RIVER: "River",
	BiomeType.Value.EMBER_FIELD: "Ember",
	BiomeType.Value.MEADOW: "Meadow",
	BiomeType.Value.WETLANDS: "Wetlands",
	BiomeType.Value.BADLANDS: "Badlands",
	BiomeType.Value.WHISTLING_CANYONS: "Whistling Canyons",
	BiomeType.Value.PRISMATIC_TERRACES: "Prismatic Terraces",
	BiomeType.Value.FROSTLANDS: "Frostlands",
	BiomeType.Value.THE_ASHFALL: "The Ashfall",
	BiomeType.Value.SACRED_STONE: "Sacred Stone",
	BiomeType.Value.MOONLIT_POOL: "Moonlit Pool",
	BiomeType.Value.EMBER_SHRINE: "Ember Shrine",
	BiomeType.Value.CLOUD_RIDGE: "Cloud Ridge",
}

func _ready() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_signal("seed_added_to_pouch"):
		alchemy.seed_added_to_pouch.connect(_on_seed_added)
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_signal("pouch_updated"):
		growth.pouch_updated.connect(_refresh)
	_refresh()

func _on_seed_added(_recipe: SeedRecipe) -> void:
	_refresh()

func _refresh() -> void:
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth == null or not growth.has_method("get_pouch"):
		text = "0/0 | Empty"
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		text = "0/0 | Empty"
		return
	if pouch.size() == 0:
		text = "0/%d | Empty" % pouch.capacity
		return
	text = _format_place_inventory_status(pouch)

func _format_place_inventory_status(pouch: SeedPouch) -> String:
	if pouch == null:
		return "0/0 | Empty"
	if pouch.size() == 0:
		return "0/%d | Empty" % pouch.capacity
	var placeable_parts: Array[String] = []
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var entry: BuildingInventoryEntry = pouch.get_building_at(i)
			if entry != null:
				placeable_parts.append("%s x%d" % [_building_display_name(entry.type_key), entry.count])
		else:
			var recipe: SeedRecipe = pouch.get_at(i)
			var uses: int = pouch.get_uses_at(i)
			if recipe != null and uses > 0:
				placeable_parts.append("%s x%d" % [_seed_display_name(recipe), uses])
	var prefix: String = "%d/%d" % [pouch.size(), pouch.capacity]
	if placeable_parts.is_empty():
		return "%s | Empty" % prefix
	return "%s | %s" % [prefix, ", ".join(placeable_parts)]

func _seed_display_name(recipe: SeedRecipe) -> String:
	if recipe == null:
		return "Seed"
	var biome_name: String = str(_BIOME_NAMES.get(recipe.produces_biome, recipe.recipe_id))
	if biome_name.ends_with("Seed"):
		return biome_name.trim_suffix(" Seed")
	return biome_name

func _building_display_name(type_key: StringName) -> String:
	var form_name: String = _form_display_name(type_key)
	if not form_name.is_empty():
		return form_name
	var raw: String = str(type_key)
	if raw.begins_with("building_"):
		raw = raw.substr("building_".length())
	if raw.begins_with("form_"):
		raw = raw.substr("form_".length())
	return raw.capitalize()

func _form_display_name(type_key: StringName) -> String:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_method("get_form_display_name"):
		return str(alchemy.get_form_display_name(type_key))
	return ""

func select_building_item(type_key: StringName) -> void:
	building_item_selected.emit(type_key)

func try_select_next_building() -> void:
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth == null or not growth.has_method("get_pouch"):
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		return
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var entry: BuildingInventoryEntry = pouch.get_building_at(i)
			if entry != null and entry.count > 0:
				building_item_selected.emit(entry.type_key)
				return
