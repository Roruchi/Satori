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
				var is_plant_or_build_mode: bool = true
				var is_build_mode: bool = false
				if hud != null:
					var is_plant_mode: bool = hud.has_method("is_plant_mode") and hud.is_plant_mode()
					is_build_mode = hud.has_method("is_build_mode") and hud.is_build_mode()
					is_plant_or_build_mode = is_plant_mode or is_build_mode
				if not is_plant_or_build_mode:
					if hud != null and hud.has_method("is_interact_mode") and hud.is_interact_mode():
						_collect_spirit_charge(coord)
					return
				if is_build_mode and _try_build_shrine(coord):
					return
				if is_build_mode and _toggle_build_block(coord):
					return
				if is_build_mode and _place_build_block_on_empty(coord):
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
						if growth_service.try_plant(coord, recipe, is_build_mode):
							pouch.consume_use_at(recipe_index)
							if growth_service.has_method("notify_pouch_updated"):
								growth_service.notify_pouch_updated()
							if growth_service.has_method("get_mode") and int(growth_service.get_mode()) == GrowthModeScript.Value.INSTANT:
								growth_service.try_bloom(coord)
							return
				return

func _place_build_block_on_empty(coord: Vector2i) -> bool:
	if GameState.grid.has_tile(coord):
		return false
	if not GameState.grid.is_placement_valid(coord):
		return false
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_pouch"):
		return false
	var pouch: SeedPouch = growth_service.get_pouch()
	if pouch == null:
		return false
	var selected_biome: int = int(GameState.selected_biome)
	var recipe_index: int = pouch.find_index_by_biome(selected_biome)
	if recipe_index < 0:
		return false
	var recipe: SeedRecipe = pouch.get_at(recipe_index)
	if recipe == null:
		return false
	pouch.consume_use_at(recipe_index)
	GameState.place_tile_from_seed(coord, recipe.produces_biome, true)
	if growth_service.has_method("notify_pouch_updated"):
		growth_service.notify_pouch_updated()
	return true

func _toggle_build_block(coord: Vector2i) -> bool:
	if not GameState.grid.has_tile(coord):
		return false
	var tile: GardenTile = GameState.grid.get_tile(coord)
	if tile == null:
		return false
	# Shrine anchors are handled separately by _try_build_shrine.
	if bool(tile.metadata.get("shrine_buildable", false)) or bool(tile.metadata.get("shrine_built", false)):
		return false
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_pouch"):
		return false
	var pouch: SeedPouch = growth_service.get_pouch()
	if pouch == null:
		return false
	var target_biome: int = tile.biome
	var recipe_index: int = pouch.find_index_by_biome(target_biome)
	var is_build_block: bool = bool(tile.metadata.get("is_build_block", false))
	if is_build_block:
		var refund_recipe: SeedRecipe = null
		if recipe_index >= 0:
			refund_recipe = pouch.get_at(recipe_index)
		if refund_recipe == null:
			refund_recipe = _find_recipe_for_biome(target_biome)
		if refund_recipe == null:
			return false
		if not pouch.add(refund_recipe, 1):
			return false
		tile.locked = false
		tile.metadata["is_build_block"] = false
		tile.metadata.erase("build_started_at")
		tile.metadata.erase("build_duration")
		tile.metadata.erase("is_building_complete")
		tile.metadata.erase("building_completed_at")
		tile.metadata.erase("build_completion_pending")
		if growth_service.has_method("notify_pouch_updated"):
			growth_service.notify_pouch_updated()
		return true
	if recipe_index < 0:
		return false
	var recipe: SeedRecipe = pouch.get_at(recipe_index)
	if recipe == null:
		return false
	pouch.consume_use_at(recipe_index)
	tile.locked = true
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_started_at"] = Time.get_unix_time_from_system()
	tile.metadata["build_duration"] = 10.0
	tile.metadata["build_completion_pending"] = true
	if growth_service.has_method("notify_pouch_updated"):
		growth_service.notify_pouch_updated()
	return true

func _find_recipe_for_biome(target_biome: int) -> SeedRecipe:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("get_registry"):
		return null
	var registry: SeedRecipeRegistry = alchemy.get_registry()
	if registry == null or not registry.has_method("all_known_recipes"):
		return null
	for recipe: SeedRecipe in registry.all_known_recipes():
		if recipe != null and int(recipe.produces_biome) == target_biome:
			return recipe
	return null

func _on_long_press(coord: Vector2i) -> void:
	GameState.try_mix_tile(coord)

func _collect_spirit_charge(coord: Vector2i) -> void:
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("collect_shrine_charge"):
		return
	alchemy.collect_shrine_charge(coord)

func _try_build_shrine(coord: Vector2i) -> bool:
	if not GameState.grid.has_tile(coord):
		return false
	var tile: GardenTile = GameState.grid.get_tile(coord)
	if tile == null:
		return false
	if not bool(tile.metadata.get("shrine_buildable", false)):
		return false
	if bool(tile.metadata.get("shrine_built", false)):
		return false
	tile.metadata["shrine_built"] = true
	var discovery_id: String = str(tile.metadata.get("build_discovery_id", ""))
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if not discovery_id.is_empty() and satori_service != null and satori_service.has_method("can_build_structure"):
		if not satori_service.can_build_structure(discovery_id):
			if satori_service.has_method("block_structure_build"):
				satori_service.block_structure_build(discovery_id, "unique_already_built")
			tile.metadata["shrine_built"] = false
			return false
	if not discovery_id.is_empty():
		var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
		if persistence != null and persistence.has_method("record_discovery"):
			var payload: DiscoveryPayload = DiscoveryPayload.create(discovery_id, [coord], {"display_name": discovery_id, "flavor_text": "", "audio_key": ""})
			persistence.record_discovery(payload)
		if satori_service != null and satori_service.has_method("apply_monument_on_build"):
			satori_service.apply_monument_on_build(discovery_id)
	return true
