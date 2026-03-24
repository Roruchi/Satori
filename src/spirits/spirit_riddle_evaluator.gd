class_name SpiritRiddleEvaluator
extends RefCounted

const _HexUtils = preload("res://src/grid/hex_utils.gd")

## Returns true if pattern is partially (but not fully) satisfied.
## Used to decide when to show riddle hint text.
func evaluate_partial(pattern: PatternDefinition, grid: RefCounted, registry: DiscoveryRegistry) -> bool:
	match pattern.pattern_type:
		PatternDefinition.PatternType.CLUSTER:
			return _evaluate_cluster_partial(pattern, grid)
		PatternDefinition.PatternType.SHAPE:
			return _evaluate_shape_partial(pattern, grid)
		PatternDefinition.PatternType.RATIO_PROXIMITY:
			return _evaluate_ratio_partial(pattern, grid)
		PatternDefinition.PatternType.COMPOUND:
			return _evaluate_compound_partial(pattern, grid, registry)
	return false

func _evaluate_cluster_partial(pattern: PatternDefinition, grid: RefCounted) -> bool:
	if pattern.required_biomes.is_empty():
		return false
	var biome: int = pattern.required_biomes[0]
	var threshold: int = pattern.size_threshold
	var half_threshold: float = float(threshold) * 0.5
	var best_size: int = _find_largest_cluster(grid, biome)
	return float(best_size) >= half_threshold and best_size < threshold

func _evaluate_shape_partial(pattern: PatternDefinition, grid: RefCounted) -> bool:
	if pattern.shape_recipe.is_empty():
		return false
	for coord_variant in grid.tiles.keys():
		var anchor: Vector2i = coord_variant
		var matched: int = 0
		var total: int = pattern.shape_recipe.size()
		for entry: Dictionary in pattern.shape_recipe:
			var offset: Vector2i = entry.get("offset", Vector2i.ZERO)
			var target_biome: int = int(entry.get("biome", -1))
			var tile: GardenTile = grid.get_tile(anchor + offset)
			if tile != null and tile.biome == target_biome:
				matched += 1
		if matched > 0 and matched < total:
			return true
	return false

func _evaluate_ratio_partial(pattern: PatternDefinition, grid: RefCounted) -> bool:
	if not pattern.neighbour_requirements.has("radius") or not pattern.neighbour_requirements.has("biomes"):
		return false
	var required_biome: int = -1
	if not pattern.required_biomes.is_empty():
		required_biome = pattern.required_biomes[0]
	var radius: int = int(pattern.neighbour_requirements["radius"])
	var required_counts: Dictionary = pattern.neighbour_requirements["biomes"]
	for coord_variant in grid.tiles.keys():
		var center: Vector2i = coord_variant
		var center_tile: GardenTile = grid.get_tile(center)
		if center_tile == null:
			continue
		if required_biome >= 0 and center_tile.biome != required_biome:
			continue
		var found_counts: Dictionary = {}
		for r: int in range(1, radius + 1):
			for ring_coord: Vector2i in _HexUtils.axial_ring(center, r):
				var t: GardenTile = grid.get_tile(ring_coord)
				if t == null:
					continue
				found_counts[t.biome] = int(found_counts.get(t.biome, 0)) + 1
		var all_met: bool = true
		var any_neighbor_present: bool = false
		for biome_key_variant in required_counts.keys():
			var biome_key: int = int(biome_key_variant)
			var needed: int = int(required_counts[biome_key_variant])
			var found: int = int(found_counts.get(biome_key, 0))
			if found > 0:
				any_neighbor_present = true
			if found < needed:
				all_met = false
		if any_neighbor_present and not all_met:
			return true
	return false

func _evaluate_compound_partial(pattern: PatternDefinition, grid: RefCounted, registry: DiscoveryRegistry) -> bool:
	var prereq_count: int = pattern.prerequisite_ids.size()
	var met_prereqs: int = 0
	for pid: String in pattern.prerequisite_ids:
		if registry.has_discovery(pid):
			met_prereqs += 1
	if met_prereqs == 0:
		return false
	# Some prereqs met but not all
	if met_prereqs < prereq_count:
		return true
	# All prereqs met — check if underlying cluster condition is not yet satisfied
	if not pattern.required_biomes.is_empty() and pattern.size_threshold > 0:
		var biome: int = pattern.required_biomes[0]
		var best_size: int = _find_largest_cluster(grid, biome)
		if best_size < pattern.size_threshold:
			return true
	return false

func _find_largest_cluster(grid: RefCounted, biome: int) -> int:
	var visited: Dictionary = {}
	var best: int = 0
	for coord_variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant
		if visited.has(coord):
			continue
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null or tile.biome != biome:
			visited[coord] = true
			continue
		var region_size: int = 0
		var queue: Array[Vector2i] = [coord]
		visited[coord] = true
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			var t: GardenTile = grid.get_tile(current)
			if t == null or t.biome != biome:
				continue
			region_size += 1
			for neighbor: Vector2i in _HexUtils.get_neighbors(current):
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
		if region_size > best:
			best = region_size
	return best
