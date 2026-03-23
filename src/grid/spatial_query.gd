class_name SpatialQuery
extends RefCounted

const CARDINAL_OFFSETS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

func get_cardinal_neighbors(origin: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in CARDINAL_OFFSETS:
		neighbors.append(origin + offset)
	return neighbors

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

		for neighbor in get_cardinal_neighbors(current):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return result

func count_biomes_in_radius(center: Vector2i, radius: int, tile_lookup: Callable) -> Dictionary:
	var counts: Dictionary = {}
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var coord: Vector2i = Vector2i(x, y)
			if coord.distance_to(center) > float(radius):
				continue
			var tile: GardenTile = tile_lookup.call(coord)
			if tile == null:
				continue
			counts[tile.biome] = int(counts.get(tile.biome, 0)) + 1
	return counts

func recipe_matches_at(anchor: Vector2i, shape_recipe: Array[Dictionary], tile_lookup: Callable) -> bool:
	for entry in shape_recipe:
		if not entry.has("offset") or not entry.has("biome"):
			return false
		var offset: Vector2i = entry["offset"]
		var target_biome: int = int(entry["biome"])
		var tile: GardenTile = tile_lookup.call(anchor + offset)
		if tile == null or tile.biome != target_biome:
			return false
	return true
