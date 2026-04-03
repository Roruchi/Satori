class_name SeedPouch
extends RefCounted

const DEFAULT_USES_PER_CRAFT: int = 10

# Each entry is either:
#   plant recipe: {"recipe": SeedRecipe, "uses": int}  (entry_kind implicitly "plant_recipe")
#   building item: {"entry_kind": StringName("building_item"), "building_type_key": StringName, "count": int}
var seeds: Array[Dictionary] = []
var capacity: int = 8

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

# --- Building item inventory support ---

func get_entry_kind_at(index: int) -> StringName:
if index < 0 or index >= seeds.size():
return &""
var entry: Dictionary = seeds[index]
var kind_variant: Variant = entry.get("entry_kind", &"plant_recipe")
if kind_variant is StringName:
return kind_variant as StringName
return &"plant_recipe"

func find_building_index(type_key: StringName) -> int:
for i: int in range(seeds.size()):
if get_entry_kind_at(i) == &"building_item":
var entry: Dictionary = seeds[i]
var key_variant: Variant = entry.get("building_type_key", &"")
if (key_variant is StringName and (key_variant as StringName) == type_key) or str(key_variant) == str(type_key):
return i
return -1

func get_building_at(index: int) -> BuildingInventoryEntry:
if index < 0 or index >= seeds.size():
return null
if get_entry_kind_at(index) != &"building_item":
return null
var entry: Dictionary = seeds[index]
var key_variant: Variant = entry.get("building_type_key", &"")
var type_key: StringName = &""
if key_variant is StringName:
type_key = key_variant as StringName
else:
type_key = StringName(str(key_variant))
var count_val: int = int(entry.get("count", 1))
return BuildingInventoryEntry.create(type_key, count_val)

func add_building(type_key: StringName, amount: int = 1) -> bool:
if amount <= 0:
return false
var remaining: int = amount
var existing_index: int = find_building_index(type_key)
if existing_index >= 0:
var current_count: int = int(seeds[existing_index].get("count", 1))
if current_count < BuildingInventoryEntry.STACK_CAP:
var can_fit: int = BuildingInventoryEntry.STACK_CAP - current_count
var to_add: int = mini(can_fit, remaining)
seeds[existing_index]["count"] = current_count + to_add
remaining -= to_add
if remaining <= 0:
return true
if is_full():
return false
seeds.append({
"entry_kind": &"building_item",
"building_type_key": type_key,
"count": mini(remaining, BuildingInventoryEntry.STACK_CAP),
})
return true

func consume_building_at(index: int, amount: int = 1) -> bool:
if index < 0 or index >= seeds.size():
return false
if get_entry_kind_at(index) != &"building_item":
return false
var current_count: int = int(seeds[index].get("count", 1))
if current_count < amount:
return false
var new_count: int = current_count - amount
if new_count <= 0:
seeds.remove_at(index)
else:
seeds[index]["count"] = new_count
return true
