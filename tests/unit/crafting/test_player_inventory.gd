extends GutTest

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_item(id: String, type: int, out_id: String, qty: int = 1) -> InventoryItem:
	var item := InventoryItem.new()
	item.recipe_id = id
	item.item_type = type
	item.output_id = out_id
	item.quantity = qty
	return item

# ---------------------------------------------------------------------------
# Tests: add_item / has_item
# ---------------------------------------------------------------------------

func test_add_item_makes_has_item_return_true() -> void:
	gut.p("add_item followed by has_item returns true")
	var inv := PlayerInventory.new()
	assert_true(inv.add_item(_make_item("recipe_fu_tile", 0, "3")), "add_item should return true")
	assert_true(inv.has_item("recipe_fu_tile"), "Inventory should contain the added item")

func test_has_item_returns_false_for_missing_item() -> void:
	gut.p("has_item returns false when item was never added")
	var inv := PlayerInventory.new()
	assert_false(inv.has_item("recipe_nonexistent"))

# ---------------------------------------------------------------------------
# Tests: consume
# ---------------------------------------------------------------------------

func test_consume_removes_item_when_quantity_reaches_zero() -> void:
	gut.p("Consuming the only copy removes the item entirely")
	var inv := PlayerInventory.new()
	inv.add_item(_make_item("recipe_chi_tile", 0, "0"))
	var success: bool = inv.consume("recipe_chi_tile")
	assert_true(success, "consume should return true")
	assert_false(inv.has_item("recipe_chi_tile"), "Item should be removed after consumption")

func test_consume_returns_false_for_missing_item() -> void:
	gut.p("consume returns false when item does not exist")
	var inv := PlayerInventory.new()
	assert_false(inv.consume("recipe_nonexistent"))

# ---------------------------------------------------------------------------
# Tests: stacking
# ---------------------------------------------------------------------------

func test_adding_same_recipe_id_twice_stacks_quantity_to_two() -> void:
	gut.p("Adding the same recipe_id twice yields quantity 2")
	var inv := PlayerInventory.new()
	inv.add_item(_make_item("recipe_starter_house", 1, "disc_starter_house"))
	inv.add_item(_make_item("recipe_starter_house", 1, "disc_starter_house"))
	var items: Array[InventoryItem] = inv.get_items()
	assert_eq(items.size(), 1, "Should be a single stack")
	assert_eq(items[0].quantity, 2, "Quantity should be 2 after adding twice")

# ---------------------------------------------------------------------------
# Tests: MAX_SLOTS = 8 capacity cap
# ---------------------------------------------------------------------------

func test_inventory_rejects_add_when_8_distinct_slots_are_full() -> void:
	gut.p("add_item returns false and does not add when 8 distinct slots already occupied")
	var inv := PlayerInventory.new()
	for i: int in range(PlayerInventory.MAX_SLOTS):
		var ok: bool = inv.add_item(_make_item("recipe_slot_%d" % i, 0, str(i)))
		assert_true(ok, "Slot %d should succeed" % i)
	# 9th distinct recipe_id must be rejected.
	var rejected: bool = inv.add_item(_make_item("recipe_overflow", 0, "overflow"))
	assert_false(rejected, "9th distinct slot should be rejected")
	assert_false(inv.has_item("recipe_overflow"), "Overflow item must not appear in inventory")

func test_can_add_item_returns_false_when_full() -> void:
	gut.p("can_add_item returns false when 8 slots are occupied by different recipe_ids")
	var inv := PlayerInventory.new()
	for i: int in range(PlayerInventory.MAX_SLOTS):
		inv.add_item(_make_item("recipe_slot_%d" % i, 0, str(i)))
	assert_false(inv.can_add_item("recipe_new"), "Should be false when full")

func test_stacking_existing_slot_succeeds_when_full() -> void:
	gut.p("Stacking into an existing slot is always allowed even when full")
	var inv := PlayerInventory.new()
	for i: int in range(PlayerInventory.MAX_SLOTS):
		inv.add_item(_make_item("recipe_slot_%d" % i, 0, str(i)))
	# Stacking into slot 0 (same recipe_id) must succeed.
	var ok: bool = inv.add_item(_make_item("recipe_slot_0", 0, "0"))
	assert_true(ok, "Stacking into existing slot should always succeed")

# ---------------------------------------------------------------------------
# Tests: serialize / deserialize round-trip
# ---------------------------------------------------------------------------

func test_serialize_deserialize_round_trip_preserves_fields() -> void:
	gut.p("serialize/deserialize preserves recipe_id, item_type, output_id, quantity")
	var inv := PlayerInventory.new()
	inv.add_item(_make_item("recipe_wayfarer_torii", 1, "disc_wayfarer_torii", 3))
	inv.add_item(_make_item("recipe_fu_tile", 0, "3", 1))

	var data: Array = inv.serialize()
	var restored: PlayerInventory = PlayerInventory.deserialize(data)

	assert_true(restored.has_item("recipe_wayfarer_torii"), "Torii should survive round-trip")
	assert_true(restored.has_item("recipe_fu_tile"), "Fu tile should survive round-trip")

	var items: Array[InventoryItem] = restored.get_items()
	var torii_item: InventoryItem = null
	var fu_item: InventoryItem = null
	for it: InventoryItem in items:
		if it.recipe_id == "recipe_wayfarer_torii":
			torii_item = it
		elif it.recipe_id == "recipe_fu_tile":
			fu_item = it

	assert_not_null(torii_item)
	assert_eq(torii_item.item_type, 1, "item_type should be preserved")
	assert_eq(torii_item.output_id, "disc_wayfarer_torii", "output_id should be preserved")
	assert_eq(torii_item.quantity, 3, "quantity should be preserved")

	assert_not_null(fu_item)
	assert_eq(fu_item.item_type, 0)
	assert_eq(fu_item.output_id, "3")
	assert_eq(fu_item.quantity, 1)

func test_deserialize_empty_array_returns_empty_inventory() -> void:
	gut.p("deserialize([]) returns an empty inventory (old-save compatibility)")
	var inv: PlayerInventory = PlayerInventory.deserialize([])
	assert_not_null(inv, "Should return a PlayerInventory, not null")
	assert_eq(inv.get_items().size(), 0, "Inventory should be empty")

# ---------------------------------------------------------------------------
# Tests: item_added signal
# ---------------------------------------------------------------------------

func test_item_added_signal_fires_on_add() -> void:
	gut.p("item_added signal is emitted when an item is added")
	var inv := PlayerInventory.new()
	var emitted: Array = []
	inv.item_added.connect(func(item: InventoryItem) -> void:
		emitted.append(item.recipe_id)
	)
	inv.add_item(_make_item("recipe_ka_tile", 0, "2"))
	assert_eq(emitted.size(), 1, "Signal should fire once")
	assert_eq(emitted[0], "recipe_ka_tile")

# ---------------------------------------------------------------------------
# Tests: item_removed signal
# ---------------------------------------------------------------------------

func test_item_removed_signal_fires_on_consume() -> void:
	gut.p("item_removed signal is emitted when an item is consumed")
	var inv := PlayerInventory.new()
	inv.add_item(_make_item("recipe_ka_tile", 0, "2"))
	var removed: Array = []
	inv.item_removed.connect(func(rid: String) -> void:
		removed.append(rid)
	)
	inv.consume("recipe_ka_tile")
	assert_eq(removed.size(), 1, "item_removed should fire once")
	assert_eq(removed[0], "recipe_ka_tile")

