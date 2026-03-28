## SoundscapeEngine — generative, blending ambient soundscape autoload.
##
## Responsibilities:
##   • Maintains one ProceduralAudioBed (or AudioStreamPlayer) per biome bed
##     and a ProceduralAudioBed neutral-wind layer; volumes are lerped each frame
##     toward targets derived from the biome composition visible in the viewport.
##   • Manages per-spirit ProceduralAudioBed rhythm layers that activate while
##     the spirit is within the viewport; volumes are normalised to stay calming
##     regardless of how many spirits are present.
##   • Queues discovery stingers (max depth 5) and plays them sequentially.
##   • Respects master volume and mute settings.
##
## No audio files are required.  The neutral wind, all spirit rhythm layers,
## and all biome beds without a .ogg asset are synthesised in real-time using
## ProceduralAudioBed (AudioStreamGenerator-backed PCM synthesis).
## When a .ogg asset IS present for a biome, it is used instead for richer texture.
extends Node

const _HexUtils = preload("res://src/grid/hex_utils.gd")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Hex circumradius in world-pixels (must match GardenView.TILE_RADIUS).
const TILE_RADIUS: float = 20.0

## How quickly biome bed volumes lerp toward their targets (per second).
const BIOME_LERP_RATE: float = 3.0

## How quickly spirit rhythm volumes lerp toward their targets (per second).
const SPIRIT_LERP_RATE: float = 2.5

## Maximum simultaneous spirit rhythm layers (keeps mix calming).
const MAX_SPIRIT_LAYERS: int = 5

## Stinger queue maximum depth.
const MAX_STINGER_QUEUE: int = 5

## Audio bus name used for all streams.
const BUS_MASTER: String = "Master"

## Interval (seconds) between full viewport biome re-samples.
const SAMPLE_INTERVAL: float = 0.1

## Global BPM for all rhythmic spirit layers.  Slow and calming.
const GLOBAL_BPM: float = 72.0
const RESONANCE_DECAY_SECONDS: float = 5.0
const RESONANCE_MAX_PITCH_DELTA: float = 0.12

# ---------------------------------------------------------------------------
# Biome-bed optional .ogg paths  (BiomeType.Value → res:// path)
# When the file is absent the engine automatically synthesises a procedural bed.
# ---------------------------------------------------------------------------

const _BIOME_BED_PATHS: Dictionary = {
	0:  "res://assets/audio/biomes/stone.ogg",
	1:  "res://assets/audio/biomes/river.ogg",
	2:  "res://assets/audio/biomes/ember_field.ogg",
	3:  "res://assets/audio/biomes/meadow.ogg",
	4:  "res://assets/audio/biomes/wetlands.ogg",
	5:  "res://assets/audio/biomes/badlands.ogg",
	6:  "res://assets/audio/biomes/whistling_canyons.ogg",
	7:  "res://assets/audio/biomes/prismatic_terraces.ogg",
	8:  "res://assets/audio/biomes/frostlands.ogg",
	9:  "res://assets/audio/biomes/the_ashfall.ogg",
	10: "res://assets/audio/biomes/sacred_stone.ogg",
	11: "res://assets/audio/biomes/moonlit_pool.ogg",
	12: "res://assets/audio/biomes/ember_shrine.ogg",
	13: "res://assets/audio/biomes/cloud_ridge.ogg",
}

## Characteristic base frequency per biome for procedural synthesis.
const _BIOME_BASE_FREQ: Dictionary = {
	0:  60.0,    # STONE          — deep rumble
	1:  200.0,   # RIVER          — mid-range flow
	2:  100.0,   # EMBER_FIELD    — low crackle
	3:  180.0,   # MEADOW         — bright breeze
	4:  150.0,   # WETLANDS       — mid murk
	5:  70.0,    # BADLANDS       — dry low rumble
	6:  260.0,   # WHISTLING_CANYONS — high wind howl
	7:  90.0,    # PRISMATIC_TERRACES — resonant drone
	8:  160.0,   # FROSTLANDS     — cold mid wind
	9:  80.0,    # THE_ASHFALL    — low ember crackle
	10: 55.0,    # SACRED_STONE   — sub drone
	11: 130.0,   # MOONLIT_POOL   — gentle water
	12: 95.0,    # EMBER_SHRINE   — warm crackle
	13: 300.0,   # CLOUD_RIDGE    — high airy wind
}

