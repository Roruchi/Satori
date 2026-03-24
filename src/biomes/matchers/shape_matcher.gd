class_name ShapeMatcher
extends RefCounted

const _HexUtils = preload("res://src/grid/hex_utils.gd")

func evaluate(pattern: PatternDefinition, grid: RefCounted, spatial_query: SpatialQuery) -> DiscoverySignal:
	var variants: Array = _HexUtils.shape_recipe_variants(pattern.shape_recipe)
	for coord_variant in grid.tiles.keys():
		var anchor: Vector2i = coord_variant
		for variant_variant in variants:
			var variant: Array[Dictionary] = variant_variant
			if not spatial_query.recipe_matches_at(anchor, variant, func(target: Vector2i) -> GardenTile:
				return grid.get_tile(target)
			):
				continue
			var coords: Array[Vector2i] = []
			for entry: Dictionary in variant:
				coords.append(anchor + entry["offset"])
			coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				if a.x == b.x:
					return a.y < b.y
				return a.x < b.x
			)
			return DiscoverySignal.create(pattern.discovery_id, coords)
	return null
