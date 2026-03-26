## Unit tests for SoundscapeEngine and SpiritRhythmCatalog.
extends GutTest

# ---------------------------------------------------------------------------
# SpiritRhythmCatalog tests
# ---------------------------------------------------------------------------

func test_spirit_rhythm_catalog_lookup_known_spirit() -> void:
	var entry: Dictionary = SpiritRhythmCatalog.lookup("spirit_mist_stag")
	assert_false(entry.is_empty(), "Mist Stag should have a rhythm entry")
	assert_eq(entry["audio_key"], "stag_hihat", "Mist Stag should have hihat audio key")
	assert_eq(entry["layer"], "hihat", "Mist Stag layer should be hihat")


func test_spirit_rhythm_catalog_lookup_wolf() -> void:
	var entry: Dictionary = SpiritRhythmCatalog.lookup("spirit_boreal_wolf")
	assert_false(entry.is_empty(), "Boreal Wolf should have a rhythm entry")
	assert_eq(entry["audio_key"], "wolf_drums", "Boreal Wolf should have drum audio key")
	assert_eq(entry["layer"], "drum", "Boreal Wolf layer should be drum")


func test_spirit_rhythm_catalog_lookup_unknown_returns_empty() -> void:
	var entry: Dictionary = SpiritRhythmCatalog.lookup("spirit_does_not_exist")
	assert_true(entry.is_empty(), "Unknown spirit should return empty dict")


func test_spirit_rhythm_catalog_all_entries_have_required_fields() -> void:
	for spirit_id: String in SpiritRhythmCatalog.ENTRIES.keys():
		var entry: Dictionary = SpiritRhythmCatalog.ENTRIES[spirit_id]
		assert_true(entry.has("audio_key"), "%s missing audio_key" % spirit_id)
		assert_true(entry.has("path"), "%s missing path" % spirit_id)
		assert_true(entry.has("volume_db"), "%s missing volume_db" % spirit_id)
		assert_true(entry.has("layer"), "%s missing layer" % spirit_id)
		var valid_layers: Array[String] = ["hihat", "drum", "melodic", "texture"]
		assert_true(
			valid_layers.has(str(entry["layer"])),
			"%s has invalid layer: %s" % [spirit_id, str(entry["layer"])]
		)


func test_stacked_volume_db_single_spirit_no_rolloff() -> void:
	var result: float = SpiritRhythmCatalog.stacked_volume_db(-6.0, 1)
	assert_eq(result, -6.0, "Single spirit should have no rolloff")


func test_stacked_volume_db_two_spirits_reduces_volume() -> void:
	var result: float = SpiritRhythmCatalog.stacked_volume_db(-6.0, 2)
	assert_lt(result, -6.0, "Two spirits should reduce each layer's volume")
	# With 2 spirits: rolloff = 3.0 * log2(2) = 3.0 dB → result = -9.0
	assert_almost_eq(result, -9.0, 0.01, "Two spirits: -6 - 3 dB rolloff = -9 dB")


func test_stacked_volume_db_four_spirits() -> void:
	var result: float = SpiritRhythmCatalog.stacked_volume_db(-6.0, 4)
	# rolloff = 3.0 * log2(4) = 3.0 * 2 = 6.0 → result = -12.0
	assert_almost_eq(result, -12.0, 0.01, "Four spirits: -6 - 6 dB rolloff = -12 dB")


# ---------------------------------------------------------------------------
# SoundscapeEngine basic instantiation tests
# ---------------------------------------------------------------------------

func test_soundscape_engine_can_be_instantiated() -> void:
	pending("SoundscapeEngine is an autoload; instantiation tested via autoload presence in game context")


func test_soundscape_engine_master_volume_clamps() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)
	engine.set_master_volume(1.5)
	assert_eq(engine.get_master_volume(), 1.0, "Volume should clamp at 1.0")
	engine.set_master_volume(-0.5)
	assert_eq(engine.get_master_volume(), 0.0, "Volume should clamp at 0.0")
	engine.set_master_volume(0.6)
	assert_almost_eq(engine.get_master_volume(), 0.6, 0.001, "Volume 0.6 should be preserved")


func test_soundscape_engine_mute_toggle() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)
	assert_false(engine.is_muted(), "Engine should not be muted by default")
	engine.set_mute(true)
	assert_true(engine.is_muted(), "Engine should be muted after set_mute(true)")
	engine.set_mute(false)
	assert_false(engine.is_muted(), "Engine should be unmuted after set_mute(false)")


func test_soundscape_engine_stinger_queue_respects_max_depth() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)
	# Fill beyond MAX_STINGER_QUEUE (5); the 6th should be dropped silently.
	for i: int in range(6):
		engine.play_stinger("stinger_river")
	# Queue size should not exceed MAX_STINGER_QUEUE.
	assert_lte(
		engine._stinger_queue.size(),
		engine.MAX_STINGER_QUEUE,
		"Stinger queue should not exceed MAX_STINGER_QUEUE"
	)


func test_soundscape_engine_spirit_summoned_registers_entry() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)

	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_mist_stag",
		Vector2i(2, 3),
		Rect2i(-4, -4, 8, 8)
	)
	engine.on_spirit_summoned("spirit_mist_stag", instance)

	assert_true(
		engine._spirit_order.has("spirit_mist_stag"),
		"Stag should appear in spirit order after summoning"
	)
	assert_true(
		engine._spirit_world_pos.has("spirit_mist_stag"),
		"Stag should have a world position recorded"
	)


func test_soundscape_engine_unknown_spirit_not_added() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)

	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_unknown_creature",
		Vector2i(0, 0),
		Rect2i(-2, -2, 4, 4)
	)
	engine.on_spirit_summoned("spirit_unknown_creature", instance)

	assert_false(
		engine._spirit_order.has("spirit_unknown_creature"),
		"Unknown spirit should not be added to spirit order (no rhythm entry)"
	)
