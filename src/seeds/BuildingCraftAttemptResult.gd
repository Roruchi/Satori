class_name BuildingCraftAttemptResult
extends RefCounted

const OUTCOME_SUCCESS: StringName = &"building_success"
const OUTCOME_NO_MATCH: StringName = &"building_no_match"
const OUTCOME_INVENTORY_FULL: StringName = &"building_inventory_full"
const OUTCOME_INSUFFICIENT_ESSENCE: StringName = &"building_insufficient_essence"

const FEEDBACK_SUCCESS: StringName = &"building_craft_success"
const FEEDBACK_NO_MATCH: StringName = &"building_craft_no_match"
const FEEDBACK_INVENTORY_FULL: StringName = &"building_craft_inventory_full"
const FEEDBACK_INSUFFICIENT_ESSENCE: StringName = &"building_craft_insufficient_essence"

var outcome: StringName = OUTCOME_NO_MATCH
var feedback_key: StringName = FEEDBACK_NO_MATCH
var guidance: String = ""
var building_type_key: StringName = &""
var consumed_slot_indices: Array[int] = []
var is_first_discovery: bool = false

static func success(type_key: StringName, consumed: Array[int], first_disc: bool) -> BuildingCraftAttemptResult:
	var result: BuildingCraftAttemptResult = new()
	result.outcome = OUTCOME_SUCCESS
	result.feedback_key = FEEDBACK_SUCCESS
	result.guidance = ""
	result.building_type_key = type_key
	result.consumed_slot_indices = consumed.duplicate()
	result.is_first_discovery = first_disc
	return result

static func no_match() -> BuildingCraftAttemptResult:
	var result: BuildingCraftAttemptResult = new()
	result.outcome = OUTCOME_NO_MATCH
	result.feedback_key = FEEDBACK_NO_MATCH
	result.guidance = "Use distinct ritual inputs to shape a known form."
	return result

static func inventory_full(type_key: StringName) -> BuildingCraftAttemptResult:
	var result: BuildingCraftAttemptResult = new()
	result.outcome = OUTCOME_INVENTORY_FULL
	result.feedback_key = FEEDBACK_INVENTORY_FULL
	result.guidance = "Free place inventory space and try again."
	result.building_type_key = type_key
	return result

static func insufficient_essence(type_key: StringName) -> BuildingCraftAttemptResult:
	var result: BuildingCraftAttemptResult = new()
	result.outcome = OUTCOME_INSUFFICIENT_ESSENCE
	result.feedback_key = FEEDBACK_INSUFFICIENT_ESSENCE
	result.guidance = "Gather more essence and try again."
	result.building_type_key = type_key
	return result

func is_success() -> bool:
	return outcome == OUTCOME_SUCCESS
