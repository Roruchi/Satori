class_name SeedPouch
extends RefCounted

var seeds: Array[SeedRecipe] = []
var capacity: int = 3

func is_full() -> bool:
	return seeds.size() >= capacity

func add(recipe: SeedRecipe) -> bool:
	if is_full():
		return false
	seeds.append(recipe)
	return true

func remove_at(index: int) -> SeedRecipe:
	if index < 0 or index >= seeds.size():
		return null
	var recipe: SeedRecipe = seeds[index]
	seeds.remove_at(index)
	return recipe

func first() -> SeedRecipe:
	if seeds.is_empty():
		return null
	return seeds[0]

func size() -> int:
	return seeds.size()
