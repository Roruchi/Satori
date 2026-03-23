class_name DiscoverySignal
extends RefCounted

var discovery_id: String = ""
var triggering_coords: Array[Vector2i] = []

static func create(id: String, coords: Array[Vector2i]) -> DiscoverySignal:
	var payload := DiscoverySignal.new()
	payload.discovery_id = id
	payload.triggering_coords = coords.duplicate()
	return payload

func to_dictionary() -> Dictionary:
	var serialized_coords: Array[String] = []
	for coord in triggering_coords:
		serialized_coords.append("%d,%d" % [coord.x, coord.y])
	return {
		"discovery_id": discovery_id,
		"triggering_coords": serialized_coords,
	}
