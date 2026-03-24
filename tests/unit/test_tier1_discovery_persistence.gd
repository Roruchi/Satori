extends GutTest

func test_discovery_log_write_read_roundtrip() -> void:
	var log := DiscoveryLog.new()
	var payload := DiscoveryPayload.new()
	payload.discovery_id = "disc_test"
	payload.display_name = "Test Discovery"
	payload.trigger_timestamp = 1000000
	payload.triggering_coords = [Vector2i(1, 2), Vector2i(3, 4)]

	log.append_entry(payload)
	assert_true(log.has_discovery("disc_test"), "Log should contain appended entry")
	assert_eq(log.entries.size(), 1, "Log should have one entry")
	assert_eq(log.entries[0]["discovery_id"], "disc_test")
	assert_eq(log.entries[0]["trigger_timestamp"], 1000000)

func test_duplicate_entries_are_suppressed() -> void:
	var log := DiscoveryLog.new()
	var payload := DiscoveryPayload.new()
	payload.discovery_id = "disc_dup"
	payload.display_name = "Dup"
	payload.trigger_timestamp = 2000000
	payload.triggering_coords = []

	log.append_entry(payload)
	log.append_entry(payload)
	assert_eq(log.entries.size(), 1, "Duplicate should not be appended twice")

func test_serialize_deserialize_roundtrip() -> void:
	var log := DiscoveryLog.new()
	var p1 := DiscoveryPayload.new()
	p1.discovery_id = "disc_a"
	p1.display_name = "Alpha"
	p1.trigger_timestamp = 1111
	p1.triggering_coords = [Vector2i(0, 0)]

	var p2 := DiscoveryPayload.new()
	p2.discovery_id = "disc_b"
	p2.display_name = "Beta"
	p2.trigger_timestamp = 2222
	p2.triggering_coords = []

	log.append_entry(p1)
	log.append_entry(p2)

	var serialized: Dictionary = log.serialize()
	var restored := DiscoveryLog.new()
	restored.deserialize(serialized)

	assert_eq(restored.entries.size(), 2, "Restored log should have 2 entries")
	assert_true(restored.has_discovery("disc_a"), "Restored log should have disc_a")
	assert_true(restored.has_discovery("disc_b"), "Restored log should have disc_b")
	assert_eq(restored.entries[0]["trigger_timestamp"], 1111, "Timestamp must survive roundtrip")

func test_hydration_prevents_rediscovery() -> void:
	var matcher := PatternMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_hydrated"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 2
	matcher.set_patterns([pattern])

	# Simulate hydration from persisted log
	var ids: Array[String] = ["disc_hydrated"]
	matcher.get_discovery_registry().mark_discoveries(ids)

	var grid_script := preload("res://src/grid/GridMap.gd")
	var grid := grid_script.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, [], "Hydrated discoveries must not re-fire")

func test_timestamp_immutability_across_reload() -> void:
	var log := DiscoveryLog.new()
	var payload := DiscoveryPayload.new()
	payload.discovery_id = "disc_ts"
	payload.display_name = "Timestamp Test"
	payload.trigger_timestamp = 9999999
	payload.triggering_coords = []
	log.append_entry(payload)

	var serialized: Dictionary = log.serialize()
	var restored := DiscoveryLog.new()
	restored.deserialize(serialized)

	assert_eq(restored.entries[0]["trigger_timestamp"], 9999999, "Timestamp must not change on reload")
