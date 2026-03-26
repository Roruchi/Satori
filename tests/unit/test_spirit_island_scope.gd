## Test Suite: Per-Island Spirit Spawning (SpiritPersistence + SpiritInstance)
##
## GUT unit tests for the island-scoped spirit summoning mechanics introduced
## by the Ku Tile Placement feature.  Covers FR-007, FR-008, FR-009.
## Run via: godot --path . --headless -s addons/gut/gut_cmdln.gd
##          -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

extends GutTest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Create a SpiritInstance with known spirit_id and island_id.
func _make_instance(sid: String, iid: String) -> SpiritInstance:
	var inst: SpiritInstance = SpiritInstance.create(sid, Vector2i.ZERO, Rect2i())
	inst.island_id = iid
	return inst


## Create an isolated SpiritPersistence node (not connected to scene tree).
func _make_persistence() -> Node:
	# Load the script directly; SpiritPersistence has no class_name to avoid
	# autoload/class_name collision.
	var script: GDScript = load("res://src/autoloads/spirit_persistence.gd")
	var node: Node = Node.new()
	node.set_script(script)
	add_child(node)
	return node


# ---------------------------------------------------------------------------
# T015 — record_and_check_island_keyed
# ---------------------------------------------------------------------------

func test_record_and_check_island_keyed() -> void:
	var persistence: Node = _make_persistence()

	var inst_a: SpiritInstance = _make_instance("spirit_mist_stag", "0,0")
	var inst_b: SpiritInstance = _make_instance("spirit_mist_stag", "1,0")

	persistence.record_instance(inst_a)
	persistence.record_instance(inst_b)

	assert_true(
		persistence.is_summoned_on_island("spirit_mist_stag", "0,0"),
		"spirit_mist_stag must be recorded on island 0,0"
	)
	assert_true(
		persistence.is_summoned_on_island("spirit_mist_stag", "1,0"),
		"spirit_mist_stag must be recorded on island 1,0"
	)


func test_is_summoned_on_island_true_and_false() -> void:
	var persistence: Node = _make_persistence()

	var inst: SpiritInstance = _make_instance("spirit_x", "0,0")
	persistence.record_instance(inst)

	assert_true(
		persistence.is_summoned_on_island("spirit_x", "0,0"),
		"is_summoned_on_island must return true for the recorded island"
	)
	assert_false(
		persistence.is_summoned_on_island("spirit_x", "1,0"),
		"is_summoned_on_island must return false for a different island"
	)
	assert_false(
		persistence.is_summoned_on_island("spirit_other", "0,0"),
		"is_summoned_on_island must return false for a different spirit_id"
	)


func test_same_island_not_recorded_twice() -> void:
	var persistence: Node = _make_persistence()

	var inst1: SpiritInstance = _make_instance("spirit_y", "0,0")
	var inst2: SpiritInstance = _make_instance("spirit_y", "0,0")
	persistence.record_instance(inst1)
	persistence.record_instance(inst2)

	# get_instances returns raw serialised dicts; count entries with matching key
	var instances: Array[Dictionary] = persistence.get_instances()
	var count: int = 0
	for d: Dictionary in instances:
		if str(d.get("spirit_id", "")) == "spirit_y" and str(d.get("island_id", "")) == "0,0":
			count += 1
	assert_eq(count, 1, "Same spirit on same island must only be recorded once")


func test_different_islands_both_recorded() -> void:
	var persistence: Node = _make_persistence()

	persistence.record_instance(_make_instance("spirit_z", "0,0"))
	persistence.record_instance(_make_instance("spirit_z", "2,0"))

	var instances: Array[Dictionary] = persistence.get_instances()
	var count: int = 0
	for d: Dictionary in instances:
		if str(d.get("spirit_id", "")) == "spirit_z":
			count += 1
	assert_eq(count, 2, "Same spirit on two different islands must produce two records")


# ---------------------------------------------------------------------------
# T015 — spirit_instance_serialise_island_id
# ---------------------------------------------------------------------------

func test_spirit_instance_serialise_island_id() -> void:
	var inst: SpiritInstance = _make_instance("spirit_abc", "2,3")
	var data: Dictionary = inst.serialize()

	assert_eq(str(data.get("island_id", "")), "2,3",
		"serialize() must include island_id key")

	var restored: SpiritInstance = SpiritInstance.deserialize(data)
	assert_eq(restored.island_id, "2,3",
		"deserialize() must restore island_id correctly")


func test_spirit_instance_deserialise_defaults_empty_island_id() -> void:
	# Simulate an old serialised dict without island_id (backward compat).
	var old_data: Dictionary = {
		"spirit_id": "spirit_legacy",
		"spawn_coord": {"x": 0, "y": 0},
		"wander_bounds": {"x": 0, "y": 0, "w": 10, "h": 10},
		"is_active": true,
		"summoned_at": 0
	}
	var inst: SpiritInstance = SpiritInstance.deserialize(old_data)
	assert_eq(inst.island_id, "",
		"Deserialising a legacy dict without island_id must produce empty string (backward compat)")


# ---------------------------------------------------------------------------
# Fallback: bare spirit_id key when island_id is empty
# ---------------------------------------------------------------------------

func test_record_instance_without_island_id_uses_bare_key() -> void:
	var persistence: Node = _make_persistence()

	# Instance with no island_id (empty string).
	var inst: SpiritInstance = _make_instance("spirit_bare", "")
	persistence.record_instance(inst)

	# The bare spirit_id must appear in get_summoned_ids() for backward compat.
	var ids: Array[String] = persistence.get_summoned_ids()
	assert_true(
		ids.has("spirit_bare"),
		"Bare spirit_id key must appear in get_summoned_ids() when island_id is empty"
	)
