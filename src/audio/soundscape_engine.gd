## SoundscapeEngine — generative, blending ambient soundscape autoload.
##
## Responsibilities:
##   • Maintains one looping AudioStreamPlayer per biome bed and a neutral-wind
##     player; volumes are lerped each frame toward targets derived from the
##     biome composition currently visible inside the camera viewport.
##   • Manages a set of per-spirit rhythmic AudioStreamPlayers that activate
##     while the spirit is within the viewport; volumes are normalised to stay
##     calming regardless of how many spirits are present.
##   • Queues discovery stingers (max depth 5) and plays them sequentially
##     without overlapping the ambient mix.
##   • Respects master volume and mute settings from GardenSettings.
##
## Audio asset files (.ogg) are never committed to the repository; every load
## is guarded and gracefully no-ops when the asset is absent.
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

## Audio bus name used for all ambient and rhythm streams.
const BUS_MASTER: String = "Master"

## Interval (seconds) between full viewport biome re-samples.
## Sampling happens at most once per SAMPLE_INTERVAL to reduce overhead.
const SAMPLE_INTERVAL: float = 0.1

# ---------------------------------------------------------------------------
# Biome-bed audio paths  (BiomeType.Value → res:// path)
# ---------------------------------------------------------------------------

const _BIOME_BED_PATHS: Dictionary = {
	0:  "res://assets/audio/biomes/stone.ogg",           # STONE / FOREST
	1:  "res://assets/audio/biomes/river.ogg",           # RIVER / WATER
	2:  "res://assets/audio/biomes/ember_field.ogg",     # EMBER_FIELD
	3:  "res://assets/audio/biomes/meadow.ogg",          # MEADOW
	4:  "res://assets/audio/biomes/wetlands.ogg",        # WETLANDS / SWAMP
	5:  "res://assets/audio/biomes/badlands.ogg",        # BADLANDS / TUNDRA / DESERT
	6:  "res://assets/audio/biomes/whistling_canyons.ogg", # WHISTLING_CANYONS
	7:  "res://assets/audio/biomes/prismatic_terraces.ogg", # PRISMATIC_TERRACES
	8:  "res://assets/audio/biomes/frostlands.ogg",      # FROSTLANDS / BOG
	9:  "res://assets/audio/biomes/the_ashfall.ogg",     # THE_ASHFALL
	10: "res://assets/audio/biomes/sacred_stone.ogg",    # SACRED_STONE
	11: "res://assets/audio/biomes/moonlit_pool.ogg",    # MOONLIT_POOL
	12: "res://assets/audio/biomes/ember_shrine.ogg",    # EMBER_SHRINE
	13: "res://assets/audio/biomes/cloud_ridge.ogg",     # CLOUD_RIDGE
}

const _NEUTRAL_BED_PATH: String = "res://assets/audio/biomes/neutral_wind.ogg"

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## BiomeType.Value → AudioStreamPlayer (looping ambient bed).
var _biome_players: Dictionary = {}

## Current live volume weight for each biome bed (0.0–1.0, lerped).
var _biome_volume: Dictionary = {}

## Target volume weight from latest viewport sample.
var _biome_target: Dictionary = {}

## Neutral wind ambient player and its live/target volumes.
var _neutral_player: AudioStreamPlayer
var _neutral_volume: float = 1.0
var _neutral_target: float = 1.0

## spirit_id → AudioStreamPlayer for rhythmic layers.
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

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_create_neutral_player()
	for biome in _BIOME_BED_PATHS.keys():
		_create_biome_player(biome)
	_stinger_player = _make_stream_player("stinger")
	_stinger_player.finished.connect(_on_stinger_finished)
	# Connect to SpiritService once the tree is ready.
	call_deferred("_connect_spirit_service")


