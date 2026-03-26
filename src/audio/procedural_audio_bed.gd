## ProceduralAudioBed — real-time PCM synthesiser using AudioStreamGenerator.
##
## No audio files required.  Provides a continuously running audio layer whose
## character is determined by its SynthMode.  Volume is controlled from outside
## via the `volume_db` property; setting it below −75 dB pauses synthesis to
## save CPU.
##
## Usage:
##   var bed := ProceduralAudioBed.new()
##   add_child(bed)                 # triggers _ready(); playback starts
##   bed.setup(SynthMode.HIHAT)     # configure synthesis mode
##   bed.volume_db = -10.0          # make audible
class_name ProceduralAudioBed
extends Node

# ---------------------------------------------------------------------------
# Synthesis modes
# ---------------------------------------------------------------------------

enum SynthMode {
	WIND,     ## Soft low-pass filtered white noise with slow amplitude swell.
	HIHAT,    ## Periodic white-noise burst with fast exponential decay — hi-hat.
	DRUM,     ## Low-frequency sine with pitch drop per beat — deep kick drum.
	DRONE,    ## Two slightly detuned sine waves — warm resonant hum.
	MELODIC,  ## Single soft sine with gentle vibrato.
	WATER,    ## Mid-frequency filtered noise with gentle ripple modulation.
	FIRE,     ## Filtered crackle noise with sparse random pops.
	STONE,    ## Very low, ultra-slow filtered rumble.
}

# ---------------------------------------------------------------------------
# Mode lookup tables (used by SoundscapeEngine)
# ---------------------------------------------------------------------------

## Maps spirit rhythm layer name → SynthMode value.
const LAYER_TO_MODE: Dictionary = {
	"hihat":   SynthMode.HIHAT,
	"drum":    SynthMode.DRUM,
	"melodic": SynthMode.MELODIC,
	"texture": SynthMode.DRONE,
}

## Maps BiomeType.Value → fallback SynthMode when no .ogg asset is present.
const BIOME_TO_MODE: Dictionary = {
	0:  SynthMode.STONE,   # STONE
	1:  SynthMode.WATER,   # RIVER
	2:  SynthMode.FIRE,    # EMBER_FIELD
	3:  SynthMode.WIND,    # MEADOW
	4:  SynthMode.WATER,   # WETLANDS
	5:  SynthMode.STONE,   # BADLANDS
	6:  SynthMode.WIND,    # WHISTLING_CANYONS
	7:  SynthMode.DRONE,   # PRISMATIC_TERRACES
	8:  SynthMode.WIND,    # FROSTLANDS
	9:  SynthMode.FIRE,    # THE_ASHFALL
	10: SynthMode.DRONE,   # SACRED_STONE
	11: SynthMode.WATER,   # MOONLIT_POOL
	12: SynthMode.FIRE,    # EMBER_SHRINE
	13: SynthMode.WIND,    # CLOUD_RIDGE
}

# ---------------------------------------------------------------------------
# Audio generator constants
# ---------------------------------------------------------------------------

## PCM sample rate — matches Godot's project default (44 100 Hz).
const MIX_RATE: float = 44100.0

## Generator ring-buffer length in seconds.  Larger = less frequent fills.
const BUFFER_LENGTH: float = 0.4

## Maximum frames pushed per _process() call (guards against very long stalls).
const MAX_FILL_FRAMES: int = 8192

## Volume threshold below which synthesis is skipped to save CPU.
const SILENCE_THRESHOLD_DB: float = -74.0

# ---------------------------------------------------------------------------
# Public properties
# ---------------------------------------------------------------------------

## Volume backing store — kept in sync with the internal AudioStreamPlayer.
var _volume_db: float = -80.0

var volume_db: float:
	set(v):
		_volume_db = v
		if _player != null:
			_player.volume_db = v
	get:
		return _volume_db

# ---------------------------------------------------------------------------
# Internal synthesiser state
# ---------------------------------------------------------------------------

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

var _mode: int = SynthMode.WIND
var _bpm: float = 72.0
var _base_freq: float = 80.0
var _lp_coeff: float = 0.015

## Main oscillator phase (0.0–1.0).
var _phase: float = 0.0
## Second oscillator phase used by DRONE mode.
var _phase2: float = 0.0
## Beat phase (0.0–1.0); advances at _bpm per second in rhythmic modes.
var _beat_phase: float = 0.0
## One-pole low-pass filter state.
var _lp_state: float = 0.0
## Elapsed synthesiser time in seconds (drives slow modulations).
var _time: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = BUFFER_LENGTH
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.bus = "Master"
	_player.volume_db = _volume_db
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


## Configure synthesis mode and rhythm parameters.  Call after add_child().
func setup(mode: int, bpm: float = 72.0, base_freq: float = 80.0) -> void:
	_mode = mode
	_bpm = bpm
	_base_freq = base_freq
	# Per-mode low-pass coefficient: smaller = more bass / more filtering.
	match mode:
		SynthMode.WIND:    _lp_coeff = 0.015
		SynthMode.HIHAT:   _lp_coeff = 0.40
		SynthMode.DRUM:    _lp_coeff = 0.008
		SynthMode.DRONE:   _lp_coeff = 0.04
		SynthMode.MELODIC: _lp_coeff = 0.06
		SynthMode.WATER:   _lp_coeff = 0.025
		SynthMode.FIRE:    _lp_coeff = 0.12
		SynthMode.STONE:   _lp_coeff = 0.005
		_:                 _lp_coeff = 0.02


