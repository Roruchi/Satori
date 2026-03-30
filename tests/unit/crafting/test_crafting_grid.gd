extends GutTest

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_registry_with_starter_house() -> RecipeRegistry:
	var reg := RecipeRegistry.new()
	# RecipeRegistry auto-loads from res://src/crafting/recipes at _init,
	# so starter_house is already present when the directory exists.
	return reg

func _make_registry_empty() -> RecipeRegistry:
	# Use a bare RefCounted-based registry without file I/O by injecting
	# recipes manually via add_for_testing.
	var reg := RecipeRegistry.new()
	return reg

func _make_fu_recipe() -> RecipeDefinition:
	var r := RecipeDefinition.new()
	r.recipe_id = "recipe_fu_tile_test"
	r.output_type = RecipeDefinition.OutputType.TILE
	r.output_id = "3"
	r.shape = [Vector2i(0, 0)]
	r.elements = [3]
	r.display_name = "Meadow"
	return r

func _make_starter_house_recipe() -> RecipeDefinition:
	var r := RecipeDefinition.new()
	r.recipe_id = "recipe_starter_house_test"
	r.output_type = RecipeDefinition.OutputType.STRUCTURE
	r.output_id = "disc_starter_house"
	r.shape = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)]
	r.elements = [3, 3, 3, 3]
	r.display_name = "Starter House"
	r.min_element_count = 4
	return r

# ---------------------------------------------------------------------------
# CraftingGrid.normalize()
# ---------------------------------------------------------------------------

func test_single_cell_normalises_to_origin() -> void:
	gut.p("Single occupied cell should normalise to Vector2i(0,0)")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(2, 2, 0)
	var result: Array = grid.normalize()
	var shape: Array = result[0]
	assert_eq(shape.size(), 1, "Shape should have 1 element")
	assert_eq(shape[0], Vector2i(0, 0), "Should normalise to origin")

func test_two_adjacent_cells_normalise_to_canonical_pair() -> void:
	gut.p("Two horizontally adjacent cells should normalise to [(0,0),(0,1)]")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(1, 1, 0)
	grid.set_cell(1, 2, 1)
	var result: Array = grid.normalize()
	var shape: Array = result[0]
	assert_eq(shape.size(), 2)
	assert_eq(shape[0], Vector2i(0, 0))
	assert_eq(shape[1], Vector2i(0, 1))

func test_2x2_block_normalises_identically_regardless_of_grid_position() -> void:
	gut.p("2x2 block placed at different corners should yield the same normalised shape")
	var reg := RecipeRegistry.new()

	var grid_a := CraftingGrid.new(reg)
	grid_a.set_cell(0, 0, 3)
	grid_a.set_cell(0, 1, 3)
	grid_a.set_cell(1, 0, 3)
	grid_a.set_cell(1, 1, 3)
	var shape_a: Array = grid_a.normalize()[0]

	var grid_b := CraftingGrid.new(reg)
	grid_b.set_cell(1, 1, 3)
	grid_b.set_cell(1, 2, 3)
	grid_b.set_cell(2, 1, 3)
	grid_b.set_cell(2, 2, 3)
	var shape_b: Array = grid_b.normalize()[0]

	assert_eq(shape_a.size(), shape_b.size(), "Both shapes should have 4 cells")
	for i: int in range(shape_a.size()):
		assert_eq(shape_a[i], shape_b[i], "Cell %d should match" % i)

# ---------------------------------------------------------------------------
# CraftingGrid.is_contiguous()
# ---------------------------------------------------------------------------

func test_empty_grid_is_contiguous() -> void:
	gut.p("Empty grid reports contiguous (vacuously true)")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	assert_true(grid.is_contiguous())

func test_single_cell_is_contiguous() -> void:
	gut.p("Single occupied cell is contiguous")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 0, 0)
	assert_true(grid.is_contiguous())

func test_orthogonally_adjacent_cells_are_contiguous() -> void:
	gut.p("Two orthogonally adjacent cells are contiguous")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 0, 0)
	grid.set_cell(0, 1, 1)
	assert_true(grid.is_contiguous())

