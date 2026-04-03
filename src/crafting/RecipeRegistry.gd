class_name RecipeRegistry
extends RefCounted

var _by_shape_key: Dictionary = {}
var _by_id: Dictionary = {}

func _init() -> void:
	_load_all_recipes()

func _load_all_recipes() -> void:
	var dir := DirAccess.open("res://src/crafting/recipes")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") and not file_name.ends_with(".uid"):
			var path: String = "res://src/crafting/recipes/" + file_name
			var recipe: RecipeDefinition = load(path) as RecipeDefinition
			if recipe != null:
				_register(recipe)
		file_name = dir.get_next()
	dir.list_dir_end()

func _register(recipe: RecipeDefinition) -> void:
	assert(not _by_id.has(recipe.recipe_id), "RecipeRegistry: duplicate recipe_id '%s'" % recipe.recipe_id)
	_by_id[recipe.recipe_id] = recipe
	var key: String = _make_shape_key(recipe.shape, recipe.elements)
	assert(not _by_shape_key.has(key), "RecipeRegistry: duplicate shape key for '%s'" % recipe.recipe_id)
	_by_shape_key[key] = recipe

func lookup(shape: Array, elements: Array) -> RecipeDefinition:
	if shape.is_empty():
		return null
	var key: String = _make_shape_key(shape, elements)
	return _by_shape_key.get(key, null) as RecipeDefinition

func get_by_id(recipe_id: String) -> RecipeDefinition:
	return _by_id.get(recipe_id, null) as RecipeDefinition

## Bypass for unit tests — register without file I/O.
func add_for_testing(recipe: RecipeDefinition) -> void:
	_register(recipe)

static func _make_shape_key(shape: Array, elements: Array) -> String:
	var parts: Array[String] = []
	for i: int in range(shape.size()):
		var v: Vector2i = shape[i] as Vector2i
		parts.append("%d,%d:%d" % [v.x, v.y, int(elements[i])])
	return "|".join(parts)
