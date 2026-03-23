## GardenView — renders the garden grid using immediate-mode 2D drawing.
extends Node2D

const TILE_SIZE: int = 32

var _hover_coord: Vector2i = Vector2i(-9999, -9999)
var _hover_valid: bool = false

func _ready() -> void:
	GameState.tile_placed.connect(_on_tile_placed)
	queue_redraw()

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	queue_redraw()

## Called by PlacementController each frame to update the placement-preview highlight.
func set_hover(coord: Vector2i, valid: bool) -> void:
	if _hover_coord == coord and _hover_valid == valid:
		return
	_hover_coord = coord
	_hover_valid = valid
	queue_redraw()

func _draw() -> void:
	for coord in GameState.grid.tiles:
		var tile: GardenTile = GameState.grid.tiles[coord]
		_draw_tile(coord, _biome_color(tile.biome))

	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)

	if _hover_valid:
		var half := TILE_SIZE / 2.0
		var cx := _hover_coord.x * TILE_SIZE
		var cy := _hover_coord.y * TILE_SIZE
		var rect := Rect2(cx - half, cy - half, TILE_SIZE, TILE_SIZE)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.35))
		draw_rect(rect, Color.WHITE, false, 2.0)

func _draw_tile(coord: Vector2i, color: Color) -> void:
	var half := TILE_SIZE / 2.0
	var rect := Rect2(
		coord.x * TILE_SIZE - half,
		coord.y * TILE_SIZE - half,
		TILE_SIZE,
		TILE_SIZE
	)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.25), false, 1.0)

static func _biome_color(biome: int) -> Color:
	match biome:
		BiomeType.Value.FOREST: return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WATER:  return Color(0.129, 0.588, 0.953)
		BiomeType.Value.STONE:  return Color(0.620, 0.620, 0.620)
		BiomeType.Value.EARTH:  return Color(0.757, 0.580, 0.376)
	return Color(0.502, 0.502, 0.502)
