class_name AssetReadinessCatalogData
extends RefCounted

const STATUS_NEEDS_POLISH: String = "needs_polish"
const STATUS_IN_PROGRESS: String = "in_progress"
const STATUS_READY: String = "ready"

const PRIORITY_HIGH: String = "high"
const PRIORITY_MEDIUM: String = "medium"
const PRIORITY_LOW: String = "low"

const _GAPS: Dictionary = {
	"merged_mountain_voxel_fallback": {
		"status": STATUS_IN_PROGRESS,
		"priority": PRIORITY_HIGH,
		"summary": "Unlocked Mountain Peak visuals are being routed through the authored Mountain Peak spritesheet instead of generated boxy voxel peaks.",
		"evidence_paths": [
			"res://src/rendering/voxel_renderer.gd",
			"res://src/grid/GardenView.gd",
			"res://src/biomes/patterns/tier1/mountain_peak.tres",
			"res://assets/structures/mountain_peak/frames/idle/down/frame_0000.png",
		],
		"missing_or_unpolished": [
			"disc_mountain_peak",
			"large_cluster_sprite_scale_qa",
		],
		"next_action": "Visually QA large Stone clusters in game and keep procedural mountain mesh generation out of the primary render path.",
	},
	"structure_sprite_fallbacks": {
		"status": STATUS_IN_PROGRESS,
		"priority": PRIORITY_HIGH,
		"summary": "Completed structures now prefer catalog sprites, including dedicated Meadow, Warm, and Stone Hollow dwelling art; remaining risk is unmapped future IDs.",
		"evidence_paths": [
			"res://src/grid/GardenView.gd",
			"res://src/ui/tile_selector_hex.gd",
			"res://src/biomes/structure_catalog_data.gd",
			"res://assets/structures/",
		],
		"missing_or_unpolished": [
			"unmapped_completed_structure_ids",
			"future_structure_ids_without_catalog_sprite",
		],
		"next_action": "Keep catalog/tests as the gate for any new structure ID so menus, inventory, and world rendering resolve a spritesheet asset before fallback.",
	},
	"biome_transition_decorations": {
		"status": STATUS_NEEDS_POLISH,
		"priority": PRIORITY_HIGH,
		"summary": "Biome edge decorations are procedural development meshes and only cover a small legacy pair set.",
		"evidence_paths": [
			"res://src/rendering/biome_transition_layer.gd",
		],
		"missing_or_unpolished": [
			"stone_river",
			"meadow_river",
			"meadow_stone",
			"all_modern_mixed_biome_edges",
		],
		"next_action": "Create a modern transition decoration library keyed to current BiomeType values.",
	},
	"generic_dwelling_reuse": {
		"status": STATUS_IN_PROGRESS,
		"priority": PRIORITY_MEDIUM,
		"summary": "Meadow, Warm, and Stone Hollow now have dedicated dwelling sprites; generic House remains an intentionally shared starter dwelling.",
		"evidence_paths": [
			"res://src/biomes/structure_catalog_data.gd",
			"res://assets/structures/meadow_hollow/frames/idle/down/frame_0000.png",
			"res://assets/structures/warm_hollow/frames/idle/down/frame_0000.png",
			"res://assets/structures/stone_hollow/frames/idle/down/frame_0000.png",
		],
		"missing_or_unpolished": [
			"building_house_optional_variant_set",
		],
		"next_action": "Add further dwelling variants only when gameplay creates a distinct named dwelling; do not draw procedural stand-ins.",
	},
	"spirit_animation_depth": {
		"status": STATUS_NEEDS_POLISH,
		"priority": PRIORITY_MEDIUM,
		"summary": "Spirit art is loadable, but Red Fox is the only full animated reference; the remaining spirits are first-pass static idle-down sprites.",
		"evidence_paths": [
			"res://docs/spirit_sprite_inventory.md",
			"res://tests/unit/spirits/test_spirit_wanderer_sprite_art.gd",
			"res://assets/spirits/",
		],
		"missing_or_unpolished": [
			"spirit_suijin",
			"spirit_mist_stag",
			"spirit_tree_frog",
			"other_static_batch_source_spirits",
		],
		"next_action": "Upgrade first-session and kami spirits from static idle-down sprites to richer directional or animated sets.",
	},
	"material_icon_metadata": {
		"status": STATUS_NEEDS_POLISH,
		"priority": PRIORITY_MEDIUM,
		"summary": "Material CSV rows point every material at one icon sheet while live HUD and ritual UI use a separate ritual icon atlas with hard-coded regions.",
		"evidence_paths": [
			"res://data/discovery_editor/runtime/materials.csv.txt",
			"res://src/ui/HUDController.gd",
			"res://src/ui/SeedAlchemyPanel.gd",
		],
		"missing_or_unpolished": [
			"living_wood_icon_metadata",
			"reed_fiber_icon_metadata",
			"spirit_stone_icon_metadata",
			"ember_clay_icon_metadata",
		],
		"next_action": "Make material icon metadata match the live atlas and regions, or split the material icons into per-material assets.",
	},
	"structure_qa_metadata": {
		"status": STATUS_NEEDS_POLISH,
		"priority": PRIORITY_LOW,
		"summary": "Most structure folders have loadable frames but do not carry a QA contact sheet, making future visual regressions harder to compare.",
		"evidence_paths": [
			"res://assets/structures/",
			"res://assets/structures/style_guide.md",
		],
		"missing_or_unpolished": [
			"most_structure_folders_without_qa_contact_sheet",
		],
		"next_action": "Generate or commit QA contact sheets for completed structure assets as a polish pass.",
	},
}


static func get_gaps() -> Dictionary:
	return _GAPS.duplicate(true)


static func get_gap(gap_id: String) -> Dictionary:
	var gap_variant: Variant = _GAPS.get(gap_id, {})
	if gap_variant is Dictionary:
		return (gap_variant as Dictionary).duplicate(true)
	return {}


static func get_priority_order() -> Array[String]:
	var ids: Array[String] = []
	for gap_id_variant: Variant in _GAPS.keys():
		ids.append(str(gap_id_variant))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return _priority_rank(str(_GAPS[a].get("priority", PRIORITY_LOW))) < _priority_rank(str(_GAPS[b].get("priority", PRIORITY_LOW)))
	)
	return ids


static func _priority_rank(priority: String) -> int:
	match priority:
		PRIORITY_HIGH:
			return 0
		PRIORITY_MEDIUM:
			return 1
		_:
			return 2
