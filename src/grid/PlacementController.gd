## PlacementController — translates mouse input into tile placement requests.
## Suppresses placement when a drag gesture was in progress (checked via CameraPanController).
## Long-press on an occupied tile triggers a mix attempt instead of placement.
extends Node2D

const _HexUtils = preload("res://src/grid/hex_utils.gd")
const TILE_RADIUS: float = 20.0
const LONG_PRESS_THRESHOLD_MS: float = 500.0
const _NO_PROJECT_ID: int = -1
const _BUILD_COUNTDOWN_SECONDS: float = 10.0
const _STRUCTURE_PAGODA_ID: String = "disc_lotus_pagoda"
const _STRUCTURE_WAYFARER_TORII_ID: String = "disc_wayfarer_torii"

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

	# Update the crafting build-mode anchor to the tile under the cursor.
	var cs: Node = get_node_or_null("/root/CraftingService")
	var active_bm: Variant = null
	if cs != null:
		active_bm = cs.get("active_build_mode")
	var in_crafting_build: bool = active_bm != null
	if in_crafting_build:
		active_bm.set_anchor(coord)

	# Long-press detection: fire once threshold is reached.
	# Fires on occupied tiles (mix) OR any tile when crafting build mode is active.
	if _pressing and (_press_on_occupied or in_crafting_build) and not _long_press_fired:
		if _camera_pan._was_drag:
			_pressing = false  # drag started — cancel long-press
		elif Time.get_ticks_msec() - _press_start_time >= int(LONG_PRESS_THRESHOLD_MS):
			_long_press_fired = true
			_on_long_press(_press_coord)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
			if _camera_pan.is_drag_gesture():
				return
			# Cancel crafting build mode on right-click.
			var cs: Node = get_node_or_null("/root/CraftingService")
			if cs != null:
				var active_bm: Variant = cs.get("active_build_mode")
				if active_bm != null:
					active_bm.cancel()
					return
			var right_coord := _world_to_tile(get_global_mouse_position())
			var right_hud: Node = get_node_or_null("../HUD")
			var right_build_mode: bool = right_hud != null and right_hud.has_method("is_build_mode") and right_hud.is_build_mode()
			if right_build_mode:
				_cancel_pending_build_block(right_coord)
			return
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
				if is_build_mode:
					# Build mode only applies to already-existing terrain tiles.
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
							return
				return

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
	var pending_project_id: int = _get_active_pending_project_id()
	var origin_shrine_build: bool = _is_origin_shrine_build_selection(tile)
	var torii_build: bool = _is_wayfarer_torii_build_selection(tile)
	if origin_shrine_build and not _can_place_origin_shrine_on_island(coord):
		return false
	var recipe_biome: int = int(GameState.selected_biome)
	if origin_shrine_build:
		recipe_biome = BiomeType.Value.MEADOW
	elif torii_build:
		recipe_biome = BiomeType.Value.STONE
	var recipe_index: int = pouch.find_index_by_biome(recipe_biome)
	var is_build_block: bool = bool(tile.metadata.get("is_build_block", false))
	var is_building_complete: bool = bool(tile.metadata.get("is_building_complete", false))
	# Completed structures are permanent and cannot become a new build target.
	if is_building_complete and not is_build_block:
		return false
	if is_build_block:
		# Completed houses are permanent structures and cannot be removed by tapping again.
		if is_building_complete:
			return false
		if _is_build_countdown_started(tile):
			# Countdown already started: permanence rule prevents cancellation/removal.
			return false
		var project_id: int = int(tile.metadata.get("build_project_id", _NO_PROJECT_ID))
		if pending_project_id != _NO_PROJECT_ID and project_id != pending_project_id:
			return false
		if not _try_start_project_countdown(project_id):
			return false
		if growth_service.has_method("notify_pouch_updated"):
			growth_service.notify_pouch_updated()
			return true
	var project_id_for_new_block: int = pending_project_id
	if project_id_for_new_block != _NO_PROJECT_ID:
		if not _is_adjacent_to_project(coord, project_id_for_new_block):
			return false
	else:
		project_id_for_new_block = _generate_project_id()
	if recipe_index < 0:
		return false
	var recipe: SeedRecipe = pouch.get_at(recipe_index)
	if recipe == null:
		return false
	var pending_structure_candidate: String = _resolve_structure_candidate_id(tile, recipe_biome)
	if project_id_for_new_block != _NO_PROJECT_ID and pending_structure_candidate.is_empty():
		# Only structure recipes can expand into multi-tile projects.
		return false
	pouch.consume_use_at(recipe_index)
	_mark_build_block_pending_confirm(tile, recipe_biome, origin_shrine_build, project_id_for_new_block, pending_structure_candidate)
	_refresh_project_recipe_state(project_id_for_new_block)
	if growth_service.has_method("notify_pouch_updated"):
		growth_service.notify_pouch_updated()
	return true

