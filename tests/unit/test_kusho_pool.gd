extends GutTest

const GodaiElement = preload("res://src/seeds/GodaiElement.gd")
const KushoPool = preload("res://src/autoloads/kusho_pool.gd")

func test_consume_and_depletion_state() -> void:
	var pool: KushoPool = KushoPool.new()
	pool.set_charge(GodaiElement.Value.CHI, 2)

	assert_true(pool.consume(GodaiElement.Value.CHI, 1), "First consume should succeed")
	assert_eq(pool.get_charge(GodaiElement.Value.CHI), 1, "Charge should decrement to 1")
	assert_true(pool.is_low(GodaiElement.Value.CHI), "Charge 1 should be low")

	assert_true(pool.consume(GodaiElement.Value.CHI, 1), "Second consume should succeed")
	assert_eq(pool.get_charge(GodaiElement.Value.CHI), 0, "Charge should reach zero")
	assert_true(pool.is_depleted(GodaiElement.Value.CHI), "Charge 0 should be depleted")
	assert_false(pool.consume(GodaiElement.Value.CHI, 1), "Consume should fail when depleted")

func test_add_charge_clamps_and_reports_overflow() -> void:
	var pool: KushoPool = KushoPool.new()
	pool.set_charge(GodaiElement.Value.SUI, 2)

	var overflow: int = pool.add_charge(GodaiElement.Value.SUI, 3)
	assert_eq(pool.get_charge(GodaiElement.Value.SUI), KushoPool.CAPACITY_PER_ELEMENT, "Charge should clamp at cap")
	assert_eq(overflow, 2, "Overflow should equal amount beyond cap")

func test_all_depleted_detection() -> void:
	var pool: KushoPool = KushoPool.new()
	assert_true(pool.are_all_depleted(), "Fresh pool should be depleted for all elements")

	pool.set_charge(GodaiElement.Value.FU, 1)
	assert_false(pool.are_all_depleted(), "Any non-zero element should break all-depleted state")
