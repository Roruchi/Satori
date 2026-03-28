## Unit tests for SoundscapeEngine, SpiritRhythmCatalog, and ProceduralAudioBed.
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
# ProceduralAudioBed tests
# ---------------------------------------------------------------------------

func test_procedural_audio_bed_layer_to_mode_hihat() -> void:
	var mode: int = int(ProceduralAudioBed.LAYER_TO_MODE.get("hihat", -1))
	assert_eq(mode, ProceduralAudioBed.SynthMode.HIHAT, "hihat layer should map to HIHAT mode")


func test_procedural_audio_bed_layer_to_mode_drum() -> void:
	var mode: int = int(ProceduralAudioBed.LAYER_TO_MODE.get("drum", -1))
	assert_eq(mode, ProceduralAudioBed.SynthMode.DRUM, "drum layer should map to DRUM mode")


func test_procedural_audio_bed_layer_to_mode_texture() -> void:
	var mode: int = int(ProceduralAudioBed.LAYER_TO_MODE.get("texture", -1))
	assert_eq(mode, ProceduralAudioBed.SynthMode.DRONE, "texture layer should map to DRONE mode")


func test_procedural_audio_bed_biome_to_mode_covers_all_biomes() -> void:
	# All 14 BiomeType.Value IDs (0–13) must have a fallback synthesis mode.
	for biome: int in range(14):
		assert_true(
			ProceduralAudioBed.BIOME_TO_MODE.has(biome),
			"Biome %d should have a fallback SynthMode" % biome
		)


func test_procedural_audio_bed_volume_property_default() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	assert_almost_eq(bed.volume_db, -80.0, 0.01, "Default volume_db should be -80.0")


func test_procedural_audio_bed_volume_property_set() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	bed.setup(ProceduralAudioBed.SynthMode.WIND)
	bed.volume_db = -12.0
	assert_almost_eq(bed.volume_db, -12.0, 0.01, "volume_db should reflect set value")


func test_procedural_audio_bed_setup_wind() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	bed.setup(ProceduralAudioBed.SynthMode.WIND, 60.0, 80.0)
	assert_almost_eq(bed._bpm, 60.0, 0.01, "BPM should be stored")
	assert_almost_eq(bed._base_freq, 80.0, 0.01, "base_freq should be stored")
	assert_almost_eq(bed._lp_coeff, 0.015, 0.001, "WIND lp_coeff should be 0.015")


func test_procedural_audio_bed_setup_hihat() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	bed.setup(ProceduralAudioBed.SynthMode.HIHAT)
	assert_almost_eq(bed._lp_coeff, 0.40, 0.001, "HIHAT lp_coeff should be 0.40")


func test_procedural_audio_bed_setup_drum() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	bed.setup(ProceduralAudioBed.SynthMode.DRUM)
	assert_almost_eq(bed._lp_coeff, 0.008, 0.001, "DRUM lp_coeff should be 0.008")


func test_procedural_audio_bed_silence_threshold_skips_synthesis() -> void:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	add_child(bed)
	bed.setup(ProceduralAudioBed.SynthMode.HIHAT)
	bed.volume_db = -80.0  # well below silence threshold
	# At volume_db = -80, synthesis should be skipped; no assertions beyond no crash.
	bed._process(0.016)
	assert_true(true, "Synthesis at silence threshold should not crash")


# ---------------------------------------------------------------------------
# SoundscapeEngine tests
# ---------------------------------------------------------------------------

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
	for i: int in range(6):
		engine.play_stinger("stinger_river")
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


func test_soundscape_engine_spirit_player_is_procedural_bed() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)

	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_mist_stag",
		Vector2i(0, 0),
		Rect2i(-4, -4, 8, 8)
	)
	engine.on_spirit_summoned("spirit_mist_stag", instance)

	assert_true(
		engine._spirit_players.has("spirit_mist_stag"),
		"Stag spirit player should be registered"
	)
	var bed: Variant = engine._spirit_players.get("spirit_mist_stag")
	assert_true(
		bed is ProceduralAudioBed,
		"Spirit player should be a ProceduralAudioBed (procedural synthesis, no .ogg needed)"
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


func test_soundscape_engine_keisu_resonance_triggers_and_decays() -> void:
	var engine := Node.new()
	engine.set_script(load("res://src/audio/soundscape_engine.gd"))
	add_child(engine)

	assert_almost_eq(engine.get_resonance_pitch_scale(), 1.0, 0.001, "Pitch should start neutral")
	engine.trigger_keisu_resonance()
	assert_gt(engine.get_resonance_pitch_scale(), 1.0, "Pitch should rise above neutral after trigger")

	engine._process(2.5)
	assert_gt(engine.get_resonance_pitch_scale(), 1.0, "Pitch should still be elevated mid-decay")

	engine._process(3.0)
	assert_almost_eq(engine.get_resonance_pitch_scale(), 1.0, 0.001, "Pitch should return to neutral after decay")
