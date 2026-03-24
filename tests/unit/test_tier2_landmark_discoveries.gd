extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_matcher(patterns: Array[PatternDefinition]) -> PatternMatcher:
	var m := PatternMatcher.new()
	m.set_patterns(patterns)
	return m


func _pattern(id: String, type: int, biomes: Array[int] = [], threshold: int = 0, recipe: Array[Dictionary] = [], forbidden: Array[int] = [], prereqs: Array[String] = [], nb_req: Dictionary = {}) -> PatternDefinition:
	var p := PatternDefinition.new()
	p.discovery_id = id
	p.pattern_type = type
	p.required_biomes = biomes
	p.size_threshold = threshold
	p.shape_recipe = recipe
	p.forbidden_biomes = forbidden
	p.prerequisite_ids = prereqs
	p.neighbour_requirements = nb_req
	return p


# ---------------------------------------------------------------------------
# T01 / T02 — absolute_anchor constraint (Origin Shrine)
# ---------------------------------------------------------------------------

func test_origin_shrine_fires_when_cross_at_grid_origin() -> void:
	var pattern := _pattern("disc_origin_shrine", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
			{"offset": Vector2i(1, 0),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, 1),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.WATER)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.WATER)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_origin_shrine"], "Origin Shrine must fire for cross at (0,0)")


func test_origin_shrine_does_not_fire_when_cross_is_not_at_grid_origin() -> void:
	var pattern := _pattern("disc_origin_shrine", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
			{"offset": Vector2i(1, 0),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, 1),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	# Cross centred at (5, 5) — should NOT fire because (0,0) has no Stone
	grid.place_tile(Vector2i(5, 5),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(6, 5),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(4, 5),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(5, 6),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(5, 4),  BiomeType.Value.WATER)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, [], "Origin Shrine must NOT fire when cross is not at grid origin")


# ---------------------------------------------------------------------------
# T01 — must_be_empty constraint (Echoing Cavern)
# ---------------------------------------------------------------------------

func test_echoing_cavern_fires_when_ring_has_empty_centre() -> void:
	# Anchor = E tile (1,0). Centre = (0,0) must be empty.
	var pattern := _pattern("disc_echoing_cavern", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0),   "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, 0),  "must_be_empty": true},
			{"offset": Vector2i(-2, 0),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, 1),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, -1), "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(0, -1),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-2, 1),  "biome": BiomeType.Value.STONE},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	# Ring of 6 Stone tiles around empty (0,0)
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, -1),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(-1, 1),  BiomeType.Value.STONE)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_echoing_cavern"], "Echoing Cavern must fire when 6-Stone ring has empty centre")


func test_echoing_cavern_does_not_fire_when_centre_is_occupied() -> void:
	var pattern := _pattern("disc_echoing_cavern", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0),   "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, 0),  "must_be_empty": true},
			{"offset": Vector2i(-2, 0),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, 1),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-1, -1), "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(0, -1),  "biome": BiomeType.Value.STONE},
			{"offset": Vector2i(-2, 1),  "biome": BiomeType.Value.STONE},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, -1),  BiomeType.Value.STONE)
	grid.place_tile(Vector2i(-1, 1),  BiomeType.Value.STONE)
	# Centre (0,0) is occupied — should block the match
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.FOREST)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, [], "Echoing Cavern must NOT fire when centre cell is occupied")


# ---------------------------------------------------------------------------
# T02 — forbidden_biomes neighbour check (Floating Pavilion)
# ---------------------------------------------------------------------------

func test_floating_pavilion_fires_when_swamp_has_no_land_neighbours() -> void:
	var land_biomes: Array[int] = [
		BiomeType.Value.FOREST, BiomeType.Value.STONE, BiomeType.Value.EARTH,
		BiomeType.Value.SWAMP, BiomeType.Value.TUNDRA, BiomeType.Value.MUDFLAT,
		BiomeType.Value.MOSSY_CRAG, BiomeType.Value.SAVANNAH, BiomeType.Value.CANYON
	]
	var pattern := _pattern("disc_floating_pavilion", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SWAMP}],
		land_biomes)
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	# Isolated Swamp tile surrounded only by Water
	grid.place_tile(Vector2i(0, 0),  BiomeType.Value.SWAMP)
	grid.place_tile(Vector2i(1, 0),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(-1, 0), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, 1),  BiomeType.Value.WATER)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_floating_pavilion"], "Floating Pavilion must fire when Swamp has only Water neighbours")


