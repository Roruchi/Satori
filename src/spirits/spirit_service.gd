class_name SpiritService
extends Node

signal spirit_summoned(spirit_id: String, instance: SpiritInstance)
signal spirit_despawned(spirit_id: String)
signal riddle_hint_triggered(spirit_id: String, riddle_text: String)
signal sky_whale_event_triggered()
signal building_completed(coord: Vector2i, biome: int)

const _PatternLoaderScript = preload("res://src/biomes/pattern_loader.gd")
const _PatternMatcherScript = preload("res://src/biomes/pattern_matcher.gd")
const _GridMapScript = preload("res://src/grid/GridMap.gd")
const _SpiritGiftProcessorScript = preload("res://src/spirits/SpiritGiftProcessor.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const SatoriConditionEvaluatorScript = preload("res://src/satori/SatoriConditionEvaluator.gd")
const BUILD_COMPLETION_SECONDS: float = 10.0
const ESSENCE_CHARGE_SECONDS: float = 60.0
const BUILD_FINALIZE_TICK_SECONDS: float = 0.25
const ESSENCE_CHARGE_TICK_SECONDS: float = 1.0
const STILLNESS_SPIRIT_HOUSING_BUFFER: int = 2
const AWAKENING_SPIRIT_HOUSING_BUFFER: int = 4
const SETTLE_HINT_TEXT: String = "A presence lingers at the edge of the island. A dwelling would help it settle."
const _UPGRADED_HOUSES_BY_SPIRIT: Dictionary = {
	"spirit_red_fox": ["building_fox_den"],
}

var _catalog: SpiritCatalog
var _spawner: SpiritSpawner
var _riddle_evaluator: SpiritRiddleEvaluator
var _sky_whale_evaluator: SkyWhaleEvaluator
## Keyed by compound key "island_{island_id}|spirit_{spirit_id}" when island_id
## is known, or bare spirit_id for spirits without island scope (e.g. Sky Whale).
var _active_instances: Dictionary = {}
var _active_wanderers: Dictionary = {}
var _next_essence_drop_at: Dictionary = {}
var _riddle_shown: Dictionary = {}
var _house_binding_by_spirit: Dictionary = {}
var _spirit_patterns: Array[PatternDefinition] = []
var _current_era: StringName = &"stillness"
var _pending_build_coords: Dictionary = {}
var _building_finalize_timer: Timer = null
var _essence_charge_timer: Timer = null
var _uses_global_spirit_discovery_scan: bool = false
var _housing_cache: Dictionary = {}
var _housing_cache_dirty: bool = true
var _housing_recompute_count: int = 0
var _settle_hint_shown: Dictionary = {}

func _ready() -> void:
	set_process(false)
	_catalog = SpiritCatalog.new()
	_catalog.load_from_data(SpiritCatalogData.new())
	_riddle_evaluator = SpiritRiddleEvaluator.new()
	_sky_whale_evaluator = SkyWhaleEvaluator.new()
	_spawner = SpiritSpawner.new()
	var loader: PatternLoader = _PatternLoaderScript.new()
	_spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)
		_uses_global_spirit_discovery_scan = _is_runtime_garden_service()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("tile_placed"):
		game_state.tile_placed.connect(_on_tile_placed)
	call_deferred("_setup_spawner")
	call_deferred("restore_from_persistence")
	call_deferred("_connect_soundscape")
	if _is_runtime_garden_service():
		_install_runtime_timers()
		_collect_pending_building_coords_once()
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if satori_service != null and satori_service.has_signal("era_changed"):
		satori_service.era_changed.connect(_on_era_changed)
		if satori_service.has_method("get_current_era"):
			_current_era = satori_service.get_current_era()
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_signal("growth_speed_multiplier_changed"):
		settings.growth_speed_multiplier_changed.connect(_on_progression_speed_changed)

func _install_runtime_timers() -> void:
	_building_finalize_timer = Timer.new()
	_building_finalize_timer.wait_time = BUILD_FINALIZE_TICK_SECONDS
	_building_finalize_timer.one_shot = false
	_building_finalize_timer.autostart = true
	_building_finalize_timer.timeout.connect(_finalize_tracked_pending_buildings)
	add_child(_building_finalize_timer)

	_essence_charge_timer = Timer.new()
	_essence_charge_timer.wait_time = ESSENCE_CHARGE_TICK_SECONDS
	_essence_charge_timer.one_shot = false
	_essence_charge_timer.autostart = true
	_essence_charge_timer.timeout.connect(_process_essence_charge_timers)
	add_child(_essence_charge_timer)

func register_pending_building(coord: Vector2i) -> void:
	_pending_build_coords[_coord_to_key(coord)] = coord

func _is_runtime_garden_service() -> bool:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return false
	return parent_node.name == "Garden" or parent_node.name == "VoxelGarden"

func set_spawner_parent(parent: Node) -> void:
	_spawner.set_parent(parent)

func _connect_soundscape() -> void:
	if not is_inside_tree():
		return
	var soundscape: Node = get_node_or_null("/root/SoundscapeEngine")
	if soundscape != null and soundscape.has_method("on_spirit_summoned") \
			and not spirit_summoned.is_connected(soundscape.on_spirit_summoned):
		spirit_summoned.connect(soundscape.on_spirit_summoned)

