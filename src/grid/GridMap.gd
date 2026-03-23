## GardenGrid — sparse Dictionary-backed tile grid.
## No class_name: this script is loaded via preload in GameState to avoid
## scan-order issues with GardenTile during Godot's class registry phase.
extends RefCounted

## Sparse tile storage keyed by world coordinate.
var tiles: Dictionary = {}          # Vector2i → GardenTile
var total_tile_count: int = 0
var garden_bounds: Rect2i = Rect2i(0, 0, 0, 0)

## Place a new tile at coord with the given biome.
func place_tile(coord: Vector2i, biome: int) -> GardenTile:
	var tile := GardenTile.create(coord, biome)
	tiles[coord] = tile
	total_tile_count += 1
	if total_tile_count == 1:
		garden_bounds = Rect2i(coord, Vector2i(1, 1))
	else:
		garden_bounds = garden_bounds.expand(coord)
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

## Return true when placing at coord would be legal:
##   - The Origin (0,0) is always valid if unoccupied.
##   - Any other coord must be empty AND have at least one occupied cardinal neighbour.
func is_placement_valid(coord: Vector2i) -> bool:
	if has_tile(coord):
		return false
	if coord == Vector2i.ZERO:
		return true
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if has_tile(coord + offset):
			return true
	return false
