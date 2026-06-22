class_name BuildingPlacementSession
extends RefCounted

var active: bool = false
var building_type_key: StringName = &""
var anchor_coord: Vector2i = Vector2i.ZERO
var footprint_tiles: Array[Vector2i] = []
var is_valid: bool = false
var invalid_reason: StringName = &""

func start(type_key: StringName) -> void:
	active = true
	building_type_key = type_key
	anchor_coord = Vector2i.ZERO
	footprint_tiles = []
	is_valid = false
	invalid_reason = &""

func update_anchor(new_anchor: Vector2i, new_footprint: Array, valid: bool, reason: StringName = &"") -> void:
	anchor_coord = new_anchor
	footprint_tiles = []
	for tile_variant: Variant in new_footprint:
		if tile_variant is Vector2i:
			footprint_tiles.append(tile_variant as Vector2i)
	is_valid = valid
	invalid_reason = reason

func cancel() -> void:
	active = false
	building_type_key = &""
	anchor_coord = Vector2i.ZERO
	footprint_tiles = []
	is_valid = false
	invalid_reason = &""

func can_confirm() -> bool:
	return active and is_valid
