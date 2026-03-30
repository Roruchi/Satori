class_name SpiritGiftProcessor
extends RefCounted

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const _INVALID_COORD: Vector2i = Vector2i(2147483647, 2147483647)

static func process(spirit_id: String, definition: Dictionary) -> void:
	if spirit_id.is_empty():
		return
	var gift_type: int = int(definition.get("gift_type", SpiritGiftTypeScript.Value.NONE))
	var gift_payload: StringName = StringName(str(definition.get("gift_payload", "")))
	process_gift(gift_type, gift_payload)

static func process_gift(gift_type: int, gift_payload: StringName) -> void:
	var root: Node = Engine.get_main_loop().root
	if root == null:
		return
	match gift_type:
		SpiritGiftTypeScript.Value.KU_UNLOCK:
			var alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
			if alchemy != null and alchemy.has_method("is_ku_unlocked") and alchemy.is_ku_unlocked():
				return
			if alchemy != null and alchemy.has_method("unlock_element"):
				alchemy.unlock_element(GodaiElementScript.Value.KU)
		SpiritGiftTypeScript.Value.TIER3_RECIPE:
			var alchemy_registry: Node = root.get_node_or_null("/root/SeedAlchemyService")
			if alchemy_registry != null and alchemy_registry.has_method("get_registry"):
				var registry: SeedRecipeRegistry = alchemy_registry.get_registry()
				if registry != null:
					registry.unlock_recipe(gift_payload)
		SpiritGiftTypeScript.Value.POUCH_EXPAND:
			var growth_service_for_slots: Node = root.get_node_or_null("/root/SeedGrowthService")
			if growth_service_for_slots != null and growth_service_for_slots.has_method("get_tracker"):
				var slots_tracker: GrowthSlotTracker = growth_service_for_slots.get_tracker()
				if slots_tracker != null:
					slots_tracker.capacity += 1
		SpiritGiftTypeScript.Value.GROWING_SLOT_EXPAND:
			var growth_service_for_pouch: Node = root.get_node_or_null("/root/SeedGrowthService")
			if growth_service_for_pouch != null and growth_service_for_pouch.has_method("get_pouch"):
				var seed_pouch: SeedPouch = growth_service_for_pouch.get_pouch()
				if seed_pouch != null:
					seed_pouch.capacity += 1
		SpiritGiftTypeScript.Value.CODEX_REVEAL:
			var codex: Node = root.get_node_or_null("/root/CodexService")
			if codex != null and codex.has_method("force_reveal"):
				codex.force_reveal(gift_payload)
		SpiritGiftTypeScript.Value.GODAI_CHARGE:
			var alchemy_for_charge: Node = root.get_node_or_null("/root/SeedAlchemyService")
			if alchemy_for_charge == null or not alchemy_for_charge.has_method("store_shrine_charge"):
				return
			var game_state: Node = root.get_node_or_null("/root/GameState")
			if game_state == null:
				return
			var key_parts: PackedStringArray = String(gift_payload).split(":")
			if key_parts.size() < 2:
				return
			var spirit_id: String = String(key_parts[0])
			var elements_part: PackedStringArray = key_parts[1].split(",")
			var grid_variant: Variant = game_state.get("grid")
			if not (grid_variant is RefCounted):
				return
			var grid: RefCounted = grid_variant as RefCounted
			if grid == null or not grid.has_method("get_tile"):
				return
			var spirit_coord: Vector2i = _find_spirit_anchor_coord(grid, spirit_id)
			var preferred_island: String = ""
			if spirit_coord != _INVALID_COORD:
				preferred_island = _island_id_for_coord(grid, spirit_coord)
			var dropoff_coord: Vector2i = _find_origin_dropoff_coord(grid, preferred_island)
			if dropoff_coord == _INVALID_COORD and not preferred_island.is_empty():
				dropoff_coord = _find_origin_dropoff_coord(grid, "")
			if dropoff_coord == _INVALID_COORD:
				return
			if _is_water_spirit(spirit_id):
				var water_house_coord: Vector2i = _find_completed_water_building_dropoff(grid, preferred_island)
				if water_house_coord == _INVALID_COORD and spirit_coord != _INVALID_COORD and not _same_island(grid, spirit_coord, dropoff_coord):
					water_house_coord = _find_completed_water_building_dropoff(grid, "")
				if water_house_coord != _INVALID_COORD:
					dropoff_coord = water_house_coord
					var fallback_tile: GardenTile = grid.get_tile(dropoff_coord)
					if fallback_tile != null:
						fallback_tile.metadata["is_water_dropoff"] = true
			for element_str: String in elements_part:
				var trimmed: String = element_str.strip_edges()
				if trimmed.is_empty():
					continue
				var element: int = int(trimmed)
				alchemy_for_charge.store_shrine_charge(dropoff_coord, element, 1)
			return
		_:
			pass

static func _find_origin_dropoff_coord(grid: RefCounted, preferred_island: String = "") -> Vector2i:
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		if bool(tile.metadata.get("is_origin_shrine", false)):
			if not preferred_island.is_empty():
				var shrine_island: String = _island_id_for_coord(grid, coord)
				if shrine_island != preferred_island:
					continue
			return coord
	if preferred_island.is_empty() and grid.has_method("has_tile") and grid.has_tile(Vector2i.ZERO):
		return Vector2i.ZERO
	return _INVALID_COORD

static func _find_spirit_anchor_coord(grid: RefCounted, spirit_id: String) -> Vector2i:
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		if str(tile.metadata.get("spirit_id", "")) == spirit_id:
			return coord
	return _INVALID_COORD

static func _find_completed_water_building_dropoff(grid: RefCounted, preferred_island: String) -> Vector2i:
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		if not bool(tile.metadata.get("is_building_complete", false)):
			continue
		if not _is_water_biome(tile.biome):
			continue
		if not preferred_island.is_empty():
			var tile_island: String = str(tile.metadata.get("island_id", ""))
			if tile_island != preferred_island:
				continue
		return coord
	return _INVALID_COORD

static func _is_water_spirit(spirit_id: String) -> bool:
	for entry_variant: Variant in SpiritCatalogData.new().get_entries():
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant as Dictionary
		if str(entry.get("spirit_id", "")) != spirit_id:
			continue
		var preferred_variant: Variant = entry.get("preferred_biomes", [])
		if not (preferred_variant is Array):
			return false
		for biome_variant: Variant in (preferred_variant as Array):
			if _is_water_biome(int(biome_variant)):
				return true
		return false
	return false

static func _is_water_biome(biome: int) -> bool:
	return biome == BiomeTypeScript.Value.RIVER or biome == BiomeTypeScript.Value.WETLANDS or biome == BiomeTypeScript.Value.MOONLIT_POOL

static func _same_island(grid: RefCounted, a: Vector2i, b: Vector2i) -> bool:
	var a_island: String = _island_id_for_coord(grid, a)
	var b_island: String = _island_id_for_coord(grid, b)
	if a_island.is_empty() or b_island.is_empty():
		return true
	return a_island == b_island

static func _island_id_for_coord(grid: RefCounted, coord: Vector2i) -> String:
	if grid == null or not grid.has_method("get_island_id"):
		return ""
	return str(grid.get_island_id(coord))