func _connect_spirit_service() -> void:
	# Primary wiring: SpiritService._connect_soundscape() connects spirit_summoned
	# directly.  This fallback handles scenes where that hook is absent.
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
	_sample_timer += delta
	if _sample_timer >= SAMPLE_INTERVAL:
		_sample_timer = 0.0
		_sample_viewport()
		_update_spirit_visibility()

	_lerp_biome_volumes(delta)
	_lerp_spirit_volumes(delta)
	_tick_stinger_queue()


# ---------------------------------------------------------------------------
# Viewport biome sampling
# ---------------------------------------------------------------------------

func _sample_viewport() -> void:
	# Get the camera viewport world rect.
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cam_pos: Vector2 = cam.get_screen_center_position()
	var zoom: Vector2 = cam.zoom
	var half_w: float = (vp_size.x * 0.5) / zoom.x
	var half_h: float = (vp_size.y * 0.5) / zoom.y
	var world_rect: Rect2 = Rect2(cam_pos - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0))

	# Count tiles per biome within the rect.
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

	# Compute new targets.
	var new_targets: Dictionary = {}
	for biome: int in _BIOME_BED_PATHS.keys():
		new_targets[biome] = 0.0

	var biome_total_weight: float = 0.0
	if total > 0:
		for biome in counts.keys():
			var w: float = float(int(counts[biome])) / float(total)
			if new_targets.has(biome):
				new_targets[biome] = w
			biome_total_weight += w

	# Update targets.
	for biome in new_targets.keys():
		_biome_target[biome] = float(new_targets[biome])

	# Neutral wind fades out as biomes fill the view.
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
	var world_rect: Rect2 = Rect2(cam_pos - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0))

	# Count in-view spirits to compute stacking normalisation.
	var in_view: Array[String] = []
	for spirit_id: String in _spirit_order:
		if not _spirit_world_pos.has(spirit_id):
			continue
		var pos: Vector2 = _spirit_world_pos.get(spirit_id, Vector2.ZERO)
		var radius: float = float(_spirit_world_radius.get(spirit_id, TILE_RADIUS * 2.0))
		var expanded: Rect2 = world_rect.grow(radius)
		if expanded.has_point(pos):
			in_view.append(spirit_id)

	# Enforce MAX_SPIRIT_LAYERS: only the most recent in_view spirits are active.
	var active_set: Dictionary = {}
	var active_count: int = min(in_view.size(), MAX_SPIRIT_LAYERS)
	for i: int in range(in_view.size() - active_count, in_view.size()):
		active_set[in_view[i]] = true

	for spirit_id: String in _spirit_order:
		if active_set.has(spirit_id):
			# Compute stacked target volume (1.0 linear → scaled by stacking).
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
		var player: AudioStreamPlayer = _biome_players[biome] as AudioStreamPlayer
		var target: float = float(_biome_target.get(biome, 0.0)) * master_lin
		var current: float = float(_biome_volume.get(biome, 0.0))
		var new_vol: float = lerp(current, target, BIOME_LERP_RATE * delta)
		_biome_volume[biome] = new_vol
		player.volume_db = linear_to_db(max(new_vol, 0.0001))
		# Start or stop player based on whether it should be audible.
		if new_vol > 0.0001 and not player.playing and player.stream != null:
			player.play()
		elif new_vol <= 0.0001 and player.playing:
			player.stop()

	# Neutral wind.
	var n_target: float = _neutral_target * master_lin
	_neutral_volume = lerp(_neutral_volume, n_target, BIOME_LERP_RATE * delta)
	_neutral_player.volume_db = linear_to_db(max(_neutral_volume, 0.0001))
	if _neutral_volume > 0.0001 and not _neutral_player.playing and _neutral_player.stream != null:
		_neutral_player.play()
	elif _neutral_volume <= 0.0001 and _neutral_player.playing:
		_neutral_player.stop()