# ---------------------------------------------------------------------------
# Buffer fill
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _playback == null:
		return
	# Skip synthesis when effectively silent — saves CPU on muted/quiet layers.
	if _volume_db < SILENCE_THRESHOLD_DB:
		return
	var available: int = _playback.get_frames_available()
	if available <= 0:
		return
	available = min(available, MAX_FILL_FRAMES)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(available)
	var beat_inc: float = (_bpm / 60.0) / MIX_RATE
	var time_inc: float = 1.0 / MIX_RATE
	for i: int in range(available):
		var s: float = _next_sample(beat_inc)
		frames[i] = Vector2(s, s)
		_time += time_inc
	_playback.push_frames(frames)


# ---------------------------------------------------------------------------
# Per-sample dispatch
# ---------------------------------------------------------------------------

func _next_sample(beat_inc: float) -> float:
	match _mode:
		SynthMode.WIND:    return _synth_wind()
		SynthMode.HIHAT:   return _synth_hihat(beat_inc)
		SynthMode.DRUM:    return _synth_drum(beat_inc)
		SynthMode.DRONE:   return _synth_drone()
		SynthMode.MELODIC: return _synth_melodic()
		SynthMode.WATER:   return _synth_water()
		SynthMode.FIRE:    return _synth_fire(beat_inc)
		SynthMode.STONE:   return _synth_stone()
	return 0.0


# ---------------------------------------------------------------------------
# Synthesis implementations
# ---------------------------------------------------------------------------

## Soft low-pass filtered noise with gentle amplitude swell — neutral wind.
func _synth_wind() -> float:
	var noise: float = randf() * 2.0 - 1.0
	_lp_state += (noise - _lp_state) * _lp_coeff
	# Slow sinusoidal amplitude swell (period ≈ 20 s).
	var am: float = 0.70 + 0.30 * sin(_time * 0.31)
	return _lp_state * am * 0.55


## Periodic white-noise burst at BPM with fast exponential decay — hi-hat.
func _synth_hihat(beat_inc: float) -> float:
	_beat_phase = fmod(_beat_phase + beat_inc, 1.0)
	# Envelope: sharp onset, decay over first ~5% of the beat.
	var env: float = exp(-_beat_phase * 30.0)
	return (randf() * 2.0 - 1.0) * env * 0.45


## Low-frequency sine with pitch-drop envelope per beat — deep kick drum.
func _synth_drum(beat_inc: float) -> float:
	_beat_phase = fmod(_beat_phase + beat_inc, 1.0)
	# Frequency drops from _base_freq to _base_freq/4 with exponential curve.
	var freq: float = _base_freq * exp(-_beat_phase * 7.0) + _base_freq * 0.25
	_phase = fmod(_phase + freq / MIX_RATE, 1.0)
	var env: float = exp(-_beat_phase * 5.0)
	return sin(_phase * TAU) * env * 0.55


## Two slightly detuned sine waves — warm resonant drone.
func _synth_drone() -> float:
	var f2: float = _base_freq * 1.007  # ≈ 12 cents sharp — gentle beating
	_phase = fmod(_phase + _base_freq / MIX_RATE, 1.0)
	_phase2 = fmod(_phase2 + f2 / MIX_RATE, 1.0)
	# Slow amplitude modulation (period ≈ 70 s).
	var am: float = 0.85 + 0.15 * sin(_time * 0.09)
	return (sin(_phase * TAU) + sin(_phase2 * TAU) * 0.55) * am * 0.22


## Soft sine with gentle vibrato — melodic water/bird spirits.
func _synth_melodic() -> float:
	var vibrato: float = 1.0 + 0.003 * sin(_time * 5.3)
	_phase = fmod(_phase + (_base_freq * vibrato) / MIX_RATE, 1.0)
	return sin(_phase * TAU) * 0.28


## Mid-frequency filtered noise with ripple AM — flowing water.
func _synth_water() -> float:
	var noise: float = randf() * 2.0 - 1.0
	_lp_state += (noise - _lp_state) * _lp_coeff
	# Dual-frequency ripple for organic texture.
	var ripple: float = 0.60 + 0.40 * sin(_time * 1.9) * sin(_time * 0.68)
	return _lp_state * ripple * 0.48


## Filtered crackle noise with sparse random pops — fire / ember.
func _synth_fire(beat_inc: float) -> float:
	_beat_phase = fmod(_beat_phase + beat_inc * 2.5, 1.0)
	var noise: float = randf() * 2.0 - 1.0
	_lp_state += (noise - _lp_state) * _lp_coeff
	# Sparse crackle pop (≈ 66 pops/s at 44100 Hz with p=0.0015).
	var crackle: float = 0.0
	if randf() < 0.0015:
		crackle = (randf() * 2.0 - 1.0) * 0.65
	return (_lp_state * 0.35 + crackle) * 0.60


## Ultra-low filtered rumble with very slow swell — stone / rock / badlands.
func _synth_stone() -> float:
	var noise: float = randf() * 2.0 - 1.0
	_lp_state += (noise - _lp_state) * _lp_coeff
	# Very slow amplitude swell (period ≈ 90 s).
	var am: float = 0.45 + 0.55 * sin(_time * 0.07)
	return _lp_state * am * 0.38
