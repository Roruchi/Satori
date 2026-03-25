class_name CodexPanel
extends PanelContainer

const CATEGORY_TITLES: Array[String] = ["Seeds", "Biomes", "Spirits", "Structures"]
const CATEGORY_SINGULARS: Array[String] = ["Seed", "Biome", "Spirit", "Structure"]
const COLOR_PARCHMENT := Color(0.90, 0.84, 0.69, 0.96)
const COLOR_INK := Color(0.18, 0.12, 0.07)
const COLOR_MUTED := Color(0.40, 0.31, 0.22)
const COLOR_ACCENT := Color(0.58, 0.39, 0.19)
const COLOR_SHADOW := Color(0.31, 0.22, 0.12, 0.60)
const COLOR_TRIM := Color(0.69, 0.52, 0.28, 0.95)
const COLOR_SCROLL_EDGE := Color(0.73, 0.61, 0.42, 0.92)
const KU_GUIDANCE_ENTRY_ID: StringName = &"ku_unlock_guidance"
const LABEL_DISCOVERED: String = "Discovered"
const LABEL_HINT: String = "Hint"
const LABEL_HINTED_PATH: String = "Hinted Path"

@onready var _tabs: TabContainer = $Tabs
@onready var _seed_list: VBoxContainer = $Tabs/Seeds/Scroll/Entries
@onready var _biome_list: VBoxContainer = $Tabs/Biomes/Scroll/Entries
@onready var _spirit_list: VBoxContainer = $Tabs/Spirits/Scroll/Entries
@onready var _structure_list: VBoxContainer = $Tabs/Structures/Scroll/Entries
@onready var _title: Label = $TitleBlock/Title
@onready var _subtitle: Label = $TitleBlock/Subtitle
@onready var _top_ornament: Panel = $TopOrnament
@onready var _bottom_ornament: Panel = $BottomOrnament
@onready var _left_spine: Panel = $LeftSpine
@onready var _right_spine: Panel = $RightSpine
var _codex_service: Node = null

func _ready() -> void:
	_style_panel()
	_codex_service = get_node_or_null("/root/CodexService")
	if _codex_service != null and _codex_service.has_signal("entry_discovered"):
		_codex_service.entry_discovered.connect(_on_entry_discovered)
	_rebuild_all()

func _on_entry_discovered(_entry_id: StringName) -> void:
	_rebuild_all()

func _rebuild_all() -> void:
	_fill_category(0, _seed_list)
	_fill_category(1, _biome_list)
	_fill_category(2, _spirit_list)
	_fill_category(3, _structure_list)

func _fill_category(category: int, container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
	container.add_theme_constant_override("separation", 12)
	var codex: Node = _codex_service
	if codex == null:
		codex = get_node_or_null("/root/CodexService")
		_codex_service = codex
	if codex == null or not codex.has_method("get_entries_by_category"):
		return
	var entries: Array[CodexEntry] = codex.get_entries_by_category(category)
	for entry: CodexEntry in entries:
		container.add_child(_build_entry_card(entry, codex.is_discovered(entry.entry_id), category))

func _style_panel() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PARCHMENT
	panel_style.border_color = COLOR_ACCENT
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.shadow_color = COLOR_SHADOW
	panel_style.shadow_size = 10
	panel_style.content_margin_left = 18
	panel_style.content_margin_top = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", panel_style)
	_title.add_theme_color_override("font_color", COLOR_INK)
	_subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	_style_ornament(_top_ornament, true)
	_style_ornament(_bottom_ornament, true)
	_style_ornament(_left_spine, false)
	_style_ornament(_right_spine, false)

	var selected_style: StyleBoxFlat = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.78, 0.63, 0.39)
	selected_style.border_color = COLOR_ACCENT
	selected_style.border_width_bottom = 3
	selected_style.corner_radius_top_left = 12
	selected_style.corner_radius_top_right = 12
	selected_style.content_margin_left = 14
	selected_style.content_margin_top = 8
	selected_style.content_margin_right = 14
	selected_style.content_margin_bottom = 8
	_tabs.add_theme_stylebox_override("tab_selected", selected_style)

	var unselected_style: StyleBoxFlat = StyleBoxFlat.new()
	unselected_style.bg_color = Color(0.66, 0.56, 0.42, 0.85)
	unselected_style.border_color = Color(0.46, 0.32, 0.18)
	unselected_style.corner_radius_top_left = 12
	unselected_style.corner_radius_top_right = 12
	unselected_style.content_margin_left = 14
	unselected_style.content_margin_top = 8
	unselected_style.content_margin_right = 14
	unselected_style.content_margin_bottom = 8
	_tabs.add_theme_stylebox_override("tab_unselected", unselected_style)
	_tabs.add_theme_color_override("font_selected_color", COLOR_INK)
	_tabs.add_theme_color_override("font_unselected_color", COLOR_MUTED)
	_tabs.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	var tabs_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	tabs_panel_style.bg_color = Color(0.95, 0.91, 0.82, 0.96)
	tabs_panel_style.border_color = Color(0.49, 0.34, 0.19)
	tabs_panel_style.border_width_left = 2
	tabs_panel_style.border_width_top = 2
	tabs_panel_style.border_width_right = 2
	tabs_panel_style.border_width_bottom = 2
	tabs_panel_style.corner_radius_top_left = 12
	tabs_panel_style.corner_radius_top_right = 12
	tabs_panel_style.corner_radius_bottom_right = 12
	tabs_panel_style.corner_radius_bottom_left = 12
	tabs_panel_style.content_margin_left = 12
	tabs_panel_style.content_margin_top = 12
	tabs_panel_style.content_margin_right = 12
	tabs_panel_style.content_margin_bottom = 12
	_tabs.add_theme_stylebox_override("panel", tabs_panel_style)
	for category_index: int in CATEGORY_TITLES.size():
		_tabs.set_tab_title(category_index, CATEGORY_TITLES[category_index])
	_style_scrolls()