func _lerp_spirit_volumes(delta: float) -> void:
	var master_lin: float = 0.0 if _muted else _master_volume
	for spirit_id: String in _spirit_players.keys():
		var player: AudioStreamPlayer = _spirit_players[spirit_id] as AudioStreamPlayer
		var target: float = float(_spirit_target.get(spirit_id, 0.0)) * master_lin
		var current: float = float(_spirit_volume.get(spirit_id, 0.0))
		var new_vol: float = lerp(current, target, SPIRIT_LERP_RATE * delta)
		_spirit_volume[spirit_id] = new_vol
		player.volume_db = linear_to_db(max(new_vol, 0.0001))
		if new_vol > 0.0001 and not player.playing and player.stream != null:
			player.play()
		elif new_vol <= 0.0001 and player.playing:
			player.stop()


# ---------------------------------------------------------------------------
# Stinger queue
# ---------------------------------------------------------------------------

func play_stinger(audio_key: String) -> void:
	if audio_key.is_empty():
		return
	# Prevent stacking beyond MAX_STINGER_QUEUE.
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
	# Look up the asset path from DiscoveryAudioPlayer's AUDIO_MAP.
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
## Registers the spirit in the rhythm pool so its layer can activate when
## the spirit's spawn position enters the camera viewport.
func on_spirit_summoned(spirit_id: String, instance: SpiritInstance) -> void:
	_on_spirit_summoned(spirit_id, instance)


func _on_spirit_summoned(spirit_id: String, instance: SpiritInstance) -> void:
	var entry: Dictionary = SpiritRhythmCatalog.lookup(spirit_id)
	if entry.is_empty():
		return  # Spirit has no rhythmic identity.

	# Record position for viewport checks.
	var spawn_world: Vector2 = _HexUtils.axial_to_pixel(instance.spawn_coord, TILE_RADIUS)
	_spirit_world_pos[spirit_id] = spawn_world
	# Wander radius stored in world-pixels: bounds.size / 2 + extra tolerance.
	var wander_px: float = float(instance.wander_bounds.size.x) * TILE_RADIUS + TILE_RADIUS * 3.0
	_spirit_world_radius[spirit_id] = wander_px

	# Create audio player if not already present.
	if not _spirit_players.has(spirit_id):
		var player: AudioStreamPlayer = _try_load_spirit_player(spirit_id, entry)
		if player != null:
			_spirit_players[spirit_id] = player
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

func _create_biome_player(biome: int) -> void:
	var path: String = str(_BIOME_BED_PATHS.get(biome, ""))
	var player: AudioStreamPlayer = _make_stream_player("biome_%d" % biome)
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path) as AudioStream
		if stream != null:
			_enable_loop(stream)
			player.stream = stream
	_biome_players[biome] = player
	_biome_volume[biome] = 0.0
	_biome_target[biome] = 0.0


func _create_neutral_player() -> void:
	_neutral_player = _make_stream_player("neutral_wind")
	if ResourceLoader.exists(_NEUTRAL_BED_PATH):
		var stream: AudioStream = load(_NEUTRAL_BED_PATH) as AudioStream
		if stream != null:
			_enable_loop(stream)
			_neutral_player.stream = stream
	_neutral_volume = 1.0
	_neutral_target = 1.0
	_neutral_player.volume_db = 0.0


func _try_load_spirit_player(spirit_id: String, entry: Dictionary) -> AudioStreamPlayer:
	var path: String = str(entry.get("path", ""))
	var player: AudioStreamPlayer = _make_stream_player("spirit_%s" % spirit_id)
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path) as AudioStream
		if stream != null:
			_enable_loop(stream)
			player.stream = stream
	# Return the player even if the asset is absent — the volume stays at 0
	# so it produces no sound, but the slot is registered for future use.
	return player


func _make_stream_player(label: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = label
	p.bus = BUS_MASTER
	p.volume_db = -80.0
	add_child(p)
	return p


## Enable looping on an AudioStream subtype.  The base AudioStream class has no
## loop property; each concrete format type must be handled individually.
func _enable_loop(stream: AudioStream) -> void:
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
		return
	var mp3: AudioStreamMP3 = stream as AudioStreamMP3
	if mp3 != null:
		mp3.loop = true
