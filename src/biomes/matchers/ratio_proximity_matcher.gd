class_name RatioProximityMatcher
extends RefCounted

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	if not pattern.neighbour_requirements.has("radius") or not pattern.neighbour_requirements.has("biomes"):
		return null

	var radius: int = int(pattern.neighbour_requirements["radius"])
	var required_counts: Dictionary = pattern.neighbour_requirements["biomes"]

	for coord_variant in grid.tiles.keys():
		var center: Vector2i = coord_variant
		var center_tile: GardenTile = grid.get_tile(center)
		if center_tile == null:
			continue
		if not pattern.required_biomes.is_empty() and center_tile.biome != int(pattern.required_biomes[0]):
			continue

		var found_counts := spatial_query.count_biomes_in_radius(center, radius, func(target: Vector2i) -> GardenTile:
			return grid.get_tile(target)
		)

		var all_met := true
		for biome_key_variant in required_counts.keys():
			var biome_key: int = int(biome_key_variant)
			var needed: int = int(required_counts[biome_key_variant])
			var found: int = int(found_counts.get(biome_key, 0))
			if found < needed:
				all_met = false
				break

		if all_met:
			return DiscoverySignal.create(pattern.discovery_id, [center])

	return null
