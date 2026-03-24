class_name SpatialQuery
extends RefCounted

const _HexUtils = preload("res://src/grid/hex_utils.gd")

func get_hex_neighbors(origin: Vector2i) -> Array[Vector2i]:
	return _HexUtils.get_neighbors(origin)

func get_connected_region(start: Vector2i, biome: int, tile_lookup: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var tile: GardenTile = tile_lookup.call(current)
		if tile == null or tile.biome != biome:
			continue
		result.append(current)

		for neighbor: Vector2i in get_hex_neighbors(current):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return result

func count_biomes_in_radius(center: Vector2i, radius: int, tile_lookup: Callable) -> Dictionary:
	var counts: Dictionary = {}
	# Count center tile
	var center_tile: GardenTile = tile_lookup.call(center)
	if center_tile != null:
		counts[center_tile.biome] = int(counts.get(center_tile.biome, 0)) + 1
	# Count all hex rings from 1 to radius
	for r: int in range(1, radius + 1):
		for coord: Vector2i in _HexUtils.axial_ring(center, r):
			var tile: GardenTile = tile_lookup.call(coord)
			if tile == null:
				continue
			counts[tile.biome] = int(counts.get(tile.biome, 0)) + 1
	return counts

func recipe_matches_at(anchor: Vector2i, shape_recipe: Array[Dictionary], tile_lookup: Callable) -> bool:
	for entry in shape_recipe:
		if not entry.has("offset"):
			return false
		var offset: Vector2i = entry["offset"]
		var must_be_empty: bool = entry.get("must_be_empty", false)
		var is_absolute: bool = entry.get("absolute_anchor", false)
		var effective_coord: Vector2i = offset if is_absolute else anchor + offset
		var tile: GardenTile = tile_lookup.call(effective_coord)
		if must_be_empty:
			if tile != null:
				return false
		else:
			if not entry.has("biome"):
				return false
			var target_biome: int = int(entry["biome"])
			if tile == null or tile.biome != target_biome:
				return false
	return true
