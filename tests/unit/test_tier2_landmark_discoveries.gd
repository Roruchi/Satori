extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")

# ---------------------------------------------------------------------------
# Helper: build a PatternDefinition inline
# ---------------------------------------------------------------------------

func _make_shape(id: String, recipe: Array[Dictionary], forbidden: Array[int] = []) -> PatternDefinition:
var p := PatternDefinition.new()
p.discovery_id = id
p.pattern_type = PatternDefinition.PatternType.SHAPE
p.shape_recipe = recipe
p.forbidden_biomes = forbidden
return p


func _make_cluster(id: String, biome: int, threshold: int) -> PatternDefinition:
var p := PatternDefinition.new()
p.discovery_id = id
p.pattern_type = PatternDefinition.PatternType.CLUSTER
p.required_biomes = [biome]
p.size_threshold = threshold
return p


func _scan(patterns: Array[PatternDefinition], grid: Object) -> Array[String]:
var matcher := PatternMatcher.new()
matcher.set_patterns(patterns)
var emitted: Array[String] = []
matcher.discovery_triggered.connect(func(id: String, _c: Array[Vector2i]) -> void:
emitted.append(id)
)
matcher.scan_and_emit(grid)
return emitted


# ---------------------------------------------------------------------------
# absolute_anchor — Origin Shrine fires only when Stone is at grid (0,0)
# ---------------------------------------------------------------------------

func test_origin_shrine_fires_for_cross_at_grid_origin() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0,  0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
{"offset": Vector2i(1,  0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0,  1), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
]
var grid := GridMapScript.new()
grid.place_tile(Vector2i( 0,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.WATER)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.WATER)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.WATER)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.WATER)
assert_eq(_scan([_make_shape("disc_origin_shrine", recipe)], grid), ["disc_origin_shrine"])


func test_origin_shrine_does_not_fire_when_cross_is_elsewhere() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0,  0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
{"offset": Vector2i(1,  0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0,  1), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
]
var grid := GridMapScript.new()
# Cross at (5,5) — not at origin
grid.place_tile(Vector2i(5, 5), BiomeType.Value.STONE)
grid.place_tile(Vector2i(6, 5), BiomeType.Value.WATER)
grid.place_tile(Vector2i(4, 5), BiomeType.Value.WATER)
grid.place_tile(Vector2i(5, 6), BiomeType.Value.WATER)
grid.place_tile(Vector2i(5, 4), BiomeType.Value.WATER)
assert_eq(_scan([_make_shape("disc_origin_shrine", recipe)], grid), [])


# ---------------------------------------------------------------------------
# must_be_empty — Echoing Cavern fires only when centre cell is empty
# ---------------------------------------------------------------------------

func test_echoing_cavern_fires_when_ring_has_empty_centre() -> void:
# Anchor at (1,0); centre relative offset (-1,0) must be empty.
var recipe: Array[Dictionary] = [
{"offset": Vector2i( 0,  0), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1,  0), "must_be_empty": true},
{"offset": Vector2i(-2,  0), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1,  1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1, -1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i( 0, -1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-2,  1), "biome": BiomeType.Value.STONE},
]
var grid := GridMapScript.new()
# Ring of 6 Stone tiles around empty (0,0)
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 1, -1), BiomeType.Value.STONE)
grid.place_tile(Vector2i(-1,  1), BiomeType.Value.STONE)
assert_eq(_scan([_make_shape("disc_echoing_cavern", recipe)], grid), ["disc_echoing_cavern"])


func test_echoing_cavern_does_not_fire_when_centre_occupied() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i( 0,  0), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1,  0), "must_be_empty": true},
{"offset": Vector2i(-2,  0), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1,  1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-1, -1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i( 0, -1), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(-2,  1), "biome": BiomeType.Value.STONE},
]
var grid := GridMapScript.new()
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 1, -1), BiomeType.Value.STONE)
grid.place_tile(Vector2i(-1,  1), BiomeType.Value.STONE)
# Centre occupied — blocks match
grid.place_tile(Vector2i(0, 0), BiomeType.Value.FOREST)
assert_eq(_scan([_make_shape("disc_echoing_cavern", recipe)], grid), [])


# ---------------------------------------------------------------------------
# forbidden_biomes — Floating Pavilion fires only when isolated on water
# ---------------------------------------------------------------------------

func _land_biomes() -> Array[int]:
return [
BiomeType.Value.FOREST, BiomeType.Value.STONE, BiomeType.Value.EARTH,
BiomeType.Value.SWAMP, BiomeType.Value.TUNDRA, BiomeType.Value.MUDFLAT,
BiomeType.Value.MOSSY_CRAG, BiomeType.Value.SAVANNAH, BiomeType.Value.CANYON,
]


