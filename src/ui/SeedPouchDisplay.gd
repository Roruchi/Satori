class_name SeedPouchDisplay
extends Label

const _BIOME_NAMES: Dictionary = {
	BiomeType.Value.STONE: "Stone",
	BiomeType.Value.RIVER: "River",
	BiomeType.Value.EMBER_FIELD: "Ember",
	BiomeType.Value.MEADOW: "Meadow",
	BiomeType.Value.CLAY: "Clay",
	BiomeType.Value.DESERT: "Desert",
	BiomeType.Value.DUNE: "Dune",
	BiomeType.Value.HOT_SPRING: "Hot Spring",
	BiomeType.Value.BOG: "Bog",
	BiomeType.Value.CINDER_HEATH: "Cinder Heath",
	BiomeType.Value.SACRED_STONE: "Sacred Stone",
	BiomeType.Value.VEIL_MARSH: "Veil Marsh",
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
		text = "Pouch: 0/0 uses | Hint: Mix to craft seeds"
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		text = "Pouch: 0/0 uses | Hint: Mix to craft seeds"
		return
	if pouch.size() == 0:
		text = "Pouch: 0/%d slots | 0 uses | Hint: Mix to craft seeds" % pouch.capacity
		return
	var total_uses: int = pouch.total_uses()
	text = "Pouch: %d/%d slots | %d uses" % [pouch.size(), pouch.capacity, total_uses]
