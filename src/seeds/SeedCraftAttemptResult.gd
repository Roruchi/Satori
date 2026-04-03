class_name SeedCraftAttemptResult
extends RefCounted

const OUTCOME_SUCCESS: StringName = &"success"
const OUTCOME_EMPTY_INPUT: StringName = &"empty_input"
const OUTCOME_NO_MATCHING_SEED_RECIPE: StringName = &"no_matching_seed_recipe"
const OUTCOME_LOCKED_ELEMENT: StringName = &"locked_element"
const OUTCOME_INVENTORY_FULL: StringName = &"inventory_full"

const FEEDBACK_SUCCESS: StringName = &"craft_success_seed_added"
const FEEDBACK_EMPTY_INPUT: StringName = &"craft_empty_input"
const FEEDBACK_NO_MATCH: StringName = &"craft_no_matching_seed_recipe"
const FEEDBACK_LOCKED_KU: StringName = &"craft_locked_ku"
const FEEDBACK_INVENTORY_FULL: StringName = &"craft_inventory_full"

var outcome: StringName = OUTCOME_EMPTY_INPUT
var feedback_key: StringName = FEEDBACK_EMPTY_INPUT
var guidance: String = ""
var matched_recipe_id: StringName = &""
var output_seed_id: StringName = &""
var consumed_slot_indices: Array[int] = []

static func success(recipe: SeedRecipe, consumed_slots: Array[int]):
	var result = new()
	result.outcome = OUTCOME_SUCCESS
	result.feedback_key = FEEDBACK_SUCCESS
	if recipe != null:
		result.matched_recipe_id = recipe.recipe_id
		result.output_seed_id = recipe.recipe_id
	result.consumed_slot_indices = consumed_slots.duplicate()
	return result

static func empty_input():
	var result = new()
	result.outcome = OUTCOME_EMPTY_INPUT
	result.feedback_key = FEEDBACK_EMPTY_INPUT
	result.guidance = "Place 1 or 2 valid seed tokens."
	return result

static func no_matching_seed_recipe():
	var result = new()
	result.outcome = OUTCOME_NO_MATCHING_SEED_RECIPE
	result.feedback_key = FEEDBACK_NO_MATCH
	result.guidance = "Use a valid single or dual seed recipe."
	return result

static func locked_element(recipe: SeedRecipe):
	var result = new()
	result.outcome = OUTCOME_LOCKED_ELEMENT
	result.feedback_key = FEEDBACK_LOCKED_KU
	result.guidance = "Unlock Ku to use this recipe."
	if recipe != null:
		result.matched_recipe_id = recipe.recipe_id
	return result

static func inventory_full(recipe: SeedRecipe):
	var result = new()
	result.outcome = OUTCOME_INVENTORY_FULL
	result.feedback_key = FEEDBACK_INVENTORY_FULL
	result.guidance = "Free plant inventory space and try again."
	if recipe != null:
		result.matched_recipe_id = recipe.recipe_id
	return result

func is_success() -> bool:
	return outcome == OUTCOME_SUCCESS
