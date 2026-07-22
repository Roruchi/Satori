extends RefCounted

const ICON_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ritual/icons/00_earth.png"),
	preload("res://assets/ritual/icons/01_water.png"),
	preload("res://assets/ritual/icons/02_fire.png"),
	preload("res://assets/ritual/icons/03_wind.png"),
	preload("res://assets/ritual/icons/04_void.png"),
	preload("res://assets/ritual/icons/05_living_wood.png"),
	preload("res://assets/ritual/icons/06_reed_fiber.png"),
	preload("res://assets/ritual/icons/07_spirit_stone.png"),
	preload("res://assets/ritual/icons/08_ember_clay.png"),
]

static func texture_at(icon_index: int) -> Texture2D:
	if icon_index < 0 or icon_index >= ICON_TEXTURES.size():
		return null
	return ICON_TEXTURES[icon_index]
