## GameState — autoload singleton.
## Holds the live garden grid and currently-selected biome.
extends Node

const _GardenGridScript = preload("res://src/grid/GridMap.gd")

var grid: RefCounted       # GardenGrid instance
var selected_biome: int = BiomeType.Value.STONE

signal tile_placed(coord: Vector2i, tile: GardenTile)
signal bloom_confirmed(coord: Vector2i, biome: int)
signal tile_mixed(coord: Vector2i, tile: GardenTile)
signal mix_rejected(coord: Vector2i, reason: String)

func _ready() -> void:
	grid = _GardenGridScript.new()
	var origin_tile: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	origin_tile.metadata["is_origin_shrine"] = true
	origin_tile.metadata["shrine_buildable"] = false
	origin_tile.metadata["shrine_built"] = true
	origin_tile.metadata["build_discovery_id"] = "disc_origin_shrine"
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
	push_warning("try_mix_tile is deprecated")
	return false


func place_tile_from_seed(coord: Vector2i, biome: int, as_build_block: bool = false) -> void:
	var tile: GardenTile = grid.place_tile(coord, biome)
	tile.locked = as_build_block
	tile.metadata["is_build_block"] = as_build_block
	if as_build_block:
		tile.metadata["is_building_complete"] = false
		tile.metadata["build_completion_pending"] = true
		tile.metadata["build_countdown_started"] = false
		tile.metadata.erase("build_started_at")
		tile.metadata.erase("build_duration")
	tile_placed.emit(coord, tile)
	bloom_confirmed.emit(coord, biome)