func test_floating_pavilion_does_not_fire_when_adjacent_land_exists() -> void:
	var land_biomes: Array[int] = [
		BiomeType.Value.FOREST, BiomeType.Value.STONE, BiomeType.Value.EARTH,
		BiomeType.Value.SWAMP, BiomeType.Value.TUNDRA, BiomeType.Value.MUDFLAT,
		BiomeType.Value.MOSSY_CRAG, BiomeType.Value.SAVANNAH, BiomeType.Value.CANYON
	]
	var pattern := _pattern("disc_floating_pavilion", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SWAMP}],
		land_biomes)
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0),  BiomeType.Value.SWAMP)
	grid.place_tile(Vector2i(1, 0),  BiomeType.Value.FOREST)  # land neighbour!
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, [], "Floating Pavilion must NOT fire when a land neighbour is adjacent")


# ---------------------------------------------------------------------------
# All 10 landmark recipes trigger correctly (SC-001)
# ---------------------------------------------------------------------------

func test_bridge_of_sighs_fires_for_stone_water_stone_line() -> void:
	var pattern := _pattern("disc_bridge_of_sighs", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE},
		 {"offset": Vector2i(1, 0), "biome": BiomeType.Value.WATER},
		 {"offset": Vector2i(2, 0), "biome": BiomeType.Value.STONE}])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
	grid.place_tile(Vector2i(2, 0), BiomeType.Value.STONE)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_bridge_of_sighs"], "Bridge of Sighs must fire for Stone-Water-Stone line")


func test_lotus_pagoda_fires_for_swamp_cluster_of_four() -> void:
	var pattern := _pattern("disc_lotus_pagoda", PatternDefinition.PatternType.CLUSTER,
		[BiomeType.Value.SWAMP], 4)
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	# 4 adjacent Swamp tiles
	grid.place_tile(Vector2i(0, 0), BiomeType.Value.SWAMP)
	grid.place_tile(Vector2i(1, 0), BiomeType.Value.SWAMP)
	grid.place_tile(Vector2i(0, 1), BiomeType.Value.SWAMP)
	grid.place_tile(Vector2i(-1, 1), BiomeType.Value.SWAMP)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_lotus_pagoda"], "Lotus Pagoda must fire for 4+ connected Swamp tiles")


func test_monks_rest_fires_for_earth_enclosed_by_forest() -> void:
	var pattern := _pattern("disc_monks_rest", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0),   "biome": BiomeType.Value.EARTH},
			{"offset": Vector2i(1, 0),   "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(-1, 0),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(0, 1),   "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(0, -1),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(1, -1),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(-1, 1),  "biome": BiomeType.Value.FOREST},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.EARTH)
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(1, -1),  BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(-1, 1),  BiomeType.Value.FOREST)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_monks_rest"], "Monk's Rest must fire for Earth fully enclosed by Forest")


func test_bamboo_chime_fires_for_savannah_line_of_five() -> void:
	var pattern := _pattern("disc_bamboo_chime", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(1, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(2, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(3, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(4, 0), "biome": BiomeType.Value.SAVANNAH},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	for i: int in range(5):
		grid.place_tile(Vector2i(i, 0), BiomeType.Value.SAVANNAH)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_bamboo_chime"], "Bamboo Chime must fire for 5-tile Savannah line")


func test_whale_bone_arch_fires_for_canyon_u_shape() -> void:
	# U-shape rotation 0: (0,-1),(0,0),(1,0),(2,0),(2,-1) all Canyon
	var pattern := _pattern("disc_whale_bone_arch", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, -1), "biome": BiomeType.Value.CANYON},
			{"offset": Vector2i(0, 0),  "biome": BiomeType.Value.CANYON},
			{"offset": Vector2i(1, 0),  "biome": BiomeType.Value.CANYON},
			{"offset": Vector2i(2, 0),  "biome": BiomeType.Value.CANYON},
			{"offset": Vector2i(2, -1), "biome": BiomeType.Value.CANYON},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	for coord: Vector2i in [Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, -1)]:
		grid.place_tile(coord, BiomeType.Value.CANYON)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, ["disc_whale_bone_arch"], "Whale-Bone Arch must fire for Canyon U-shape")


