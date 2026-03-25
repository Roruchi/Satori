class_name SeedPouch
extends RefCounted

const DEFAULT_USES_PER_CRAFT: int = 10

# Each entry is {"recipe": SeedRecipe, "uses": int}
var seeds: Array[Dictionary] = []
var capacity: int = 3

func is_full() -> bool:
	return seeds.size() >= capacity

func add(recipe: SeedRecipe, uses: int = DEFAULT_USES_PER_CRAFT) -> bool:
	if recipe == null or uses <= 0:
		return false
	var existing_index: int = find_index_by_recipe_id(recipe.recipe_id)
	if existing_index >= 0:
		var existing_uses: int = get_uses_at(existing_index)
		seeds[existing_index]["uses"] = existing_uses + uses
		return true
	if is_full():
		return false
	seeds.append({"recipe": recipe, "uses": uses})
	return true

func remove_at(index: int) -> SeedRecipe:
	if index < 0 or index >= seeds.size():
		return null
	var recipe: SeedRecipe = get_at(index)
	seeds.remove_at(index)
	return recipe

func consume_use_at(index: int) -> SeedRecipe:
	if index < 0 or index >= seeds.size():
		return null
	var recipe: SeedRecipe = get_at(index)
	if recipe == null:
		return null
	var uses_remaining: int = get_uses_at(index) - 1
	if uses_remaining <= 0:
		seeds.remove_at(index)
	else:
		seeds[index]["uses"] = uses_remaining
	return recipe

func first() -> SeedRecipe:
	if seeds.is_empty():
		return null
	return get_at(0)

func get_at(index: int) -> SeedRecipe:
	if index < 0 or index >= seeds.size():
		return null
	var entry: Dictionary = seeds[index]
	var recipe_variant: Variant = entry.get("recipe")
	if recipe_variant is SeedRecipe:
		return recipe_variant as SeedRecipe
	return null

func get_uses_at(index: int) -> int:
	if index < 0 or index >= seeds.size():
		return 0
	var entry: Dictionary = seeds[index]
	return int(entry.get("uses", 0))

func find_index_by_recipe_id(recipe_id: StringName) -> int:
	for i: int in range(seeds.size()):
		var recipe: SeedRecipe = get_at(i)
		if recipe != null and recipe.recipe_id == recipe_id:
			return i
	return -1

func find_index_by_biome(target_biome: int) -> int:
	for i: int in range(seeds.size()):
		var recipe: SeedRecipe = get_at(i)
		if recipe != null and recipe.produces_biome == target_biome:
			return i
	return -1

func size() -> int:
	return seeds.size()

func total_uses() -> int:
	var total: int = 0
	for i: int in range(seeds.size()):
		total += get_uses_at(i)
	return total