func _cancel_pending_build_block(coord: Vector2i) -> bool:
	if not GameState.grid.has_tile(coord):
		return false
	var tile: GardenTile = GameState.grid.get_tile(coord)
	if tile == null:
		return false
	var removed_project_id: int = int(tile.metadata.get("build_project_id", _NO_PROJECT_ID))
	if not bool(tile.metadata.get("is_build_block", false)):
		return false
	if bool(tile.metadata.get("is_building_complete", false)):
		return false
	if _is_build_countdown_started(tile):
		return false
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service == null or not growth_service.has_method("get_pouch"):
		return false
	var pouch: SeedPouch = growth_service.get_pouch()
	if pouch == null:
		return false
	var recipe_biome: int = int(tile.metadata.get("build_recipe_biome", tile.biome))
	var refund_recipe: SeedRecipe = _find_recipe_for_biome(recipe_biome)
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
	tile.metadata.erase("build_countdown_started")
	tile.metadata.erase("build_recipe_biome")
	tile.metadata.erase("build_project_id")
	tile.metadata.erase("pending_origin_shrine")
	tile.metadata.erase("pending_structure_candidate")
	tile.metadata.erase("pending_structure_id")
	tile.metadata.erase("pending_structure_anchor")
	tile.metadata.erase("project_recipe_required")
	tile.metadata.erase("project_recipe_valid")
	tile.metadata.erase("project_invalid_flash_started_at")
	_refresh_project_recipe_state(removed_project_id)
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

func _mark_build_block_pending_confirm(tile: GardenTile, recipe_biome: int, pending_origin_shrine: bool, project_id: int, pending_structure_candidate: String) -> void:
	tile.locked = true
	tile.metadata["is_build_block"] = true
	tile.metadata["is_building_complete"] = false
	tile.metadata["build_completion_pending"] = true
	tile.metadata["build_countdown_started"] = false
	tile.metadata["build_recipe_biome"] = recipe_biome
	tile.metadata["build_project_id"] = project_id
	tile.metadata["pending_origin_shrine"] = pending_origin_shrine
	if pending_structure_candidate.is_empty():
		tile.metadata.erase("pending_structure_candidate")
	else:
		tile.metadata["pending_structure_candidate"] = pending_structure_candidate
	tile.metadata.erase("build_started_at")
	tile.metadata.erase("build_duration")
	tile.metadata.erase("building_completed_at")
	tile.metadata.erase("pending_structure_id")
	tile.metadata.erase("pending_structure_anchor")
	tile.metadata.erase("project_invalid_flash_started_at")

func _is_origin_shrine_build_selection(tile: GardenTile) -> bool:
	if tile == null:
		return false
	if tile.biome != BiomeType.Value.STONE:
		return false
	# Reserve Ku selection for origin-shrine intent so Fu can always place normal houses.
	return int(GameState.selected_biome) == BiomeType.Value.KU

func _is_wayfarer_torii_build_selection(tile: GardenTile) -> bool:
	if tile == null:
		return false
	if tile.biome == BiomeType.Value.KU:
		return false
	return int(GameState.selected_biome) == BiomeType.Value.STONE

func _can_place_origin_shrine_on_island(coord: Vector2i) -> bool:
	var target_island: String = ""
	if GameState.grid != null and GameState.grid.has_method("get_island_id"):
		target_island = str(GameState.grid.get_island_id(coord))
	for coord_variant: Variant in GameState.grid.tiles.keys():
		var tile_coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = GameState.grid.get_tile(tile_coord)
		if tile == null:
			continue
		if not bool(tile.metadata.get("is_origin_shrine", false)):
			continue
		if target_island.is_empty():
			return false
		var existing_island: String = ""
		if GameState.grid.has_method("get_island_id"):
			existing_island = str(GameState.grid.get_island_id(tile_coord))
		if existing_island == target_island:
			return false
	return true

func _start_build_countdown(tile: GardenTile) -> void:
	tile.metadata["build_countdown_started"] = true
	tile.metadata["build_started_at"] = Time.get_unix_time_from_system()
	tile.metadata["build_duration"] = _BUILD_COUNTDOWN_SECONDS
	tile.metadata["build_completion_pending"] = true

