class_name PatternDefinition
extends Resource

enum PatternType {
	CLUSTER,
	SHAPE,
	RATIO_PROXIMITY,
	COMPOUND,
}

@export var discovery_id: String = ""
@export var pattern_type: PatternType = PatternType.CLUSTER
@export var required_biomes: Array[int] = []
@export var forbidden_biomes: Array[int] = []
@export var size_threshold: int = 0
@export var shape_recipe: Array[Dictionary] = []
@export var neighbour_requirements: Dictionary = {}
@export var prerequisite_ids: Array[String] = []

func is_valid_definition() -> bool:
	if discovery_id.is_empty():
		return false
	match pattern_type:
		PatternType.CLUSTER:
			return size_threshold > 0 and not required_biomes.is_empty()
		PatternType.SHAPE:
			return not shape_recipe.is_empty()
		PatternType.RATIO_PROXIMITY:
			return neighbour_requirements.has("radius") and neighbour_requirements.has("biomes")
		PatternType.COMPOUND:
			return not prerequisite_ids.is_empty() and not required_biomes.is_empty()
	return false
