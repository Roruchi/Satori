class_name SatoriServiceNode
extends Node

const SatoriConditionSetScript = preload("res://src/satori/SatoriConditionSet.gd")
const SatoriConditionEvaluatorScript = preload("res://src/satori/SatoriConditionEvaluator.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SatoriIdsScript = preload("res://src/satori/SatoriIds.gd")
const PatternLoaderScript = preload("res://src/biomes/pattern_loader.gd")
const DiscoveryCatalogDataScript = preload("res://src/biomes/discovery_catalog_data.gd")
const StructureCatalogDataScript = preload("res://src/biomes/structure_catalog_data.gd")

signal satori_moment_fired(condition_id: StringName)
signal satori_changed(current: int, cap: int)
signal satori_cap_changed(cap: int)
signal era_changed(new_era: StringName)
signal structure_build_blocked(discovery_id: String, reason: String)

const TICK_INTERVAL_SECONDS: float = 60.0
const PAGODA_PASSIVE_PER_MINUTE: int = 5
const GREAT_TORII_BURST: int = 500
const VOID_MIRROR_MULTIPLIER: float = 1.5
const GUIDANCE_LANTERN_PACIFIED_MAX: int = 3
const UNIQUE_ALREADY_BUILT_REASON: String = "unique_already_built"
const HOUSED_GAIN_INTERVAL_SECONDS: float = 60.0
const UNHOUSED_LOSS_INTERVAL_SECONDS: float = 30.0
const STILLNESS_UNHOUSED_LOSS_INTERVAL_SECONDS: float = 120.0
const UPGRADED_HOUSE_BONUS_PER_MINUTE: int = 1
const DISCOVERY_CAP_PER_UNIQUE: int = 50

var _conditions: Array[SatoriConditionSet] = []
var _fired: Dictionary = {}
var _active_overlay: CanvasLayer
var _skip_available: bool = false
var _pending_unlock: SatoriConditionSet
var _skip_timer: SceneTreeTimer

var _current_satori: int = 0
var _current_cap: int = SatoriIdsScript.BASE_SATORI_CAP
var _current_era: StringName = SatoriIdsScript.ERA_STILLNESS
var _tick_accumulator: float = 0.0
var _fractional_satori_delta: float = 0.0
var _structures: Array[Dictionary] = []
var _blocked_unique_discovery_ids: Dictionary = {}
var _structure_defs: Dictionary = {}

func _ready() -> void:
	_load_conditions()
	_load_structure_definitions()
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_signal("bloom_confirmed"):
		growth_service.bloom_confirmed.connect(_on_progress_event)
	var spirit_service: Node = get_node_or_null("/root/SpiritService")
	if spirit_service != null and spirit_service.has_signal("spirit_summoned"):
		spirit_service.spirit_summoned.connect(_on_spirit_summoned)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("tile_placed"):
		game_state.tile_placed.connect(_on_world_changed)
	if game_state != null and game_state.has_signal("tile_mixed"):
		game_state.tile_mixed.connect(_on_world_changed)
	var discovery_persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if discovery_persistence != null and discovery_persistence.has_signal("discovery_recorded"):
		discovery_persistence.discovery_recorded.connect(_on_discovery_recorded)
	_recompute_structures_from_grid()
	_recompute_cap_from_structures()
	_emit_satori_if_changed()

func _process(delta: float) -> void:
	_tick_accumulator += _progression_delta(delta)
	while _tick_accumulator >= TICK_INTERVAL_SECONDS:
		_tick_accumulator -= TICK_INTERVAL_SECONDS
		process_minute_tick()

func _load_conditions() -> void:
	var dir: DirAccess = DirAccess.open("res://src/satori/conditions/")
	if dir == null:
		return
	dir.list_dir_begin()
	var filename: String = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path: String = "res://src/satori/conditions/%s" % filename
			var resource: Resource = load(path)
			if resource is SatoriConditionSetScript:
				_conditions.append(resource as SatoriConditionSet)
		filename = dir.get_next()
	dir.list_dir_end()

func _load_structure_definitions() -> void:
	_structure_defs.clear()
	var catalog_data: DiscoveryCatalogData = DiscoveryCatalogDataScript.new()
	var structure_catalog: RefCounted = StructureCatalogDataScript.new()
	var structure_assets_by_id: Dictionary = structure_catalog.get_entries_by_id()
	var all_entries: Array[Dictionary] = []
	all_entries.append_array(catalog_data.get_tier1_entries())
	all_entries.append_array(catalog_data.get_tier2_entries())
	all_entries.append_array(catalog_data.get_tier3_entries())
	for meta: Dictionary in all_entries:
		var did_from_catalog: String = str(meta.get("discovery_id", ""))
		if did_from_catalog.is_empty():
			continue
		_structure_defs[did_from_catalog] = _make_structure_definition(
			did_from_catalog,
			int(meta.get("tier", 0)),
			int(meta.get("cap_increase", 0)),
			bool(meta.get("is_unique", false)),
			int(meta.get("housing_capacity", 0)),
			str(meta.get("effect_type", "")),
			_dictionary_from_variant(meta.get("effect_params", {})),
			structure_assets_by_id
		)
	var loader: PatternLoader = PatternLoaderScript.new()
	var patterns: Array[PatternDefinition] = loader.load_patterns()
	for pattern: PatternDefinition in patterns:
		var did: String = pattern.discovery_id
		if did.is_empty():
			continue
		var existing: Dictionary = get_structure_definition(did)
		var effect_params: Dictionary = pattern.effect_params.duplicate(true)
		if effect_params.is_empty() and existing.has("effect_params"):
			effect_params = _dictionary_from_variant(existing.get("effect_params", {}))
		var housing_capacity: int = pattern.housing_capacity
		if housing_capacity == 0:
			housing_capacity = int(existing.get("housing_capacity", 0))
		_structure_defs[did] = _make_structure_definition(
			did,
			pattern.tier,
			pattern.cap_increase,
			pattern.is_unique,
			housing_capacity,
			pattern.effect_type,
			effect_params,
			structure_assets_by_id
		)

func _make_structure_definition(
	discovery_id: String,
	tier: int,
	cap_increase: int,
	is_unique: bool,
	housing_capacity: int,
	effect_type: String,
	effect_params: Dictionary,
	structure_assets_by_id: Dictionary
) -> Dictionary:
	var asset_entry: Dictionary = _asset_entry_for_structure(discovery_id, structure_assets_by_id)
	var effects: Array[Dictionary] = _effects_from_legacy(effect_type, effect_params, housing_capacity)
	if effects.is_empty() and asset_entry.get("effects", []) is Array:
		effects = _effects_array_from_variant(asset_entry.get("effects", []))
	return {
		"discovery_id": discovery_id,
		"tier": tier,
		"cap_increase": cap_increase,
		"is_unique": is_unique,
		"housing_capacity": housing_capacity,
		"effect_type": effect_type,
		"effect_params": effect_params.duplicate(true),
		"effects": effects,
		"asset_path": str(asset_entry.get("asset_path", "")),
		"sprite_frames_path": str(asset_entry.get("sprite_frames_path", "")),
	}

func _asset_entry_for_structure(discovery_id: String, structure_assets_by_id: Dictionary) -> Dictionary:
	var entry_variant: Variant = structure_assets_by_id.get(discovery_id, {})
	if entry_variant is Dictionary:
		return (entry_variant as Dictionary).duplicate(true)
	return {}

func _effects_from_legacy(effect_type: String, effect_params: Dictionary, housing_capacity: int) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if not effect_type.is_empty():
		var params: Dictionary = effect_params.duplicate(true)
		if effect_type == "dwelling" and housing_capacity > 0 and not params.has("capacity"):
			params["capacity"] = housing_capacity
		effects.append({"type": effect_type, "params": params})
	if housing_capacity > 0 and effect_type != "dwelling":
		effects.append({"type": "housing", "params": {"capacity": housing_capacity}})
	return effects

func _effects_array_from_variant(value: Variant) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if not (value is Array):
		return effects
	for effect_variant: Variant in value as Array:
		if effect_variant is Dictionary:
			effects.append((effect_variant as Dictionary).duplicate(true))
	return effects

func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

func _on_progress_event(_coord: Vector2i, _biome: int) -> void:
	evaluate()

func _on_spirit_summoned(_spirit_id: String, _instance: SpiritInstance) -> void:
	evaluate()

func _on_world_changed(_coord: Vector2i, _tile: GardenTile) -> void:
	_recompute_structures_from_grid()
	_recompute_cap_from_structures()

func _on_discovery_recorded(_discovery_id: String) -> void:
	_recompute_cap_from_structures()

func evaluate() -> void:
	for condition_set: SatoriConditionSet in _conditions:
		if bool(_fired.get(condition_set.condition_id, false)):
			continue
		if SatoriConditionEvaluatorScript.evaluate(condition_set.requirements):
			_play_sequence(condition_set)
			return

func trigger_debug() -> void:
	for condition_set: SatoriConditionSet in _conditions:
		if str(condition_set.condition_id) == "satori_first_awakening":
			if bool(_fired.get(condition_set.condition_id, false)):
				return
			_play_sequence(condition_set)
			return

func _play_sequence(condition_set: SatoriConditionSet) -> void:
	_fired[condition_set.condition_id] = true
	_pending_unlock = condition_set
	satori_moment_fired.emit(condition_set.condition_id)

	var root: Node = get_tree().root
	_active_overlay = CanvasLayer.new()
	_active_overlay.layer = 10
	root.add_child(_active_overlay)
	var rect: ColorRect = ColorRect.new()
	rect.color = Color(1.0, 1.0, 1.0, 0.0)
	rect.anchor_left = 0.0
	rect.anchor_top = 0.0
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	_active_overlay.add_child(rect)

	var tween: Tween = create_tween()
	tween.tween_property(rect, "color", Color(1.0, 1.0, 1.0, 0.25), _progression_duration(0.5))
	tween.tween_interval(_progression_duration(2.0))
	tween.tween_property(rect, "color", Color(1.0, 1.0, 1.0, 0.0), _progression_duration(1.0))
	tween.finished.connect(_complete_sequence)
	_skip_available = false
	set_process_input(true)
	_skip_timer = get_tree().create_timer(_progression_duration(2.0))
	_skip_timer.timeout.connect(func() -> void:
		if _active_overlay == null:
			return
		_skip_available = true
	)

func _input(event: InputEvent) -> void:
	if not _skip_available:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_complete_sequence()

func _complete_sequence() -> void:
	set_process_input(false)
	_skip_available = false
	_skip_timer = null
	if _active_overlay != null:
		_active_overlay.queue_free()
		_active_overlay = null
	if _pending_unlock != null:
		_apply_unlock(_pending_unlock.unlock_type, _pending_unlock.unlock_payload)
		_pending_unlock = null

func _apply_unlock(unlock_type: int, payload: StringName) -> void:
	match unlock_type:
		SpiritGiftTypeScript.Value.GROWING_SLOT_EXPAND:
			var growth: Node = get_node_or_null("/root/SeedGrowthService")
			if growth != null and growth.has_method("expand_slots"):
				growth.expand_slots()
		SpiritGiftTypeScript.Value.KU_UNLOCK:
			var alchemy: Node = get_node_or_null("/root/SeedAlchemyService")
			if alchemy != null and alchemy.has_method("unlock_element"):
				alchemy.unlock_element(GodaiElementScript.Value.KU)
		SpiritGiftTypeScript.Value.TIER3_RECIPE:
			var alchemy2: Node = get_node_or_null("/root/SeedAlchemyService")
			if alchemy2 != null and alchemy2.has_method("get_registry"):
				var registry: SeedRecipeRegistry = alchemy2.get_registry()
				if registry != null:
					registry.unlock_recipe(payload)

func _progression_delta(delta_seconds: float) -> float:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_method("scale_progress_delta"):
		return float(settings.scale_progress_delta(delta_seconds))
	return maxf(0.0, delta_seconds)

func _progression_duration(duration_seconds: float) -> float:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings != null and settings.has_method("scaled_progress_duration"):
		return float(settings.scaled_progress_duration(duration_seconds))
	return maxf(0.1, duration_seconds)

func get_current_satori() -> int:
	return _current_satori

func get_satori_for_island(_island_id: String) -> int:
	return _current_satori

func get_current_cap() -> int:
	return _current_cap

func get_current_era() -> StringName:
	return _current_era

func set_satori_for_testing(value: int) -> void:
	_apply_satori(value)

func set_cap_for_testing(cap_value: int) -> void:
	_current_cap = maxi(cap_value, SatoriIdsScript.BASE_SATORI_CAP)
	_apply_satori(_current_satori)
	emit_signal("satori_cap_changed", _current_cap)

func serialize_satori_state() -> Dictionary:
	return {
		"current_satori": _current_satori,
		"current_cap": _current_cap,
		"current_era": str(_current_era),
		"tick_accumulator": _tick_accumulator,
		"fractional_satori_delta": _fractional_satori_delta,
		"fired": _fired.duplicate(true),
	}

func restore_satori_state(data: Dictionary) -> bool:
	_recompute_structures_from_grid()
	_recompute_cap_from_structures()
	var restored_cap: int = maxi(int(data.get("current_cap", _current_cap)), SatoriIdsScript.BASE_SATORI_CAP)
	_current_cap = restored_cap
	_tick_accumulator = maxf(0.0, float(data.get("tick_accumulator", 0.0)))
	_fractional_satori_delta = float(data.get("fractional_satori_delta", 0.0))
	var fired_variant: Variant = data.get("fired", {})
	_fired.clear()
	if fired_variant is Dictionary:
		_fired = (fired_variant as Dictionary).duplicate(true)
	_apply_satori(int(data.get("current_satori", _current_satori)))
	var restored_era: StringName = StringName(str(data.get("current_era", _current_era)))
	if restored_era != _current_era:
		_current_era = restored_era
		era_changed.emit(_current_era)
		_emit_satori_if_changed()
	return true

func process_minute_tick(snapshot_override: Dictionary = {}) -> Dictionary:
	var snapshot: Dictionary = snapshot_override if not snapshot_override.is_empty() else _snapshot_from_services()
	var housed_count: int = int(snapshot.get("housed_count", 0))
	var unhoused_count: int = int(snapshot.get("unhoused_count", 0))
	var upgraded_housed_count: int = int(snapshot.get("upgraded_housed_count", 0))
	var unhoused_loss_interval: float = _unhoused_loss_interval_for_current_era()
	var base_delta: float = (
		float(housed_count) * (TICK_INTERVAL_SECONDS / HOUSED_GAIN_INTERVAL_SECONDS)
	) + (
		float(upgraded_housed_count * UPGRADED_HOUSE_BONUS_PER_MINUTE) * (TICK_INTERVAL_SECONDS / 60.0)
	) - (
		float(unhoused_count) * (TICK_INTERVAL_SECONDS / unhoused_loss_interval)
	)
	var modifier_delta: float = _modifier_delta_from_structures(snapshot) * (TICK_INTERVAL_SECONDS / 60.0)
	_fractional_satori_delta += base_delta + modifier_delta
	var applied_delta: int = 0
	if _fractional_satori_delta >= 1.0:
		applied_delta = int(floor(_fractional_satori_delta))
	elif _fractional_satori_delta <= -1.0:
		applied_delta = int(ceil(_fractional_satori_delta))
	_fractional_satori_delta -= float(applied_delta)
	if applied_delta != 0:
		_apply_satori(_current_satori + applied_delta)
	return {
		"base_delta": base_delta,
		"modifier_delta": modifier_delta,
		"applied_delta": applied_delta,
		"new_satori": _current_satori,
		"new_era": _current_era,
	}

func _unhoused_loss_interval_for_current_era() -> float:
	if _current_era == SatoriIdsScript.ERA_STILLNESS:
		return STILLNESS_UNHOUSED_LOSS_INTERVAL_SECONDS
	return UNHOUSED_LOSS_INTERVAL_SECONDS

func _modifier_delta_from_structures(snapshot: Dictionary) -> int:
	var delta: int = 0
	var pacified_unhoused: int = mini(int(snapshot.get("unhoused_count", 0)), _guidance_lantern_count() * GUIDANCE_LANTERN_PACIFIED_MAX)
	delta += pacified_unhoused
	delta += _pagoda_count() * PAGODA_PASSIVE_PER_MINUTE
	var housed_by_island_variant: Variant = snapshot.get("housed_by_island", {})
	if housed_by_island_variant is Dictionary:
		var housed_by_island: Dictionary = housed_by_island_variant as Dictionary
		for island_key: Variant in housed_by_island.keys():
			var island_id: String = str(island_key)
			var housed_count: int = int(housed_by_island[island_key])
			var multiplier_count: int = _void_mirror_count_for_island(island_id)
			if multiplier_count <= 0:
				continue
			var extra: int = int(floor(float(housed_count) * (VOID_MIRROR_MULTIPLIER - 1.0) * float(multiplier_count)))
			delta += extra
	return delta

func _apply_satori(next_value: int) -> void:
	var clamped: int = clamp(next_value, 0, _current_cap)
	var old_satori: int = _current_satori
	var old_era: StringName = _current_era
	_current_satori = clamped
	_current_era = SatoriConditionEvaluatorScript.era_from_satori(_current_satori)
	if old_satori != _current_satori:
		_emit_satori_if_changed()
	if old_era != _current_era:
		era_changed.emit(_current_era)
		_emit_satori_if_changed()

func _emit_satori_if_changed() -> void:
	satori_changed.emit(_current_satori, _current_cap)

func _snapshot_from_services() -> Dictionary:
	var housed_count: int = 0
	var unhoused_count: int = 0
	var upgraded_housed_count: int = 0
	var housed_by_island: Dictionary = {}
	var upgraded_housed_by_island: Dictionary = {}
	var spirit_service: Node = get_node_or_null("/root/Garden/SpiritService")
	if spirit_service == null:
		spirit_service = get_node_or_null("/root/SpiritService")
	if spirit_service != null and spirit_service.has_method("get_housing_snapshot"):
		var snap: Dictionary = spirit_service.get_housing_snapshot()
		housed_count = int(snap.get("housed_count", 0))
		unhoused_count = int(snap.get("unhoused_count", 0))
		upgraded_housed_count = int(snap.get("upgraded_housed_count", 0))
		var by_island_variant: Variant = snap.get("housed_by_island", {})
		if by_island_variant is Dictionary:
			housed_by_island = (by_island_variant as Dictionary).duplicate(true)
		var upgraded_by_island_variant: Variant = snap.get("upgraded_housed_by_island", {})
		if upgraded_by_island_variant is Dictionary:
			upgraded_housed_by_island = (upgraded_by_island_variant as Dictionary).duplicate(true)
	return {
		"housed_count": housed_count,
		"unhoused_count": unhoused_count,
		"upgraded_housed_count": upgraded_housed_count,
		"housed_by_island": housed_by_island,
		"upgraded_housed_by_island": upgraded_housed_by_island,
	}

func _recompute_structures_from_grid() -> void:
	_structures.clear()
	_blocked_unique_discovery_ids.clear()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = game_state.get("grid")
	if grid == null:
		return
	_enforce_wayfarer_torii_per_biome(grid)
	var seen_unique: Dictionary = {}
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		if bool(tile.metadata.get("is_origin_shrine", false)):
			continue
		if not bool(tile.metadata.get("shrine_built", false)):
			continue
		var discovery_id: String = str(tile.metadata.get("build_discovery_id", ""))
		if discovery_id.is_empty():
			continue
		var def: Dictionary = get_structure_definition(discovery_id)
		if def.is_empty():
			continue
		if bool(def.get("is_unique", false)):
			if seen_unique.has(discovery_id):
				_blocked_unique_discovery_ids[discovery_id] = true
				continue
			seen_unique[discovery_id] = true
		var island_id: String = ""
		if grid.has_method("get_island_id"):
			island_id = str(grid.get_island_id(coord))
		var structure: Dictionary = {
			"discovery_id": discovery_id,
			"coord": coord,
			"biome": tile.biome,
			"island_id": island_id,
			"tier": int(def.get("tier", 0)),
			"cap_increase": int(def.get("cap_increase", 0)),
			"is_unique": bool(def.get("is_unique", false)),
			"housing_capacity": int(def.get("housing_capacity", 0)),
			"effect_type": str(def.get("effect_type", "")),
			"effect_params": (def.get("effect_params", {}) as Dictionary).duplicate(true),
			"effects": _effects_array_from_variant(def.get("effects", [])),
			"asset_path": str(def.get("asset_path", "")),
			"sprite_frames_path": str(def.get("sprite_frames_path", "")),
		}
		_structures.append(structure)

func _enforce_wayfarer_torii_per_biome(grid: RefCounted) -> void:
	if grid == null or not grid.has_method("get_tile"):
		return
	var torii_coords_by_biome: Dictionary = {}
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
			continue
		if not bool(tile.metadata.get("shrine_built", false)):
			continue
		if str(tile.metadata.get("build_discovery_id", "")) != "disc_wayfarer_torii":
			continue
		var biome: int = tile.biome
		var arr_variant: Variant = torii_coords_by_biome.get(biome, null)
		var arr: Array[Vector2i] = []
		if arr_variant is Array:
			for existing_variant: Variant in arr_variant as Array:
				if existing_variant is Vector2i:
					arr.append(existing_variant as Vector2i)
		arr.append(coord)
		torii_coords_by_biome[biome] = arr

	for biome_variant: Variant in torii_coords_by_biome.keys():
		var coords_variant: Variant = torii_coords_by_biome.get(int(biome_variant), null)
		if not (coords_variant is Array):
			continue
		var coords: Array[Vector2i] = []
		for coord_variant: Variant in coords_variant as Array:
			if coord_variant is Vector2i:
				coords.append(coord_variant as Vector2i)
		if coords.size() <= 1:
			continue
		coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		)
		for i: int in range(1, coords.size()):
			var extra_coord: Vector2i = coords[i]
			var extra_tile: GardenTile = grid.get_tile(extra_coord)
			if extra_tile == null:
				continue
			extra_tile.metadata["shrine_built"] = false
			extra_tile.metadata.erase("build_discovery_id")
			extra_tile.metadata.erase("is_water_dropoff")

