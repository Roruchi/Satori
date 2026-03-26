extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

func test_first_trigger_emits_notification_payload() -> void:
	var matcher := PatternMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_deep_stand"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 10

	var catalog := DiscoveryCatalog.new()
	catalog.load_from_data(DiscoveryCatalogData.new())

	matcher.set_patterns([pattern])
	var grid := GridMapScript.new()
	for i in range(10):
		grid.place_tile(Vector2i(i, 0), BiomeType.Value.FOREST)

	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(discovery_id: String, _coords: Array[Vector2i]) -> void:
		emitted.append(discovery_id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_deep_stand"], "First qualifying placement should emit once")
	assert_true(catalog.has_entry("disc_deep_stand"), "Catalog must have metadata for disc_deep_stand")

func test_second_trigger_is_suppressed() -> void:
	var matcher := PatternMatcher.new()
	var pattern := PatternDefinition.new()
	pattern.discovery_id = "disc_deep_stand"
	pattern.pattern_type = PatternDefinition.PatternType.CLUSTER
	pattern.required_biomes = [BiomeType.Value.FOREST]
	pattern.size_threshold = 10
	matcher.set_patterns([pattern])

	var grid := GridMapScript.new()
	for i in range(10):
		grid.place_tile(Vector2i(i, 0), BiomeType.Value.FOREST)

	var first: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		first.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(first.size(), 1, "First scan emits once")

	var second: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		second.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(second.size(), 0, "Second scan must be suppressed")

func test_dual_trigger_queues_both_in_order() -> void:
	var scheduler := PatternScanScheduler.new()
	add_child(scheduler)

	var cluster := PatternDefinition.new()
	cluster.discovery_id = "disc_z_cluster"
	cluster.pattern_type = PatternDefinition.PatternType.CLUSTER
	cluster.required_biomes = [BiomeType.Value.FOREST]
	cluster.size_threshold = 3

	var shape := PatternDefinition.new()
	shape.discovery_id = "disc_a_shape"
	shape.pattern_type = PatternDefinition.PatternType.SHAPE
	shape.shape_recipe = [
		{"offset": Vector2i(0, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(1, 0), "biome": BiomeType.Value.FOREST},
		{"offset": Vector2i(2, 0), "biome": BiomeType.Value.FOREST},
	]

	var matcher := PatternMatcher.new()
	matcher.set_patterns([cluster, shape])
	scheduler.set_matcher_for_testing(matcher)

	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.FOREST)
	scheduler.set_grid_provider(func() -> RefCounted:
		return grid
	)

	var emitted: Array[String] = []
	scheduler.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	scheduler.enqueue_scan(Vector2i(2, 0))
	await get_tree().process_frame

	assert_eq(emitted, ["disc_a_shape", "disc_z_cluster"], "Dual triggers must be ordered by discovery_id")

func test_notification_queue_processes_items_sequentially() -> void:
	var queue := DiscoveryNotificationQueue.new()
	add_child(queue)

	var shown: Array[String] = []
	queue.notification_shown.connect(func(payload: DiscoveryPayload) -> void:
		shown.append(payload.discovery_id)
	)

	var p1 := DiscoveryPayload.new()
	p1.discovery_id = "disc_a"
	p1.display_name = "Discovery A"
	p1.duration_seconds = 0.05

	var p2 := DiscoveryPayload.new()
	p2.discovery_id = "disc_b"
	p2.display_name = "Discovery B"
	p2.duration_seconds = 0.05

	queue.enqueue(p1)
	queue.enqueue(p2)

	assert_eq(shown.size(), 1, "Only one notification active immediately after enqueue")
	assert_eq(shown[0], "disc_a", "First item shown first")
	await get_tree().create_timer(0.2).timeout
	assert_eq(shown.size(), 2, "Second notification shown after first timer expires")

func test_4_second_auto_dismiss_timing() -> void:
	var queue := DiscoveryNotificationQueue.new()
	add_child(queue)
	queue.set_process(true)

	var dismissed_count: int = 0
	queue.notification_dismissed.connect(func() -> void:
		dismissed_count += 1
	)

	var p := DiscoveryPayload.new()
	p.discovery_id = "disc_test"
	p.display_name = "Test Discovery"
	p.duration_seconds = 0.1

	queue.enqueue(p)
	assert_eq(dismissed_count, 0, "Not yet dismissed")
	await get_tree().create_timer(1.0).timeout
	assert_eq(dismissed_count, 1, "Should auto-dismiss after duration")
