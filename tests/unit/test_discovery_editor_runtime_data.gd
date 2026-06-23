extends GutTest

func _read_text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected file to open: %s" % path)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text.strip_edges()

func test_runtime_ritual_data_mirrors_editor_csv() -> void:
	assert_eq(
		_read_text("res://data/discovery_editor/runtime/rituals.csv.txt"),
		_read_text("res://data/discovery_editor/rituals.csv")
	)

func test_runtime_material_data_mirrors_editor_csv() -> void:
	assert_eq(
		_read_text("res://data/discovery_editor/runtime/materials.csv.txt"),
		_read_text("res://data/discovery_editor/materials.csv")
	)
