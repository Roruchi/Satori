## GameState — autoload singleton.
## Holds the live garden grid and currently-selected biome.
extends Node

const _GardenGridScript = preload("res://src/grid/GridMap.gd")
const _TerrainValidatorScript = preload("res://src/crafting/TerrainValidator.gd")

var grid: RefCounted       # GardenGrid instance
var selected_biome: int = BiomeType.Value.STONE
var placement_records: Array = []

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

## Atomically place a crafted structure's tiles on the grid.
## Called by CraftingService after the player confirms ghost placement.
func confirm_placement(record: PlacementRecord) -> void:
	var recipe: RecipeDefinition = CraftingService.registry.get_by_id(record.recipe_id)
	if recipe == null:
		push_error("GameState.confirm_placement: unknown recipe_id '%s'" % record.recipe_id)
		return
	var rotated: Array[Vector2i] = _TerrainValidatorScript.apply_rotation(
		recipe.shape, record.rotation_steps
	)
	# Atomicity check — abort if any target cell is already occupied.
	for offset: Vector2i in rotated:
		var coord: Vector2i = Vector2i(record.anchor_cell.x + offset.x,
				record.anchor_cell.y + offset.y)
		if grid.has_tile(coord):
			push_error("GameState.confirm_placement: cell %s is already occupied" % str(coord))
			return
	# Place all tiles in a single pass.
	for i: int in range(rotated.size()):
		var offset: Vector2i = rotated[i]
		var coord: Vector2i = Vector2i(record.anchor_cell.x + offset.x,
				record.anchor_cell.y + offset.y)
		var biome: int = _element_to_biome(int(recipe.elements[i]))
		var tile: GardenTile = grid.place_tile(coord, biome)
		tile.metadata["placement_record_id"] = record.recipe_id
		tile_placed.emit(coord, tile)
	placement_records.append(record)

## Map a GodaiElement value to its corresponding BiomeType.
static func _element_to_biome(element: int) -> int:
	match element:
		0: return BiomeType.Value.STONE        # CHI
		1: return BiomeType.Value.RIVER        # SUI
		2: return BiomeType.Value.EMBER_FIELD  # KA
		3: return BiomeType.Value.MEADOW       # FU
		_: return BiomeType.Value.STONE
