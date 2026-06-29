class_name DiscoveryAudioPlayer
extends Node

const AUDIO_MAP: Dictionary = {}

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func has_audio_key(audio_key: String) -> bool:
	return AUDIO_MAP.has(audio_key)

func play_stinger(audio_key: String) -> void:
	if audio_key.is_empty() or not AUDIO_MAP.has(audio_key):
		return
	var path: String = str(AUDIO_MAP[audio_key])
	if not ResourceLoader.exists(path):
		RuntimeLogger.warn("DiscoveryAudioPlayer", "Audio asset not found: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		RuntimeLogger.warn("DiscoveryAudioPlayer", "Failed to load audio stream: %s" % path)
		return
	if _player.playing:
		_player.stop()
	_player.stream = stream
	_player.play()
