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
	if alchemy != null and alchemy.has_signal("building_craft_resolved"):
		alchemy.building_craft_resolved.connect(func(_tk: StringName, _oc: StringName, _fk: StringName, _g: String, _c: Array[int], _fd: bool) -> void: _refresh())
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth != null and growth.has_signal("pouch_updated"):
		growth.pouch_updated.connect(_refresh)
	_refresh()

func _on_seed_added(_recipe: SeedRecipe) -> void:
	_refresh()

func _refresh() -> void:
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth == null or not growth.has_method("get_pouch"):
		text = "Place: 0/0 uses | Hint: Craft placeables"
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		text = "Place: 0/0 uses | Hint: Craft placeables"
		return
	if pouch.size() == 0:
		text = "Place: 0/%d slots | 0 uses | Hint: Craft placeables" % pouch.capacity
		return
	text = _format_place_inventory_status(pouch)

func _format_place_inventory_status(pouch: SeedPouch) -> String:
	var total_uses: int = pouch.total_uses()
	var building_parts: Array[String] = []
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var entry: BuildingInventoryEntry = pouch.get_building_at(i)
			if entry != null:
				building_parts.append("%s x%d" % [_building_display_name(entry.type_key), entry.count])
	var prefix: String = "Place: %d/%d slots" % [pouch.size(), pouch.capacity]
	if building_parts.is_empty():
		return "%s | %d uses" % [prefix, total_uses]
	if total_uses > 0:
		return "%s | %d uses | %s" % [prefix, total_uses, ", ".join(building_parts)]
	return "%s | %s" % [prefix, ", ".join(building_parts)]

func _building_display_name(type_key: StringName) -> String:
	var raw: String = str(type_key)
	if raw.begins_with("building_"):
		raw = raw.substr("building_".length())
	return raw.capitalize()

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
