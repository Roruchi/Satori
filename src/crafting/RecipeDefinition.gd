class_name RecipeDefinition
extends Resource

enum OutputType { TILE = 0, STRUCTURE = 1 }

@export var recipe_id: String = ""
@export var output_type: int = OutputType.TILE
@export var output_id: String = ""
@export var shape: Array[Vector2i] = []
@export var elements: Array[int] = []
@export var display_name: String = ""
@export var icon_path: String = ""
@export var terrain_rules: Array[Dictionary] = []
@export var min_element_count: int = 1
