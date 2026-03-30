class_name PlacementRecord
extends Resource

@export var recipe_id: String = ""
@export var anchor_cell: Vector2i = Vector2i.ZERO
@export var rotation_steps: int = 0

func serialize() -> Dictionary:
	return {
		"recipe_id": recipe_id,
		"anchor_cell": {"x": anchor_cell.x, "y": anchor_cell.y},
		"rotation_steps": rotation_steps,
	}

static func deserialize(d: Dictionary) -> PlacementRecord:
	var r := PlacementRecord.new()
	r.recipe_id = str(d.get("recipe_id", ""))
	var ac: Dictionary = d.get("anchor_cell", {})
	r.anchor_cell = Vector2i(int(ac.get("x", 0)), int(ac.get("y", 0)))
	r.rotation_steps = int(d.get("rotation_steps", 0))
	return r
