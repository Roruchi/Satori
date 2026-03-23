class_name PatternLoader
extends RefCounted

const DEFAULT_PATTERN_DIR := "res://src/biomes/patterns"

func load_patterns(pattern_dir: String = DEFAULT_PATTERN_DIR) -> Array[PatternDefinition]:
	var loaded_patterns: Array[PatternDefinition] = []
	var dir := DirAccess.open(pattern_dir)
	if dir == null:
		RuntimeLogger.warn("PatternLoader", "Pattern directory does not exist: %s" % pattern_dir)
		return loaded_patterns

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".tres"):
			continue

		var full_path := "%s/%s" % [pattern_dir, file_name]
		var resource := load(full_path)
		if resource == null:
			RuntimeLogger.warn("PatternLoader", "Failed to load pattern resource: %s" % full_path)
			continue
		if not (resource is PatternDefinition):
			RuntimeLogger.warn("PatternLoader", "Skipping non-PatternDefinition resource: %s" % full_path)
			continue

		var definition: PatternDefinition = resource
		if not definition.is_valid_definition():
			RuntimeLogger.warn("PatternLoader", "Skipping invalid pattern definition: %s" % full_path)
			continue

		loaded_patterns.append(definition)
	dir.list_dir_end()

	loaded_patterns.sort_custom(func(a: PatternDefinition, b: PatternDefinition) -> bool:
		return a.discovery_id < b.discovery_id
	)
	return loaded_patterns