func _recompute_cap_from_structures() -> void:
	var cap_total: int = SatoriIdsScript.BASE_SATORI_CAP + _discovery_cap_bonus()
	var old_cap: int = _current_cap
	_current_cap = maxi(cap_total, SatoriIdsScript.BASE_SATORI_CAP)
	if old_cap != _current_cap:
		_current_satori = clamp(_current_satori, 0, _current_cap)
		satori_cap_changed.emit(_current_cap)
		_emit_satori_if_changed()

func _discovery_cap_bonus() -> int:
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	if persistence == null or not persistence.has_method("get_discovered_ids"):
		return 0
	var discovered_ids: Array[String] = []
	var discovered_variant: Variant = persistence.get_discovered_ids()
	if discovered_variant is Array:
		for id_variant: Variant in discovered_variant:
			discovered_ids.append(str(id_variant))
	var unique_disc_ids: Dictionary = {}
	for did: String in discovered_ids:
		if not did.begins_with("disc_"):
			continue
		unique_disc_ids[did] = true
	return unique_disc_ids.size() * DISCOVERY_CAP_PER_UNIQUE

func get_active_structures() -> Array[Dictionary]:
	return _structures.duplicate(true)

func set_structures_for_testing(structures: Array[Dictionary]) -> void:
	_structures = structures.duplicate(true)

