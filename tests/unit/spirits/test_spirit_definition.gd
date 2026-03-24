## Test Suite: SpiritDefinition and SpiritInstance
##
## GUT unit tests for SpiritDefinition default field values,
## SpiritInstance.create(), and SpiritInstance serialize/deserialize round-trip.
## Run via tests/gut_runner.tscn

extends GutTest


func test_spirit_definition_has_default_spirit_id() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.spirit_id, "", "Default spirit_id should be empty")


func test_spirit_definition_has_default_display_name() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.display_name, "", "Default display_name should be empty")


func test_spirit_definition_has_default_riddle_text() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.riddle_text, "", "Default riddle_text should be empty")


func test_spirit_definition_has_default_pattern_id() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.pattern_id, "", "Default pattern_id should be empty")


func test_spirit_definition_has_default_wander_radius() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.wander_radius, 4, "Default wander_radius should be 4")


func test_spirit_definition_has_default_wander_speed() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.wander_speed, 2.0, "Default wander_speed should be 2.0")


func test_spirit_definition_has_default_color_hint() -> void:
	var def := SpiritDefinition.new()
	assert_eq(def.color_hint, Color.WHITE, "Default color_hint should be WHITE")


func test_spirit_instance_create_sets_spirit_id() -> void:
	var bounds := Rect2i(Vector2i(-4, -4), Vector2i(9, 9))
	var inst: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 2), bounds)
	assert_eq(inst.spirit_id, "spirit_red_fox", "spirit_id should be set by create()")


func test_spirit_instance_create_sets_spawn_coord() -> void:
	var bounds := Rect2i(Vector2i(-4, -4), Vector2i(9, 9))
	var inst: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 2), bounds)
	assert_eq(inst.spawn_coord, Vector2i(1, 2), "spawn_coord should be set by create()")


func test_spirit_instance_create_sets_wander_bounds() -> void:
	var bounds := Rect2i(Vector2i(-4, -4), Vector2i(9, 9))
	var inst: SpiritInstance = SpiritInstance.create("spirit_red_fox", Vector2i(1, 2), bounds)
	assert_eq(inst.wander_bounds, bounds, "wander_bounds should be set by create()")


func test_spirit_instance_create_sets_is_active() -> void:
	var bounds := Rect2i(Vector2i(0, 0), Vector2i(5, 5))
	var inst: SpiritInstance = SpiritInstance.create("spirit_owl_of_silence", Vector2i.ZERO, bounds)
	assert_true(inst.is_active, "is_active should be true after create()")


func test_spirit_instance_create_sets_summoned_at() -> void:
	var bounds := Rect2i(Vector2i(0, 0), Vector2i(5, 5))
	var inst: SpiritInstance = SpiritInstance.create("spirit_owl_of_silence", Vector2i.ZERO, bounds)
	assert_gt(inst.summoned_at, 0, "summoned_at should be a positive unix timestamp")


func test_spirit_instance_serialize_roundtrip() -> void:
	var bounds := Rect2i(Vector2i(-3, -2), Vector2i(8, 7))
	var inst: SpiritInstance = SpiritInstance.create("spirit_koi_fish", Vector2i(5, -1), bounds)
	var data: Dictionary = inst.serialize()
	var restored: SpiritInstance = SpiritInstance.deserialize(data)
	assert_eq(restored.spirit_id, inst.spirit_id, "Deserialized spirit_id should match")
	assert_eq(restored.spawn_coord, inst.spawn_coord, "Deserialized spawn_coord should match")
	assert_eq(restored.wander_bounds, inst.wander_bounds, "Deserialized wander_bounds should match")
	assert_eq(restored.is_active, inst.is_active, "Deserialized is_active should match")
	assert_eq(restored.summoned_at, inst.summoned_at, "Deserialized summoned_at should match")


func test_spirit_instance_deserialize_handles_empty_dict() -> void:
	var inst: SpiritInstance = SpiritInstance.deserialize({})
	assert_eq(inst.spirit_id, "", "Empty dict: spirit_id should default to empty")
	assert_eq(inst.spawn_coord, Vector2i.ZERO, "Empty dict: spawn_coord should default to zero")
