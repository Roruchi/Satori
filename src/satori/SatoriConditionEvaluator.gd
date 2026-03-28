class_name SatoriConditionEvaluator
extends RefCounted

const SatoriIdsScript = preload("res://src/satori/SatoriIds.gd")

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

static func era_from_satori(satori_value: int) -> StringName:
	if satori_value >= SatoriIdsScript.THRESHOLD_SATORI_MIN:
		return SatoriIdsScript.ERA_SATORI
	if satori_value >= SatoriIdsScript.THRESHOLD_FLOW_MIN:
		return SatoriIdsScript.ERA_FLOW
	if satori_value >= SatoriIdsScript.THRESHOLD_AWAKENING_MIN:
		return SatoriIdsScript.ERA_AWAKENING
	return SatoriIdsScript.ERA_STILLNESS

static func is_tier2_allowed(era: StringName) -> bool:
	return era == SatoriIdsScript.ERA_AWAKENING or era == SatoriIdsScript.ERA_FLOW or era == SatoriIdsScript.ERA_SATORI

static func is_tier3_allowed(era: StringName) -> bool:
	return era == SatoriIdsScript.ERA_FLOW or era == SatoriIdsScript.ERA_SATORI

static func is_tier4_allowed(era: StringName) -> bool:
	return era == SatoriIdsScript.ERA_SATORI

static func era_meets_requirement(current_era: StringName, required_era: StringName) -> bool:
	var order: Dictionary = {
		SatoriIdsScript.ERA_STILLNESS: 0,
		SatoriIdsScript.ERA_AWAKENING: 1,
		SatoriIdsScript.ERA_FLOW: 2,
		SatoriIdsScript.ERA_SATORI: 3,
	}
	var current_rank: int = int(order.get(current_era, -1))
	var required_rank: int = int(order.get(required_era, 99))
	return current_rank >= required_rank
