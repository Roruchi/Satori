## GameState — autoload singleton.
## Holds the live garden grid and currently-selected biome.
extends Node

const _GardenGridScript = preload("res://src/grid/GridMap.gd")

var grid: RefCounted       # GardenGrid instance
var selected_biome: int = BiomeType.Value.FOREST

signal tile_placed(coord: Vector2i, tile: GardenTile)
signal tile_mixed(coord: Vector2i, tile: GardenTile)
signal mix_rejected(coord: Vector2i, reason: String)

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

## Attempt to mix the selected biome into the existing tile at coord.
## Returns true on a successful mix, false on any rejection.
## Emits tile_mixed on success; emits mix_rejected with a reason string on failure.
func try_mix_tile(coord: Vector2i) -> bool:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return false

	# Locked tile rejects immediately — permanent, irreversible state.
	if tile.locked:
		mix_rejected.emit(coord, "locked")
		return false

	# Same-type mixing is not a valid recipe.
	if selected_biome == tile.biome:
		mix_rejected.emit(coord, "same_type")
		return false

	# Look up the hybrid result for this base-pair combination.
	var result: BiomeType.Value = BiomeType.mix(selected_biome, tile.biome)

	# No matching recipe in the mixing table.
	if result == BiomeType.Value.NONE:
		mix_rejected.emit(coord, "no_recipe")
		return false

	# Apply the mix: replace tile biome and lock it.
	grid.replace_tile(coord, result)
	tile_mixed.emit(coord, grid.get_tile(coord))
	return true
