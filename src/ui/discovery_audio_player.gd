class_name DiscoveryAudioPlayer
extends Node

const AUDIO_MAP: Dictionary = {
	"stinger_river": "res://assets/audio/discoveries/river.ogg",
	"stinger_deep_stand": "res://assets/audio/discoveries/deep_stand.ogg",
	"stinger_glade": "res://assets/audio/discoveries/glade.ogg",
	"stinger_mirror_archipelago": "res://assets/audio/discoveries/mirror_archipelago.ogg",
	"stinger_barren_expanse": "res://assets/audio/discoveries/barren_expanse.ogg",
	"stinger_great_reef": "res://assets/audio/discoveries/great_reef.ogg",
	"stinger_lotus_pond": "res://assets/audio/discoveries/lotus_pond.ogg",
	"stinger_mountain_peak": "res://assets/audio/discoveries/mountain_peak.ogg",
	"stinger_boreal_forest": "res://assets/audio/discoveries/boreal_forest.ogg",
	"stinger_peat_bog": "res://assets/audio/discoveries/peat_bog.ogg",
	"stinger_obsidian_expanse": "res://assets/audio/discoveries/obsidian_expanse.ogg",
	"stinger_waterfall": "res://assets/audio/discoveries/waterfall.ogg",
}

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func has_audio_key(audio_key: String) -> bool:
	return AUDIO_MAP.has(audio_key)

func play_stinger(audio_key: String) -> void:
	if not AUDIO_MAP.has(audio_key):
		RuntimeLogger.warn("DiscoveryAudioPlayer", "No audio mapping for key: %s" % audio_key)
		return
	var path: String = str(AUDIO_MAP[audio_key])
	if not ResourceLoader.exists(path):
		RuntimeLogger.warn("DiscoveryAudioPlayer", "Audio asset not found (placeholder): %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		RuntimeLogger.warn("DiscoveryAudioPlayer", "Failed to load audio stream: %s" % path)
		return
	if _player.playing:
		_player.stop()
	_player.stream = stream
	_player.play()
