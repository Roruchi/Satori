class_name CodexPanel
extends PanelContainer

@onready var _tabs: TabContainer = $Tabs
@onready var _seed_list: VBoxContainer = $Tabs/Seeds/Scroll/Entries
@onready var _biome_list: VBoxContainer = $Tabs/Biomes/Scroll/Entries
@onready var _spirit_list: VBoxContainer = $Tabs/Spirits/Scroll/Entries
@onready var _structure_list: VBoxContainer = $Tabs/Structures/Scroll/Entries

func _ready() -> void:
	var codex: Node = get_node_or_null("/root/CodexService")
	if codex != null and codex.has_signal("entry_discovered"):
		codex.entry_discovered.connect(_on_entry_discovered)
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
	var codex: Node = get_node_or_null("/root/CodexService")
	if codex == null or not codex.has_method("get_entries_by_category"):
		return
	var entries: Array[CodexEntry] = codex.get_entries_by_category(category)
	for entry: CodexEntry in entries:
		var label: Label = Label.new()
		if entry.always_hidden:
			label.text = "???"
		elif codex.is_discovered(entry.entry_id):
			label.text = "%s — %s" % [entry.full_name, entry.full_description]
		else:
			label.text = "Silhouette — %s" % entry.hint_text
		container.add_child(label)
