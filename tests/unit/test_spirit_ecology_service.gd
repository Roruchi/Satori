extends GutTest

func test_tension_fires_when_distance_within_threshold() -> void:
	var service: SpiritEcologyServiceNode = SpiritEcologyServiceNode.new()
	add_child(service)
	service._spirit_positions["spirit_red_fox"] = Vector2i(0, 0)
	service._spirit_positions["spirit_hare"] = Vector2i(2, 0)
	service._tension_pairs_by_spirit["spirit_red_fox"] = ["spirit_hare"]
	watch_signals(service)
	service._check_tension("spirit_red_fox")
	assert_signal_emitted(service, "tension_active")
	service.queue_free()

func test_harmony_fires_once_after_accumulated_ticks() -> void:
	var service: SpiritEcologyServiceNode = SpiritEcologyServiceNode.new()
	add_child(service)
	watch_signals(service)
	for i in range(21):
		service.on_spirit_moved("spirit_koi_fish", Vector2i(i, 0))
		service.on_spirit_moved("spirit_blue_kingfisher", Vector2i(i, 1))
	assert_signal_emitted(service, "harmony_event_fired")
	var emitted_count: int = get_signal_emit_count(service, "harmony_event_fired")
	for j in range(21):
		service.on_spirit_moved("spirit_koi_fish", Vector2i(j + 50, 0))
		service.on_spirit_moved("spirit_blue_kingfisher", Vector2i(j + 50, 1))
	assert_eq(get_signal_emit_count(service, "harmony_event_fired"), emitted_count)
	service.queue_free()