func _build_entry_card(entry: CodexEntry, discovered: bool, category: int) -> PanelContainer:
	var codex: Node = _codex_service
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.97, 0.94, 0.86, 0.98) if discovered else Color(0.77, 0.72, 0.63, 0.95)
	card_style.border_color = COLOR_ACCENT if discovered else Color(0.40, 0.31, 0.22)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 14
	card_style.corner_radius_top_right = 14
	card_style.corner_radius_bottom_right = 14
	card_style.corner_radius_bottom_left = 14
	card_style.content_margin_left = 14
	card_style.content_margin_top = 12
	card_style.content_margin_right = 14
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)

	var header: Label = Label.new()
	header.text = entry.full_name if discovered and not entry.always_hidden else "Unknown %s" % CATEGORY_SINGULARS[category]
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", COLOR_INK if discovered else COLOR_MUTED)
	content.add_child(header)

	var subtitle: Label = Label.new()
	var guidance_state: String = LABEL_DISCOVERED if discovered and not entry.always_hidden else LABEL_HINT
	if entry.entry_id == KU_GUIDANCE_ENTRY_ID and codex != null and codex.has_method("get_ku_guidance_state"):
		guidance_state = LABEL_DISCOVERED if StringName(codex.get_ku_guidance_state()) == &"discovered" else LABEL_HINTED_PATH
	subtitle.text = guidance_state
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", COLOR_ACCENT)
	content.add_child(subtitle)

	var body: Label = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", COLOR_INK if discovered else COLOR_MUTED)
	if entry.always_hidden:
		body.text = "???"
	elif discovered:
		body.text = entry.full_description
	else:
		body.text = entry.hint_text
	content.add_child(body)

	return card

func _style_ornament(panel: Panel, horizontal: bool) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_SCROLL_EDGE
	style.border_color = COLOR_TRIM
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if horizontal:
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_right = 14
		style.corner_radius_bottom_left = 14
	else:
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)

func _style_scrolls() -> void:
	var scrolls: Array[ScrollContainer] = [
		$Tabs/Seeds/Scroll,
		$Tabs/Biomes/Scroll,
		$Tabs/Spirits/Scroll,
		$Tabs/Structures/Scroll,
	]
	for scroll: ScrollContainer in scrolls:
		var scroll_style: StyleBoxFlat = StyleBoxFlat.new()
		scroll_style.bg_color = Color(0.99, 0.96, 0.89, 0.82)
		scroll_style.border_color = Color(0.54, 0.39, 0.21, 0.65)
		scroll_style.border_width_left = 1
		scroll_style.border_width_top = 1
		scroll_style.border_width_right = 1
		scroll_style.border_width_bottom = 1
		scroll_style.corner_radius_top_left = 10
		scroll_style.corner_radius_top_right = 10
		scroll_style.corner_radius_bottom_right = 10
		scroll_style.corner_radius_bottom_left = 10
		scroll_style.content_margin_left = 10
		scroll_style.content_margin_top = 10
		scroll_style.content_margin_right = 10
		scroll_style.content_margin_bottom = 10
		scroll.add_theme_stylebox_override("panel", scroll_style)
