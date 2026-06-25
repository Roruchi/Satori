## GameState — autoload singleton.
## Holds the live garden grid and currently-selected biome.
extends Node

const _GardenGridScript = preload("res://src/grid/GridMap.gd")
const _HexUtils = preload("res://src/grid/hex_utils.gd")
const _GodaiElement = preload("res://src/seeds/GodaiElement.gd")
const MATERIAL_OUTCOME_SUCCESS: StringName = &"success"
const MATERIAL_OUTCOME_MISSING_NODE: StringName = &"missing_node"
const MATERIAL_OUTCOME_ALREADY_COLLECTED: StringName = &"already_collected"
const MATERIAL_OUTCOME_INVENTORY_FULL: StringName = &"inventory_full"
const MATERIAL_STATE_READY: StringName = &"ready"
const MATERIAL_STATE_COLLECTED: StringName = &"collected"
const MATERIAL_LIVING_WOOD: StringName = &"living_wood"
const MATERIAL_REED_FIBER: StringName = &"reed_fiber"
const MATERIAL_SPIRIT_STONE: StringName = &"spirit_stone"
const MATERIAL_EMBER_CLAY: StringName = &"ember_clay"
const MATERIAL_BASE_TILE_SECONDS: float = 100.0
const MATERIAL_CAPACITY_BONUS_PER_STORAGE: int = 25
const MATERIAL_STRUCTURE_EFFECT_RADIUS: int = 1
const ESSENCE_CAPACITY_BONUS_PER_STRUCTURE: int = 1
const ESSENCE_GENERATOR_INTERVAL_SECONDS: float = 120.0

var grid: RefCounted       # GardenGrid instance
var selected_biome: int = BiomeType.Value.STONE
var _is_initialized: bool = false
var _material_spawn_accumulators: Dictionary = {}
var _material_spawn_counts: Dictionary = {}
var _essence_generator_accumulators: Dictionary = {}

signal tile_placed(coord: Vector2i, tile: GardenTile)
signal bloom_confirmed(coord: Vector2i, biome: int)
signal tile_mixed(coord: Vector2i, tile: GardenTile)
signal mix_rejected(coord: Vector2i, reason: String)
signal material_node_spawned(coord: Vector2i, material_id: StringName, amount: int)
signal material_node_harvested(coord: Vector2i, material_id: StringName, amount: int)
signal material_harvest_blocked(coord: Vector2i, reason: StringName)
signal structure_essence_generated(coord: Vector2i, structure_id: StringName, element_id: int, amount: int)

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	_initialize_fresh_garden()

func _initialize_fresh_garden() -> void:
	_material_spawn_accumulators.clear()
	_material_spawn_counts.clear()
	_essence_generator_accumulators.clear()
	grid = _GardenGridScript.new()
	var origin_tile: GardenTile = grid.place_tile(Vector2i.ZERO, BiomeType.Value.STONE)
	origin_tile.metadata["is_origin_shrine"] = true
	origin_tile.metadata["shrine_buildable"] = false
	origin_tile.metadata["shrine_built"] = true
	origin_tile.metadata["build_discovery_id"] = "disc_origin_shrine"
	tile_placed.emit(Vector2i.ZERO, origin_tile)

func _process(delta: float) -> void:
	evaluate_material_spawns(delta)
	evaluate_structure_essence_generators(delta)

func serialize_game_state() -> Dictionary:
	var serialized_tiles: Array[Dictionary] = []
	if grid != null:
		var coords: Array[Vector2i] = []
		for coord_variant: Variant in grid.tiles.keys():
			if coord_variant is Vector2i:
				coords.append(coord_variant as Vector2i)
		_sort_coords(coords)
		for coord: Vector2i in coords:
			var tile: GardenTile = grid.get_tile(coord)
			if tile == null:
				continue
			serialized_tiles.append({
				"coord": [coord.x, coord.y],
				"biome": tile.biome,
				"locked": tile.locked,
				"metadata": _to_json_safe_value(tile.metadata),
			})
	return {
		"selected_biome": selected_biome,
		"material_spawn_accumulators": _to_json_safe_value(_material_spawn_accumulators),
		"material_spawn_counts": _to_json_safe_value(_material_spawn_counts),
		"essence_generator_accumulators": _to_json_safe_value(_essence_generator_accumulators),
		"tiles": serialized_tiles,
	}

