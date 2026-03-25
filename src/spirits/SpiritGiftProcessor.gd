class_name SpiritGiftProcessor
extends RefCounted

const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")

static func process(spirit_id: String, definition: Dictionary) -> void:
	if spirit_id.is_empty():
		return
	var gift_type: int = int(definition.get("gift_type", SpiritGiftTypeScript.Value.NONE))
	var gift_payload: StringName = StringName(str(definition.get("gift_payload", "")))
	process_gift(gift_type, gift_payload)

static func process_gift(gift_type: int, gift_payload: StringName) -> void:
	var root: Node = Engine.get_main_loop().root
	if root == null:
		return
	match gift_type:
		SpiritGiftTypeScript.Value.KU_UNLOCK:
			var alchemy: Node = root.get_node_or_null("/root/SeedAlchemyService")
			if alchemy != null and alchemy.has_method("is_ku_unlocked") and alchemy.is_ku_unlocked():
				return
			if alchemy != null and alchemy.has_method("unlock_element"):
				alchemy.unlock_element(GodaiElementScript.Value.KU)
		SpiritGiftTypeScript.Value.TIER3_RECIPE:
			var alchemy_registry: Node = root.get_node_or_null("/root/SeedAlchemyService")
			if alchemy_registry != null and alchemy_registry.has_method("get_registry"):
				var registry: SeedRecipeRegistry = alchemy_registry.get_registry()
				if registry != null:
					registry.unlock_recipe(gift_payload)
		SpiritGiftTypeScript.Value.POUCH_EXPAND:
			var growth_service_for_slots: Node = root.get_node_or_null("/root/SeedGrowthService")
			if growth_service_for_slots != null and growth_service_for_slots.has_method("get_tracker"):
				var slots_tracker: GrowthSlotTracker = growth_service_for_slots.get_tracker()
				if slots_tracker != null:
					slots_tracker.capacity += 1
		SpiritGiftTypeScript.Value.GROWING_SLOT_EXPAND:
			var growth_service_for_pouch: Node = root.get_node_or_null("/root/SeedGrowthService")
			if growth_service_for_pouch != null and growth_service_for_pouch.has_method("get_pouch"):
				var seed_pouch: SeedPouch = growth_service_for_pouch.get_pouch()
				if seed_pouch != null:
					seed_pouch.capacity += 1
		SpiritGiftTypeScript.Value.CODEX_REVEAL:
			var codex: Node = root.get_node_or_null("/root/CodexService")
			if codex != null and codex.has_method("force_reveal"):
				codex.force_reveal(gift_payload)
		_:
			pass
