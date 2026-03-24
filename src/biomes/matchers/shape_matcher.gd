class_name ShapeMatcher
extends RefCounted

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	# If any recipe entry has absolute_anchor:true, only try that coordinate as anchor.
	var absolute_anchor_coord: Vector2i = Vector2i.ZERO
	var has_absolute_anchor := false
	for entry in pattern.shape_recipe:
		if entry.get("absolute_anchor", false):
			absolute_anchor_coord = entry["offset"]
			has_absolute_anchor = true
			break

	for coord_variant in grid.tiles.keys():
		var anchor: Vector2i = coord_variant
		if has_absolute_anchor and anchor != absolute_anchor_coord:
			continue
		if spatial_query.recipe_matches_at(anchor, pattern.shape_recipe, func(target: Vector2i) -> GardenTile:
			return grid.get_tile(target)
		):
			# Enforce forbidden_biomes: no neighbour of the anchor may have these biomes.
			if not pattern.forbidden_biomes.is_empty():
				var forbidden_match := false
				for nb: Vector2i in spatial_query.get_hex_neighbors(anchor):
					var nb_tile: GardenTile = grid.get_tile(nb)
					if nb_tile != null and pattern.forbidden_biomes.has(nb_tile.biome):
						forbidden_match = true
						break
				if forbidden_match:
					continue
			var coords: Array[Vector2i] = []
			for entry in pattern.shape_recipe:
				if entry.get("must_be_empty", false):
					continue
				var offset: Vector2i = entry["offset"]
				var is_absolute: bool = entry.get("absolute_anchor", false)
				coords.append(offset if is_absolute else anchor + offset)
			coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				if a.x == b.x:
					return a.y < b.y
				return a.x < b.x
			)
			return DiscoverySignal.create(pattern.discovery_id, coords)
	return null
