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
	payload.triggering_coords = coords.duplicate()
	payload.trigger_timestamp = Time.get_unix_time_from_system() as int
	payload.display_name = meta.get("display_name", id)
	payload.flavor_text = meta.get("flavor_text", "")
	payload.audio_key = meta.get("audio_key", "")
	return payload
