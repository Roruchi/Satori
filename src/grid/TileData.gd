class_name GardenTile
extends RefCounted

## Axial grid coordinate of this tile.
var coord: Vector2i

## Biome assigned to this tile (stored as int — use BiomeType.Value constants to read/write).
var biome: int

## True once the tile has been alchemically merged — no further mixing allowed.
var locked: bool

## Extensible metadata bag.  Keys used by the engine:
##   "discovery_ids" : Array[String]  — discoveries this tile participates in
##   "spirit_id"     : String         — spirit animal anchored here (if any)
var metadata: Dictionary


## Factory — creates a new, unlocked tile at the given coordinate and biome.
static func create(c: Vector2i, b: int) -> GardenTile:
	var tile := GardenTile.new()
	tile.coord    = c
	tile.biome    = b
	tile.locked   = false
	tile.metadata = {}
	return tile
