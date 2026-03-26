## SpiritPersistence — autoload singleton for spirit instance persistence.
extends Node

const SAVE_PATH: String = "user://spirit_instances.json"

var _instances: Array[Dictionary] = []
var _summoned_ids: Dictionary = {}

func _ready() -> void:
	_load()

## Record a spirit instance.  When the instance carries a non-empty island_id the
## deduplication key is "island_{island_id}|spirit_{spirit_id}" so the same spirit
## can be summoned again on a different island.  When island_id is empty the bare
## spirit_id is used as the key (backward-compatible with pre-island saves).
func record_instance(instance: SpiritInstance) -> void:
	var key: String = _island_spirit_key(instance)
	if _summoned_ids.has(key):
		return
	_summoned_ids[key] = true
	_instances.append(instance.serialize())
	_save()

## Return true if the given spirit has already been summoned on the given island.
func is_summoned_on_island(spirit_id: String, island_id: String) -> bool:
	var key: String
	if island_id.is_empty():
		key = spirit_id
	else:
		key = "island_%s|spirit_%s" % [island_id, spirit_id]
	return _summoned_ids.has(key)

func get_instances() -> Array[Dictionary]:
	return _instances

func get_summoned_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in _summoned_ids.keys():
		ids.append(str(key))
	return ids

## Private helper — compute the deduplication key for an instance.
func _island_spirit_key(instance: SpiritInstance) -> String:
	if instance.island_id.is_empty():
		return instance.spirit_id
	return "island_%s|spirit_%s" % [instance.island_id, instance.spirit_id]

func _load() -> void:
	pass  # DISABLED for now — re-enable when save/load is ready

func _save() -> void:
	pass  # DISABLED for now — re-enable when save/load is ready
