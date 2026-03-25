class_name SatoriServiceNode
extends Node

const SatoriConditionSetScript = preload("res://src/satori/SatoriConditionSet.gd")
const SatoriConditionEvaluatorScript = preload("res://src/satori/SatoriConditionEvaluator.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const GrowthModeScript = preload("res://src/seeds/GrowthMode.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")

signal satori_moment_fired(condition_id: StringName)

var _conditions: Array[SatoriConditionSet] = []
var _fired: Dictionary = {}
var _active_overlay: CanvasLayer
var _skip_available: bool = false
var _pending_unlock: SatoriConditionSet
var _skip_timer: SceneTreeTimer

func _ready() -> void:
	_load_conditions()
	var growth_service: Node = get_node_or_null("/root/SeedGrowthService")
	if growth_service != null and growth_service.has_signal("bloom_confirmed"):
		growth_service.bloom_confirmed.connect(_on_progress_event)
	var spirit_service: Node = get_node_or_null("/root/SpiritService")
	if spirit_service != null and spirit_service.has_signal("spirit_summoned"):
		spirit_service.spirit_summoned.connect(_on_spirit_summoned)

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

func _on_progress_event(_coord: Vector2i, _biome: int) -> void:
	evaluate()

func _on_spirit_summoned(_spirit_id: String, _instance: SpiritInstance) -> void:
	evaluate()

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
