class_name SpiritSpawner
extends RefCounted

const SpiritWandererScript = preload("res://src/spirits/spirit_wanderer.gd")

var _parent_node: Node3D

func set_parent(parent: Node3D) -> void:
	_parent_node = parent

func spawn(instance: SpiritInstance, catalog_entry: Dictionary) -> Node3D:
	if _parent_node == null:
		return null
	var wanderer: Node3D = SpiritWandererScript.new()
	_parent_node.add_child(wanderer)
	wanderer.setup(instance, catalog_entry)
	return wanderer

func despawn_all() -> void:
	if _parent_node == null:
		return
	for child in _parent_node.get_children():
		child.queue_free()

func get_wanderer(spirit_id: String) -> Node3D:
	if _parent_node == null:
		return null
	for child in _parent_node.get_children():
		if child.has_method("get") and child.get("spirit_id") == spirit_id:
			return child
	return null
