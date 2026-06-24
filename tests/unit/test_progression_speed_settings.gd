extends GutTest

const GameStateScript = preload("res://src/autoloads/GameState.gd")

var _settings_was_created: bool = false
var _original_multiplier: float = 1.0

func before_each() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	_original_multiplier = float(settings.get("growth_speed_multiplier"))
	settings.set_growth_speed_multiplier(1.0)

func after_each() -> void:
	var settings: GardenSettingsNode = get_tree().root.get_node_or_null("/root/GardenSettings") as GardenSettingsNode
	if settings != null:
		settings.set_growth_speed_multiplier(_original_multiplier)
		if _settings_was_created:
			get_tree().root.remove_child(settings)
			settings.free()
			_settings_was_created = false

func _ensure_settings() -> GardenSettingsNode:
	var root: Node = get_tree().root
	var settings: GardenSettingsNode = root.get_node_or_null("/root/GardenSettings") as GardenSettingsNode
	if settings != null:
		return settings
	settings = GardenSettingsNode.new()
	settings.name = "GardenSettings"
	root.add_child(settings)
	_settings_was_created = true
	return settings

func test_progression_speed_helpers_clamp_and_scale_to_x16() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(32.0)
	assert_eq(settings.get_progression_speed_multiplier(), 16.0)
	assert_eq(settings.scale_progress_delta(6.25), 100.0)
	assert_eq(settings.scaled_progress_duration(10.0), 0.625)

func test_hud_progression_button_cycles_to_x16() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(1.0)
	var button: Button = GrowthModeToggleButton.new()
	add_child(button)
	await get_tree().process_frame
	assert_eq(button.text, "x1")
	button.pressed.emit()
	assert_eq(settings.get_progression_speed_multiplier(), 4.0)
	assert_eq(button.text, "x4")
	button.pressed.emit()
	assert_eq(settings.get_progression_speed_multiplier(), 8.0)
	assert_eq(button.text, "x8")
	button.pressed.emit()
	assert_eq(settings.get_progression_speed_multiplier(), 16.0)
	assert_eq(button.text, "x16")
	button.pressed.emit()
	assert_eq(settings.get_progression_speed_multiplier(), 1.0)
	assert_eq(button.text, "x1")
	remove_child(button)
	button.free()

func test_material_spawn_uses_progression_speed_multiplier() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(16.0)
	var game_state: Node = Node.new()
	game_state.set_script(GameStateScript)
	add_child(game_state)
	game_state._ready()
	game_state.place_tile_from_seed(Vector2i(1, 0), BiomeType.Value.MEADOW)
	assert_eq(game_state.evaluate_material_spawns(6.24).size(), 0)
	assert_eq(game_state.evaluate_material_spawns(0.01).size(), 1)
	assert_true(game_state.has_ready_material_at(Vector2i(1, 0)))
	remove_child(game_state)
	game_state.free()

func test_satori_tick_accumulator_uses_progression_speed_multiplier() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(16.0)
	var service: SatoriServiceNode = SatoriServiceNode.new()
	add_child(service)
	service._process(3.75)
	assert_true(float(service.get("_tick_accumulator")) < 0.001)
	remove_child(service)
	service.free()

func test_build_countdown_duration_uses_progression_speed_multiplier() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(16.0)
	var controller: Node2D = load("res://src/grid/PlacementController.gd").new()
	add_child(controller)
	assert_eq(float(controller.call("_build_countdown_duration")), 0.625)
	remove_child(controller)
	controller.free()

func test_spirit_essence_duration_uses_progression_speed_multiplier() -> void:
	var settings: GardenSettingsNode = _ensure_settings()
	settings.set_growth_speed_multiplier(16.0)
	var service: SpiritService = SpiritService.new()
	add_child(service)
	assert_eq(float(service.call("_progression_duration", 60.0)), 3.75)
	remove_child(service)
	service.free()
