class_name CraftingGrid
extends RefCounted

const EMPTY: int = -1
const GRID_SIZE: int = 3

signal grid_changed(matched_recipe: RecipeDefinition)

var _registry: RecipeRegistry
var _cells: Array = []

func _init(registry: RecipeRegistry) -> void:
	_registry = registry
	_cells.resize(GRID_SIZE * GRID_SIZE)
	_cells.fill(EMPTY)

func _idx(row: int, col: int) -> int:
	return row * GRID_SIZE + col

func set_cell(row: int, col: int, element: int) -> void:
	_cells[_idx(row, col)] = element
	_emit_grid_changed()

func clear_cell(row: int, col: int) -> void:
	_cells[_idx(row, col)] = EMPTY
	_emit_grid_changed()

func clear_all() -> void:
	_cells.fill(EMPTY)
	_emit_grid_changed()

func get_cell(row: int, col: int) -> int:
	return int(_cells[_idx(row, col)])

func occupied_count() -> int:
	var count: int = 0
	for v: Variant in _cells:
		if int(v) != EMPTY:
			count += 1
	return count

## Returns [shape: Array[Vector2i], elements: Array[int]] normalized to
## min_row=0, min_col=0, sorted by (row, col) ascending.
func normalize() -> Array:
	var positions: Array[Vector2i] = []
	var elems: Array[int] = []
	for row: int in range(GRID_SIZE):
		for col: int in range(GRID_SIZE):
			var e: int = get_cell(row, col)
			if e != EMPTY:
				positions.append(Vector2i(row, col))
				elems.append(e)
	if positions.is_empty():
		return [[], []]
	var min_row: int = positions[0].x
	var min_col: int = positions[0].y
	for v: Vector2i in positions:
		if v.x < min_row:
			min_row = v.x
		if v.y < min_col:
			min_col = v.y
	# Translate
	var translated: Array[Vector2i] = []
	for v: Vector2i in positions:
		translated.append(Vector2i(v.x - min_row, v.y - min_col))
	# Sort by (row, col)
	var combined: Array = []
	for i: int in range(translated.size()):
		combined.append({"pos": translated[i], "elem": elems[i]})
	combined.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: Vector2i = a["pos"] as Vector2i
		var pb: Vector2i = b["pos"] as Vector2i
		if pa.x != pb.x:
			return pa.x < pb.x
		return pa.y < pb.y
	)
	var sorted_shape: Array[Vector2i] = []
	var sorted_elems: Array[int] = []
	for entry: Dictionary in combined:
		sorted_shape.append(entry["pos"] as Vector2i)
		sorted_elems.append(int(entry["elem"]))
	return [sorted_shape, sorted_elems]

## Returns true if all occupied cells form a single connected component
## (orthogonal OR diagonal adjacency).
func is_contiguous() -> bool:
	var occupied: Array[Vector2i] = []
	for row: int in range(GRID_SIZE):
		for col: int in range(GRID_SIZE):
			if get_cell(row, col) != EMPTY:
				occupied.append(Vector2i(row, col))
	if occupied.size() <= 1:
		return true
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [occupied[0]]
	visited[occupied[0]] = true
	var occupied_set: Dictionary = {}
	for v: Vector2i in occupied:
		occupied_set[v] = true
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for dr: int in [-1, 0, 1]:
			for dc: int in [-1, 0, 1]:
				if dr == 0 and dc == 0:
					continue
				var neighbor: Vector2i = Vector2i(current.x + dr, current.y + dc)
				if visited.has(neighbor):
					continue
				if not occupied_set.has(neighbor):
					continue
				visited[neighbor] = true
				queue.append(neighbor)
	return visited.size() == occupied.size()

func _emit_grid_changed() -> void:
	var matched: RecipeDefinition = null
	if is_contiguous() and occupied_count() > 0:
		var result: Array = normalize()
		var shape: Array = result[0]
		var elems: Array = result[1]
		matched = _registry.lookup(shape, elems)
	grid_changed.emit(matched)
