## Test Suite: SkyWhaleEvaluator
##
## GUT unit tests for SkyWhaleEvaluator.evaluate() with various grid configurations.
## Run via tests/gut_runner.tscn

extends GutTest

const GridMapScript = preload("res://src/grid/GridMap.gd")


func _make_grid() -> RefCounted:
	return GridMapScript.new()


func _fill_grid_with_biomes(grid: RefCounted, counts: Dictionary) -> void:
	var q: int = 0
	var r: int = 0
	for biome: int in counts.keys():
		var n: int = int(counts[biome])
		for _i: int in range(n):
			while grid.has_tile(Vector2i(q, r)):
				q += 1
				if q > 100:
					q = 0
					r += 1
			grid.place_tile(Vector2i(q, r), biome)
			q += 1
			if q > 100:
				q = 0
				r += 1


func test_evaluate_returns_false_when_tile_count_below_1000() -> void:
	var grid: RefCounted = _make_grid()
	_fill_grid_with_biomes(grid, {0: 250, 1: 250, 2: 249, 3: 250})
	var evaluator := SkyWhaleEvaluator.new()
	assert_false(evaluator.evaluate(grid),
		"Should return false when total tile count < 1000")


func test_evaluate_returns_false_when_one_biome_dominates() -> void:
	var grid: RefCounted = _make_grid()
	# 700 FOREST, 100 each of WATER, STONE, EARTH = 1000 total but very unbalanced
	_fill_grid_with_biomes(grid, {0: 700, 1: 100, 2: 100, 3: 100})
	var evaluator := SkyWhaleEvaluator.new()
	assert_false(evaluator.evaluate(grid),
		"Should return false when FOREST dominates with 70%")


func test_evaluate_returns_true_when_balanced_1000_tiles() -> void:
	var grid: RefCounted = _make_grid()
	# Exactly 250 each of FOREST, WATER, STONE, EARTH = 1000 total, perfectly balanced
	_fill_grid_with_biomes(grid, {0: 250, 1: 250, 2: 250, 3: 250})
	var evaluator := SkyWhaleEvaluator.new()
	assert_true(evaluator.evaluate(grid),
		"Should return true when 1000 tiles equally distributed among 4 biomes")


func test_evaluate_returns_false_when_macro_biome_missing() -> void:
	var grid: RefCounted = _make_grid()
	# No EARTH at all: 500 FOREST, 250 WATER, 250 STONE = 1000 total, EARTH = 0%
	_fill_grid_with_biomes(grid, {0: 500, 1: 250, 2: 250})
	var evaluator := SkyWhaleEvaluator.new()
	assert_false(evaluator.evaluate(grid),
		"Should return false when EARTH macro biome is entirely missing")


func test_evaluate_hybrid_biomes_fold_into_macro_groups() -> void:
	var grid: RefCounted = _make_grid()
	# SWAMP (4) folds into FOREST, TUNDRA (5) into STONE, MUDFLAT (6) into EARTH
	# 250 FOREST, 250 WATER, 250 TUNDRA (->STONE), 250 MUDFLAT (->EARTH) = balanced
	_fill_grid_with_biomes(grid, {0: 250, 1: 250, 5: 250, 6: 250})
	var evaluator := SkyWhaleEvaluator.new()
	assert_true(evaluator.evaluate(grid),
		"Hybrid biomes should fold into macro groups for balance check")


func test_get_balance_hint_returns_balanced_when_even() -> void:
	var grid: RefCounted = _make_grid()
	_fill_grid_with_biomes(grid, {0: 250, 1: 250, 2: 250, 3: 250})
	var evaluator := SkyWhaleEvaluator.new()
	assert_eq(evaluator.get_balance_hint(grid), "balanced",
		"get_balance_hint should return 'balanced' for equal distribution")


func test_get_balance_hint_returns_biome_name_when_imbalanced() -> void:
	var grid: RefCounted = _make_grid()
	_fill_grid_with_biomes(grid, {0: 700, 1: 100, 2: 100, 3: 100})
	var evaluator := SkyWhaleEvaluator.new()
	var hint: String = evaluator.get_balance_hint(grid)
	assert_ne(hint, "balanced", "get_balance_hint should not return 'balanced' when imbalanced")
