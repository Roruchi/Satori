class_name ShapeMatcher
extends RefCounted

const _HexUtils = preload("res://src/grid/hex_utils.gd")

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	# Determine if any entry has absolute_anchor:true — if so, restrict anchor iteration
	# to only that single grid coordinate (prevents firing at arbitrary positions).
	var absolute_anchor_coord: Vector2i = Vector2i.ZERO
	var has_absolute_anchor := false
	for entry in pattern.shape_recipe:
		if entry.get("absolute_anchor", false):
			absolute_anchor_coord = entry["offset"]
			has_absolute_anchor = true
			break

	var variants: Array = _HexUtils.shape_recipe_variants(pattern.shape_recipe)
	for coord_variant in grid.tiles.keys():
		var anchor: Vector2i = coord_variant
		if has_absolute_anchor and anchor != absolute_anchor_coord:
			continue
		for variant_variant in variants:
			var variant: Array[Dictionary] = variant_variant
			if not spatial_query.recipe_matches_at(anchor, variant, func(target: Vector2i) -> GardenTile:
				return grid.get_tile(target)
			):
				continue
			# Enforce forbidden_biomes: no neighbour of the anchor may have these biomes.
			if not pattern.forbidden_biomes.is_empty():
				var forbidden_match := false
				for neighbor_coord: Vector2i in spatial_query.get_hex_neighbors(anchor):
					var nb_tile: GardenTile = grid.get_tile(neighbor_coord)
					if nb_tile != null and pattern.forbidden_biomes.has(nb_tile.biome):
						forbidden_match = true
						break
				if forbidden_match:
					continue
			# All constraints satisfied — collect triggering coords and emit.
			var coords: Array[Vector2i] = []
			for entry: Dictionary in variant:
				if entry.get("must_be_empty", false):
					continue
				coords.append(anchor + entry["offset"])
			coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				if a.x == b.x:
					return a.y < b.y
				return a.x < b.x
			)
			return DiscoverySignal.create(pattern.discovery_id, coords)
	return null
