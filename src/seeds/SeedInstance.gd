class_name SeedInstance
extends RefCounted

var recipe_id: StringName = &""
var hex_coord: Vector2i = Vector2i.ZERO
var planted_at: float = 0.0
var growth_duration: float = 0.0
var state: int = SeedState.Value.GROWING
var produces_biome: int = BiomeType.Value.NONE
var as_build_block: bool = false

static func create(rid: StringName, coord: Vector2i, duration: float, target_biome: int, build_block: bool = false) -> SeedInstance:
	var instance: SeedInstance = SeedInstance.new()
	instance.recipe_id = rid
	instance.hex_coord = coord
	instance.planted_at = Time.get_unix_time_from_system()
	instance.growth_duration = duration
	instance.state = SeedState.Value.GROWING
	instance.produces_biome = target_biome
	instance.as_build_block = build_block
	return instance

func is_ready() -> bool:
	return state == SeedState.Value.READY or state == SeedState.Value.BLOOMED

func evaluate_growth() -> bool:
	if state != SeedState.Value.GROWING:
		return false
	if growth_duration <= 0.0:
		state = SeedState.Value.READY
		return true
	var elapsed: float = Time.get_unix_time_from_system() - planted_at
	if elapsed >= growth_duration:
		state = SeedState.Value.READY
		return true
	return false

func serialize() -> Dictionary:
	return {
		"recipe_id": str(recipe_id),
		"hex_coord": {"x": hex_coord.x, "y": hex_coord.y},
		"planted_at": planted_at,
		"growth_duration": growth_duration,
		"state": state,
		"produces_biome": produces_biome,
		"as_build_block": as_build_block,
	}

static func deserialize(data: Dictionary) -> SeedInstance:
	var instance: SeedInstance = SeedInstance.new()
	instance.recipe_id = StringName(str(data.get("recipe_id", "")))
	var coord_data: Dictionary = data.get("hex_coord", {})
	instance.hex_coord = Vector2i(int(coord_data.get("x", 0)), int(coord_data.get("y", 0)))
	instance.planted_at = float(data.get("planted_at", 0.0))
	instance.growth_duration = float(data.get("growth_duration", 0.0))
	instance.state = int(data.get("state", SeedState.Value.GROWING))
	# Backward compatibility: older seed saves used "biome" as the key.
	instance.produces_biome = int(data.get("produces_biome", data.get("biome", BiomeType.Value.NONE)))
	instance.as_build_block = bool(data.get("as_build_block", false))
	return instance
