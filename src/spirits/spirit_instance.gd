class_name SpiritInstance
extends RefCounted

var spirit_id: String = ""
var spawn_coord: Vector2i = Vector2i.ZERO
var wander_bounds: Rect2i = Rect2i()
var is_active: bool = false
var summoned_at: int = 0
## Island on which this spirit was summoned.  Empty string when island tracking
## is not applicable (e.g., Sky Whale) or for legacy saved data.
var island_id: String = ""

static func create(sid: String, coord: Vector2i, bounds: Rect2i) -> SpiritInstance:
	var inst := SpiritInstance.new()
	inst.spirit_id = sid
	inst.spawn_coord = coord
	inst.wander_bounds = bounds
	inst.is_active = true
	inst.summoned_at = int(Time.get_unix_time_from_system())
	return inst

func serialize() -> Dictionary:
	return {
		"spirit_id": spirit_id,
		"spawn_coord": {"x": spawn_coord.x, "y": spawn_coord.y},
		"wander_bounds": {
			"x": wander_bounds.position.x,
			"y": wander_bounds.position.y,
			"w": wander_bounds.size.x,
			"h": wander_bounds.size.y
		},
		"is_active": is_active,
		"summoned_at": summoned_at,
		"island_id": island_id
	}

static func deserialize(data: Dictionary) -> SpiritInstance:
	var inst := SpiritInstance.new()
	inst.spirit_id = str(data.get("spirit_id", ""))
	var sc: Dictionary = data.get("spawn_coord", {"x": 0, "y": 0})
	inst.spawn_coord = Vector2i(int(sc.get("x", 0)), int(sc.get("y", 0)))
	var wb: Dictionary = data.get("wander_bounds", {"x": 0, "y": 0, "w": 0, "h": 0})
	inst.wander_bounds = Rect2i(
		int(wb.get("x", 0)), int(wb.get("y", 0)),
		int(wb.get("w", 0)), int(wb.get("h", 0))
	)
	inst.is_active = bool(data.get("is_active", true))
	inst.summoned_at = int(data.get("summoned_at", 0))
	inst.island_id = str(data.get("island_id", ""))
	return inst