func _setup_spawner() -> void:
	var garden_view: Node = get_node_or_null("../GardenView")
	if garden_view == null:
		return
	var spirit_layer: Node2D = garden_view.get_node_or_null("SpiritLayer2D")
	if spirit_layer == null:
		spirit_layer = Node2D.new()
		spirit_layer.name = "SpiritLayer2D"
		garden_view.add_child(spirit_layer)
	_spawner.set_parent(spirit_layer)

func restore_from_persistence() -> void:
	if not is_inside_tree():
		return
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence == null:
		return
	for data: Dictionary in persistence.get_instances():
		var instance: SpiritInstance = SpiritInstance.deserialize(data)
		if instance.spirit_id.is_empty():
			continue
		var key: String = _spirit_key(instance.spirit_id, instance.island_id)
		_active_instances[key] = instance
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		var wanderer: Node = _spawner.spawn(instance, entry)
		_active_wanderers[key] = wanderer
		_next_essence_drop_at[key] = Time.get_unix_time_from_system() + _progression_duration(ESSENCE_CHARGE_SECONDS)
		var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
		if ecology != null and ecology.has_method("register_wanderer"):
			ecology.register_wanderer(wanderer)

func _on_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	if not discovery_id.begins_with("spirit_"):
		return
	if discovery_id == SkyWhaleEvaluator.SPIRIT_ID:
		return  # Sky Whale is triggered by tile_placed balance check, not by PatternMatcher
	var island_id: String = _island_for_coords(triggering_coords)
	var game_state: Node = get_node_or_null("/root/GameState")
	var grid: RefCounted = _grid_from_game_state(game_state)
	if _is_spirit_active_on_island(discovery_id, island_id, grid):
		return
	if not _can_spawn_under_era_pacing(discovery_id, island_id):
		_emit_settle_hint_once(discovery_id, island_id)
		return
	_summon_spirit(discovery_id, triggering_coords, island_id)

func _summon_spirit(spirit_id: String, coords: Array[Vector2i], island_id: String = "") -> void:
	if not _can_spawn_in_current_era(spirit_id):
		return
	var entry: Dictionary = _catalog.lookup(spirit_id)
	var wander_radius: int = int(entry.get("wander_radius", 4))
	var bounds: Rect2i = SpiritWanderBounds.from_coords(coords, wander_radius)
	var spawn: Vector2i = SpiritWanderBounds.centroid(coords)
	var instance: SpiritInstance = SpiritInstance.create(spirit_id, spawn, bounds)
	instance.island_id = island_id
	var key: String = _spirit_key(spirit_id, island_id)
	_active_instances[key] = instance
	_next_essence_drop_at[key] = Time.get_unix_time_from_system() + _progression_duration(ESSENCE_CHARGE_SECONDS)
	mark_housing_dirty()
	if _is_ku_deity_spirit(spirit_id):
		_maybe_mark_shrine_buildable(instance)
	var wanderer: Node = _spawner.spawn(instance, entry)
	_active_wanderers[key] = wanderer
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		var grid: RefCounted = _grid_from_game_state(game_state)
		if grid != null and grid.has_method("get_tile"):
			var spawn_tile: GardenTile = grid.get_tile(spawn)
			if spawn_tile != null:
				spawn_tile.metadata["spirit_id"] = spirit_id
	_SpiritGiftProcessorScript.process(spirit_id, entry)
	var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
	if ecology != null and ecology.has_method("register_wanderer"):
		ecology.register_wanderer(wanderer)
	spirit_summoned.emit(spirit_id, instance)
	var codex: Node = get_node_or_null("/root/CodexService")
	if codex != null and codex.has_method("mark_discovered"):
		codex.mark_discovered(StringName(spirit_id))
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)

func _on_tile_placed(coord: Vector2i, _tile: GardenTile) -> void:
	if not is_inside_tree():
		return
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null:
		return
	mark_housing_dirty()
	_refresh_active_instance_islands(grid)
	if _sky_whale_evaluator.evaluate(grid) and not _active_instances.has(SkyWhaleEvaluator.SPIRIT_ID):
		_summon_sky_whale(grid)
	if not _uses_global_spirit_discovery_scan:
		_try_spawn_spirits_for_island(coord, grid)
	_evaluate_riddle_hints(grid)

func _refresh_active_instance_islands(grid: RefCounted) -> void:
	if grid == null or not grid.has_method("get_island_id"):
		return
	var next_instances: Dictionary = {}
	var next_wanderers: Dictionary = {}
	var next_drop_times: Dictionary = {}
	var next_bindings: Dictionary = {}
	for old_key_variant: Variant in _active_instances.keys():
		var old_key: String = str(old_key_variant)
		var instance: SpiritInstance = _active_instances.get(old_key, null)
		if instance == null:
			continue
		var island_id: String = instance.island_id
		if instance.spirit_id != SkyWhaleEvaluator.SPIRIT_ID:
			var current_island: String = str(grid.get_island_id(instance.spawn_coord))
			if not current_island.is_empty():
				island_id = current_island
		instance.island_id = island_id
		var new_key: String = _spirit_key(instance.spirit_id, island_id)
		next_instances[new_key] = instance
		var wanderer: Node = _active_wanderers.get(old_key, null)
		if wanderer != null:
			next_wanderers[new_key] = wanderer
			if wanderer.has_method("set_island_id"):
				wanderer.set_island_id(island_id)
		next_drop_times[new_key] = float(_next_essence_drop_at.get(old_key, Time.get_unix_time_from_system() + _progression_duration(ESSENCE_CHARGE_SECONDS)))
		if _house_binding_by_spirit.has(old_key):
			next_bindings[new_key] = _house_binding_by_spirit[old_key]
	_active_instances = next_instances
	_active_wanderers = next_wanderers
	_next_essence_drop_at = next_drop_times
	_house_binding_by_spirit = next_bindings
	mark_housing_dirty()

