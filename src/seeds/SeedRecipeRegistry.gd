class_name SeedRecipeRegistry
extends RefCounted

const SeedRecipeCatalogPhase1Script = preload("res://src/seeds/SeedRecipeCatalogPhase1.gd")

var _recipes: Dictionary = {}
var _recipes_by_id: Dictionary = {}
var _unlocked_tier3: Dictionary = {}
var _phase1_catalog = SeedRecipeCatalogPhase1Script.new()

func _init() -> void:
	_load_recipes()

func _load_recipes() -> void:
	var dir: DirAccess = DirAccess.open("res://src/seeds/recipes/")
	if dir == null:
		return
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path: String = "res://src/seeds/recipes/%s" % filename
			var recipe_resource: Resource = load(path)
			if recipe_resource is SeedRecipe:
				var recipe: SeedRecipe = recipe_resource as SeedRecipe
				var key: String = _key_for_elements(recipe.elements)
				_recipes[key] = recipe
				_recipes_by_id[recipe.recipe_id] = recipe
		filename = dir.get_next()
	dir.list_dir_end()

func _key_for_elements(elements: Array[int]) -> String:
	var sorted_elements: Array[int] = elements.duplicate()
	sorted_elements.sort()
	var parts: Array[String] = []
	for value: int in sorted_elements:
		parts.append(str(value))
	return "_".join(parts)

func lookup(elements: Array[int]) -> SeedRecipe:
	var key: String = _key_for_elements(elements)
	if not _recipes.has(key):
		return null
	var recipe: SeedRecipe = _recipes[key] as SeedRecipe
	if recipe == null:
		return null
	if int(recipe.tier) == 3:
		if not _unlocked_tier3.get(recipe.recipe_id, false):
			return null
	return recipe

func lookup_phase1_seed(elements: Array[int]) -> SeedRecipe:
	if not _phase1_catalog.is_valid_token_count(elements.size()):
		return null
	var key: String = _key_for_elements(elements)
	if not _phase1_catalog.is_allowed_key(key):
		return null
	return lookup(elements)

func unlock_recipe(recipe_id: StringName) -> void:
	var recipe: SeedRecipe = _recipes_by_id.get(recipe_id, null)
	if recipe == null:
		return
	if int(recipe.tier) < 3:
		return
	_unlocked_tier3[recipe.recipe_id] = true

func is_recipe_known(recipe_id: StringName) -> bool:
	return _recipes_by_id.has(recipe_id)

func all_known_recipes() -> Array[SeedRecipe]:
	var result: Array[SeedRecipe] = []
	for recipe_variant in _recipes.values():
		var recipe: SeedRecipe = recipe_variant as SeedRecipe
		if recipe != null:
			result.append(recipe)
	return result

func add_recipe_for_testing(recipe: SeedRecipe) -> void:
	if recipe == null:
		return
	var key: String = _key_for_elements(recipe.elements)
	_recipes[key] = recipe
	_recipes_by_id[recipe.recipe_id] = recipe
