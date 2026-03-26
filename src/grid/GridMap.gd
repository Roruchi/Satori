## GardenGrid — sparse Dictionary-backed tile grid.
## No class_name: this script is loaded via preload in GameState to avoid
## scan-order issues with GardenTile during Godot's class registry phase.
extends RefCounted

## Sparse tile storage keyed by world coordinate.
var tiles: Dictionary = {}          # Vector2i → GardenTile
var total_tile_count: int = 0
var garden_bounds: Rect2i = Rect2i(0, 0, 0, 0)

## Internal island map: Vector2i → String island_id.
## Recomputed by compute_island_ids() after every placement.
var _island_map: Dictionary = {}

## Place a new tile at coord with the given biome.
func place_tile(coord: Vector2i, biome: int) -> GardenTile:
	var tile := GardenTile.create(coord, biome)
	tiles[coord] = tile
	total_tile_count += 1
	if total_tile_count == 1:
		garden_bounds = Rect2i(coord, Vector2i(1, 1))
	else:
		garden_bounds = garden_bounds.expand(coord)
	compute_island_ids()
	return tile

## Return the GardenTile at coord, or null if the cell is empty.
func get_tile(coord: Vector2i) -> GardenTile:
	return tiles.get(coord, null)

## Return true if a tile exists at coord.
func has_tile(coord: Vector2i) -> bool:
	return tiles.has(coord)

## Replace an existing tile's biome in-place and mark it as permanently locked.
## Asserts that a tile already exists at coord.
func replace_tile(coord: Vector2i, new_biome: int) -> void:
	assert(has_tile(coord), "replace_tile: no tile exists at %s" % str(coord))
	tiles[coord].biome = new_biome
	tiles[coord].locked = true

const _HexUtils = preload("res://src/grid/hex_utils.gd")

## Return true when placing at coord would be legal:
##   - The Origin (0,0) is always valid if unoccupied.
##   - Any other coord must be empty AND have at least one occupied hex neighbour.
func is_placement_valid(coord: Vector2i) -> bool:
	if has_tile(coord):
		return false
	if coord == Vector2i.ZERO:
		return true
	for neighbor: Vector2i in _HexUtils.get_neighbors(coord):
		if has_tile(neighbor):
			return true
	return false

## Recompute island IDs for every tile in the grid using BFS flood-fill.
## KU tiles are treated as walls (abyss) and receive an empty island_id.
## Every other connected component of non-KU tiles shares the same island_id,
## derived from the lexicographically smallest coordinate in the component.
## Results are written into each tile's metadata["island_id"] and also stored
## in the internal _island_map dictionary for fast lookup.
func compute_island_ids() -> void:
	_island_map.clear()
	var visited: Dictionary = {}

	# Clear existing island_id metadata on all tiles first.
	for coord: Variant in tiles:
		var tile: GardenTile = tiles[coord]
		tile.metadata["island_id"] = ""

	# Flood-fill each unvisited non-KU tile.
	for coord: Variant in tiles:
		var c: Vector2i = coord as Vector2i
		if visited.has(c):
			continue
		var tile: GardenTile = tiles[c]
		if tile.biome == BiomeType.Value.KU:
			visited[c] = true
			continue

		# BFS to collect the full connected component.
		var component: Array[Vector2i] = []
		var queue: Array[Vector2i] = [c]
		visited[c] = true

		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			var current_tile: GardenTile = tiles.get(current, null)
			if current_tile == null or current_tile.biome == BiomeType.Value.KU:
				continue
			component.append(current)
			for neighbor: Vector2i in _HexUtils.get_neighbors(current):
				if visited.has(neighbor):
					continue
				if not tiles.has(neighbor):
					continue
				visited[neighbor] = true
				queue.append(neighbor)

		if component.is_empty():
			continue

		# Determine canonical coord: lexicographically smallest (x first, y tiebreaker).
		var canonical: Vector2i = component[0]
		for i: int in range(1, component.size()):
			var v: Vector2i = component[i]
			if v.x < canonical.x or (v.x == canonical.x and v.y < canonical.y):
				canonical = v
		var island_id: String = "%d,%d" % [canonical.x, canonical.y]

		# Write island_id into each tile and the fast-lookup map.
		for v: Vector2i in component:
			_island_map[v] = island_id
			tiles[v].metadata["island_id"] = island_id

## Return the island_id for the tile at coord, or "" if coord is empty or a KU tile.
func get_island_id(coord: Vector2i) -> String:
	return str(_island_map.get(coord, ""))
