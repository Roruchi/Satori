## TileSelector — CanvasLayer UI for switching between Grass and Water tiles.
extends CanvasLayer

@onready var _grass_btn: Button = $HBoxContainer/GrassButton
@onready var _water_btn: Button = $HBoxContainer/WaterButton
@onready var _discovery_panel: PanelContainer = $DiscoveryPanel
@onready var _discovery_label: Label = $DiscoveryPanel/DiscoveryLabel

const DISCOVERY_TOAST_SECONDS: float = 2.5

var _discovery_timer: float = 0.0

func _ready() -> void:
	_grass_btn.pressed.connect(func(): _select(BiomeType.Value.FOREST))
	_water_btn.pressed.connect(func(): _select(BiomeType.Value.WATER))
	_select(BiomeType.Value.FOREST)
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)

func _process(delta: float) -> void:
	if _discovery_timer <= 0.0:
		return
	_discovery_timer -= delta
	if _discovery_timer <= 0.0:
		_discovery_panel.visible = false
		_discovery_label.text = ""

func _select(biome: int) -> void:
	GameState.selected_biome = biome
	_grass_btn.modulate = Color.WHITE if biome == BiomeType.Value.FOREST else Color(0.6, 0.6, 0.6)
	_water_btn.modulate = Color.WHITE if biome == BiomeType.Value.WATER else Color(0.6, 0.6, 0.6)

func _on_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	_discovery_label.text = "Discovery: %s (%d tiles)" % [discovery_id, triggering_coords.size()]
	_discovery_panel.visible = true
	_discovery_timer = DISCOVERY_TOAST_SECONDS
