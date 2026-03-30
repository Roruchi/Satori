class_name TerrainValidator
extends RefCounted

## Apply rotation_steps × 90° clockwise to each offset in offsets.
## Each step: (r, c) → (c, -r), then renormalize to min_row=min_col=0.
static func apply_rotation(offsets: Array[Vector2i], rotation_steps: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for v: Vector2i in offsets:
		result.append(v)
	for _step: int in range(rotation_steps % 4):
		var rotated: Array[Vector2i] = []
		for v: Vector2i in result:
			rotated.append(Vector2i(v.y, -v.x))
		# Renormalize
		if rotated.is_empty():
			result = rotated
			continue
		var min_r: int = rotated[0].x
		var min_c: int = rotated[0].y
		for v: Vector2i in rotated:
			if v.x < min_r:
				min_r = v.x
			if v.y < min_c:
				min_c = v.y
		var normalized: Array[Vector2i] = []
		for v: Vector2i in rotated:
			normalized.append(Vector2i(v.x - min_r, v.y - min_c))
		result = normalized
	return result

## Validate a recipe's footprint against the grid at the given anchor and rotation.
## Returns Array[Dictionary] with one entry per shape cell:
##   { "world_coord": Vector2i, "valid": bool, "error": String }
func validate(recipe: RecipeDefinition, anchor: Vector2i, rotation_steps: int, grid: RefCounted) -> Array[Dictionary]:
	var rotated: Array[Vector2i] = apply_rotation(recipe.shape, rotation_steps)
	var results: Array[Dictionary] = []
	for i: int in range(rotated.size()):
		var offset: Vector2i = rotated[i]
		var world_coord: Vector2i = Vector2i(anchor.x + offset.x, anchor.y + offset.y)
		var valid: bool = true
		var error: String = ""
		# Bounds check
		if abs(world_coord.x) > 500 or abs(world_coord.y) > 500:
			valid = false
			error = "Out of bounds"
		# Occupied check
		elif grid.has_tile(world_coord):
			valid = false
			error = "Cell already occupied"
		else:
			# Terrain rule check
			if i < recipe.terrain_rules.size():
				var rule: Dictionary = recipe.terrain_rules[i] as Dictionary
				var required_biome: int = int(rule.get("required_biome", -1))
				if required_biome >= 0:
					var found: bool = false
					if grid.has_tile(world_coord):
						found = int((grid.get_tile(world_coord) as GardenTile).biome) == required_biome
					if not found:
						valid = false
						var biome_name: String = BiomeType.get_display_name(required_biome) if BiomeType.has_method("get_display_name") else "Biome %d" % required_biome
						error = "Requires %s foundation" % biome_name
		results.append({"world_coord": world_coord, "valid": valid, "error": error})
	return results

static func all_valid(results: Array[Dictionary]) -> bool:
	for entry: Dictionary in results:
		if not bool(entry.get("valid", false)):
			return false
	return true
