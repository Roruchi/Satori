## BitmaskAutotiler — computes the 6-bit hex neighbour bitmask for a tile.
##
## Bit layout (pointy-top axial hex):
##   bit 0 = E    Vector2i( 1,  0)
##   bit 1 = W    Vector2i(-1,  0)
##   bit 2 = SE   Vector2i( 0,  1)
##   bit 3 = NW   Vector2i( 0, -1)
##   bit 4 = NE   Vector2i( 1, -1)
##   bit 5 = SW   Vector2i(-1,  1)
##
## Raw range: 0–63.
## Canonical range: 0–12 (D6 dihedral symmetry reduction — 13 equivalence classes).
##
## The D6 group has 12 elements (6 rotations × reflection).  Applying all 12
## transforms to a raw bitmask and taking the minimum integer value gives the
## canonical representative; 64 values collapse to exactly 13 classes.

## Neighbour offset table ordered by bit position 0–5.
const _OFFSETS: Array[Vector2i] = [
	Vector2i( 1,  0),  # bit 0  E
	Vector2i(-1,  0),  # bit 1  W
	Vector2i( 0,  1),  # bit 2  SE
	Vector2i( 0, -1),  # bit 3  NW
	Vector2i( 1, -1),  # bit 4  NE
	Vector2i(-1,  1),  # bit 5  SW
]

## Pre-built lookup table: raw bitmask (0–63) → canonical index (0–12).
## Populated lazily on the first call to to_canonical().
static var _canonical_table: Array[int] = []


## Compute the raw 6-bit bitmask for the tile at `coord`.
## A neighbour contributes its bit only when it exists AND shares the same biome.
static func compute_bitmask(coord: Vector2i, grid: RefCounted) -> int:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return 0
	var biome: int = tile.biome
	var mask: int = 0
	for bit: int in range(6):
		var neighbour: GardenTile = grid.get_tile(coord + _OFFSETS[bit])
		if neighbour != null and neighbour.biome == biome:
			mask |= (1 << bit)
	return mask


## Map a raw 6-bit bitmask (0–63) to a canonical index (0–12) via D6 symmetry.
## Same input always produces same output (pure / deterministic).
static func to_canonical(raw: int) -> int:
	if _canonical_table.is_empty():
		_build_canonical_table()
	return _canonical_table[raw & 0x3F]


# ---------------------------------------------------------------------------
# D6 canonical table construction
# ---------------------------------------------------------------------------

## Build the 64-element lookup table mapping raw bitmask → canonical index (0–12).
## Called once; results are cached in _canonical_table.
static func _build_canonical_table() -> void:
	# Step 1: compute the D6-minimum representative for each of the 64 raw values
	var min_reps: Array[int] = []
	min_reps.resize(64)
	for raw: int in range(64):
		min_reps[raw] = _d6_minimum(raw)

	# Step 2: collect the 13 unique minimum representatives in sorted order
	var unique: Array[int] = []
	for rep: int in min_reps:
		if not unique.has(rep):
			unique.append(rep)
	unique.sort()

	# Step 3: build final table — raw → index of its min_rep in the sorted unique list
	_canonical_table.resize(64)
	for raw: int in range(64):
		_canonical_table[raw] = unique.find(min_reps[raw])


## Return the minimum integer value in the D6 orbit of `mask`.
## Applies all 12 D6 transforms (6 rotations + 6 rotation-reflections).
static func _d6_minimum(mask: int) -> int:
	var min_val: int = mask
	var current: int = mask
	# 5 more CW rotations (identity already counted as mask)
	for _i: int in range(5):
		current = _rotate60(current)
		if current < min_val:
			min_val = current
	# Reflection + its 5 rotations
	current = _reflect(mask)
	if current < min_val:
		min_val = current
	for _i: int in range(5):
		current = _rotate60(current)
		if current < min_val:
			min_val = current
	return min_val


## Rotate bitmask clockwise by 60° around the hex centre.
## Each neighbour direction moves one step CW in the ring E→SE→SW→W→NW→NE→E.
## Permutation (old bit → new bit): E(0)→SE(2), W(1)→NW(3), SE(2)→SW(5),
##   NW(3)→NE(4), NE(4)→E(0), SW(5)→W(1).
static func _rotate60(mask: int) -> int:
	const ROT: Array[int] = [2, 3, 5, 4, 0, 1]
	var new_mask: int = 0
	for i: int in range(6):
		if mask & (1 << i):
			new_mask |= (1 << ROT[i])
	return new_mask


## Reflect bitmask over the vertical axis (E↔W, SE↔SW, NW↔NE).
## Permutation: E(0)↔W(1), SE(2)↔SW(5), NW(3)↔NE(4).
static func _reflect(mask: int) -> int:
	const REF: Array[int] = [1, 0, 5, 4, 3, 2]
	var new_mask: int = 0
	for i: int in range(6):
		if mask & (1 << i):
			new_mask |= (1 << REF[i])
	return new_mask
