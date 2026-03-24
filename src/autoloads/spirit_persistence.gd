## SpiritPersistence — autoload singleton for spirit instance persistence.
extends Node

const SAVE_PATH: String = "user://spirit_instances.json"

var _instances: Array[Dictionary] = []
var _summoned_ids: Dictionary = {}

func _ready() -> void:
	_load()

func record_instance(instance: SpiritInstance) -> void:
	if _summoned_ids.has(instance.spirit_id):
		return
	_summoned_ids[instance.spirit_id] = true
	_instances.append(instance.serialize())
	_save()

func get_instances() -> Array[Dictionary]:
	return _instances

func get_summoned_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _summoned_ids.keys():
		ids.append(str(key))
	return ids

func _load() -> void:
	pass  # DISABLED for now — re-enable when save/load is ready

func _save() -> void:
	pass  # DISABLED for now — re-enable when save/load is ready