func restore_game_state(data: Dictionary) -> bool:
	var raw_tiles: Variant = data.get("tiles", [])
	if not (raw_tiles is Array):
		return false
	var restored_grid: RefCounted = _GardenGridScript.new()
	var tile_count: int = 0
	var bounds: Rect2i = Rect2i(0, 0, 0, 0)
	for raw_tile: Variant in raw_tiles:
		if not (raw_tile is Dictionary):
			continue
		var tile_data: Dictionary = raw_tile as Dictionary
		var coord: Vector2i = _coord_from_save_value(tile_data.get("coord", []))
		var tile: GardenTile = GardenTile.create(coord, int(tile_data.get("biome", BiomeType.Value.STONE)))
		tile.locked = bool(tile_data.get("locked", false))
		var metadata: Variant = _from_json_safe_value(tile_data.get("metadata", {}))
		if metadata is Dictionary:
			tile.metadata = metadata as Dictionary
		restored_grid.tiles[coord] = tile
		tile_count += 1
		if tile_count == 1:
			bounds = Rect2i(coord, Vector2i(1, 1))
		else:
			bounds = bounds.expand(coord)
	if tile_count <= 0:
		return false
	restored_grid.total_tile_count = tile_count
	restored_grid.garden_bounds = bounds
	restored_grid.compute_island_ids()
	grid = restored_grid
	selected_biome = int(data.get("selected_biome", BiomeType.Value.STONE))
	_material_spawn_accumulators = _dictionary_from_json_safe_value(data.get("material_spawn_accumulators", {}))
	_material_spawn_counts = _dictionary_from_json_safe_value(data.get("material_spawn_counts", {}))
	_essence_generator_accumulators = _dictionary_from_json_safe_value(data.get("essence_generator_accumulators", {}))
	return true

## Attempt to place the selected biome at coord.
## Returns true on success, false if placement is invalid.
func try_place_tile(coord: Vector2i) -> bool:
	if not grid.is_placement_valid(coord):
		return false
	var tile: GardenTile = grid.place_tile(coord, selected_biome)
	tile_placed.emit(coord, tile)
	return true

## Attempt to mix the selected biome into the existing tile at coord.
## Returns true on a successful mix, false on any rejection.
## Emits tile_mixed on success; emits mix_rejected with a reason string on failure.
func try_mix_tile(coord: Vector2i) -> bool:
	push_warning("try_mix_tile is deprecated")
	return false


func place_tile_from_seed(coord: Vector2i, biome: int, as_build_block: bool = false) -> void:
	var tile: GardenTile = grid.place_tile(coord, biome)
	tile.locked = as_build_block
	tile.metadata["is_build_block"] = as_build_block
	if as_build_block:
		tile.metadata["is_building_complete"] = false
		tile.metadata["build_completion_pending"] = true
		tile.metadata["build_countdown_started"] = false
		tile.metadata.erase("build_started_at")
		tile.metadata.erase("build_duration")
	tile_placed.emit(coord, tile)
	bloom_confirmed.emit(coord, biome)

