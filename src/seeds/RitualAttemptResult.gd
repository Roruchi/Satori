class_name RitualAttemptResult
extends RefCounted

const OUTCOME_SUCCESS: StringName = &"success"
const OUTCOME_EMPTY_INPUT: StringName = &"empty_input"
const OUTCOME_DUPLICATE_INPUT: StringName = &"duplicate_input"
const OUTCOME_MISSING_ESSENCE: StringName = &"missing_essence"
const OUTCOME_LOCKED_INPUT: StringName = &"locked_input"
const OUTCOME_NO_MATCH: StringName = &"no_match"
const OUTCOME_INVENTORY_FULL: StringName = &"inventory_full"
const OUTCOME_CONTEXT_BLOCKED: StringName = &"context_blocked"

const FEEDBACK_SUCCESS: StringName = &"ritual_success"
const FEEDBACK_EMPTY_INPUT: StringName = &"ritual_empty_input"
const FEEDBACK_DUPLICATE_INPUT: StringName = &"ritual_duplicate_input"
const FEEDBACK_MISSING_ESSENCE: StringName = &"ritual_missing_essence"
const FEEDBACK_LOCKED_INPUT: StringName = &"ritual_locked_input"
const FEEDBACK_NO_MATCH: StringName = &"ritual_no_match"
const FEEDBACK_INVENTORY_FULL: StringName = &"ritual_inventory_full"
const FEEDBACK_CONTEXT_BLOCKED: StringName = &"ritual_context_blocked"

var outcome: StringName = OUTCOME_EMPTY_INPUT
var feedback_key: StringName = FEEDBACK_EMPTY_INPUT
var guidance: String = ""
var ritual_id: StringName = &""
var result_kind: StringName = &""
var result_id: StringName = &""
var consumed_input_keys: Array[String] = []
var discovered_id: StringName = &""

static func success(p_ritual_id: StringName, p_result_kind: StringName, p_result_id: StringName, consumed: Array[String], p_discovered_id: StringName = &"") -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_SUCCESS
	result.feedback_key = FEEDBACK_SUCCESS
	result.ritual_id = p_ritual_id
	result.result_kind = p_result_kind
	result.result_id = p_result_id
	result.consumed_input_keys = consumed.duplicate()
	result.discovered_id = p_discovered_id
	return result

static func empty_input() -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_EMPTY_INPUT
	result.feedback_key = FEEDBACK_EMPTY_INPUT
	result.guidance = "Choose one to three ritual inputs."
	return result

static func duplicate_input() -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_DUPLICATE_INPUT
	result.feedback_key = FEEDBACK_DUPLICATE_INPUT
	result.guidance = "Each ritual slot must hold a different essence, material or assistant."
	return result

static func missing_essence() -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_MISSING_ESSENCE
	result.feedback_key = FEEDBACK_MISSING_ESSENCE
	result.guidance = "Add at least one essence to give the ritual intent."
	return result

static func locked_input(input_key: String) -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_LOCKED_INPUT
	result.feedback_key = FEEDBACK_LOCKED_INPUT
	result.guidance = "%s is not available yet." % input_key
	return result

static func no_match() -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_NO_MATCH
	result.feedback_key = FEEDBACK_NO_MATCH
	result.guidance = "The chosen inputs do not yet shape a known form."
	return result

static func inventory_full(p_result_kind: StringName, p_result_id: StringName) -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_INVENTORY_FULL
	result.feedback_key = FEEDBACK_INVENTORY_FULL
	result.result_kind = p_result_kind
	result.result_id = p_result_id
	result.guidance = "Free a place inventory slot and try the ritual again."
	return result

static func context_blocked(message: String = "") -> RitualAttemptResult:
	var result: RitualAttemptResult = new()
	result.outcome = OUTCOME_CONTEXT_BLOCKED
	result.feedback_key = FEEDBACK_CONTEXT_BLOCKED
	result.guidance = message
	return result

func is_success() -> bool:
	return outcome == OUTCOME_SUCCESS