func test_floating_pavilion_fires_when_swamp_isolated_on_water() -> void:
var recipe: Array[Dictionary] = [{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SWAMP}]
var grid := GridMapScript.new()
grid.place_tile(Vector2i(0,  0), BiomeType.Value.SWAMP)
grid.place_tile(Vector2i(1,  0), BiomeType.Value.WATER)
grid.place_tile(Vector2i(-1, 0), BiomeType.Value.WATER)
grid.place_tile(Vector2i(0,  1), BiomeType.Value.WATER)
assert_eq(_scan([_make_shape("disc_floating_pavilion", recipe, _land_biomes())], grid), ["disc_floating_pavilion"])


func test_floating_pavilion_does_not_fire_when_adjacent_land() -> void:
var recipe: Array[Dictionary] = [{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SWAMP}]
var grid := GridMapScript.new()
grid.place_tile(Vector2i(0, 0), BiomeType.Value.SWAMP)
grid.place_tile(Vector2i(1, 0), BiomeType.Value.FOREST)  # land neighbour blocks it
assert_eq(_scan([_make_shape("disc_floating_pavilion", recipe, _land_biomes())], grid), [])


# ---------------------------------------------------------------------------
# Landmark recipe triggers (SC-001)
# ---------------------------------------------------------------------------

func test_bridge_of_sighs_fires_for_stone_water_stone_line() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0, 0), "biome": BiomeType.Value.STONE},
{"offset": Vector2i(1, 0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(2, 0), "biome": BiomeType.Value.STONE},
]
var grid := GridMapScript.new()
grid.place_tile(Vector2i(0, 0), BiomeType.Value.STONE)
grid.place_tile(Vector2i(1, 0), BiomeType.Value.WATER)
grid.place_tile(Vector2i(2, 0), BiomeType.Value.STONE)
assert_eq(_scan([_make_shape("disc_bridge_of_sighs", recipe)], grid), ["disc_bridge_of_sighs"])


func test_lotus_pagoda_fires_for_swamp_cluster_of_four() -> void:
var grid := GridMapScript.new()
grid.place_tile(Vector2i( 0, 0), BiomeType.Value.SWAMP)
grid.place_tile(Vector2i( 1, 0), BiomeType.Value.SWAMP)
grid.place_tile(Vector2i( 0, 1), BiomeType.Value.SWAMP)
grid.place_tile(Vector2i(-1, 1), BiomeType.Value.SWAMP)
assert_eq(_scan([_make_cluster("disc_lotus_pagoda", BiomeType.Value.SWAMP, 4)], grid), ["disc_lotus_pagoda"])


func test_monks_rest_fires_for_earth_enclosed_by_forest() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i( 0,  0), "biome": BiomeType.Value.EARTH},
{"offset": Vector2i( 1,  0), "biome": BiomeType.Value.FOREST},
{"offset": Vector2i(-1,  0), "biome": BiomeType.Value.FOREST},
{"offset": Vector2i( 0,  1), "biome": BiomeType.Value.FOREST},
{"offset": Vector2i( 0, -1), "biome": BiomeType.Value.FOREST},
{"offset": Vector2i( 1, -1), "biome": BiomeType.Value.FOREST},
{"offset": Vector2i(-1,  1), "biome": BiomeType.Value.FOREST},
]
var grid := GridMapScript.new()
grid.place_tile(Vector2i( 0,  0), BiomeType.Value.EARTH)
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.FOREST)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.FOREST)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.FOREST)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.FOREST)
grid.place_tile(Vector2i( 1, -1), BiomeType.Value.FOREST)
grid.place_tile(Vector2i(-1,  1), BiomeType.Value.FOREST)
assert_eq(_scan([_make_shape("disc_monks_rest", recipe)], grid), ["disc_monks_rest"])


func test_bamboo_chime_fires_for_savannah_line_of_five() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(1, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(2, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(3, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(4, 0), "biome": BiomeType.Value.SAVANNAH},
]
var grid := GridMapScript.new()
for i: int in range(5):
grid.place_tile(Vector2i(i, 0), BiomeType.Value.SAVANNAH)
assert_eq(_scan([_make_shape("disc_bamboo_chime", recipe)], grid), ["disc_bamboo_chime"])


func test_whale_bone_arch_fires_for_canyon_u_shape() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0, -1), "biome": BiomeType.Value.CANYON},
{"offset": Vector2i(0,  0), "biome": BiomeType.Value.CANYON},
{"offset": Vector2i(1,  0), "biome": BiomeType.Value.CANYON},
{"offset": Vector2i(2,  0), "biome": BiomeType.Value.CANYON},
{"offset": Vector2i(2, -1), "biome": BiomeType.Value.CANYON},
]
var grid := GridMapScript.new()
for coord: Vector2i in [Vector2i(0,-1), Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,-1)]:
grid.place_tile(coord, BiomeType.Value.CANYON)
assert_eq(_scan([_make_shape("disc_whale_bone_arch", recipe)], grid), ["disc_whale_bone_arch"])


