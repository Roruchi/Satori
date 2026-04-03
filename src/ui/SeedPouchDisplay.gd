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
		text = "Pouch: 0/0 uses | Hint: Craft seeds"
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		text = "Pouch: 0/0 uses | Hint: Craft seeds"
		return
	if pouch.size() == 0:
		text = "Pouch: 0/%d slots | 0 uses | Hint: Craft seeds" % pouch.capacity
		return
	var total_uses: int = pouch.total_uses()
	var building_parts: Array[String] = []
	for i: int in range(pouch.size()):
		if pouch.get_entry_kind_at(i) == &"building_item":
			var entry: BuildingInventoryEntry = pouch.get_building_at(i)
			if entry != null:
				var display_name: String = str(entry.type_key).replace("building_", "").capitalize()
				building_parts.append("%s x%d" % [display_name, entry.count])
	if building_parts.is_empty():
		text = "Pouch: %d/%d slots | %d uses" % [pouch.size(), pouch.capacity, total_uses]
	else:
		text = "Pouch: %d/%d slots | %d uses | Buildings: %s" % [pouch.size(), pouch.capacity, total_uses, ", ".join(building_parts)]

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