func _try_start_project_countdown(project_id: int) -> bool:
	var project_coords: Array[Vector2i] = _get_project_coords(project_id, false)
	if project_coords.is_empty():
		return false
	var requires_recipe: bool = _project_requires_structure_recipe(project_coords)
	if not requires_recipe and project_coords.size() > 1:
		# Generic houses can only be confirmed one tile at a time.
		_mark_project_invalid_flash(project_coords)
		_refresh_project_recipe_state(project_id)
		return false
	var structure_id: String = ""
	if requires_recipe:
		structure_id = _resolve_project_structure_id(project_coords)
		if structure_id.is_empty():
			_mark_project_invalid_flash(project_coords)
			_refresh_project_recipe_state(project_id)
			return false
	_start_project_countdown(project_id, structure_id)
	return true

func _start_project_countdown(project_id: int, structure_id: String) -> void:
	if project_id == _NO_PROJECT_ID:
		return
	var project_coords: Array[Vector2i] = _get_project_coords(project_id, false)
	if project_coords.is_empty():
		return
	var structure_anchor: Vector2i = _lexicographic_min_coord(project_coords)
	var now: float = Time.get_unix_time_from_system()
	for coord: Vector2i in project_coords:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		tile.metadata["build_countdown_started"] = true
		tile.metadata["build_started_at"] = now
		tile.metadata["build_duration"] = _BUILD_COUNTDOWN_SECONDS
		tile.metadata["build_completion_pending"] = true
		tile.metadata.erase("project_recipe_required")
		tile.metadata.erase("project_recipe_valid")
		tile.metadata.erase("project_invalid_flash_started_at")
		if not structure_id.is_empty():
			tile.metadata["pending_structure_id"] = structure_id
			tile.metadata["pending_structure_anchor"] = coord == structure_anchor
		else:
			tile.metadata.erase("pending_structure_id")
			tile.metadata.erase("pending_structure_anchor")

func _get_active_pending_project_id() -> int:
	var found_project_id: int = _NO_PROJECT_ID
	for coord_variant: Variant in GameState.grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		if not bool(tile.metadata.get("is_build_block", false)):
			continue
		if bool(tile.metadata.get("is_building_complete", false)):
			continue
		if bool(tile.metadata.get("build_countdown_started", false)):
			continue
		var project_id: int = int(tile.metadata.get("build_project_id", _NO_PROJECT_ID))
		if project_id == _NO_PROJECT_ID:
			continue
		if found_project_id == _NO_PROJECT_ID:
			found_project_id = project_id
		elif found_project_id != project_id:
			return found_project_id
	return found_project_id

func _is_adjacent_to_project(coord: Vector2i, project_id: int) -> bool:
	for project_coord: Vector2i in _get_project_coords(project_id, false):
		for neighbor: Vector2i in _HexUtils.get_neighbors(project_coord):
			if neighbor == coord:
				return true
	return false

func _get_project_coords(project_id: int, include_countdown_started: bool) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord_variant: Variant in GameState.grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		if not bool(tile.metadata.get("is_build_block", false)):
			continue
		if bool(tile.metadata.get("is_building_complete", false)):
			continue
		if int(tile.metadata.get("build_project_id", _NO_PROJECT_ID)) != project_id:
			continue
		if not include_countdown_started and bool(tile.metadata.get("build_countdown_started", false)):
			continue
		coords.append(coord)
	return coords

func _generate_project_id() -> int:
	return int(Time.get_ticks_msec())

func _resolve_structure_candidate_id(tile: GardenTile, recipe_biome: int) -> String:
	if tile == null:
		return ""
	if recipe_biome == BiomeType.Value.STONE and _is_wayfarer_torii_build_selection(tile):
		return _STRUCTURE_WAYFARER_TORII_ID
	if recipe_biome == BiomeType.Value.MEADOW and tile.biome == BiomeType.Value.WETLANDS:
		return _STRUCTURE_PAGODA_ID
	return ""

func _resolve_project_structure_id(project_coords: Array[Vector2i]) -> String:
	if project_coords.size() == 3 and _all_project_tiles_match_candidate(project_coords, _STRUCTURE_WAYFARER_TORII_ID):
		if _forms_rotatable_u(project_coords):
			return _STRUCTURE_WAYFARER_TORII_ID
	if project_coords.size() != 4:
		return ""
	if not _all_project_tiles_match_candidate(project_coords, _STRUCTURE_PAGODA_ID):
		return ""
	if _forms_four_tile_parallelogram(project_coords):
		if not _is_structure_unlocked(_STRUCTURE_PAGODA_ID):
			return ""
		return _STRUCTURE_PAGODA_ID
	return ""