## Base frequency per spirit rhythm layer type.
const _LAYER_BASE_FREQ: Dictionary = {
	"hihat":   400.0,
	"drum":    70.0,
	"melodic": 220.0,
	"texture": 110.0,
}

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## BiomeType.Value → Node (AudioStreamPlayer when .ogg present, else ProceduralAudioBed).
var _biome_players: Dictionary = {}

## Current live volume weight for each biome bed (0.0–1.0, lerped).
var _biome_volume: Dictionary = {}

## Target volume weight from latest viewport sample.
var _biome_target: Dictionary = {}

## Neutral wind ambient layer (always procedural).
var _neutral_player: ProceduralAudioBed
var _neutral_volume: float = 1.0
var _neutral_target: float = 1.0

## spirit_id → ProceduralAudioBed for rhythmic layers (always procedural).
var _spirit_players: Dictionary = {}

## Current live volume weight per spirit rhythm layer (0.0–1.0).
var _spirit_volume: Dictionary = {}

## Target volume weight per spirit (1.0 = in-view, 0.0 = out-of-view or silent).
var _spirit_target: Dictionary = {}

## spirit_id → world spawn position (used for viewport check).
var _spirit_world_pos: Dictionary = {}

## spirit_id → wander radius in world pixels (used to expand viewport test).
var _spirit_world_radius: Dictionary = {}

## Ordered set of currently active spirit IDs (most-recently-summoned last).
var _spirit_order: Array[String] = []

## Queue of audio_key strings for discovery stingers.
var _stinger_queue: Array[String] = []

## Single AudioStreamPlayer for sequential stinger playback.
var _stinger_player: AudioStreamPlayer

## Whether a stinger is currently playing.
var _stinger_active: bool = false

## Master volume (linear, 0.0–1.0).
var _master_volume: float = 1.0

## Mute flag.
var _muted: bool = false

## Accumulator for viewport re-sample throttle.
var _sample_timer: float = 0.0
var _resonance_time_left: float = 0.0
var _resonance_pitch_scale: float = 1.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_create_neutral_player()
	for biome: int in _BIOME_BED_PATHS.keys():
		_create_biome_player(biome)
	_stinger_player = _make_ogg_player("stinger")
	_stinger_player.finished.connect(_on_stinger_finished)
	call_deferred("_connect_spirit_service")


func _connect_spirit_service() -> void:
	# Primary wiring: SpiritService._connect_soundscape() already connected.
	# This fallback catches any scene where that hook is absent.
	for child: Node in get_tree().root.get_children():
		_try_connect_spirit_service_in(child)


func _try_connect_spirit_service_in(node: Node) -> void:
	if node.get_script() != null \
			and node.get_script().resource_path == "res://src/spirits/spirit_service.gd":
		if node.has_signal("spirit_summoned") \
				and not node.spirit_summoned.is_connected(on_spirit_summoned):
			node.spirit_summoned.connect(on_spirit_summoned)
		return
	for child: Node in node.get_children():
		_try_connect_spirit_service_in(child)


func _process(delta: float) -> void:
	_tick_resonance(delta)
	_sample_timer += delta
	if _sample_timer >= SAMPLE_INTERVAL:
		_sample_timer = 0.0
		_sample_viewport()
		_update_spirit_visibility()
	_lerp_biome_volumes(delta)
	_lerp_spirit_volumes(delta)
	_tick_stinger_queue()

func trigger_keisu_resonance() -> void:
	_resonance_time_left = RESONANCE_DECAY_SECONDS
	_apply_resonance_pitch()

func get_resonance_pitch_scale() -> float:
	return _resonance_pitch_scale


# ---------------------------------------------------------------------------
# Viewport biome sampling
# ---------------------------------------------------------------------------

