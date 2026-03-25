## TileSelector — CanvasLayer UI for switching between biomes and showing discovery notifications.
extends CanvasLayer

@onready var _hex_selector: Node2D = $TileSelectorHex
@onready var _discovery_panel: PanelContainer = $DiscoveryPanel
@onready var _discovery_label: Label = $DiscoveryPanel/VBoxContainer/DiscoveryLabel
@onready var _discovery_flavor: Label = $DiscoveryPanel/VBoxContainer/DiscoveryFlavorLabel
@onready var _discovery_queue: DiscoveryNotificationQueue = $DiscoveryQueue
@onready var _discovery_audio: DiscoveryAudioPlayer = $DiscoveryAudioPlayer
@onready var _discovery_router: DiscoveryEventRouter = $DiscoveryRouter

func _ready() -> void:
	_hex_selector.biome_selected.connect(_select)
	_select(BiomeType.Value.STONE)

	_style_discovery_panel()

	_discovery_router.set_queue(_discovery_queue)
	_discovery_queue.notification_shown.connect(_on_notification_shown)
	_discovery_queue.notification_dismissed.connect(_on_notification_dismissed)
	_discovery_queue.notification_shown.connect(func(payload: DiscoveryPayload) -> void:
		_discovery_audio.play_stinger(payload.audio_key)
	)


func _select(biome: int) -> void:
	GameState.selected_biome = biome
	_hex_selector.select(biome)


## Apply a dark void-themed style to the discovery notification panel so it
## matches the new background aesthetic rather than using the default OS style.
func _style_discovery_panel() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.11, 0.90)
	panel_style.border_color = Color(0.30, 0.26, 0.50, 0.75)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	_discovery_panel.add_theme_stylebox_override("panel", panel_style)
	_discovery_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.80))
	_discovery_flavor.add_theme_color_override("font_color", Color(0.76, 0.74, 0.68))


func _on_notification_shown(payload: DiscoveryPayload) -> void:
	_discovery_label.text = payload.display_name
	_discovery_flavor.text = payload.flavor_text
	_discovery_panel.visible = true


func _on_notification_dismissed() -> void:
	_discovery_panel.visible = false
	_discovery_label.text = ""
	_discovery_flavor.text = ""
