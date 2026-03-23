## GardenView — renders the garden grid using immediate-mode 2D drawing.
extends Node2D

const TILE_SIZE: int = 32

var _hover_coord: Vector2i = Vector2i(-9999, -9999)
var _hover_valid: bool = false

# --- mix success animation ---
var _mix_coord: Vector2i = Vector2i(-9999, -9999)
var _mix_timer: float = 0.0

# --- rejection animation ---
var _reject_coord: Vector2i = Vector2i(-9999, -9999)
var _reject_reason: String = ""
var _reject_timer: float = 0.0

func _ready() -> void:
	GameState.tile_placed.connect(_on_tile_placed)
	GameState.tile_mixed.connect(_on_tile_mixed)
	GameState.mix_rejected.connect(_on_mix_rejected)
	queue_redraw()

func _process(delta: float) -> void:
	var needs_redraw := false
	if _mix_timer > 0.0:
		_mix_timer -= delta
		needs_redraw = true
	if _reject_timer > 0.0:
		_reject_timer -= delta
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	queue_redraw()

func _on_tile_mixed(coord: Vector2i, _tile: GardenTile) -> void:
	_mix_coord = coord
	_mix_timer = 0.4
	queue_redraw()

func _on_mix_rejected(coord: Vector2i, reason: String) -> void:
	_reject_coord = coord
	_reject_reason = reason
	_reject_timer = 0.3
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
		# Locked indicator: gold dot in top-right corner of the tile.
		if tile.locked:
			var half := TILE_SIZE / 2.0
			var cx: float = coord.x * TILE_SIZE
			var cy: float = coord.y * TILE_SIZE
			draw_circle(Vector2(cx + half - 5.0, cy - half + 5.0), 4.0, Color(1.0, 0.85, 0.0))

	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)

	# Mix success shimmer: white rect that expands outward and fades over 0.4s.
	if _mix_timer > 0.0:
		var t := _mix_timer / 0.4
		var alpha := t * 0.8
		var expand := (1.0 - t) * 8.0
		var half := TILE_SIZE / 2.0 + expand
		var cx := _mix_coord.x * TILE_SIZE
		var cy := _mix_coord.y * TILE_SIZE
		draw_rect(Rect2(cx - half, cy - half, half * 2.0, half * 2.0), Color(1.0, 1.0, 1.0, alpha))

	# Rejection overlay: color encodes the rejection reason.
	if _reject_timer > 0.0:
		var t := _reject_timer / 0.3
		var half := TILE_SIZE / 2.0
		var cx := _reject_coord.x * TILE_SIZE
		var cy := _reject_coord.y * TILE_SIZE
		var rect := Rect2(cx - half, cy - half, TILE_SIZE, TILE_SIZE)
		if _reject_reason == "same_type":
			# Yellow pulse: communicates "invalid mix" without implying permanence.
			draw_rect(rect, Color(1.0, 1.0, 0.0, 0.5 * t))
		else:
			# Red flash: communicates "this tile is complete / locked".
			draw_rect(rect, Color(1.0, 0.2, 0.2, 0.6 * t))

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
		BiomeType.Value.FOREST:     return Color(0.298, 0.686, 0.314)
		BiomeType.Value.WATER:      return Color(0.129, 0.588, 0.953)
		BiomeType.Value.STONE:      return Color(0.620, 0.620, 0.620)
		BiomeType.Value.EARTH:      return Color(0.757, 0.580, 0.376)
		BiomeType.Value.SWAMP:      return Color(0.25, 0.40, 0.20)
		BiomeType.Value.TUNDRA:     return Color(0.75, 0.88, 0.95)
		BiomeType.Value.MUDFLAT:    return Color(0.42, 0.28, 0.15)
		BiomeType.Value.MOSSY_CRAG: return Color(0.45, 0.52, 0.35)
		BiomeType.Value.SAVANNAH:   return Color(0.78, 0.65, 0.25)
		BiomeType.Value.CANYON:     return Color(0.72, 0.35, 0.18)
	return Color(0.502, 0.502, 0.502)
