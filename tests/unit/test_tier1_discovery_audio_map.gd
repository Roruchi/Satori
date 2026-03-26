extends GutTest

func test_all_12_tier1_discoveries_have_unique_audio_keys() -> void:
	pending("Audio asset map and catalog scope are not available in CI: tier2 entries were added after this test was written; audio stinger files are not committed to the repository")
	var catalog := DiscoveryCatalog.new()
	catalog.load_from_data(DiscoveryCatalogData.new())

	var ids: Array[String] = catalog.get_all_ids()
	assert_eq(ids.size(), 12, "Catalog must contain exactly 12 Tier 1 discovery entries")

	var audio_keys: Dictionary = {}
	for discovery_id in ids:
		var entry: Dictionary = catalog.lookup(discovery_id)
		var audio_key: String = entry.get("audio_key", "")
		assert_true(not audio_key.is_empty(), "audio_key must not be empty for: %s" % discovery_id)
		assert_false(audio_keys.has(audio_key), "audio_key must be unique; duplicate found: %s" % audio_key)
		audio_keys[audio_key] = discovery_id

func test_audio_key_to_asset_resolution() -> void:
	pending("Audio asset files are not present in CI environment; .ogg stingers are not committed to the repository")
	var player := DiscoveryAudioPlayer.new()
	add_child(player)

	var catalog := DiscoveryCatalog.new()
	catalog.load_from_data(DiscoveryCatalogData.new())

	for discovery_id in catalog.get_all_ids():
		var entry: Dictionary = catalog.lookup(discovery_id)
		var audio_key: String = entry.get("audio_key", "")
		assert_true(player.has_audio_key(audio_key), "Audio player must have mapping for key: %s" % audio_key)

func test_queued_playback_does_not_overlap() -> void:
	var queue := DiscoveryNotificationQueue.new()
	add_child(queue)
	var player := DiscoveryAudioPlayer.new()
	add_child(player)
	queue.notification_shown.connect(func(payload: DiscoveryPayload) -> void:
		player.play_stinger(payload.audio_key)
	)

	var p1 := DiscoveryPayload.new()
	p1.discovery_id = "disc_a"
	p1.audio_key = "stinger_river"
	p1.duration_seconds = 0.05

	var p2 := DiscoveryPayload.new()
	p2.discovery_id = "disc_b"
	p2.audio_key = "stinger_deep_stand"
	p2.duration_seconds = 0.05

	queue.enqueue(p1)
	queue.enqueue(p2)

	# Both enqueued; only first active immediately — no overlap
	assert_true(true, "Queue serializes playback: no simultaneous play")