func _sample_viewport() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cam_pos: Vector2 = cam.get_screen_center_position()
	var zoom: Vector2 = cam.zoom
	var half_w: float = (vp_size.x * 0.5) / zoom.x
	var half_h: float = (vp_size.y * 0.5) / zoom.y
	var world_rect: Rect2 = Rect2(
		cam_pos - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0)
	)

	var counts: Dictionary = {}
	var grid: RefCounted = GameState.grid
	var total: int = 0
	for coord: Vector2i in grid.tiles.keys():
		var world_px: Vector2 = _HexUtils.axial_to_pixel(coord, TILE_RADIUS)
		if world_rect.has_point(world_px):
			var tile: GardenTile = grid.tiles[coord] as GardenTile
			if tile == null:
				continue
			var b: int = tile.biome
			counts[b] = int(counts.get(b, 0)) + 1
			total += 1

	var new_targets: Dictionary = {}
	for biome: int in _BIOME_BED_PATHS.keys():
		new_targets[biome] = 0.0

	var biome_total_weight: float = 0.0
	if total > 0:
		for biome: int in counts.keys():
			var w: float = float(int(counts[biome])) / float(total)
			if new_targets.has(biome):
				new_targets[biome] = w
			biome_total_weight += w

	for biome: int in new_targets.keys():
		_biome_target[biome] = float(new_targets[biome])

	_neutral_target = max(0.0, 1.0 - biome_total_weight)


# ---------------------------------------------------------------------------
# Spirit visibility
# ---------------------------------------------------------------------------

func _update_spirit_visibility() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cam_pos: Vector2 = cam.get_screen_center_position()
	var zoom: Vector2 = cam.zoom
	var half_w: float = (vp_size.x * 0.5) / zoom.x
	var half_h: float = (vp_size.y * 0.5) / zoom.y
	var world_rect: Rect2 = Rect2(
		cam_pos - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0)
	)

	var in_view: Array[String] = []
	for spirit_id: String in _spirit_order:
		if not _spirit_world_pos.has(spirit_id):
			continue
		var pos: Vector2 = _spirit_world_pos.get(spirit_id, Vector2.ZERO)
		var radius: float = float(_spirit_world_radius.get(spirit_id, TILE_RADIUS * 2.0))
		if world_rect.grow(radius).has_point(pos):
			in_view.append(spirit_id)

	var active_set: Dictionary = {}
	var active_count: int = min(in_view.size(), MAX_SPIRIT_LAYERS)
	for i: int in range(in_view.size() - active_count, in_view.size()):
		active_set[in_view[i]] = true

	for spirit_id: String in _spirit_order:
		if active_set.has(spirit_id):
			var entry: Dictionary = SpiritRhythmCatalog.lookup(spirit_id)
			var base_db: float = float(entry.get("volume_db", -10.0))
			var stacked_db: float = SpiritRhythmCatalog.stacked_volume_db(base_db, active_count)
			_spirit_target[spirit_id] = db_to_linear(stacked_db)
		else:
			_spirit_target[spirit_id] = 0.0


# ---------------------------------------------------------------------------
# Volume lerping
# ---------------------------------------------------------------------------

func _lerp_biome_volumes(delta: float) -> void:
	var master_lin: float = 0.0 if _muted else _master_volume
	for biome: int in _biome_players.keys():
		var target: float = float(_biome_target.get(biome, 0.0)) * master_lin
		var current: float = float(_biome_volume.get(biome, 0.0))
		var new_vol: float = lerp(current, target, BIOME_LERP_RATE * delta)
		_biome_volume[biome] = new_vol
		_set_node_volume(_biome_players[biome] as Node, linear_to_db(max(new_vol, 0.0001)))
	# Neutral wind.
	var n_target: float = _neutral_target * master_lin
	_neutral_volume = lerp(_neutral_volume, n_target, BIOME_LERP_RATE * delta)
	_neutral_player.volume_db = linear_to_db(max(_neutral_volume, 0.0001))