func evaluate_material_spawns(delta_seconds: float) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = []
	if grid == null or delta_seconds <= 0.0:
		return spawned
	var scaled_delta_seconds: float = _progression_delta(delta_seconds)
	var active_cluster_keys: Dictionary = {}
	for cluster: Dictionary in _collect_material_spawn_clusters():
		var cluster_key: String = str(cluster.get("cluster_key", ""))
		if cluster_key.is_empty():
			continue
		active_cluster_keys[cluster_key] = true
		var tile_count: int = int(cluster.get("tile_count", 0))
		if tile_count <= 0:
			continue
		var effective_tile_count: int = tile_count + _material_spawn_speed_bonus(cluster)
		var interval_seconds: float = MATERIAL_BASE_TILE_SECONDS / float(maxi(1, effective_tile_count))
		var accumulated: float = float(_material_spawn_accumulators.get(cluster_key, 0.0)) + scaled_delta_seconds
		var spawnable_coords: Array[Vector2i] = []
		var spawnable_variant: Variant = cluster.get("spawnable_coords", [])
		if spawnable_variant is Array:
			for coord_variant: Variant in spawnable_variant:
				if coord_variant is Vector2i:
					spawnable_coords.append(coord_variant as Vector2i)
		if spawnable_coords.is_empty():
			_material_spawn_accumulators[cluster_key] = 0.0
			continue
		while accumulated >= interval_seconds and not spawnable_coords.is_empty():
			accumulated -= interval_seconds
			var coord: Vector2i = _choose_material_spawn_coord(cluster_key, spawnable_coords)
			var tile: GardenTile = grid.get_tile(coord)
			if tile == null:
				_remove_coord_from_material_candidates(spawnable_coords, coord)
				continue
			var material_node: Dictionary = _spawn_material_node_for_tile(coord, tile)
			if not material_node.is_empty():
				spawned.append(material_node.duplicate(true))
			_remove_coord_from_material_candidates(spawnable_coords, coord)
		if spawnable_coords.is_empty():
			accumulated = 0.0
		_material_spawn_accumulators[cluster_key] = accumulated
	for key_variant: Variant in _material_spawn_accumulators.keys():
		var key: String = str(key_variant)
		if not active_cluster_keys.has(key):
			_material_spawn_accumulators.erase(key)
			_material_spawn_counts.erase(key)
	return spawned

func _progression_delta(delta_seconds: float) -> float:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_method("scale_progress_delta"):
		return float(settings.scale_progress_delta(delta_seconds))
	return maxf(0.0, delta_seconds)

func get_material_node_at(coord: Vector2i) -> Dictionary:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return {}
	var node_variant: Variant = tile.metadata.get("material_node", null)
	if node_variant is Dictionary:
		return (node_variant as Dictionary).duplicate(true)
	return {}

func get_material_capacity_bonus(material_id: StringName) -> int:
	var bonus: int = 0
	if grid == null:
		return bonus
	for coord_variant: Variant in grid.tiles.keys():
		if not (coord_variant is Vector2i):
			continue
		var tile: GardenTile = grid.get_tile(coord_variant as Vector2i)
		var structure_id: StringName = _completed_structure_id(tile)
		if structure_id == &"":
			continue
		if _storage_material_for_structure(structure_id) == material_id:
			bonus += MATERIAL_CAPACITY_BONUS_PER_STORAGE
	return bonus

func get_element_capacity_bonus(element: int) -> int:
	var bonus: int = 0
	if grid == null:
		return bonus
	for coord_variant: Variant in grid.tiles.keys():
		if not (coord_variant is Vector2i):
			continue
		var tile: GardenTile = grid.get_tile(coord_variant as Vector2i)
		var structure_id: StringName = _completed_structure_id(tile)
		if structure_id == &"":
			continue
		if _essence_cap_element_for_structure(structure_id) == element:
			bonus += ESSENCE_CAPACITY_BONUS_PER_STRUCTURE
	return bonus