# ---------------------------------------------------------------------------
# Duplicate suppression (SC-002)
# ---------------------------------------------------------------------------

func test_origin_shrine_fires_only_once() -> void:
	var pattern := _pattern("disc_origin_shrine", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
			{"offset": Vector2i(1, 0),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, 1),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.WATER)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.WATER)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.WATER)
	var count: int = 0
	matcher.discovery_triggered.connect(func(_id: String, _c: Array[Vector2i]) -> void:
		count += 1
	)
	matcher.scan_and_emit(grid)
	matcher.scan_and_emit(grid)
	assert_eq(count, 1, "Origin Shrine must fire exactly once even across multiple scans")


func test_monks_rest_fires_only_once() -> void:
	var pattern := _pattern("disc_monks_rest", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0),   "biome": BiomeType.Value.EARTH},
			{"offset": Vector2i(1, 0),   "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(-1, 0),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(0, 1),   "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(0, -1),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(1, -1),  "biome": BiomeType.Value.FOREST},
			{"offset": Vector2i(-1, 1),  "biome": BiomeType.Value.FOREST},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.EARTH)
	for neighbor_coord: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)]:
		grid.place_tile(neighbor_coord, BiomeType.Value.FOREST)
	var count: int = 0
	matcher.discovery_triggered.connect(func(_id: String, _c: Array[Vector2i]) -> void:
		count += 1
	)
	matcher.scan_and_emit(grid)
	matcher.scan_and_emit(grid)
	assert_eq(count, 1, "Monk's Rest must fire exactly once")


func test_bamboo_chime_fires_only_once_for_same_line() -> void:
	var pattern := _pattern("disc_bamboo_chime", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(1, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(2, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(3, 0), "biome": BiomeType.Value.SAVANNAH},
			{"offset": Vector2i(4, 0), "biome": BiomeType.Value.SAVANNAH},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	for i: int in range(5):
		grid.place_tile(Vector2i(i, 0), BiomeType.Value.SAVANNAH)
	var count: int = 0
	matcher.discovery_triggered.connect(func(_id: String, _c: Array[Vector2i]) -> void:
		count += 1
	)
	matcher.scan_and_emit(grid)
	matcher.scan_and_emit(grid)
	assert_eq(count, 1, "Bamboo Chime must fire exactly once")


# ---------------------------------------------------------------------------
# Biome-type mismatch must not trigger landmark
# ---------------------------------------------------------------------------

func test_origin_shrine_does_not_fire_with_wrong_biome_types() -> void:
	var pattern := _pattern("disc_origin_shrine", PatternDefinition.PatternType.SHAPE,
		[], 0,
		[
			{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
			{"offset": Vector2i(1, 0),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, 1),  "biome": BiomeType.Value.WATER},
			{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
		])
	var matcher := _make_matcher([pattern])
	var grid := GridMapScript.new()
	# Cross of Forest instead of Water — should not fire
	grid.place_tile(Vector2i(0, 0),   BiomeType.Value.STONE)
	grid.place_tile(Vector2i(1, 0),   BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(-1, 0),  BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, 1),   BiomeType.Value.FOREST)
	grid.place_tile(Vector2i(0, -1),  BiomeType.Value.FOREST)
	var emitted: Array[String] = []
	matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
		emitted.append(id)
	)
	matcher.scan_and_emit(grid)
	assert_eq(emitted, [], "Origin Shrine must NOT fire when arm biomes are wrong")


# ---------------------------------------------------------------------------
# Catalog data — all 10 tier2 IDs present
# ---------------------------------------------------------------------------

func test_tier2_catalog_has_all_10_entries() -> void:
	var data := DiscoveryCatalogData.new()
	var catalog := DiscoveryCatalog.new()
	catalog.load_from_data(data)
	var expected_ids: Array[String] = [
		"disc_origin_shrine", "disc_bridge_of_sighs", "disc_lotus_pagoda",
		"disc_monks_rest", "disc_star_gazing_deck", "disc_sun_dial",
		"disc_whale_bone_arch", "disc_echoing_cavern", "disc_bamboo_chime",
		"disc_floating_pavilion",
	]
	for id: String in expected_ids:
		assert_true(catalog.has_entry(id), "Catalog must contain tier2 entry: %s" % id)