func _try_spawn_spirits_for_island(coord: Vector2i, grid: RefCounted) -> void:
	if grid == null or not grid.has_method("get_island_id") or not grid.has_method("get_tile"):
		return
	var island_id: String = str(grid.get_island_id(coord))
	if island_id.is_empty():
		return
	var island_grid: RefCounted = _build_island_grid(grid, island_id)
	if island_grid == null or island_grid.tiles.is_empty():
		return
	var matcher: PatternMatcher = _PatternMatcherScript.new()
	matcher.set_patterns(_spirit_patterns)
	var registry: DiscoveryRegistry = DiscoveryRegistry.new()
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence != null and persistence.has_method("get_discovered_ids"):
		var ids: Array[String] = persistence.get_discovered_ids()
		if not ids.is_empty():
			registry.mark_discoveries(ids)
	matcher.set_discovery_registry(registry)
	var matches: Array[DiscoverySignal] = matcher.scan_grid(island_grid)
	for payload: DiscoverySignal in matches:
		var spirit_id: String = payload.discovery_id
		if not spirit_id.begins_with("spirit_") or spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
			continue
		if _is_spirit_active_on_island(spirit_id, island_id, grid):
			continue
		if not _can_spawn_under_era_pacing(spirit_id, island_id):
			_emit_settle_hint_once(spirit_id, island_id)
			continue
		_summon_spirit(spirit_id, payload.triggering_coords, island_id)

func _build_island_grid(grid: RefCounted, island_id: String) -> RefCounted:
	var island_grid: RefCounted = _GridMapScript.new()
	for coord_variant: Variant in grid.tiles.keys():
		var tile_coord: Vector2i = coord_variant as Vector2i
		if str(grid.get_island_id(tile_coord)) != island_id:
			continue
		var tile: GardenTile = grid.get_tile(tile_coord)
		if tile == null:
			continue
		island_grid.place_tile(tile_coord, tile.biome)
	return island_grid

func _evaluate_riddle_hints(grid: RefCounted) -> void:
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	var registry: DiscoveryRegistry = DiscoveryRegistry.new()
	if persistence != null and persistence.has_method("get_discovered_ids"):
		var ids: Array[String] = persistence.get_discovered_ids()
		registry.mark_discoveries(ids)
	for pattern: PatternDefinition in _spirit_patterns:
		var sid: String = pattern.discovery_id
		# Skip if spirit is already active on any island — riddle hint no longer relevant.
		if _is_spirit_active_anywhere(sid):
			continue
		if _riddle_shown.has(sid):
			continue
		if _riddle_evaluator.evaluate_partial(pattern, grid, registry):
			_riddle_shown[sid] = true
			var entry: Dictionary = _catalog.lookup(sid)
			var riddle: String = str(entry.get("riddle_text", ""))
			riddle_hint_triggered.emit(sid, riddle)

func _summon_sky_whale(grid: RefCounted) -> void:
	var bounds: Rect2i = grid.garden_bounds
	var center: Vector2i = bounds.position + bounds.size / 2
	var entry: Dictionary = _catalog.lookup(SkyWhaleEvaluator.SPIRIT_ID)
	var wander_radius: int = int(entry.get("wander_radius", 50))
	var expanded_bounds: Rect2i = Rect2i(
		bounds.position - Vector2i(wander_radius, wander_radius),
		bounds.size + Vector2i(wander_radius * 2, wander_radius * 2)
	)
	var instance: SpiritInstance = SpiritInstance.create(SkyWhaleEvaluator.SPIRIT_ID, center, expanded_bounds)
	# Sky Whale is global — no island scoping.
	instance.island_id = ""
	_active_instances[SkyWhaleEvaluator.SPIRIT_ID] = instance
	_next_essence_drop_at[SkyWhaleEvaluator.SPIRIT_ID] = Time.get_unix_time_from_system() + _progression_duration(ESSENCE_CHARGE_SECONDS)
	mark_housing_dirty()
	var wanderer: Node = _spawner.spawn(instance, entry)
	var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
	if ecology != null and ecology.has_method("register_wanderer"):
		ecology.register_wanderer(wanderer)
	spirit_summoned.emit(SkyWhaleEvaluator.SPIRIT_ID, instance)
	sky_whale_event_triggered.emit()
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)

func active_count() -> int:
	return _active_instances.size()

func get_housing_snapshot() -> Dictionary:
	var assignment: Dictionary = _get_housing_assignment()
	return {
		"housed_count": int(assignment.get("housed_count", 0)),
		"unhoused_count": int(assignment.get("unhoused_count", 0)),
		"upgraded_housed_count": int(assignment.get("upgraded_housed_count", 0)),
		"housed_by_island": (assignment.get("housed_by_island", {}) as Dictionary).duplicate(true),
		"upgraded_housed_by_island": (assignment.get("upgraded_housed_by_island", {}) as Dictionary).duplicate(true),
	}

func is_spirit_housed(spirit_id: String, island_id: String = "") -> bool:
	var key: String = _spirit_key(spirit_id, island_id)
	var assignment: Dictionary = _get_housing_assignment()
	var housed_keys_variant: Variant = assignment.get("housed_keys", {})
	if housed_keys_variant is Dictionary:
		return bool((housed_keys_variant as Dictionary).get(key, false))
	return false

