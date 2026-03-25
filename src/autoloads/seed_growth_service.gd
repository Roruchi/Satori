class_name SeedGrowthServiceNode
extends Node

const SeedInstanceScript = preload("res://src/seeds/SeedInstance.gd")
const GrowthSlotTrackerScript = preload("res://src/seeds/GrowthSlotTracker.gd")
const SeedPouchScript = preload("res://src/seeds/SeedPouch.gd")
const SeedStateScript = preload("res://src/seeds/SeedState.gd")
const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")
const EVALUATION_TICK_SECONDS: float = 60.0
const REAL_TIME_GROWTH_SECONDS: float = 10.0

signal seed_planted(seed: SeedInstance)
signal seed_ready(seed: SeedInstance)
signal bloom_confirmed(coord: Vector2i, biome: int)
signal pouch_updated()

var _tracker: GrowthSlotTracker = GrowthSlotTrackerScript.new()
var _pouch: SeedPouch = SeedPouchScript.new()
var _mode: int = GrowthModeScript.Value.INSTANT
var _tick_timer: Timer

func _ready() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = EVALUATION_TICK_SECONDS
	_tick_timer.one_shot = false
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_tick_timeout)
	add_child(_tick_timer)

func _on_tick_timeout() -> void:
	_evaluate_all()

func _process(_delta: float) -> void:
	if _mode == GrowthModeScript.Value.REAL_TIME:
		_evaluate_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_evaluate_all()

func _duration_for_tier(tier: int) -> float:
	if _should_grow_instantly():
		return 0.0
	return REAL_TIME_GROWTH_SECONDS

func _should_grow_instantly() -> bool:
	return _mode == GrowthModeScript.Value.INSTANT

func try_plant(coord: Vector2i, recipe: SeedRecipe) -> bool:
	if _tracker.is_full():
		return false
	var duration: float = _duration_for_tier(recipe.tier)
	var seed: SeedInstance = SeedInstanceScript.create(recipe.recipe_id, coord, duration, recipe.produces_biome)
	_tracker.add(seed)
	seed_planted.emit(seed)
	if seed.evaluate_growth():
		seed_ready.emit(seed)
	return true

func try_bloom(coord: Vector2i) -> bool:
	var seed: SeedInstance = _tracker.get_at(coord)
	if seed == null:
		return false
	if seed.state == SeedStateScript.Value.GROWING:
		seed.evaluate_growth()
	if seed.state != SeedStateScript.Value.READY:
		return false
	seed.state = SeedStateScript.Value.BLOOMED
	_tracker.remove_bloomed(coord)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("place_tile_from_seed"):
		game_state.place_tile_from_seed(coord, seed.produces_biome)
	bloom_confirmed.emit(coord, seed.produces_biome)
	return true

func _evaluate_all() -> void:
	var pending_ready: Array[SeedInstance] = []
	for seed: SeedInstance in _tracker.active_seeds:
		if seed.evaluate_growth():
			pending_ready.append(seed)
	for seed_ready_instance: SeedInstance in pending_ready:
		seed_ready.emit(seed_ready_instance)

func get_mode() -> int:
	return _mode

func set_mode(mode: int) -> void:
	_mode = mode
	if _mode == GrowthModeScript.Value.INSTANT:
		_evaluate_all()
		_auto_bloom_ready_when_possible()

func _auto_bloom_ready_when_possible() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("place_tile_from_seed"):
		return
	var ready_coords: Array[Vector2i] = []
	for seed: SeedInstance in _tracker.get_ready_seeds():
		ready_coords.append(seed.hex_coord)
	for coord: Vector2i in ready_coords:
		try_bloom(coord)

func available_slots() -> int:
	return _tracker.available_slots()

func get_ready_seeds() -> Array[SeedInstance]:
	return _tracker.get_ready_seeds()

func get_tracker() -> GrowthSlotTracker:
	return _tracker

func get_pouch() -> SeedPouch:
	return _pouch

func notify_pouch_updated() -> void:
	pouch_updated.emit()

func expand_slots() -> void:
	_tracker.capacity += 1

func debug_expand_slots() -> void:
	expand_slots()
