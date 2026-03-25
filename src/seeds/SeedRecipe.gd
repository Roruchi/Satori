class_name SeedRecipe
extends Resource

@export var recipe_id: StringName = &""
@export var elements: Array[int] = []
@export var tier: int = 1
@export var produces_biome: int = BiomeType.Value.NONE
@export var spirit_unlock_id: StringName = &""
@export var codex_hint: String = ""

func element_key() -> String:
	var sorted_elements: Array[int] = elements.duplicate()
	sorted_elements.sort()
	var parts: Array[String] = []
	for value: int in sorted_elements:
		parts.append(str(value))
	return "_".join(parts)
