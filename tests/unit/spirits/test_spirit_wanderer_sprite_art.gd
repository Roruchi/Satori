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
