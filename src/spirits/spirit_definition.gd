class_name SpiritDefinition
extends Resource

@export var spirit_id: String = ""
@export var display_name: String = ""
@export var riddle_text: String = ""
@export var pattern_id: String = ""
@export var wander_radius: int = 4
@export var wander_speed: float = 2.0
@export var color_hint: Color = Color.WHITE

@export_group("Habitat & Gift")
@export var preferred_biomes: Array[int] = []
@export var disliked_biomes: Array[int] = []
@export var harmony_partner_id: StringName = &""
@export var tension_partner_id: StringName = &""
@export var gift_type: int = 0
@export var gift_payload: StringName = &""
