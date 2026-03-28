class_name SatoriServiceNode
extends Node

const SatoriConditionSetScript = preload("res://src/satori/SatoriConditionSet.gd")
const SatoriConditionEvaluatorScript = preload("res://src/satori/SatoriConditionEvaluator.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SatoriIdsScript = preload("res://src/satori/SatoriIds.gd")
const PatternLoaderScript = preload("res://src/biomes/pattern_loader.gd")
const DiscoveryCatalogDataScript = preload("res://src/biomes/discovery_catalog_data.gd")

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
	_recompute_structures_from_grid()
	_recompute_cap_from_structures()
	_emit_satori_if_changed()

func _process(delta: float) -> void:
	_tick_accumulator += delta
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
	var all_entries: Array[Dictionary] = []
	all_entries.append_array(catalog_data.get_tier1_entries())
	all_entries.append_array(catalog_data.get_tier2_entries())
	for meta: Dictionary in all_entries:
		var did_from_catalog: String = str(meta.get("discovery_id", ""))
		if did_from_catalog.is_empty():
			continue
		var effect_params_variant: Variant = meta.get("effect_params", {})
		var effect_params: Dictionary = {}
		if effect_params_variant is Dictionary:
			effect_params = (effect_params_variant as Dictionary).duplicate(true)
		_structure_defs[did_from_catalog] = {
			"discovery_id": did_from_catalog,
			"tier": int(meta.get("tier", 0)),
			"cap_increase": int(meta.get("cap_increase", 0)),
			"is_unique": bool(meta.get("is_unique", false)),
			"housing_capacity": int(meta.get("housing_capacity", 0)),
			"effect_type": str(meta.get("effect_type", "")),
			"effect_params": effect_params,
		}
	var loader: PatternLoader = PatternLoaderScript.new()
	var patterns: Array[PatternDefinition] = loader.load_patterns()
	for pattern: PatternDefinition in patterns:
		var did: String = pattern.discovery_id
		if did.is_empty():
			continue
		_structure_defs[did] = {
			"discovery_id": did,
			"tier": pattern.tier,
			"cap_increase": pattern.cap_increase,
			"is_unique": pattern.is_unique,
			"housing_capacity": pattern.housing_capacity,
			"effect_type": pattern.effect_type,
			"effect_params": pattern.effect_params.duplicate(true),
		}

func _on_progress_event(_coord: Vector2i, _biome: int) -> void:
	evaluate()

func _on_spirit_summoned(_spirit_id: String, _instance: SpiritInstance) -> void:
	evaluate()

func _on_world_changed(_coord: Vector2i, _tile: GardenTile) -> void:
	_recompute_structures_from_grid()
	_recompute_cap_from_structures()

func evaluate() -> void:
	for condition_set: SatoriConditionSet in _conditions:
		if bool(_fired.get(condition_set.condition_id, false)):
			continue
		if SatoriConditionEvaluatorScript.evaluate(condition_set.requirements):
			_play_sequence(condition_set)
			return

func trigger_debug() -> void:
	var settings: Node = get_node_or_null("/root/GardenSettings")
	if settings == null:
		return
	if int(settings.get("growth_mode")) != GrowthModeScript.Value.INSTANT:
		return
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
	tween.tween_property(rect, "color", Color(1.0, 1.0, 1.0, 0.25), 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(rect, "color", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween.finished.connect(_complete_sequence)
	_skip_available = false
	set_process_input(true)
	_skip_timer = get_tree().create_timer(2.0)
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

func get_current_satori() -> int:
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

func process_minute_tick(snapshot_override: Dictionary = {}) -> Dictionary:
	var snapshot: Dictionary = snapshot_override if not snapshot_override.is_empty() else _snapshot_from_services()
	var housed_count: int = int(snapshot.get("housed_count", 0))
	var unhoused_count: int = int(snapshot.get("unhoused_count", 0))
	var base_delta: int = housed_count - (unhoused_count * 2)
	var modifier_delta: int = _modifier_delta_from_structures(snapshot)
	var applied_delta: int = base_delta + modifier_delta
	_apply_satori(_current_satori + applied_delta)
	return {
		"base_delta": base_delta,
		"modifier_delta": modifier_delta,
		"applied_delta": applied_delta,
		"new_satori": _current_satori,
		"new_era": _current_era,
	}

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
	var housed_by_island: Dictionary = {}
	var spirit_service: Node = get_node_or_null("/root/Garden/SpiritService")
	if spirit_service == null:
		spirit_service = get_node_or_null("/root/SpiritService")
	if spirit_service != null and spirit_service.has_method("get_housing_snapshot"):
		var snap: Dictionary = spirit_service.get_housing_snapshot()
		housed_count = int(snap.get("housed_count", 0))
		unhoused_count = int(snap.get("unhoused_count", 0))
		var by_island_variant: Variant = snap.get("housed_by_island", {})
		if by_island_variant is Dictionary:
			housed_by_island = (by_island_variant as Dictionary).duplicate(true)
	return {
		"housed_count": housed_count,
		"unhoused_count": unhoused_count,
		"housed_by_island": housed_by_island,
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
	var seen_unique: Dictionary = {}
	for coord_variant: Variant in grid.tiles.keys():
		var coord: Vector2i = coord_variant
		var tile: GardenTile = grid.get_tile(coord)
		if tile == null:
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
			"island_id": island_id,
			"tier": int(def.get("tier", 0)),
			"cap_increase": int(def.get("cap_increase", 0)),
			"is_unique": bool(def.get("is_unique", false)),
			"housing_capacity": int(def.get("housing_capacity", 0)),
			"effect_type": str(def.get("effect_type", "")),
			"effect_params": (def.get("effect_params", {}) as Dictionary).duplicate(true),
		}
		_structures.append(structure)

func _recompute_cap_from_structures() -> void:
	var cap_total: int = SatoriIdsScript.BASE_SATORI_CAP
	for structure: Dictionary in _structures:
		cap_total += int(structure.get("cap_increase", 0))
	var old_cap: int = _current_cap
	_current_cap = maxi(cap_total, SatoriIdsScript.BASE_SATORI_CAP)
	if old_cap != _current_cap:
		_current_satori = clamp(_current_satori, 0, _current_cap)
		satori_cap_changed.emit(_current_cap)
		_emit_satori_if_changed()

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