func evaluate_structure_essence_generators(delta_seconds: float) -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	if grid == null or delta_seconds <= 0.0:
		return generated
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("store_shrine_charge"):
		return generated
	var scaled_delta_seconds: float = _progression_delta(delta_seconds)
	var active_generator_keys: Dictionary = {}
	for coord_variant: Variant in grid.tiles.keys():
		if not (coord_variant is Vector2i):
			continue
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		var structure_id: StringName = _completed_structure_id(tile)
		if structure_id == &"":
			continue
		var element: int = _essence_generator_element_for_structure(structure_id)
		if element < 0:
			continue
		if alchemy.has_method("is_element_unlocked") and not bool(alchemy.is_element_unlocked(element)):
			continue
		var generator_key: String = _essence_generator_key(coord, structure_id, element)
		active_generator_keys[generator_key] = true
		var accumulated: float = float(_essence_generator_accumulators.get(generator_key, 0.0)) + scaled_delta_seconds
		while accumulated >= ESSENCE_GENERATOR_INTERVAL_SECONDS:
			accumulated -= ESSENCE_GENERATOR_INTERVAL_SECONDS
			if alchemy.store_shrine_charge(coord, element, 1):
				var entry: Dictionary = {
					"coord": coord,
					"structure_id": structure_id,
					"element": element,
					"amount": 1,
				}
				generated.append(entry)
				structure_essence_generated.emit(coord, structure_id, element, 1)
			else:
				accumulated = ESSENCE_GENERATOR_INTERVAL_SECONDS
				break
		_essence_generator_accumulators[generator_key] = accumulated
	for key_variant: Variant in _essence_generator_accumulators.keys():
		var key: String = str(key_variant)
		if not active_generator_keys.has(key):
			_essence_generator_accumulators.erase(key)
	return generated

func has_ready_material_at(coord: Vector2i) -> bool:
	var node: Dictionary = get_material_node_at(coord)
	return not node.is_empty() and StringName(str(node.get("state", &""))) == MATERIAL_STATE_READY

func harvest_material_at(coord: Vector2i, actor: StringName = &"player") -> Dictionary:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return _material_result(MATERIAL_OUTCOME_MISSING_NODE)
	var node_variant: Variant = tile.metadata.get("material_node", null)
	if not (node_variant is Dictionary):
		return _material_result(MATERIAL_OUTCOME_MISSING_NODE)
	var node: Dictionary = node_variant as Dictionary
	var state: StringName = StringName(str(node.get("state", &"")))
	var material_id: StringName = StringName(str(node.get("material_id", &"")))
	var amount: int = int(node.get("amount", 0))
	if state == MATERIAL_STATE_COLLECTED:
		material_harvest_blocked.emit(coord, MATERIAL_OUTCOME_ALREADY_COLLECTED)
		return _material_result(MATERIAL_OUTCOME_ALREADY_COLLECTED, material_id, amount)
	if state != MATERIAL_STATE_READY or amount <= 0 or material_id == &"":
		material_harvest_blocked.emit(coord, MATERIAL_OUTCOME_MISSING_NODE)
		return _material_result(MATERIAL_OUTCOME_MISSING_NODE, material_id, amount)
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("try_add_material") or not alchemy.try_add_material(material_id, amount):
		material_harvest_blocked.emit(coord, MATERIAL_OUTCOME_INVENTORY_FULL)
		return _material_result(MATERIAL_OUTCOME_INVENTORY_FULL, material_id, amount)
	tile.metadata.erase("material_node")
	material_node_harvested.emit(coord, material_id, amount)
	return _material_result(MATERIAL_OUTCOME_SUCCESS, material_id, amount)

func harvest_material_for_placement(coord: Vector2i) -> Dictionary:
	var result: Dictionary = harvest_material_at(coord, &"placement")
	var outcome: StringName = StringName(str(result.get("outcome", &"")))
	if outcome == MATERIAL_OUTCOME_INVENTORY_FULL:
		_clear_material_node_at(coord)
	return result

func _clear_material_node_at(coord: Vector2i) -> void:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return
	tile.metadata.erase("material_node")

