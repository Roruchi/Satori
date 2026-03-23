class_name ShapeMatcher
extends RefCounted

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	for coord_variant in grid.tiles.keys():
		var anchor: Vector2i = coord_variant
		if spatial_query.recipe_matches_at(anchor, pattern.shape_recipe, func(target: Vector2i) -> GardenTile:
			return grid.get_tile(target)
		):
			var coords: Array[Vector2i] = []
			for entry in pattern.shape_recipe:
				coords.append(anchor + entry["offset"])
			coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				if a.x == b.x:
					return a.y < b.y
				return a.x < b.x
			)
			return DiscoverySignal.create(pattern.discovery_id, coords)
	return null