func has_housed_spirit(spirit_id: String) -> bool:
	var assignment: Dictionary = _get_housing_assignment()
	var housed_keys_variant: Variant = assignment.get("housed_keys", {})
	if not (housed_keys_variant is Dictionary):
		return false
	var housed_keys: Dictionary = housed_keys_variant as Dictionary
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		if not bool(housed_keys.get(key, false)):
			continue
		var instance: SpiritInstance = _active_instances.get(key_variant, null)
		if instance != null and instance.spirit_id == spirit_id:
			return true
	return false

func get_house_owner_at_coord(coord: Vector2i) -> Dictionary:
	_get_housing_assignment()
	var house_key: String = _coord_to_key(coord)
	for spirit_key_variant: Variant in _house_binding_by_spirit.keys():
		var spirit_key: String = str(spirit_key_variant)
		if str(_house_binding_by_spirit.get(spirit_key, "")) != house_key:
			continue
		var instance: SpiritInstance = _active_instances.get(spirit_key, null)
		if instance == null:
			continue
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		return {
			"spirit_id": instance.spirit_id,
			"display_name": str(entry.get("display_name", instance.spirit_id)),
			"island_id": instance.island_id,
		}
	return {}

func mark_housing_dirty() -> void:
	_housing_cache_dirty = true

func has_active_spirit(spirit_id: String) -> bool:
	return _is_spirit_active_anywhere(spirit_id)

func get_housing_recompute_count() -> int:
	return _housing_recompute_count

func get_pending_building_count() -> int:
	return _pending_build_coords.size()

func _get_housing_assignment() -> Dictionary:
	if _housing_cache_dirty or _housing_cache.is_empty():
		_housing_cache = _compute_housing_assignment()
		_housing_cache_dirty = false
		_housing_recompute_count += 1
	return _housing_cache

func _compute_housing_assignment() -> Dictionary:
	var housed_count: int = 0
	var unhoused_count: int = 0
	var upgraded_housed_count: int = 0
	var housed_by_island: Dictionary = {}
	var upgraded_housed_by_island: Dictionary = {}
	var housed_keys: Dictionary = {}
	var houses_by_island: Dictionary = _collect_available_houses_by_island()
	var house_info_by_key: Dictionary = _collect_house_info_by_key(houses_by_island)
	_cleanup_house_bindings(houses_by_island)
	# Preserve existing bindings first so houses remain bound to their current spirit.
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances.get(key, null)
		if instance == null or instance.spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
			continue
		var bound_house_key: String = str(_house_binding_by_spirit.get(key, ""))
		if bound_house_key.is_empty():
			continue
		if _has_better_upgraded_house_available(houses_by_island, instance.island_id, instance.spirit_id, bound_house_key, house_info_by_key):
			continue
		var assigned_island: String = _consume_bound_house(houses_by_island, instance.island_id, bound_house_key)
		if assigned_island.is_empty():
			continue
		housed_count += 1
		housed_keys[key] = true
		housed_by_island[assigned_island] = int(housed_by_island.get(assigned_island, 0)) + 1
		if _is_upgraded_house_for_spirit(instance.spirit_id, str((house_info_by_key.get(bound_house_key, {}) as Dictionary).get("structure_id", ""))):
			upgraded_housed_count += 1
			upgraded_housed_by_island[assigned_island] = int(upgraded_housed_by_island.get(assigned_island, 0)) + 1

	# Assign unbound spirits: species upgrades first, then preferred-biome houses, then any house on the same island.
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances.get(key, null)
		if instance == null:
			continue
		if instance.spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
			continue
		if housed_keys.has(key):
			continue
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		var preferred: Array[int] = _preferred_biomes(entry)
		var assignment: Dictionary = _assign_house_for_spirit(houses_by_island, instance.island_id, preferred, key, instance.spirit_id, house_info_by_key)
		var assigned_island: String = str(assignment.get("island_id", ""))
		if assigned_island.is_empty():
			_house_binding_by_spirit.erase(key)
			unhoused_count += 1
			continue
		housed_count += 1
		housed_keys[key] = true
		housed_by_island[assigned_island] = int(housed_by_island.get(assigned_island, 0)) + 1
		if bool(assignment.get("upgraded", false)):
			upgraded_housed_count += 1
			upgraded_housed_by_island[assigned_island] = int(upgraded_housed_by_island.get(assigned_island, 0)) + 1
	return {
		"housed_count": housed_count,
		"unhoused_count": unhoused_count,
		"upgraded_housed_count": upgraded_housed_count,
		"housed_by_island": housed_by_island,
		"upgraded_housed_by_island": upgraded_housed_by_island,
		"housed_keys": housed_keys,
	}

func get_catalog_entry(spirit_id: String) -> Dictionary:
	return _catalog.lookup(spirit_id)

## Return the compound active-instance key for a spirit on an island.
## When island_id is empty the bare spirit_id is used (Sky Whale, legacy).
func _spirit_key(spirit_id: String, island_id: String) -> String:
	if island_id.is_empty():
		return spirit_id
	return "island_%s|spirit_%s" % [island_id, spirit_id]

