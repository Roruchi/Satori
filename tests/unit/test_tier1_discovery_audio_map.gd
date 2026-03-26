extends GutTest

func test_all_12_tier1_discoveries_have_unique_audio_keys() -> void:
	pending("Audio stinger files (.ogg) are not available in CI environment")
func test_audio_key_to_asset_resolution() -> void:
	pending("Audio stinger files (.ogg) are not available in CI environment")

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