func _collect_material_spawn_clusters() -> Array[Dictionary]:
	var clusters: Array[Dictionary] = []
	var visited: Dictionary = {}
	for coord_variant: Variant in grid.tiles.keys():
		if not (coord_variant is Vector2i):
			continue
		var start_coord: Vector2i = coord_variant as Vector2i
		if visited.has(start_coord):
			continue
		var start_tile: GardenTile = grid.get_tile(start_coord)
		if not _is_material_spawn_tile(start_tile):
			continue
		var start_def: Dictionary = _material_definition_for_biome(start_tile.biome)
		if start_def.is_empty():
			continue
		var material_id: StringName = StringName(str(start_def.get("material_id", &"")))
		if material_id == &"":
			continue
		var cluster_coords: Array[Vector2i] = []
		var spawnable_coords: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start_coord]
		var queue_index: int = 0
		visited[start_coord] = true
		while queue_index < queue.size():
			var coord: Vector2i = queue[queue_index]
			queue_index += 1
			cluster_coords.append(coord)
			var tile: GardenTile = grid.get_tile(coord)
			if tile != null and not _tile_has_ready_material(tile):
				spawnable_coords.append(coord)
			for neighbor: Vector2i in _HexUtils.get_neighbors(coord):
				if visited.has(neighbor):
					continue
				var neighbor_tile: GardenTile = grid.get_tile(neighbor)
				if not _is_material_spawn_tile(neighbor_tile):
					continue
				var neighbor_def: Dictionary = _material_definition_for_biome(neighbor_tile.biome)
				if StringName(str(neighbor_def.get("material_id", &""))) != material_id:
					continue
				visited[neighbor] = true
				queue.append(neighbor)
		_sort_material_coords(cluster_coords)
		_sort_material_coords(spawnable_coords)
		clusters.append({
			"cluster_key": _material_cluster_key(material_id, cluster_coords),
			"material_id": material_id,
			"tile_count": cluster_coords.size(),
			"coords": cluster_coords,
			"spawnable_coords": spawnable_coords,
		})
	return clusters

func _is_material_spawn_tile(tile: GardenTile) -> bool:
	if tile == null:
		return false
	if bool(tile.metadata.get("is_build_block", false)):
		return false
	if bool(tile.metadata.get("is_building_complete", false)):
		return false
	if bool(tile.metadata.get("is_origin_shrine", false)):
		return false
	if bool(tile.metadata.get("shrine_built", false)):
		return false
	if bool(tile.metadata.get("shrine_buildable", false)):
		return false
	return not _material_definition_for_biome(tile.biome).is_empty()

func _tile_has_ready_material(tile: GardenTile) -> bool:
	if tile == null:
		return false
	var node_variant: Variant = tile.metadata.get("material_node", null)
	if not (node_variant is Dictionary):
		return false
	var node: Dictionary = node_variant as Dictionary
	return StringName(str(node.get("state", &""))) == MATERIAL_STATE_READY

func _spawn_material_node_for_tile(coord: Vector2i, tile: GardenTile) -> Dictionary:
	if tile == null:
		return {}
	if not _is_material_spawn_tile(tile):
		return {}
	if _tile_has_ready_material(tile):
		return {}
	var material_def: Dictionary = _material_definition_for_biome(tile.biome)
	if material_def.is_empty():
		return {}
	var material_id: StringName = StringName(str(material_def.get("material_id", &"")))
	var visual_id: StringName = StringName(str(material_def.get("visual_id", &"")))
	if material_id == &"":
		return {}
	var node: Dictionary = {
		"node_id": StringName("material_%s_%d_%d" % [str(material_id), coord.x, coord.y]),
		"material_id": material_id,
		"amount": 1,
		"coord": coord,
		"visual_id": visual_id,
		"state": MATERIAL_STATE_READY,
		"spawned_at": Time.get_unix_time_from_system(),
	}
	tile.metadata["material_node"] = node
	material_node_spawned.emit(coord, material_id, 1)
	if _try_auto_harvest_material_node(coord, material_id, 1):
		var auto_node: Dictionary = node.duplicate(true)
		auto_node["state"] = MATERIAL_STATE_COLLECTED
		auto_node["auto_harvested"] = true
		return auto_node
	return node

func _try_auto_harvest_material_node(coord: Vector2i, material_id: StringName, amount: int) -> bool:
	if material_id != MATERIAL_LIVING_WOOD:
		return false
	if not _has_structure_near_coord(coord, &"building_wind_chime", MATERIAL_STRUCTURE_EFFECT_RADIUS):
		return false
	var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
	if alchemy == null or not alchemy.has_method("try_add_material"):
		return false
	if not alchemy.try_add_material(material_id, amount):
		return false
	_clear_material_node_at(coord)
	material_node_harvested.emit(coord, material_id, amount)
	return true

