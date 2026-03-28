extends GutTest

func test_biome_placement_spends_kusho_charge_and_fails_when_empty() -> void:
	var alchemy: SeedAlchemyServiceNode = SeedAlchemyServiceNode.new()
	add_child(alchemy)
	alchemy._ready()

	alchemy.set_element_charge_for_testing(GodaiElement.Value.CHI, 1)
	assert_true(
		alchemy.spend_for_biome_placement(BiomeType.Value.STONE),
		"Stone placement should spend one Chi/Kusho charge when available"
	)
	assert_eq(
		alchemy.get_element_charge(GodaiElement.Value.CHI),
		0,
		"Chi/Kusho charge should decrement to zero after spend"
	)
	assert_false(
		alchemy.spend_for_biome_placement(BiomeType.Value.STONE),
		"Stone placement should fail once Chi/Kusho charge is depleted"
	)
	alchemy.queue_free()
