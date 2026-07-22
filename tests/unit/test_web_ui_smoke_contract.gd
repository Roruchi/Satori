extends GutTest

const RitualIconCatalogScript = preload("res://src/ui/ritual_icon_catalog.gd")
const UNSUPPORTED_DECORATIVE_GLYPHS: Array[String] = ["⬢", "✦", "✋", "☷", "⚙", "▶", "✕", "✓", "✗", "⚡", "⬡"]
const TEXT_FILES: Array[String] = [
	"res://scenes/UI/HUD.tscn",
	"res://scenes/UI/SettingsMenu.tscn",
	"res://scenes/TitleScreen.tscn",
	"res://src/ui/HUDController.gd",
]

func test_web_ui_copy_avoids_mobile_font_tofu_glyphs() -> void:
	for file_path: String in TEXT_FILES:
		var text: String = FileAccess.get_file_as_string(file_path)
		assert_false(text.is_empty(), "%s should be readable" % file_path)
		for glyph: String in UNSUPPORTED_DECORATIVE_GLYPHS:
			assert_false(text.contains(glyph), "%s should not contain unsupported decorative glyph %s" % [file_path, glyph])

func test_mode_tab_markers_are_ascii_safe() -> void:
	var scene: PackedScene = load("res://scenes/UI/HUD.tscn") as PackedScene
	assert_not_null(scene)
	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().process_frame

	var plant_button: Button = hud.get_node("Root/BottomBar/PlantButton") as Button
	var ritual_button: Button = hud.get_node("Root/BottomBar/MixButton") as Button
	var codex_button: Button = hud.get_node("Root/BottomBar/CodexButton") as Button
	var speed_button: Button = hud.get_node("Root/TopBar/ProgressionSpeedButton") as Button
	assert_eq(plant_button.text, "Place")
	assert_eq(ritual_button.text, "Ritual")
	assert_eq(codex_button.text, "Codex")
	assert_null(hud.get_node_or_null("Root/BottomBar/InteractButton"))
	assert_true(plant_button.icon is Texture2D)
	assert_true(ritual_button.icon is Texture2D)
	assert_true(codex_button.icon is Texture2D)
	assert_false(plant_button.icon is AtlasTexture)
	assert_false(ritual_button.icon is AtlasTexture)
	assert_false(codex_button.icon is AtlasTexture)
	assert_eq(speed_button.text, "x1")

	remove_child(hud)
	hud.free()

func test_ritual_icons_are_direct_imported_textures() -> void:
	assert_eq(RitualIconCatalogScript.ICON_TEXTURES.size(), 9)
	for icon_index: int in RitualIconCatalogScript.ICON_TEXTURES.size():
		var texture: Texture2D = RitualIconCatalogScript.texture_at(icon_index)
		assert_not_null(texture, "icon %d should load" % icon_index)
		assert_false(texture is AtlasTexture, "icon %d should not need atlas sampling" % icon_index)
		assert_false(texture is ImageTexture, "icon %d should not need runtime pixel readback" % icon_index)
	assert_null(RitualIconCatalogScript.texture_at(-1))
	assert_null(RitualIconCatalogScript.texture_at(9))
