extends SceneTree

const GARDEN_SCENE_PATH := "res://scenes/Garden.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load(GARDEN_SCENE_PATH)
	if packed == null:
		push_error("Headless boot failed: could not load %s" % GARDEN_SCENE_PATH)
		quit(1)
		return

	var garden: Node = packed.instantiate()
	if garden == null:
		push_error("Headless boot failed: could not instantiate %s" % GARDEN_SCENE_PATH)
		quit(1)
		return

	root.add_child(garden)
	await process_frame
	await process_frame

	var autoloads: Array[String] = [
		"GameState",
		"SeedAlchemyService",
		"SeedGrowthService",
		"CodexService",
		"SatoriService",
	]
	for autoload_name: String in autoloads:
		if root.get_node_or_null(autoload_name) == null:
			push_error("Headless boot failed: missing autoload %s" % autoload_name)
			quit(1)
			return

	print("Headless boot ok: %s loaded and core autoloads are present." % GARDEN_SCENE_PATH)
	quit(0)
