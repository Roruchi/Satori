extends GutTest

const AssetReadinessCatalogDataScript = preload("res://src/biomes/asset_readiness_catalog_data.gd")


func test_asset_readiness_catalog_lists_prioritized_gaps() -> void:
	var order: Array[String] = AssetReadinessCatalogDataScript.get_priority_order()

	assert_gt(order.size(), 0)
	assert_eq(order[0], "merged_mountain_voxel_fallback")
	assert_has(order, "structure_sprite_fallbacks")
	assert_has(order, "biome_transition_decorations")
	assert_has(order, "generic_dwelling_reuse")
	assert_has(order, "spirit_animation_depth")
	assert_has(order, "material_icon_metadata")


func test_each_asset_gap_has_actionable_metadata() -> void:
	var gaps: Dictionary = AssetReadinessCatalogDataScript.get_gaps()

	for gap_id_variant: Variant in gaps.keys():
		var gap_id: String = str(gap_id_variant)
		var gap: Dictionary = AssetReadinessCatalogDataScript.get_gap(gap_id)
		assert_false(str(gap.get("status", "")).is_empty(), "%s should have a status" % gap_id)
		assert_false(str(gap.get("priority", "")).is_empty(), "%s should have a priority" % gap_id)
		assert_false(str(gap.get("summary", "")).is_empty(), "%s should explain the gap" % gap_id)
		assert_true(gap.get("evidence_paths", []) is Array, "%s should list evidence paths" % gap_id)
		assert_gt((gap.get("evidence_paths", []) as Array).size(), 0, "%s should list at least one evidence path" % gap_id)
		assert_true(gap.get("missing_or_unpolished", []) is Array, "%s should list missing or unpolished assets" % gap_id)
		assert_gt((gap.get("missing_or_unpolished", []) as Array).size(), 0, "%s should list at least one asset target" % gap_id)
		assert_false(str(gap.get("next_action", "")).is_empty(), "%s should include a next action" % gap_id)