## Return true if the given spirit is active on any island.
## Checks both bare keys (Sky Whale / empty island) and compound island-scoped keys.
func _is_spirit_active_anywhere(spirit_id: String) -> bool:
	if _active_instances.has(spirit_id):
		return true
	var suffix: String = "|spirit_%s" % spirit_id
	for key: Variant in _active_instances:
		if str(key).ends_with(suffix):
			return true
	return false

func _can_spawn_in_current_era(spirit_id: String) -> bool:
	var entry: Dictionary = _catalog.lookup(spirit_id)
	var required_era: StringName = StringName(str(entry.get("min_era", "stillness")))
	return SatoriConditionEvaluatorScript.era_meets_requirement(_current_era, required_era)

func _can_spawn_under_era_pacing(spirit_id: String, island_id: String) -> bool:
	if spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
		return true
	var limit: int = _spirit_pacing_limit_for_island(island_id)
	if limit < 0:
		return true
	return _active_non_special_spirit_count_for_island(island_id) < limit

func _spirit_pacing_limit_for_island(island_id: String) -> int:
	match _current_era:
		&"stillness":
			return _completed_house_count_for_island(island_id) + STILLNESS_SPIRIT_HOUSING_BUFFER
		&"awakening":
			return _completed_house_count_for_island(island_id) + AWAKENING_SPIRIT_HOUSING_BUFFER
		_:
			return -1

func _completed_house_count_for_island(island_id: String) -> int:
	var houses_by_island: Dictionary = _collect_available_houses_by_island()
	var houses_variant: Variant = houses_by_island.get(island_id, [])
	if not (houses_variant is Array):
		return 0
	return (houses_variant as Array).size()

func _active_non_special_spirit_count_for_island(island_id: String) -> int:
	var count: int = 0
	for key_variant: Variant in _active_instances.keys():
		var instance: SpiritInstance = _active_instances.get(key_variant, null)
		if instance == null:
			continue
		if instance.spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
			continue
		if instance.island_id == island_id:
			count += 1
	return count

func _emit_settle_hint_once(spirit_id: String, island_id: String) -> void:
	var key: String = "%s|%s" % [island_id, spirit_id]
	if bool(_settle_hint_shown.get(key, false)):
		return
	_settle_hint_shown[key] = true
	riddle_hint_triggered.emit(spirit_id, SETTLE_HINT_TEXT)

func _is_spirit_active_on_island(spirit_id: String, island_id: String, grid: RefCounted) -> bool:
	if island_id.is_empty():
		return _active_instances.has(_spirit_key(spirit_id, ""))
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances.get(key, null)
		if instance == null:
			continue
		if instance.spirit_id != spirit_id:
			continue
		var instance_island: String = ""
		if grid != null and grid.has_method("get_island_id"):
			instance_island = str(grid.get_island_id(instance.spawn_coord))
		if instance_island.is_empty():
			instance_island = instance.island_id
		if instance_island == island_id:
			return true
	return false

func _on_era_changed(new_era: StringName) -> void:
	_current_era = new_era
	_apply_era_requirements()

func _on_progression_speed_changed(_multiplier: float) -> void:
	var now: float = Time.get_unix_time_from_system()
	var next_fast_drop: float = now + _progression_duration(ESSENCE_CHARGE_SECONDS)
	for key_variant: Variant in _next_essence_drop_at.keys():
		var key: String = str(key_variant)
		var current_drop: float = float(_next_essence_drop_at.get(key, next_fast_drop))
		_next_essence_drop_at[key] = minf(current_drop, next_fast_drop)

func _apply_era_requirements() -> void:
	var keys_to_remove: Array[String] = []
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances[key]
		if instance == null:
			continue
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		var required_era: StringName = StringName(str(entry.get("min_era", "stillness")))
		if SatoriConditionEvaluatorScript.era_meets_requirement(_current_era, required_era):
			continue
		keys_to_remove.append(key)
	for key: String in keys_to_remove:
		_despawn_by_key(key)

func _despawn_by_key(key: String) -> void:
	var instance: SpiritInstance = _active_instances.get(key)
	if instance == null:
		return
	var wanderer: Node = _active_wanderers.get(key)
	if wanderer != null:
		wanderer.queue_free()
	_active_wanderers.erase(key)
	_next_essence_drop_at.erase(key)
	_house_binding_by_spirit.erase(key)
	_active_instances.erase(key)
	mark_housing_dirty()
	spirit_despawned.emit(instance.spirit_id)

## Look up the island_id for the first valid coord in a triggering-coords array.
## Returns "" if the coord is not in the grid or has no island_id (e.g., Ku tile).
## The has_method guard allows this to work in unit-test contexts where GameState
## may have a mock grid that has not yet implemented get_island_id.
func _island_for_coords(coords: Array[Vector2i]) -> String:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return ""
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null or not grid.has_method("get_island_id"):
		return ""
	for coord: Vector2i in coords:
		var iid: String = grid.get_island_id(coord)
		if not iid.is_empty():
			return iid
	return ""

func _maybe_mark_shrine_buildable(instance: SpiritInstance) -> void:
	if instance == null:
		return
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null or not grid.has_method("get_tile"):
		return
	var tile: GardenTile = grid.get_tile(instance.spawn_coord)
	if tile == null:
		return
	tile.metadata["shrine_buildable"] = true
	tile.metadata["shrine_built"] = false
	tile.metadata["shrine_spirit_id"] = instance.spirit_id