func _material_spawn_speed_bonus(cluster: Dictionary) -> int:
	var material_id: StringName = StringName(str(cluster.get("material_id", &"")))
	if material_id == &"":
		return 0
	var coords: Array[Vector2i] = []
	var coords_variant: Variant = cluster.get("coords", [])
	if coords_variant is Array:
		for coord_variant: Variant in coords_variant:
			if coord_variant is Vector2i:
				coords.append(coord_variant as Vector2i)
	if coords.is_empty():
		return 0
	var bonus: int = 0
	if material_id == MATERIAL_LIVING_WOOD and _has_structure_near_any_coord(coords, &"building_root_network", MATERIAL_STRUCTURE_EFFECT_RADIUS):
		bonus += 1
	if material_id == MATERIAL_EMBER_CLAY and _has_structure_near_any_coord(coords, &"building_kiln_heart", MATERIAL_STRUCTURE_EFFECT_RADIUS):
		bonus += 1
	return bonus

func _has_structure_near_any_coord(coords: Array[Vector2i], structure_id: StringName, radius: int) -> bool:
	for coord: Vector2i in coords:
		if _has_structure_near_coord(coord, structure_id, radius):
			return true
	return false

func _has_structure_near_coord(coord: Vector2i, structure_id: StringName, radius: int) -> bool:
	if grid == null:
		return false
	var candidates: Array[Vector2i] = [coord]
	if radius >= 1:
		for neighbor: Vector2i in _HexUtils.get_neighbors(coord):
			candidates.append(neighbor)
	for candidate: Vector2i in candidates:
		var tile: GardenTile = grid.get_tile(candidate)
		if _completed_structure_id(tile) == structure_id:
			return true
	return false

func _completed_structure_id(tile: GardenTile) -> StringName:
	if tile == null:
		return &""
	var completed: bool = bool(tile.metadata.get("is_building_complete", false)) or bool(tile.metadata.get("shrine_built", false))
	if not completed:
		return &""
	var structure_id: String = str(tile.metadata.get("structure_discovery_id", ""))
	if structure_id.is_empty():
		structure_id = str(tile.metadata.get("build_discovery_id", ""))
	if structure_id.is_empty():
		return &""
	return StringName(structure_id)

func _storage_material_for_structure(structure_id: StringName) -> StringName:
	match structure_id:
		&"building_dew_bowl":
			return MATERIAL_LIVING_WOOD
		&"building_reed_nest":
			return MATERIAL_REED_FIBER
		&"building_foundation_marker":
			return MATERIAL_SPIRIT_STONE
		&"building_hearth_stone":
			return MATERIAL_EMBER_CLAY
		_:
			return &""

func _essence_cap_element_for_structure(structure_id: StringName) -> int:
	match structure_id:
		&"building_dew_bowl", &"form_dew_bowl":
			return _GodaiElement.Value.FU
		&"building_reed_nest", &"form_reed_nest":
			return _GodaiElement.Value.SUI
		&"building_hearth_stone", &"form_hearth_stone":
			return _GodaiElement.Value.KA
		_:
			return -1

func _essence_generator_element_for_structure(structure_id: StringName) -> int:
	match structure_id:
		&"building_tiny_shrine", &"form_tiny_shrine":
			return _GodaiElement.Value.KU
		_:
			return -1

func _essence_generator_key(coord: Vector2i, structure_id: StringName, element: int) -> String:
	return "%d,%d:%s:%d" % [coord.x, coord.y, str(structure_id), element]

func _choose_material_spawn_coord(cluster_key: String, candidates: Array[Vector2i]) -> Vector2i:
	if candidates.is_empty():
		return Vector2i.ZERO
	var spawn_count: int = int(_material_spawn_counts.get(cluster_key, 0))
	var hash_value: int = abs(hash("%s:%d" % [cluster_key, spawn_count]))
	var index: int = hash_value % candidates.size()
	_material_spawn_counts[cluster_key] = spawn_count + 1
	return candidates[index]

