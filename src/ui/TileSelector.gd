## TileSelector — CanvasLayer UI for switching between biomes and showing discovery notifications.
extends CanvasLayer

@onready var _grass_btn: Button = $HBoxContainer/GrassButton
@onready var _water_btn: Button = $HBoxContainer/WaterButton
@onready var _stone_btn: Button = $HBoxContainer/StoneButton
@onready var _earth_btn: Button = $HBoxContainer/EarthButton
@onready var _discovery_panel: PanelContainer = $DiscoveryPanel
@onready var _discovery_label: Label = $DiscoveryPanel/VBoxContainer/DiscoveryLabel
@onready var _discovery_flavor: Label = $DiscoveryPanel/VBoxContainer/DiscoveryFlavorLabel
@onready var _discovery_queue: DiscoveryNotificationQueue = $DiscoveryQueue
@onready var _discovery_audio: DiscoveryAudioPlayer = $DiscoveryAudioPlayer
@onready var _discovery_router: DiscoveryEventRouter = $DiscoveryRouter

func _ready() -> void:
	_grass_btn.pressed.connect(func(): _select(BiomeType.Value.FOREST))
	_water_btn.pressed.connect(func(): _select(BiomeType.Value.WATER))
	_stone_btn.pressed.connect(func(): _select(BiomeType.Value.STONE))
	_earth_btn.pressed.connect(func(): _select(BiomeType.Value.EARTH))
	_select(BiomeType.Value.FOREST)

	_discovery_router.set_queue(_discovery_queue)
	_discovery_queue.notification_shown.connect(_on_notification_shown)
	_discovery_queue.notification_dismissed.connect(_on_notification_dismissed)
	_discovery_queue.notification_shown.connect(func(payload: DiscoveryPayload) -> void:
		_discovery_audio.play_stinger(payload.audio_key)
	)

func _select(biome: int) -> void:
	GameState.selected_biome = biome
	_grass_btn.modulate = Color.WHITE if biome == BiomeType.Value.FOREST else Color(0.6, 0.6, 0.6)
	_water_btn.modulate = Color.WHITE if biome == BiomeType.Value.WATER else Color(0.6, 0.6, 0.6)
	_stone_btn.modulate = Color.WHITE if biome == BiomeType.Value.STONE else Color(0.6, 0.6, 0.6)
	_earth_btn.modulate = Color.WHITE if biome == BiomeType.Value.EARTH else Color(0.6, 0.6, 0.6)

func _on_notification_shown(payload: DiscoveryPayload) -> void:
	_discovery_label.text = payload.display_name
	_discovery_flavor.text = payload.flavor_text
	_discovery_panel.visible = true

func _on_notification_dismissed() -> void:
	_discovery_panel.visible = false
	_discovery_label.text = ""
	_discovery_flavor.text = ""
