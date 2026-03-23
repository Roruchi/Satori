## GameState — autoload singleton.
## Holds the live garden grid and currently-selected biome.
extends Node

const _GardenGridScript = preload("res://src/grid/GridMap.gd")

var grid: RefCounted       # GardenGrid instance
var selected_biome: int = BiomeType.Value.FOREST

signal tile_placed(coord: Vector2i, tile: GardenTile)

func _ready() -> void:
	grid = _GardenGridScript.new()
	var origin_tile: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.FOREST)
	tile_placed.emit(Vector2i.ZERO, origin_tile)

## Attempt to place the selected biome at coord.
## Returns true on success, false if placement is invalid.
func try_place_tile(coord: Vector2i) -> bool:
	if not grid.is_placement_valid(coord):
		return false
	var tile: GardenTile = grid.place_tile(coord, selected_biome)
	tile_placed.emit(coord, tile)
	return true
