class_name DiscoveryEventRouter
extends Node

var _catalog: DiscoveryCatalog
var _queue: DiscoveryNotificationQueue

func _ready() -> void:
	_catalog = DiscoveryCatalog.new()
	_catalog.load_from_data(DiscoveryCatalogData.new())
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)

func set_queue(queue: DiscoveryNotificationQueue) -> void:
	_queue = queue

func _on_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	if discovery_id.begins_with("spirit_"):
		return  # Spirit discoveries are handled by SpiritService
	var meta: Dictionary = _catalog.lookup(discovery_id)
	if meta.is_empty():
		RuntimeLogger.warn("DiscoveryEventRouter", "No catalog entry for: %s" % discovery_id)
		meta = {"display_name": discovery_id, "flavor_text": "", "audio_key": ""}
	var payload: DiscoveryPayload = DiscoveryPayload.create(discovery_id, triggering_coords, meta)
	# Persist the discovery
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence != null and persistence.has_method("record_discovery"):
		persistence.record_discovery(payload)
	var codex: Node = get_node_or_null("/root/CodexService")
	if codex != null and codex.has_method("mark_discovered"):
		codex.mark_discovered(StringName(discovery_id))
	# Enqueue for UI notification
	if _queue != null:
		_queue.enqueue(payload)
