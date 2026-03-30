## GhostFootprint — renders the placement preview overlay during Build Mode.
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 20.0

var _validation: Array = []

## Called by CraftingService.active_build_mode.validation_updated signal.
func update_from_validation(results: Array) -> void:
	_validation = results
	queue_redraw()

func _draw() -> void:
	for entry: Variant in _validation:
		var d: Dictionary = entry as Dictionary
		var world_coord: Vector2i = d.get("world_coord", Vector2i.ZERO) as Vector2i
		var valid: bool = bool(d.get("valid", false))
		var error: String = str(d.get("error", ""))
		var pixel_pos: Vector2 = _HexUtils.axial_to_pixel(world_coord, TILE_RADIUS)
		var poly: PackedVector2Array = _hex_polygon(pixel_pos, TILE_RADIUS)
		if valid:
			draw_colored_polygon(poly, Color(0.2, 0.8, 0.2, 0.45))
		else:
			draw_colored_polygon(poly, Color(0.9, 0.1, 0.1, 0.45))
			if error != "":
				draw_string(
					ThemeDB.fallback_font,
					pixel_pos + Vector2(-30.0, 4.0),
					error,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					10,
					Color.WHITE
				)

static func _hex_polygon(centre: Vector2, radius: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(6):
		var angle_deg: float = -90.0 + 60.0 * float(i)
		var angle_rad: float = deg_to_rad(angle_deg)
		pts.append(centre + Vector2(cos(angle_rad), sin(angle_rad)) * radius)
	return pts
