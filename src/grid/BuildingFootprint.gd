class_name BuildingFootprint
extends RefCounted

var footprint_id: StringName = &""
var offsets: Array[Vector2i] = []
var size_class: StringName = &"single_tile"

static func single_tile(id: StringName) -> BuildingFootprint:
	var fp: BuildingFootprint = new()
	fp.footprint_id = id
	fp.size_class = &"single_tile"
	fp.offsets = [Vector2i(0, 0)]
	return fp

static func multi_tile(id: StringName, tile_offsets: Array[Vector2i]) -> BuildingFootprint:
	var fp: BuildingFootprint = new()
	fp.footprint_id = id
	fp.size_class = &"multi_tile"
	fp.offsets = tile_offsets.duplicate()
	return fp

func get_world_tiles(anchor: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: Vector2i in offsets:
		result.append(anchor + offset)
	return result
