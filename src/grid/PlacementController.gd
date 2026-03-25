## PlacementController — translates mouse input into tile placement requests.
## Suppresses placement when a drag gesture was in progress (checked via CameraPanController).
## Long-press on an occupied tile triggers a mix attempt instead of placement.
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")
const TILE_RADIUS: float = 20.0
const LONG_PRESS_THRESHOLD_MS: float = 500.0

@onready var _garden_view: Node2D = $"../GardenView"
@onready var _camera_pan: Node2D = $"../CameraPanController"

# --- long-press state ---
var _pressing: bool = false
var _press_start_time: int = 0
var _press_coord: Vector2i = Vector2i.ZERO
var _press_on_occupied: bool = false
var _long_press_fired: bool = false

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return _HexUtils.pixel_to_axial(world_pos, TILE_RADIUS)

func _process(_delta: float) -> void:
	var coord := _world_to_tile(get_global_mouse_position())
	var valid: bool = GameState.grid.is_placement_valid(coord)
	var mix: bool = not valid and GameState.grid.has_tile(coord)
	_garden_view.set_hover(coord, valid, mix)

	# Long-press detection: fire once threshold is reached on an occupied tile.
	if _pressing and _press_on_occupied and not _long_press_fired:
		if _camera_pan._was_drag:
			_pressing = false  # drag started — cancel long-press
		elif Time.get_ticks_msec() - _press_start_time >= int(LONG_PRESS_THRESHOLD_MS):
			_long_press_fired = true
			_on_long_press(_press_coord)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var coord := _world_to_tile(get_global_mouse_position())
				_pressing = true
				_press_start_time = Time.get_ticks_msec()
				_press_coord = coord
				_press_on_occupied = GameState.grid.has_tile(coord)
				_long_press_fired = false
			else:
				_pressing = false
				if _camera_pan.is_drag_gesture():
					return
				if _long_press_fired:
					return  # long-press already handled; skip normal tap placement
				var coord := _world_to_tile(get_global_mouse_position())
				var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
				if growth_service != null and growth_service.has_method("get_pouch"):
					if growth_service.has_method("try_bloom") and growth_service.has_method("get_tracker"):
						var tracker: GrowthSlotTracker = growth_service.get_tracker()
						if tracker != null and tracker.get_at(coord) != null:
							growth_service.try_bloom(coord)
							return
				var hud: Node = get_node_or_null("../HUD")
				if hud != null and hud.has_method("is_plant_mode") and not hud.is_plant_mode():
					return
				if growth_service != null and growth_service.has_method("get_pouch"):
					var pouch: SeedPouch = growth_service.get_pouch()
					if pouch != null:
						var selected_biome: int = int(GameState.selected_biome)
						var recipe_index: int = pouch.find_index_by_biome(selected_biome)
						if recipe_index < 0:
							return
						var recipe: SeedRecipe = pouch.get_at(recipe_index)
						if recipe == null:
							return
						if not GameState.grid.is_placement_valid(coord):
							return
						if growth_service.try_plant(coord, recipe):
							pouch.consume_use_at(recipe_index)
							if growth_service.has_method("notify_pouch_updated"):
								growth_service.notify_pouch_updated()
							if growth_service.has_method("get_mode") and int(growth_service.get_mode()) == GrowthModeScript.Value.INSTANT:
								growth_service.try_bloom(coord)
							return
				return

func _on_long_press(coord: Vector2i) -> void:
	GameState.try_mix_tile(coord)
