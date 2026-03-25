class_name SpiritEcologyServiceNode
extends Node

const HexUtils = preload("res://src/grid/hex_utils.gd")

signal tension_active(spirit_a_id: String, spirit_b_id: String)
signal tension_cleared(spirit_a_id: String, spirit_b_id: String)
signal harmony_event_fired(spirit_a_id: String, spirit_b_id: String, overlap_hexes: Array[Vector2i])

var _harmony_ticks: Dictionary = {}
var _harmony_fired: Dictionary = {}
var _tension_active_map: Dictionary = {}
var _spirit_positions: Dictionary = {}
var _tension_pairs_by_spirit: Dictionary = {}
var _harmony_pairs_by_spirit: Dictionary = {}

const TENSION_DISTANCE: int = 5
const HARMONY_TICKS_REQUIRED: int = 20

func register_wanderer(wanderer: Node) -> void:
	if wanderer == null or not wanderer.has_signal("moved_to"):
		return
	if not wanderer.moved_to.is_connected(on_spirit_moved):
		wanderer.moved_to.connect(on_spirit_moved)
	if wanderer.has_variable("spirit_id"):
		var spirit_id: String = str(wanderer.get("spirit_id"))
		_index_spirit_pairs(spirit_id)

func on_spirit_moved(spirit_id: String, coord: Vector2i) -> void:
	_spirit_positions[spirit_id] = coord
	_check_tension(spirit_id)
	_check_harmony(spirit_id)

func harmony_count() -> int:
	return _harmony_fired.size()

func _get_catalog_entry(spirit_id: String) -> Dictionary:
	var spirit_service: Node = get_node_or_null("/root/SpiritService")
	if spirit_service == null:
		return {}
	if not spirit_service.has_method("get_catalog_entry"):
		return {}
	return spirit_service.get_catalog_entry(spirit_id)

func _pair_key(a: String, b: String) -> String:
	if a < b:
		return "%s|%s" % [a, b]
	return "%s|%s" % [b, a]

func _check_tension(moved_spirit_id: String) -> void:
	var partner_list: Array = _tension_pairs_by_spirit.get(moved_spirit_id, [])
	for partner_variant in partner_list:
		var partner_name: String = str(partner_variant)
		if not _spirit_positions.has(partner_name):
			continue
		var coord_a: Vector2i = _spirit_positions[moved_spirit_id]
		var coord_b: Vector2i = _spirit_positions[partner_name]
		var key: String = _pair_key(moved_spirit_id, partner_name)
		var in_range: bool = HexUtils.axial_distance(coord_a, coord_b) <= TENSION_DISTANCE
		var was_active: bool = bool(_tension_active_map.get(key, false))
		if in_range and not was_active:
			_tension_active_map[key] = true
			tension_active.emit(moved_spirit_id, partner_name)
		elif not in_range and was_active:
			_tension_active_map[key] = false
			tension_cleared.emit(moved_spirit_id, partner_name)

func _check_harmony(moved_spirit_id: String) -> void:
	var partner_list: Array = _harmony_pairs_by_spirit.get(moved_spirit_id, [])
	for partner_variant in partner_list:
		var partner_name: String = str(partner_variant)
		if not _spirit_positions.has(partner_name):
			continue
		var key: String = _pair_key(moved_spirit_id, partner_name)
		if bool(_harmony_fired.get(key, false)):
			continue
		var ticks: int = int(_harmony_ticks.get(key, 0)) + 1
		_harmony_ticks[key] = ticks
		if ticks >= HARMONY_TICKS_REQUIRED:
			_harmony_fired[key] = true
			var overlap: Array[Vector2i] = []
			overlap.append(_spirit_positions[moved_spirit_id])
			harmony_event_fired.emit(moved_spirit_id, partner_name, overlap)

func _index_spirit_pairs(spirit_id: String) -> void:
	var entry: Dictionary = _get_catalog_entry(spirit_id)
	var tension_partner: String = str(entry.get("tension_partner_id", ""))
	var harmony_partner: String = str(entry.get("harmony_partner_id", ""))
	if not tension_partner.is_empty():
		var tension_list: Array = _tension_pairs_by_spirit.get(spirit_id, [])
		if not tension_list.has(tension_partner):
			tension_list.append(tension_partner)
		_tension_pairs_by_spirit[spirit_id] = tension_list
	if not harmony_partner.is_empty():
		var harmony_list: Array = _harmony_pairs_by_spirit.get(spirit_id, [])
		if not harmony_list.has(harmony_partner):
			harmony_list.append(harmony_partner)
		_harmony_pairs_by_spirit[spirit_id] = harmony_list