func _is_ku_deity_spirit(spirit_id: String) -> bool:
	return [
		"spirit_oyamatsumi",
		"spirit_suijin",
		"spirit_kagutsuchi",
		"spirit_fujin",
	].has(spirit_id)

func _maybe_queue_godai_charge_drop(spirit_id: String, entry: Dictionary) -> void:
	var elements: Array[int] = _elements_for_spirit_charge(entry)
	if spirit_id == "spirit_mist_stag":
		elements = [GodaiElementScript.Value.KU]
	if elements.is_empty():
		return
	var element_parts: PackedStringArray = []
	for element: int in elements:
		element_parts.append(str(element))
	_SpiritGiftProcessorScript.process_gift(
		SpiritGiftTypeScript.Value.GODAI_CHARGE,
		StringName("%s:%s" % [spirit_id, ",".join(element_parts)])
	)

func _elements_for_spirit_charge(entry: Dictionary) -> Array[int]:
	var elements: Array[int] = []
	var seen: Dictionary = {}
	var preferred_variant: Variant = entry.get("preferred_biomes", [])
	if preferred_variant is Array:
		var preferred_biomes: Array = preferred_variant as Array
		for biome_variant: Variant in preferred_biomes:
			var biome: int = int(biome_variant)
			var mapped: Array[int] = _elements_for_biome(biome)
			for element: int in mapped:
				if seen.has(element):
					continue
				seen[element] = true
				elements.append(element)
	if elements.is_empty():
		elements.append(GodaiElementScript.Value.CHI)
	return elements