func _all_project_tiles_match_candidate(project_coords: Array[Vector2i], candidate_id: String) -> bool:
	for coord: Vector2i in project_coords:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			return false
		if str(tile.metadata.get("pending_structure_candidate", "")) != candidate_id:
			return false
	return true

func _forms_four_tile_parallelogram(project_coords: Array[Vector2i]) -> bool:
	var coord_set: Dictionary = {}
	for coord: Vector2i in project_coords:
		coord_set[coord] = true
	for origin: Vector2i in project_coords:
		for dir_a: Vector2i in _HexUtils.HEX_NEIGHBORS:
			for dir_b: Vector2i in _HexUtils.HEX_NEIGHBORS:
				if dir_b == dir_a:
					continue
				if dir_b == -dir_a:
					continue
				var p1: Vector2i = origin + dir_a
				var p2: Vector2i = origin + dir_b
				var p3: Vector2i = origin + dir_a + dir_b
				if coord_set.has(origin) and coord_set.has(p1) and coord_set.has(p2) and coord_set.has(p3):
					return true
	return false

func _forms_rotatable_u(project_coords: Array[Vector2i]) -> bool:
	if project_coords.size() != 3:
		return false
	var coord_set: Dictionary = {}
	for coord: Vector2i in project_coords:
		coord_set[coord] = true
	var pivot: Vector2i = Vector2i.ZERO
	var found_pivot: bool = false
	for coord: Vector2i in project_coords:
		var degree: int = 0
		for neighbor_delta: Vector2i in _HexUtils.HEX_NEIGHBORS:
			if coord_set.has(coord + neighbor_delta):
				degree += 1
		if degree == 2:
			pivot = coord
			found_pivot = true
		elif degree != 1:
			return false
	if not found_pivot:
		return false
	var neighbor_dirs: Array[Vector2i] = []
	for neighbor_delta: Vector2i in _HexUtils.HEX_NEIGHBORS:
		var neighbor_coord: Vector2i = pivot + neighbor_delta
		if coord_set.has(neighbor_coord):
			neighbor_dirs.append(neighbor_delta)
	if neighbor_dirs.size() != 2:
		return false
	# Reject straight 3-in-line; U-shape requires a bend at the pivot.
	if neighbor_dirs[0] == -neighbor_dirs[1]:
		return false
	return true

func _is_structure_unlocked(discovery_id: String) -> bool:
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence == null or not persistence.has_method("get_discovered_ids"):
		return false
	var ids: Array[String] = persistence.get_discovered_ids()
	return ids.has(discovery_id)

func _lexicographic_min_coord(coords: Array[Vector2i]) -> Vector2i:
	if coords.is_empty():
		return Vector2i.ZERO
	var sorted: Array[Vector2i] = coords.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	return sorted[0]

func _project_requires_structure_recipe(project_coords: Array[Vector2i]) -> bool:
	if project_coords.size() == 3 and _all_project_tiles_match_candidate(project_coords, _STRUCTURE_WAYFARER_TORII_ID):
		return true
	if project_coords.size() == 4 and _all_project_tiles_match_candidate(project_coords, _STRUCTURE_PAGODA_ID):
		return true
	return false

func _refresh_project_recipe_state(project_id: int) -> void:
	if project_id == _NO_PROJECT_ID:
		return
	var project_coords: Array[Vector2i] = _get_project_coords(project_id, false)
	if project_coords.is_empty():
		return
	var requires_recipe: bool = _project_requires_structure_recipe(project_coords)
	var valid_recipe: bool = false
	if requires_recipe:
		valid_recipe = not _resolve_project_structure_id(project_coords).is_empty()
	for coord: Vector2i in project_coords:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		tile.metadata["project_recipe_required"] = requires_recipe
		tile.metadata["project_recipe_valid"] = valid_recipe

func _mark_project_invalid_flash(project_coords: Array[Vector2i]) -> void:
	var now: float = Time.get_unix_time_from_system()
	for coord: Vector2i in project_coords:
		var tile: GardenTile = GameState.grid.get_tile(coord)
		if tile == null:
			continue
		tile.metadata["project_invalid_flash_started_at"] = now

func _is_build_countdown_started(tile: GardenTile) -> bool:
	return bool(tile.metadata.get("build_countdown_started", false))

func _on_long_press(coord: Vector2i) -> void:
	# If crafting build mode is active, long-press confirms the placement.
	var cs: Node = get_node_or_null("/root/CraftingService")
	if cs != null:
		var active_bm: Variant = cs.get("active_build_mode")
		if active_bm != null:
			active_bm.set_anchor(coord)
			if active_bm.can_confirm():
				active_bm.confirm()
			return
	# Fall through: long-press on an occupied tile attempts a biome mix (legacy).
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
