## TileRenderState — in-memory rendering state for one placed tile.
## Owned by VoxelRenderer; never persisted.
class_name TileRenderState
extends RefCounted

## Grid coordinate of this tile.
var coord: Vector2i = Vector2i.ZERO

## Biome type (BiomeType.Value).
var biome: int = BiomeType.Value.NONE

## Raw 6-bit hex neighbour bitmask (0–63).
var bitmask6: int = 0

## Hex canonical index (0–12) derived from bitmask6 via D6 symmetry reduction.
var canonical: int = 0

## Owning 8×8 chunk coordinate.
var chunk_id: Vector2i = Vector2i.ZERO

## True when this tile is part of an active MountainCluster merge.
var in_mountain: bool = false


static func create(c: Vector2i, b: int) -> TileRenderState:
	var s := TileRenderState.new()
	s.coord = c
	s.biome = b
	s.chunk_id = Vector2i(
		floori(float(c.x) / 8.0),
		floori(float(c.y) / 8.0)
	)
	return s
