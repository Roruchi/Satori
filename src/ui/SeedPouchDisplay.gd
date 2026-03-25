class_name SeedPouchDisplay
extends Label

func _ready() -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy != null and alchemy.has_signal("seed_added_to_pouch"):
		alchemy.seed_added_to_pouch.connect(_on_seed_added)
	_refresh()

func _on_seed_added(_recipe: SeedRecipe) -> void:
	_refresh()

func _refresh() -> void:
	var growth: Node = get_node_or_null("/root/SeedGrowthService")
	if growth == null or not growth.has_method("get_pouch"):
		text = "Pouch: 0"
		return
	var pouch: SeedPouch = growth.get_pouch()
	if pouch == null:
		text = "Pouch: 0"
		return
	text = "Pouch: %d/%d" % [pouch.size(), pouch.capacity]