func test_diagonally_adjacent_cells_are_contiguous() -> void:
	gut.p("Two diagonally adjacent cells are contiguous (diagonal counts)")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 0, 0)
	grid.set_cell(1, 1, 1)
	assert_true(grid.is_contiguous())

func test_non_adjacent_cells_are_not_contiguous() -> void:
	gut.p("Cells at (0,0) and (2,2) are not contiguous (gap between them)")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 0, 0)
	grid.set_cell(2, 2, 0)
	assert_false(grid.is_contiguous())

# ---------------------------------------------------------------------------
# Starter House matching in all four corners
# ---------------------------------------------------------------------------

func test_starter_house_matches_top_left_corner() -> void:
	gut.p("Starter House 2x2 matches when placed in top-left corner")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 0, 3)
	grid.set_cell(0, 1, 3)
	grid.set_cell(1, 0, 3)
	grid.set_cell(1, 1, 3)
	var result: Array = grid.normalize()
	var recipe: RecipeDefinition = reg.lookup(result[0], result[1])
	assert_not_null(recipe, "Should match a recipe")
	assert_eq(recipe.output_id, "disc_starter_house")

func test_starter_house_matches_bottom_right_corner() -> void:
	gut.p("Starter House 2x2 matches when placed in bottom-right corner")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(1, 1, 3)
	grid.set_cell(1, 2, 3)
	grid.set_cell(2, 1, 3)
	grid.set_cell(2, 2, 3)
	var result: Array = grid.normalize()
	var recipe: RecipeDefinition = reg.lookup(result[0], result[1])
	assert_not_null(recipe, "Should match a recipe")
	assert_eq(recipe.output_id, "disc_starter_house")

func test_starter_house_matches_top_right_corner() -> void:
	gut.p("Starter House 2x2 matches when placed in top-right corner")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(0, 1, 3)
	grid.set_cell(0, 2, 3)
	grid.set_cell(1, 1, 3)
	grid.set_cell(1, 2, 3)
	var result: Array = grid.normalize()
	var recipe: RecipeDefinition = reg.lookup(result[0], result[1])
	assert_not_null(recipe, "Should match a recipe")
	assert_eq(recipe.output_id, "disc_starter_house")

func test_starter_house_matches_bottom_left_corner() -> void:
	gut.p("Starter House 2x2 matches when placed in bottom-left corner")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	grid.set_cell(1, 0, 3)
	grid.set_cell(1, 1, 3)
	grid.set_cell(2, 0, 3)
	grid.set_cell(2, 1, 3)
	var result: Array = grid.normalize()
	var recipe: RecipeDefinition = reg.lookup(result[0], result[1])
	assert_not_null(recipe, "Should match a recipe")
	assert_eq(recipe.output_id, "disc_starter_house")

# ---------------------------------------------------------------------------
# grid_changed signal
# ---------------------------------------------------------------------------

func test_non_contiguous_grid_emits_null_from_grid_changed() -> void:
	gut.p("Non-contiguous layout emits grid_changed with null recipe")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	var emitted: Array = []
	grid.grid_changed.connect(func(r: RecipeDefinition) -> void:
		emitted.append(r)
	)
	# Place two cells that are not contiguous
	grid.set_cell(0, 0, 0)
	grid.set_cell(2, 2, 0)
	assert_true(emitted.size() > 0, "Signal should have fired")
	assert_null(emitted.back(), "Last emission should be null for non-contiguous grid")

func test_grid_changed_signal_fires_on_set_cell() -> void:
	gut.p("grid_changed signal fires whenever set_cell is called")
	var reg := RecipeRegistry.new()
	var grid := CraftingGrid.new(reg)
	var count: int = 0
	grid.grid_changed.connect(func(_r: RecipeDefinition) -> void:
		count += 1
	)
	grid.set_cell(0, 0, 3)
	grid.set_cell(0, 1, 3)
	assert_eq(count, 2, "Signal should fire once per set_cell call")
