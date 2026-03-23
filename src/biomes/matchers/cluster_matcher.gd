class_name ClusterMatcher
extends RefCounted

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	if pattern.required_biomes.is_empty():
		return null

	var required_biome: int = pattern.required_biomes[0]
	var visited: Dictionary = {}
	var best_region: Array[Vector2i] = []

	for coord_variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant
		if visited.has(coord):
			continue

		var tile: GardenTile = grid.get_tile(coord)
		if tile == null or tile.biome != required_biome:
			visited[coord] = true
			continue

		var region := spatial_query.get_connected_region(coord, required_biome, func(target: Vector2i) -> GardenTile:
			return grid.get_tile(target)
		)
		for region_coord in region:
			visited[region_coord] = true

		if region.size() >= pattern.size_threshold:
			if region.size() > best_region.size():
				best_region = region
			elif region.size() == best_region.size() and _is_region_lexicographically_smaller(region, best_region):
				best_region = region

	if best_region.is_empty():
		return null

	var sorted_coords := _sorted_coords(best_region)
	return DiscoverySignal.create(pattern.discovery_id, sorted_coords)

func _sorted_coords(coords: Array[Vector2i]) -> Array[Vector2i]:
	var sorted := coords.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	return sorted

func _is_region_lexicographically_smaller(candidate: Array[Vector2i], current: Array[Vector2i]) -> bool:
	if current.is_empty():
		return true
	var sorted_candidate := _sorted_coords(candidate)
	var sorted_current := _sorted_coords(current)
	if sorted_candidate[0].x == sorted_current[0].x:
		return sorted_candidate[0].y < sorted_current[0].y
	return sorted_candidate[0].x < sorted_current[0].x