# ---------------------------------------------------------------------------
# Duplicate suppression (SC-002) — landmark fires exactly once per scan cycle
# ---------------------------------------------------------------------------

func test_origin_shrine_fires_only_once() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0,  0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
{"offset": Vector2i(1,  0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0,  1), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
]
var matcher := PatternMatcher.new()
matcher.set_patterns([_make_shape("disc_origin_shrine", recipe)])
var count: int = 0
matcher.discovery_triggered.connect(func(_id: String, _c: Array[Vector2i]) -> void:
count += 1
)
var grid := GridMapScript.new()
grid.place_tile(Vector2i( 0,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.WATER)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.WATER)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.WATER)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.WATER)
matcher.scan_and_emit(grid)
matcher.scan_and_emit(grid)
assert_eq(count, 1, "Origin Shrine must fire exactly once across multiple scans")


func test_bamboo_chime_fires_only_once() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(1, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(2, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(3, 0), "biome": BiomeType.Value.SAVANNAH},
{"offset": Vector2i(4, 0), "biome": BiomeType.Value.SAVANNAH},
]
var matcher := PatternMatcher.new()
matcher.set_patterns([_make_shape("disc_bamboo_chime", recipe)])
var count: int = 0
matcher.discovery_triggered.connect(func(_id: String, _c: Array[Vector2i]) -> void:
count += 1
)
var grid := GridMapScript.new()
for i: int in range(5):
grid.place_tile(Vector2i(i, 0), BiomeType.Value.SAVANNAH)
matcher.scan_and_emit(grid)
matcher.scan_and_emit(grid)
assert_eq(count, 1, "Bamboo Chime must fire exactly once")


# ---------------------------------------------------------------------------
# Biome mismatch must not trigger
# ---------------------------------------------------------------------------

func test_origin_shrine_does_not_fire_with_wrong_arm_biomes() -> void:
var recipe: Array[Dictionary] = [
{"offset": Vector2i(0,  0), "biome": BiomeType.Value.STONE, "absolute_anchor": true},
{"offset": Vector2i(1,  0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(-1, 0), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0,  1), "biome": BiomeType.Value.WATER},
{"offset": Vector2i(0, -1), "biome": BiomeType.Value.WATER},
]
var grid := GridMapScript.new()
# Arms are Forest not Water
grid.place_tile(Vector2i( 0,  0), BiomeType.Value.STONE)
grid.place_tile(Vector2i( 1,  0), BiomeType.Value.FOREST)
grid.place_tile(Vector2i(-1,  0), BiomeType.Value.FOREST)
grid.place_tile(Vector2i( 0,  1), BiomeType.Value.FOREST)
grid.place_tile(Vector2i( 0, -1), BiomeType.Value.FOREST)
assert_eq(_scan([_make_shape("disc_origin_shrine", recipe)], grid), [])


# ---------------------------------------------------------------------------
# Catalog — all 10 tier2 IDs are present after load
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
assert_true(catalog.has_entry(id), "Catalog must contain: %s" % id)

func test_ku_structure_patterns_fire_for_required_biomes() -> void:
	var structures: Array[Dictionary] = [
		{"id": "disc_iwakura_sanctum", "biome": BiomeType.Value.SACRED_STONE},
		{"id": "disc_misogi_spring_shrine", "biome": BiomeType.Value.VEIL_MARSH},
		{"id": "disc_eternal_kagura_hall", "biome": BiomeType.Value.EMBER_SHRINE},
		{"id": "disc_heavenwind_torii", "biome": BiomeType.Value.CLOUD_RIDGE},
	]
	for structure: Dictionary in structures:
		var test_grid: RefCounted = GridMapScript.new()
		test_grid.place_tile(Vector2i(0, 0), int(structure["biome"]))
		test_grid.place_tile(Vector2i(1, 0), int(structure["biome"]))
		test_grid.place_tile(Vector2i(0, 1), int(structure["biome"]))
		test_grid.place_tile(Vector2i(-1, 1), int(structure["biome"]))
		var pattern: PatternDefinition = _make_cluster(str(structure["id"]), int(structure["biome"]), 4)
		assert_eq(_scan([pattern], test_grid), [str(structure["id"])], "Expected structure discovery for %s" % str(structure["id"]))

func test_tier2_catalog_has_ku_entries() -> void:
	var data := DiscoveryCatalogData.new()
	var catalog := DiscoveryCatalog.new()
	catalog.load_from_data(data)
	var ku_ids: Array[String] = [
		"disc_iwakura_sanctum",
		"disc_misogi_spring_shrine",
		"disc_eternal_kagura_hall",
		"disc_heavenwind_torii",
	]
	for discovery_id: String in ku_ids:
		assert_true(catalog.has_entry(discovery_id), "Catalog must contain Ku structure: %s" % discovery_id)
