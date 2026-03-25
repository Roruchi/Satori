## TileSelector — CanvasLayer UI for switching between biomes and showing discovery notifications.
extends CanvasLayer

const BIOME_PANEL_BG := Color(0.20, 0.16, 0.08, 0.94)
const BIOME_PANEL_BORDER := Color(0.62, 0.54, 0.29, 0.95)
const BIOME_TITLE := Color(0.97, 0.92, 0.77)
const BIOME_BODY := Color(0.86, 0.80, 0.66)
const SPIRIT_PANEL_BG := Color(0.08, 0.13, 0.16, 0.95)
const SPIRIT_PANEL_BORDER := Color(0.35, 0.72, 0.76, 0.95)
const SPIRIT_TITLE := Color(0.87, 0.97, 1.00)
const SPIRIT_BODY := Color(0.68, 0.89, 0.92)

@onready var _hex_selector: Node2D = $TileSelectorHex
@onready var _discovery_panel: PanelContainer = $DiscoveryPanel
@onready var _discovery_accent: ColorRect = $DiscoveryPanel/AccentBar
@onready var _discovery_type: Label = $DiscoveryPanel/VBoxContainer/TypeLabel
@onready var _discovery_label: Label = $DiscoveryPanel/VBoxContainer/DiscoveryLabel
@onready var _discovery_flavor: Label = $DiscoveryPanel/VBoxContainer/DiscoveryFlavorLabel
@onready var _discovery_queue: DiscoveryNotificationQueue = $DiscoveryQueue
@onready var _discovery_audio: DiscoveryAudioPlayer = $DiscoveryAudioPlayer
@onready var _discovery_router: DiscoveryEventRouter = $DiscoveryRouter

func _ready() -> void:
	_hex_selector.biome_selected.connect(_select)
	if _hex_selector.has_method("get_selected_biome"):
		_select(int(_hex_selector.get_selected_biome()))
	else:
		_select(BiomeType.Value.STONE)

	_style_discovery_panel()

	_discovery_router.set_queue(_discovery_queue)
	_discovery_router.set_spirit_service(get_node_or_null("../SpiritService"))
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
	_apply_notification_theme(false)

func _apply_notification_theme(is_spirit: bool) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = SPIRIT_PANEL_BG if is_spirit else BIOME_PANEL_BG
	panel_style.border_color = SPIRIT_PANEL_BORDER if is_spirit else BIOME_PANEL_BORDER
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	_discovery_panel.add_theme_stylebox_override("panel", panel_style)
	_discovery_accent.color = SPIRIT_PANEL_BORDER if is_spirit else BIOME_PANEL_BORDER
	_discovery_type.text = "SPIRIT SUMMONED" if is_spirit else "BIOME DISCOVERED"
	_discovery_type.add_theme_color_override("font_color", SPIRIT_PANEL_BORDER if is_spirit else BIOME_PANEL_BORDER)
	_discovery_label.add_theme_color_override("font_color", SPIRIT_TITLE if is_spirit else BIOME_TITLE)
	_discovery_flavor.add_theme_color_override("font_color", SPIRIT_BODY if is_spirit else BIOME_BODY)


func _on_notification_shown(payload: DiscoveryPayload) -> void:
	var is_spirit: bool = payload.discovery_id.begins_with("spirit_")
	_apply_notification_theme(is_spirit)
	_discovery_label.text = payload.display_name
	_discovery_flavor.text = payload.flavor_text
	_discovery_panel.visible = true


func _on_notification_dismissed() -> void:
	_discovery_panel.visible = false
	_discovery_type.text = "DISCOVERY"
	_discovery_label.text = ""
	_discovery_flavor.text = ""