func _lerp_spirit_volumes(delta: float) -> void:
	var master_lin: float = 0.0 if _muted else _master_volume
	for spirit_id: String in _spirit_players.keys():
		var bed: ProceduralAudioBed = _spirit_players[spirit_id] as ProceduralAudioBed
		if bed == null:
			continue
		var target: float = float(_spirit_target.get(spirit_id, 0.0)) * master_lin
		var current: float = float(_spirit_volume.get(spirit_id, 0.0))
		var new_vol: float = lerp(current, target, SPIRIT_LERP_RATE * delta)
		_spirit_volume[spirit_id] = new_vol
		bed.volume_db = linear_to_db(max(new_vol, 0.0001))


# ---------------------------------------------------------------------------
# Stinger queue
# ---------------------------------------------------------------------------

func play_stinger(audio_key: String) -> void:
	if audio_key.is_empty():
		return
	if _stinger_queue.size() >= MAX_STINGER_QUEUE:
		RuntimeLogger.warn("SoundscapeEngine", "Stinger queue full; dropping: %s" % audio_key)
		return
	_stinger_queue.append(audio_key)


func _tick_stinger_queue() -> void:
	if _stinger_active or _stinger_queue.is_empty():
		return
	if _stinger_player.playing:
		return
	var audio_key: String = str(_stinger_queue.pop_front())
	_play_stinger_now(audio_key)


func _play_stinger_now(audio_key: String) -> void:
	var path: String = DiscoveryAudioPlayer.AUDIO_MAP.get(audio_key, "")
	if path.is_empty():
		_stinger_active = false
		return
	if not ResourceLoader.exists(path):
		RuntimeLogger.warn("SoundscapeEngine", "Stinger asset absent (placeholder): %s" % path)
		_stinger_active = false
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		_stinger_active = false
		return
	_stinger_active = true
	_stinger_player.stream = stream
	_stinger_player.volume_db = 0.0
	_stinger_player.play()


func _on_stinger_finished() -> void:
	_stinger_active = false


# ---------------------------------------------------------------------------
# Spirit summoning hook
# ---------------------------------------------------------------------------

## Public entry point — called by SpiritService via signal connection.
func on_spirit_summoned(spirit_id: String, instance: SpiritInstance) -> void:
	_on_spirit_summoned(spirit_id, instance)


func _on_spirit_summoned(spirit_id: String, instance: SpiritInstance) -> void:
	var entry: Dictionary = SpiritRhythmCatalog.lookup(spirit_id)
	if entry.is_empty():
		return  # Spirit has no rhythmic identity.

	var spawn_world: Vector2 = _HexUtils.axial_to_pixel(instance.spawn_coord, TILE_RADIUS)
	_spirit_world_pos[spirit_id] = spawn_world
	var wander_px: float = float(instance.wander_bounds.size.x) * TILE_RADIUS + TILE_RADIUS * 3.0
	_spirit_world_radius[spirit_id] = wander_px

	if not _spirit_players.has(spirit_id):
		var bed: ProceduralAudioBed = _make_spirit_bed(spirit_id, entry)
		_spirit_players[spirit_id] = bed
		_spirit_volume[spirit_id] = 0.0
		_spirit_target[spirit_id] = 0.0
	if not _spirit_order.has(spirit_id):
		_spirit_order.append(spirit_id)


# ---------------------------------------------------------------------------
# Master volume and mute
# ---------------------------------------------------------------------------

func set_master_volume(linear: float) -> void:
	_master_volume = clampf(linear, 0.0, 1.0)


func set_mute(muted: bool) -> void:
	_muted = muted


func get_master_volume() -> float:
	return _master_volume