func _remove_coord_from_material_candidates(candidates: Array[Vector2i], coord: Vector2i) -> void:
	for index: int in range(candidates.size()):
		if candidates[index] == coord:
			candidates.remove_at(index)
			return

func _material_cluster_key(material_id: StringName, coords: Array[Vector2i]) -> String:
	if coords.is_empty():
		return ""
	var anchor: Vector2i = coords[0]
	return "%s:%d,%d:%d" % [str(material_id), anchor.x, anchor.y, coords.size()]

func _sort_material_coords(coords: Array[Vector2i]) -> void:
	coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)

func _material_definition_for_biome(biome: int) -> Dictionary:
	match biome:
		BiomeType.Value.MEADOW, BiomeType.Value.CLOUD_RIDGE:
			return {"material_id": MATERIAL_LIVING_WOOD, "visual_id": &"living_wood_tree"}
		BiomeType.Value.RIVER, BiomeType.Value.WETLANDS, BiomeType.Value.MOONLIT_POOL, BiomeType.Value.PRISMATIC_TERRACES, BiomeType.Value.FROSTLANDS:
			return {"material_id": MATERIAL_REED_FIBER, "visual_id": &"water_fish_reeds"}
		BiomeType.Value.STONE, BiomeType.Value.SACRED_STONE, BiomeType.Value.BADLANDS, BiomeType.Value.WHISTLING_CANYONS:
			return {"material_id": MATERIAL_SPIRIT_STONE, "visual_id": &"spirit_stone_minerals"}
		BiomeType.Value.EMBER_FIELD, BiomeType.Value.EMBER_SHRINE, BiomeType.Value.THE_ASHFALL:
			return {"material_id": MATERIAL_EMBER_CLAY, "visual_id": &"ember_clay_shards"}
		_:
			return {}

func _material_result(outcome: StringName, material_id: StringName = &"", amount: int = 0) -> Dictionary:
	return {
		"outcome": outcome,
		"material_id": material_id,
		"amount": amount,
		"feedback_key": outcome,
	}

func _sort_coords(coords: Array[Vector2i]) -> void:
	coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)

func _to_json_safe_value(value: Variant) -> Variant:
	if value is Vector2i:
		var coord: Vector2i = value as Vector2i
		return {"__type": "Vector2i", "x": coord.x, "y": coord.y}
	if value is StringName:
		return str(value)
	if value is Dictionary:
		var result: Dictionary = {}
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			result[str(key)] = _to_json_safe_value(source[key])
		return result
	if value is Array:
		var array_result: Array = []
		var source_array: Array = value as Array
		for item: Variant in source_array:
			array_result.append(_to_json_safe_value(item))
		return array_result
	return value

func _from_json_safe_value(value: Variant) -> Variant:
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		if str(source.get("__type", "")) == "Vector2i":
			return Vector2i(int(source.get("x", 0)), int(source.get("y", 0)))
		var result: Dictionary = {}
		for key: Variant in source.keys():
			result[str(key)] = _from_json_safe_value(source[key])
		return result
	if value is Array:
		var array_result: Array = []
		var source_array: Array = value as Array
		for item: Variant in source_array:
			array_result.append(_from_json_safe_value(item))
		return array_result
	return value

func _dictionary_from_json_safe_value(value: Variant) -> Dictionary:
	var decoded: Variant = _from_json_safe_value(value)
	if decoded is Dictionary:
		return decoded as Dictionary
	return {}

func _coord_from_save_value(value: Variant) -> Vector2i:
	if value is Array:
		var coord_array: Array = value as Array
		if coord_array.size() >= 2:
			return Vector2i(int(coord_array[0]), int(coord_array[1]))
	if value is Dictionary:
		var decoded: Variant = _from_json_safe_value(value)
		if decoded is Vector2i:
			return decoded as Vector2i
	return Vector2i.ZERO