func _elements_for_biome(biome: int) -> Array[int]:
	match biome:
		BiomeTypeScript.Value.STONE:
			return [GodaiElementScript.Value.CHI]
		BiomeTypeScript.Value.RIVER:
			return [GodaiElementScript.Value.SUI]
		BiomeTypeScript.Value.EMBER_FIELD:
			return [GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.MEADOW:
			return [GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.WETLANDS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.SUI]
		BiomeTypeScript.Value.BADLANDS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.WHISTLING_CANYONS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.PRISMATIC_TERRACES:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.FROSTLANDS:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.THE_ASHFALL:
			return [GodaiElementScript.Value.KA, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.SACRED_STONE:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.MOONLIT_POOL:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.EMBER_SHRINE:
			return [GodaiElementScript.Value.KA, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.CLOUD_RIDGE:
			return [GodaiElementScript.Value.FU, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.KU:
			return [GodaiElementScript.Value.KU]
		_:
			return []

func _process_essence_charge_timers() -> void:
	if _active_instances.is_empty():
		return
	var now: float = Time.get_unix_time_from_system()
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances.get(key, null)
		if instance == null:
			continue
		if instance.spirit_id == SkyWhaleEvaluator.SPIRIT_ID:
			continue
		var next_drop_at: float = float(_next_essence_drop_at.get(key, now + _progression_duration(ESSENCE_CHARGE_SECONDS)))
		if now < next_drop_at:
			continue
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		_maybe_queue_godai_charge_drop(instance.spirit_id, entry)
		_next_essence_drop_at[key] = now + _progression_duration(ESSENCE_CHARGE_SECONDS)

func _collect_available_houses_by_island() -> Dictionary:
	var houses_by_island: Dictionary = {}
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return houses_by_island
	var grid: RefCounted = game_state.get("grid") as RefCounted
	if grid == null or not grid.has_method("get_tile"):
		return houses_by_island
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		# Special structures (including origin shrine) are not spirit houses.
		if bool(tile.metadata.get("shrine_built", false)):
			continue
		if not bool(tile.metadata.get("is_building_complete", false)):
			continue
		var island_id: String = ""
		if grid.has_method("get_island_id"):
			island_id = str(grid.get_island_id(coord))
		if island_id.is_empty():
			island_id = str(tile.metadata.get("island_id", ""))
		var arr_variant: Variant = houses_by_island.get(island_id, null)
		var arr: Array[Dictionary] = []
		if arr_variant is Array:
			for item_variant: Variant in (arr_variant as Array):
				if item_variant is Dictionary:
					arr.append((item_variant as Dictionary).duplicate(true))
		arr.append({
			"coord": coord,
			"biome": tile.biome,
			"key": _coord_to_key(coord),
			"structure_id": str(tile.metadata.get("structure_discovery_id", "")),
		})
		houses_by_island[island_id] = arr
	return houses_by_island

func _collect_house_info_by_key(houses_by_island: Dictionary) -> Dictionary:
	var info_by_key: Dictionary = {}
	for island_variant: Variant in houses_by_island.keys():
		var island_id: String = str(island_variant)
		var arr_variant: Variant = houses_by_island.get(island_id, null)
		if not (arr_variant is Array):
			continue
		for house_variant: Variant in (arr_variant as Array):
			if not (house_variant is Dictionary):
				continue
			var house: Dictionary = house_variant as Dictionary
			var house_key: String = str(house.get("key", ""))
			if house_key.is_empty():
				continue
			var copy: Dictionary = house.duplicate(true)
			copy["island_id"] = island_id
			info_by_key[house_key] = copy
	return info_by_key

func _preferred_biomes(entry: Dictionary) -> Array[int]:
	var preferred: Array[int] = []
	var preferred_variant: Variant = entry.get("preferred_biomes", [])
	if preferred_variant is Array:
		for biome_variant: Variant in (preferred_variant as Array):
			preferred.append(int(biome_variant))
	return preferred

func _assign_house_for_spirit(houses_by_island: Dictionary, preferred_island: String, preferred_biomes: Array[int], spirit_key: String, spirit_id: String, house_info_by_key: Dictionary) -> Dictionary:
	if preferred_island.is_empty():
		return {}
	var consumed_house_key: String = _consume_upgraded_house(houses_by_island, preferred_island, spirit_id)
	if consumed_house_key.is_empty():
		consumed_house_key = _consume_matching_house(houses_by_island, preferred_island, preferred_biomes)
	if consumed_house_key.is_empty():
		consumed_house_key = _consume_any_house(houses_by_island, preferred_island)
	if consumed_house_key.is_empty():
		return {}
	_house_binding_by_spirit[spirit_key] = consumed_house_key
	var structure_id: String = str((house_info_by_key.get(consumed_house_key, {}) as Dictionary).get("structure_id", ""))
	return {
		"island_id": preferred_island,
		"house_key": consumed_house_key,
		"upgraded": _is_upgraded_house_for_spirit(spirit_id, structure_id),
	}

func _consume_upgraded_house(houses_by_island: Dictionary, island_id: String, spirit_id: String) -> String:
	var arr_variant: Variant = houses_by_island.get(island_id, null)
	if not (arr_variant is Array):
		return ""
	var houses: Array = arr_variant as Array
	for i: int in range(houses.size()):
		var house_variant: Variant = houses[i]
		if not (house_variant is Dictionary):
			continue
		var house: Dictionary = house_variant as Dictionary
		var structure_id: String = str(house.get("structure_id", ""))
		if not _is_upgraded_house_for_spirit(spirit_id, structure_id):
			continue
		var house_key: String = str(house.get("key", ""))
		houses.remove_at(i)
		houses_by_island[island_id] = houses
		return house_key
	return ""

func _has_better_upgraded_house_available(houses_by_island: Dictionary, island_id: String, spirit_id: String, bound_house_key: String, house_info_by_key: Dictionary) -> bool:
	var bound_info_variant: Variant = house_info_by_key.get(bound_house_key, {})
	if bound_info_variant is Dictionary:
		var bound_structure_id: String = str((bound_info_variant as Dictionary).get("structure_id", ""))
		if _is_upgraded_house_for_spirit(spirit_id, bound_structure_id):
			return false
	var arr_variant: Variant = houses_by_island.get(island_id, null)
	if not (arr_variant is Array):
		return false
	for house_variant: Variant in (arr_variant as Array):
		if not (house_variant is Dictionary):
			continue
		var house: Dictionary = house_variant as Dictionary
		if str(house.get("key", "")) == bound_house_key:
			continue
		if _is_upgraded_house_for_spirit(spirit_id, str(house.get("structure_id", ""))):
			return true
	return false

func _is_upgraded_house_for_spirit(spirit_id: String, structure_id: String) -> bool:
	var ids_variant: Variant = _UPGRADED_HOUSES_BY_SPIRIT.get(spirit_id, [])
	if not (ids_variant is Array):
		return false
	for id_variant: Variant in ids_variant as Array:
		if str(id_variant) == structure_id:
			return true
	return false

func _consume_matching_house(houses_by_island: Dictionary, island_id: String, preferred_biomes: Array[int]) -> String:
	var arr_variant: Variant = houses_by_island.get(island_id, null)
	if not (arr_variant is Array):
		return ""
	var houses: Array = arr_variant as Array
	if houses.is_empty():
		return ""
	for i: int in range(houses.size()):
		var house_variant: Variant = houses[i]
		if not (house_variant is Dictionary):
			continue
		var house: Dictionary = house_variant as Dictionary
		var biome: int = int(house.get("biome", -1))
		if not preferred_biomes.is_empty() and not preferred_biomes.has(biome):
			continue
		var house_key: String = str(house.get("key", ""))
		houses.remove_at(i)
		houses_by_island[island_id] = houses
		return house_key
	return ""

func _consume_any_house(houses_by_island: Dictionary, island_id: String) -> String:
	var arr_variant: Variant = houses_by_island.get(island_id, null)
	if not (arr_variant is Array):
		return ""
	var houses: Array = arr_variant as Array
	if houses.is_empty():
		return ""
	var house_variant: Variant = houses.pop_front()
	houses_by_island[island_id] = houses
	if house_variant is Dictionary:
		return str((house_variant as Dictionary).get("key", ""))
	return ""

func _consume_bound_house(houses_by_island: Dictionary, island_id: String, house_key: String) -> String:
	var arr_variant: Variant = houses_by_island.get(island_id, null)
	if not (arr_variant is Array):
		return ""
	var houses: Array = arr_variant as Array
	for i: int in range(houses.size()):
		var house_variant: Variant = houses[i]
		if not (house_variant is Dictionary):
			continue
		var house: Dictionary = house_variant as Dictionary
		if str(house.get("key", "")) != house_key:
			continue
		houses.remove_at(i)
		houses_by_island[island_id] = houses
		return island_id
	return ""

func _cleanup_house_bindings(houses_by_island: Dictionary) -> void:
	var valid_house_keys: Dictionary = {}
	for island_variant: Variant in houses_by_island.keys():
		var arr_variant: Variant = houses_by_island.get(str(island_variant), null)
		if not (arr_variant is Array):
			continue
		for house_variant: Variant in (arr_variant as Array):
			if not (house_variant is Dictionary):
				continue
			var house: Dictionary = house_variant as Dictionary
			valid_house_keys[str(house.get("key", ""))] = true
	var binding_keys: Array = _house_binding_by_spirit.keys()
	for spirit_key_variant: Variant in binding_keys:
		var spirit_key: String = str(spirit_key_variant)
		if not _active_instances.has(spirit_key):
			_house_binding_by_spirit.erase(spirit_key)
			continue
		var house_key: String = str(_house_binding_by_spirit.get(spirit_key, ""))
		if house_key.is_empty() or not valid_house_keys.has(house_key):
			_house_binding_by_spirit.erase(spirit_key)

func _coord_to_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func _grid_from_game_state(game_state: Node) -> RefCounted:
	if game_state == null:
		return null
	var grid_variant: Variant = game_state.get("grid")
	if grid_variant is RefCounted:
		return grid_variant as RefCounted
	return null

func _collect_pending_building_coords_once() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null or not grid.has_method("get_tile"):
		return
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if _is_pending_building_tile(tile):
			register_pending_building(coord)

func _finalize_pending_buildings() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null or not grid.has_method("get_tile"):
		return
	var coords: Array[Vector2i] = []
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if _is_pending_building_tile(tile):
			coords.append(coord)
	_finalize_pending_buildings_for_coords(coords)

func _finalize_tracked_pending_buildings() -> void:
	if _pending_build_coords.is_empty():
		return
	var coords: Array[Vector2i] = []
	for coord_variant: Variant in _pending_build_coords.values():
		if coord_variant is Vector2i:
			coords.append(coord_variant as Vector2i)
	_finalize_pending_buildings_for_coords(coords)

func _finalize_pending_buildings_for_coords(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return
	var game_state: Node = get_node_or_null("/root/GameState")
	var grid: RefCounted = _grid_from_game_state(game_state)
	if grid == null or not grid.has_method("get_tile"):
		return
	var now: float = Time.get_unix_time_from_system()
	for coord: Vector2i in coords:
		var coord_key: String = _coord_to_key(coord)
		var tile: GardenTile = grid.get_tile(coord)
		if not _is_pending_building_tile(tile):
			_pending_build_coords.erase(coord_key)
			continue
		var started_at: float = float(tile.metadata.get("build_started_at", now))
		var duration: float = float(tile.metadata.get("build_duration", _progression_duration(BUILD_COMPLETION_SECONDS)))
		if now - started_at < maxf(0.1, duration):
			_pending_build_coords[coord_key] = coord
			continue
		_complete_pending_building_tile(coord, tile, now)
		_pending_build_coords.erase(coord_key)

func _is_pending_building_tile(tile: GardenTile) -> bool:
	if tile == null:
		return false
	if not bool(tile.metadata.get("is_build_block", false)):
		return false
	if bool(tile.metadata.get("is_building_complete", false)):
		return false
	return bool(tile.metadata.get("build_countdown_started", false))

func _complete_pending_building_tile(coord: Vector2i, tile: GardenTile, now: float) -> void:
	var pending_structure_id: String = str(tile.metadata.get("pending_structure_id", ""))
	var pending_structure_anchor: bool = bool(tile.metadata.get("pending_structure_anchor", true))
	var pending_origin_shrine: bool = bool(tile.metadata.get("pending_origin_shrine", false))
	var is_special_structure: bool = pending_origin_shrine or not pending_structure_id.is_empty()
	tile.metadata["is_build_block"] = false
	tile.metadata["is_building_complete"] = not is_special_structure
	if not is_special_structure:
		tile.metadata.erase("structure_discovery_id")
	if pending_origin_shrine:
		tile.metadata["is_origin_shrine"] = true
		tile.metadata["shrine_buildable"] = false
		tile.metadata["shrine_built"] = true
		tile.metadata["build_discovery_id"] = "disc_origin_shrine"
		tile.metadata["structure_discovery_id"] = "disc_origin_shrine"
	if not pending_structure_id.is_empty():
		tile.metadata["shrine_buildable"] = false
		tile.metadata["shrine_built"] = true
		tile.metadata["structure_discovery_id"] = pending_structure_id
		if pending_structure_anchor:
			tile.metadata["build_discovery_id"] = pending_structure_id
			var satori_service: Node = get_node_or_null("/root/SatoriService")
			if satori_service != null and satori_service.has_method("apply_monument_on_build"):
				satori_service.apply_monument_on_build(pending_structure_id)
			var codex: Node = get_node_or_null("/root/CodexService")
			if codex != null and codex.has_method("mark_structure_recipe_completed"):
				codex.mark_structure_recipe_completed(StringName(pending_structure_id))
		else:
			tile.metadata.erase("build_discovery_id")
	tile.metadata["building_completed_at"] = now
	tile.metadata["build_completion_pending"] = false
	tile.metadata.erase("build_started_at")
	tile.metadata.erase("build_duration")
	tile.metadata["build_countdown_started"] = false
	tile.metadata.erase("build_recipe_biome")
	tile.metadata.erase("build_project_id")
	tile.metadata.erase("pending_origin_shrine")
	tile.metadata.erase("pending_structure_candidate")
	tile.metadata.erase("pending_structure_id")
	tile.metadata.erase("pending_structure_anchor")
	tile.locked = false
	mark_housing_dirty()
	building_completed.emit(coord, tile.biome)

func _progression_duration(duration_seconds: float) -> float:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_method("scaled_progress_duration"):
		return float(settings.scaled_progress_duration(duration_seconds))
	return maxf(0.1, duration_seconds)
