## TileSelector — CanvasLayer UI for switching between Grass and Water tiles.
extends CanvasLayer

@onready var _grass_btn: Button = $HBoxContainer/GrassButton
@onready var _water_btn: Button = $HBoxContainer/WaterButton

func _ready() -> void:
	_grass_btn.pressed.connect(func(): _select(BiomeType.Value.FOREST))
	_water_btn.pressed.connect(func(): _select(BiomeType.Value.WATER))
	_select(BiomeType.Value.FOREST)

func _select(biome: int) -> void:
	GameState.selected_biome = biome
	_grass_btn.modulate = Color.WHITE if biome == BiomeType.Value.FOREST else Color(0.6, 0.6, 0.6)
	_water_btn.modulate = Color.WHITE if biome == BiomeType.Value.WATER else Color(0.6, 0.6, 0.6)
