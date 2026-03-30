class_name BuildMode
extends RefCounted

signal placement_confirmed(record: PlacementRecord)
signal placement_cancelled(recipe_id: String)
signal validation_updated(results: Array)

var recipe: RecipeDefinition
var rotation_steps: int = 0
var anchor_cell: Vector2i = Vector2i.ZERO

var _validator: TerrainValidator
var _grid: RefCounted
var _last_validation: Array[Dictionary] = []

func _init(p_recipe: RecipeDefinition, p_grid: RefCounted) -> void:
	recipe = p_recipe
	_grid = p_grid
	_validator = TerrainValidator.new()

func rotate_cw() -> void:
	rotation_steps = (rotation_steps + 1) % 4
	_revalidate()

func set_anchor(cell: Vector2i) -> void:
	anchor_cell = cell
	_revalidate()

func can_confirm() -> bool:
	if _last_validation.is_empty():
		return false
	return TerrainValidator.all_valid(_last_validation)

func confirm() -> PlacementRecord:
	if not can_confirm():
		return null
	var record := PlacementRecord.new()
	record.recipe_id = recipe.recipe_id
	record.anchor_cell = anchor_cell
	record.rotation_steps = rotation_steps
	placement_confirmed.emit(record)
	return record

func cancel() -> void:
	placement_cancelled.emit(recipe.recipe_id)

func get_footprint_cells() -> Array[Vector2i]:
	var rotated: Array[Vector2i] = TerrainValidator.apply_rotation(recipe.shape, rotation_steps)
	var result: Array[Vector2i] = []
	for offset: Vector2i in rotated:
		result.append(Vector2i(anchor_cell.x + offset.x, anchor_cell.y + offset.y))
	return result

func get_last_validation() -> Array[Dictionary]:
	return _last_validation

func _revalidate() -> void:
	_last_validation = _validator.validate(recipe, anchor_cell, rotation_steps, _grid)
	validation_updated.emit(_last_validation)
