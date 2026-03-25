class_name CodexEntry
extends Resource

enum Category {
	SEED = 0,
	BIOME = 1,
	SPIRIT = 2,
	STRUCTURE = 3,
}

@export var entry_id: StringName = &""
@export var category: int = Category.SEED
@export var hint_text: String = ""
@export var full_name: String = ""
@export var full_description: String = ""
@export var always_hidden: bool = false