func is_muted() -> bool:
	return _muted


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Create one biome ambient layer.  Uses .ogg when available; falls back to
## a ProceduralAudioBed tuned to the biome's character.
func _create_biome_player(biome: int) -> void:
	var path: String = str(_BIOME_BED_PATHS.get(biome, ""))
	if ResourceLoader.exists(path):
		var player: AudioStreamPlayer = _make_ogg_player("biome_%d" % biome)
		var stream: AudioStream = load(path) as AudioStream
		if stream != null:
			_enable_loop(stream)
			player.stream = stream
			player.play()
		_biome_players[biome] = player
	else:
		var mode: int = int(ProceduralAudioBed.BIOME_TO_MODE.get(biome, ProceduralAudioBed.SynthMode.WIND))
		var freq: float = float(_BIOME_BASE_FREQ.get(biome, 100.0))
		var bed: ProceduralAudioBed = _make_proc_bed("biome_%d" % biome, mode, -80.0, freq)
		_biome_players[biome] = bed
	_biome_volume[biome] = 0.0
	_biome_target[biome] = 0.0


## Neutral wind — always synthesised; no asset file needed.
func _create_neutral_player() -> void:
	_neutral_player = _make_proc_bed(
		"neutral_wind", ProceduralAudioBed.SynthMode.WIND, 0.0, 60.0
	)
	_neutral_volume = 1.0
	_neutral_target = 1.0


## Spirit rhythm layer — always synthesised; no asset file needed.
func _make_spirit_bed(spirit_id: String, entry: Dictionary) -> ProceduralAudioBed:
	var layer: String = str(entry.get("layer", "texture"))
	var mode: int = int(ProceduralAudioBed.LAYER_TO_MODE.get(layer, ProceduralAudioBed.SynthMode.DRONE))
	var freq: float = float(_LAYER_BASE_FREQ.get(layer, 80.0))
	return _make_proc_bed("spirit_%s" % spirit_id, mode, -80.0, freq)


## Instantiate a ProceduralAudioBed, add it as a child, configure it, and
## set its initial volume.
func _make_proc_bed(
	label: String, mode: int, initial_vol_db: float, base_freq: float
) -> ProceduralAudioBed:
	var bed: ProceduralAudioBed = ProceduralAudioBed.new()
	bed.name = label
	add_child(bed)  # _ready() runs: AudioStreamGenerator created and started
	bed.setup(mode, GLOBAL_BPM, base_freq)
	bed.volume_db = initial_vol_db
	return bed


## Instantiate a plain AudioStreamPlayer for .ogg playback (stingers, biome .ogg).
func _make_ogg_player(label: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = label
	p.bus = BUS_MASTER
	p.volume_db = -80.0
	add_child(p)
	return p


## Set volume_db on a node that is either AudioStreamPlayer or ProceduralAudioBed.
func _set_node_volume(node: Node, db: float) -> void:
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).volume_db = db
	elif node is ProceduralAudioBed:
		(node as ProceduralAudioBed).volume_db = db

func _set_node_pitch(node: Node, pitch: float) -> void:
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).pitch_scale = pitch
	elif node is ProceduralAudioBed:
		(node as ProceduralAudioBed).pitch_scale = pitch

func _tick_resonance(delta: float) -> void:
	if _resonance_time_left > 0.0:
		_resonance_time_left = maxf(0.0, _resonance_time_left - delta)
	var safe_decay: float = maxf(RESONANCE_DECAY_SECONDS, 0.001)
	var ratio: float = _resonance_time_left / safe_decay
	_resonance_pitch_scale = 1.0 + (RESONANCE_MAX_PITCH_DELTA * ratio)
	_apply_resonance_pitch()

func _apply_resonance_pitch() -> void:
	var pitch: float = _resonance_pitch_scale
	if _neutral_player != null:
		_neutral_player.pitch_scale = pitch
	if _stinger_player != null:
		_stinger_player.pitch_scale = pitch
	for biome: int in _biome_players.keys():
		_set_node_pitch(_biome_players[biome] as Node, pitch)
	for spirit_id: String in _spirit_players.keys():
		_set_node_pitch(_spirit_players[spirit_id] as Node, pitch)


## Enable looping on a concrete AudioStream subtype (.ogg or .mp3).
func _enable_loop(stream: AudioStream) -> void:
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
		return
	var mp3: AudioStreamMP3 = stream as AudioStreamMP3
	if mp3 != null:
		mp3.loop = true
