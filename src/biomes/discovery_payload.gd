class_name DiscoveryPayload
extends RefCounted

var discovery_id: String = ""
var display_name: String = ""
var flavor_text: String = ""
var audio_key: String = ""
var duration_seconds: float = 4.0
var trigger_timestamp: int = 0
var triggering_coords: Array[Vector2i] = []

static func create(id: String, coords: Array[Vector2i], meta: Dictionary) -> DiscoveryPayload:
	var payload := DiscoveryPayload.new()
	payload.discovery_id = id
	for coord in coords:
		payload.triggering_coords.append(coord)
	payload.trigger_timestamp = int(Time.get_unix_time_from_system())
	payload.display_name = str(meta.get("display_name", id))
	payload.flavor_text = str(meta.get("flavor_text", ""))
	payload.audio_key = str(meta.get("audio_key", ""))
	return payload