func get_structure_definition(discovery_id: String) -> Dictionary:
	var def_variant: Variant = _structure_defs.get(discovery_id, null)
	if def_variant is Dictionary:
		return (def_variant as Dictionary).duplicate(true)
	return {}

func get_structure_count(discovery_id: String) -> int:
	var count: int = 0
	for structure: Dictionary in _structures:
		if str(structure.get("discovery_id", "")) == discovery_id:
			count += 1
	return count

func can_build_structure(discovery_id: String) -> bool:
	var def: Dictionary = get_structure_definition(discovery_id)
	if def.is_empty():
		return true
	if not bool(def.get("is_unique", false)):
		return true
	return get_structure_count(discovery_id) == 0

func block_structure_build(discovery_id: String, reason: String = "unique_already_built") -> void:
	_blocked_unique_discovery_ids[discovery_id] = true
	structure_build_blocked.emit(discovery_id, reason)

func is_structure_blocked(discovery_id: String) -> bool:
	return bool(_blocked_unique_discovery_ids.get(discovery_id, false))

func apply_monument_on_build(discovery_id: String) -> void:
	if discovery_id == "disc_great_torii":
		_apply_satori(_current_satori + GREAT_TORII_BURST)

func get_spirit_housing_capacity_bonus() -> int:
	var total_bonus: int = 0
	for structure: Dictionary in _structures:
		total_bonus += int(structure.get("housing_capacity", 0))
	return total_bonus

func _guidance_lantern_count() -> int:
	return get_structure_count("disc_guidance_lantern")

func _pagoda_count() -> int:
	return get_structure_count("disc_pagoda_of_the_five")

func _void_mirror_count_for_island(island_id: String) -> int:
	var count: int = 0
	if island_id.is_empty():
		return 0
	for structure: Dictionary in _structures:
		if str(structure.get("discovery_id", "")) != "disc_void_mirror":
			continue
		if str(structure.get("island_id", "")) == island_id:
			count += 1
	return count
