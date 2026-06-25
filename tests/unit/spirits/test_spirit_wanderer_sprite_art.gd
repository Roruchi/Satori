## Test Suite: SpiritWanderer sprite art wiring
##
## Verifies that generated SpriteFrames assets are consumed by wanderers.

extends GutTest


func test_red_fox_loads_generated_sprite_frames() -> void:
	var wanderer: SpiritWanderer = SpiritWanderer.new()
	add_child(wanderer)
	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_red_fox",
		Vector2i.ZERO,
		Rect2i(Vector2i.ZERO, Vector2i.ONE)
	)
	wanderer.setup(instance, {
		"display_name": "Red Fox",
		"wander_speed": 0.0,
	})

	var sprite: AnimatedSprite2D = wanderer.get_node_or_null("SpiritSprite") as AnimatedSprite2D
	assert_not_null(sprite, "Red Fox should create an AnimatedSprite2D child")
	assert_not_null(sprite.sprite_frames, "Red Fox sprite should load sprite_frames.tres")
	assert_eq(sprite.animation, "idle_down", "Red Fox should start on the idle_down clip")
	assert_true(sprite.visible, "Red Fox sprite should be visible")

	remove_child(wanderer)
	wanderer.free()


func test_static_spirit_loads_generated_sprite_frames() -> void:
	var catalog: SpiritCatalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	catalog.load_from_data(data)

	var wanderer: SpiritWanderer = SpiritWanderer.new()
	add_child(wanderer)
	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_tree_frog",
		Vector2i.ZERO,
		Rect2i(Vector2i.ZERO, Vector2i.ONE)
	)
	wanderer.setup(instance, catalog.lookup("spirit_tree_frog"))

	var sprite: AnimatedSprite2D = wanderer.get_node_or_null("SpiritSprite") as AnimatedSprite2D
	assert_not_null(sprite, "Tree Frog should create an AnimatedSprite2D child from static art")
	assert_not_null(sprite.sprite_frames, "Tree Frog sprite should load sprite_frames.tres")
	assert_eq(sprite.animation, "idle_down", "Tree Frog should start on the static idle_down clip")
	assert_true(sprite.visible, "Tree Frog sprite should be visible")

	remove_child(wanderer)
	wanderer.free()


func test_catalog_spirits_have_loadable_sprite_frames() -> void:
	var catalog: SpiritCatalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	catalog.load_from_data(data)

	for spirit_id: String in catalog.get_all_spirit_ids():
		var sprite_path: String = "res://assets/spirits/%s/sprite_frames.tres" % spirit_id
		assert_true(ResourceLoader.exists(sprite_path, "SpriteFrames"), "%s should have sprite_frames.tres" % spirit_id)
		var resource: Resource = ResourceLoader.load(sprite_path, "SpriteFrames")
		var frames: SpriteFrames = resource as SpriteFrames
		assert_not_null(frames, "%s sprite_frames.tres should load as SpriteFrames" % spirit_id)
		if frames != null:
			assert_true(frames.has_animation("idle_down"), "%s should expose idle_down" % spirit_id)


func test_catalog_spirits_have_sprite_scale_metadata() -> void:
	var catalog: SpiritCatalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	catalog.load_from_data(data)

	for spirit_id: String in catalog.get_all_spirit_ids():
		var entry: Dictionary = catalog.lookup(spirit_id)
		assert_true(entry.has("sprite_scale"), "%s should declare sprite_scale" % spirit_id)
		assert_gt(float(entry["sprite_scale"]), 0.0, "%s sprite_scale should be positive" % spirit_id)


func test_sprite_scale_matches_relative_animal_size() -> void:
	var catalog: SpiritCatalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	catalog.load_from_data(data)

	var frog: Dictionary = catalog.lookup("spirit_tree_frog")
	var fox: Dictionary = catalog.lookup("spirit_red_fox")
	var whale: Dictionary = catalog.lookup("spirit_sky_whale")

	assert_lt(float(frog["sprite_scale"]), float(fox["sprite_scale"]), "Tree Frog should render smaller than Red Fox")
	assert_gt(float(whale["sprite_scale"]), float(fox["sprite_scale"]) * 2.0, "Sky Whale should span multiple tile widths")


func test_wanderer_applies_catalog_sprite_scale() -> void:
	var catalog: SpiritCatalog = SpiritCatalog.new()
	var data: SpiritCatalogData = SpiritCatalogData.new()
	catalog.load_from_data(data)

	var whale_wanderer: SpiritWanderer = SpiritWanderer.new()
	add_child(whale_wanderer)
	var whale_instance: SpiritInstance = SpiritInstance.create(
		"spirit_sky_whale",
		Vector2i.ZERO,
		Rect2i(Vector2i.ZERO, Vector2i.ONE)
	)
	whale_wanderer.setup(whale_instance, catalog.lookup("spirit_sky_whale"))
	var whale_sprite: AnimatedSprite2D = whale_wanderer.get_node_or_null("SpiritSprite") as AnimatedSprite2D
	assert_not_null(whale_sprite, "Sky Whale should load sprite art")
	if whale_sprite != null:
		assert_almost_eq(whale_sprite.scale.x, 1.95, 0.001, "Sky Whale should render across multiple tiles")
		assert_almost_eq(whale_sprite.scale.y, 1.95, 0.001, "Sky Whale scale should be uniform")

	var frog_wanderer: SpiritWanderer = SpiritWanderer.new()
	add_child(frog_wanderer)
	var frog_instance: SpiritInstance = SpiritInstance.create(
		"spirit_tree_frog",
		Vector2i.ZERO,
		Rect2i(Vector2i.ZERO, Vector2i.ONE)
	)
	frog_wanderer.setup(frog_instance, catalog.lookup("spirit_tree_frog"))
	var frog_sprite: AnimatedSprite2D = frog_wanderer.get_node_or_null("SpiritSprite") as AnimatedSprite2D
	assert_not_null(frog_sprite, "Tree Frog should load sprite art")
	if frog_sprite != null:
		assert_almost_eq(frog_sprite.scale.x, 0.32, 0.001, "Tree Frog should render around half a tile")
		assert_almost_eq(frog_sprite.scale.y, 0.32, 0.001, "Tree Frog scale should be uniform")

	remove_child(whale_wanderer)
	whale_wanderer.free()
	remove_child(frog_wanderer)
	frog_wanderer.free()


func test_spirit_without_sprite_frames_keeps_placeholder_fallback() -> void:
	var wanderer: SpiritWanderer = SpiritWanderer.new()
	add_child(wanderer)
	var instance: SpiritInstance = SpiritInstance.create(
		"spirit_missing_art",
		Vector2i.ZERO,
		Rect2i(Vector2i.ZERO, Vector2i.ONE)
	)
	wanderer.setup(instance, {
		"display_name": "Missing Art",
		"wander_speed": 0.0,
	})

	var sprite: AnimatedSprite2D = wanderer.get_node_or_null("SpiritSprite") as AnimatedSprite2D
	assert_null(sprite, "Spirits without sprite_frames.tres should keep the draw fallback")

	remove_child(wanderer)
	wanderer.free()
