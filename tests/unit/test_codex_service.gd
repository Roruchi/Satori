extends GutTest

const KU_GUIDANCE_ENTRY_ID: StringName = &"ku_unlock_guidance"
const MIST_STAG_MARKER: String = "Mist Stag"

func test_ku_guidance_hint_exists_before_unlock() -> void:
	var codex: CodexServiceNode = CodexServiceNode.new()
	add_child(codex)
	codex._ready()
	var entries: Array[CodexEntry] = codex.get_entries_by_category(CodexEntry.Category.SEED)
	var guidance: CodexEntry = null
	for entry: CodexEntry in entries:
		if entry.entry_id == KU_GUIDANCE_ENTRY_ID:
			guidance = entry
			break
	assert_not_null(guidance, "Ku guidance entry should be loaded")
	assert_eq(codex.get_ku_guidance_state(), &"hinted")
	assert_eq(codex.is_discovered(KU_GUIDANCE_ENTRY_ID), false)
	assert_true(guidance.hint_text.contains(MIST_STAG_MARKER), "Hint should explicitly name Mist Stag")
	assert_true(not guidance.hint_text.contains("size threshold"), "Hint should avoid numeric checklist terms")
	codex.queue_free()

func test_ku_guidance_switches_to_discovered_after_mark_discovered() -> void:
	var codex: CodexServiceNode = CodexServiceNode.new()
	add_child(codex)
	codex._ready()
	codex.mark_discovered(KU_GUIDANCE_ENTRY_ID)
	assert_eq(codex.get_ku_guidance_state(), &"discovered")
	assert_eq(codex.is_discovered(KU_GUIDANCE_ENTRY_ID), true)
	codex.queue_free()

func test_structure_crafting_recipes_are_registered_in_codex() -> void:
	var codex: CodexServiceNode = CodexServiceNode.new()
	add_child(codex)
	codex._ready()
	var entries: Array[CodexEntry] = codex.get_entries_by_category(CodexEntry.Category.STRUCTURE)
	var by_id: Dictionary = {}
	for entry: CodexEntry in entries:
		by_id[entry.entry_id] = entry

	var expected_recipes: Dictionary = {
		&"disc_building_house": "Chi + Chi + Fu",
		&"disc_building_granary": "Sui + Sui + Chi",
		&"disc_building_watchtower": "Fu + Fu + Chi",
		&"disc_building_pavilion": "Fu + Fu + Sui",
		&"disc_building_forge": "Ka + Ka + Chi",
	}
	for entry_id: StringName in expected_recipes.keys():
		assert_true(by_id.has(entry_id), "Codex missing structure recipe entry: %s" % entry_id)
		var entry: CodexEntry = by_id[entry_id] as CodexEntry
		assert_true(entry.hint_text.contains(str(expected_recipes[entry_id])), "Hint should show recipe for %s" % entry_id)
		assert_true(entry.full_description.contains(str(expected_recipes[entry_id])), "Full entry should show recipe for %s" % entry_id)
	codex.queue_free()
