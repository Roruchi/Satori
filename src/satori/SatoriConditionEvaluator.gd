class_name SatoriConditionEvaluator
extends RefCounted

static func evaluate(requirements: Array[Dictionary]) -> bool:
	var root: Node = Engine.get_main_loop().root
	if root == null:
		return false
	var game_state: Node = root.get_node_or_null("/root/GameState")
	var spirit_service: Node = root.get_node_or_null("/root/SpiritService")
	var ecology_service: Node = root.get_node_or_null("/root/SpiritEcologyService")
	if game_state == null:
		return false
	var grid: RefCounted = game_state.get("grid")
	if grid == null:
		return false
	for requirement: Dictionary in requirements:
		var req_type: String = str(requirement.get("type", ""))
		if req_type == "biome_present":
			var biome: int = int(requirement.get("biome", -999))
			var found: bool = false
			for tile in grid.tiles.values():
				if tile.biome == biome:
					found = true
					break
			if not found:
				return false
		elif req_type == "spirit_count_gte":
			if spirit_service == null:
				return false
			var min_count: int = int(requirement.get("count", 0))
			var active_count: int = int(spirit_service.active_count())
			if active_count < min_count:
				return false
		elif req_type == "harmony_count_gte":
			if ecology_service == null:
				return false
			var harmony_min: int = int(requirement.get("count", 0))
			var current_harmony: int = int(ecology_service.harmony_count())
			if current_harmony < harmony_min:
				return false
		elif req_type == "tile_count_gte":
			var tile_count: int = int(grid.total_tile_count)
			var min_tiles: int = int(requirement.get("count", 0))
			if tile_count < min_tiles:
				return false
		else:
			return false
	return true
