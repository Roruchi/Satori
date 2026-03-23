## BitmaskAutotiler — computes the 8-bit neighbour bitmask for a tile.
##
## Bit layout (matches standard RPG Maker / Godot blob autotile convention):
##   bit 0 = NW   bit 1 = N    bit 2 = NE
##   bit 3 = W                 bit 4 = E
##   bit 5 = SW   bit 6 = S    bit 7 = SE
##
## A neighbour sets its bit only when it exists AND shares the same biome
## as the queried tile.  Cross-biome transition handling is applied separately
## by BiomeTransitionLayer.

const _NW: int = 1 << 0
const _N:  int = 1 << 1
const _NE: int = 1 << 2
const _W:  int = 1 << 3
const _E:  int = 1 << 4
const _SW: int = 1 << 5
const _S:  int = 1 << 6
const _SE: int = 1 << 7

## Neighbour offset table ordered NW, N, NE, W, E, SW, S, SE (bits 0–7).
const _OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1),  # bit 0 NW
	Vector2i(0, -1),   # bit 1 N
	Vector2i(1, -1),   # bit 2 NE
	Vector2i(-1, 0),   # bit 3 W
	Vector2i(1, 0),    # bit 4 E
	Vector2i(-1, 1),   # bit 5 SW
	Vector2i(0, 1),    # bit 6 S
	Vector2i(1, 1),    # bit 7 SE
]


## Compute the raw 8-bit bitmask for the tile at `coord`.
## Neighbours that share the tile's biome set their respective bits.
## Missing tiles or different-biome tiles contribute 0.
static func compute_bitmask(coord: Vector2i, grid: RefCounted) -> int:
	var tile: GardenTile = grid.get_tile(coord)
	if tile == null:
		return 0

	var biome: int = tile.biome
	var mask: int = 0

	for bit: int in range(8):
		var neighbour: GardenTile = grid.get_tile(coord + _OFFSETS[bit])
		if neighbour != null and neighbour.biome == biome:
			mask |= (1 << bit)

	return mask


## Map a raw 8-bit bitmask (0–255) to a canonical Wang index (0–46).
## Applies corner-dependency normalisation first, then maps to canonical class.
## Same input always produces same output (pure / deterministic).
static func to_canonical(raw: int) -> int:
	# Corner-dependency rule: clear a diagonal if either adjacent cardinal is absent
	var v: int = raw & 0xFF
	if (v & _N) == 0 or (v & _W) == 0:
		v &= ~_NW
	if (v & _N) == 0 or (v & _E) == 0:
		v &= ~_NE
	if (v & _S) == 0 or (v & _W) == 0:
		v &= ~_SW
	if (v & _S) == 0 or (v & _E) == 0:
		v &= ~_SE
	return _normalised_to_canonical(v)


## Map a corner-normalised bitmask to a canonical index 0–46.
## Uses the 47-class blob tile enumeration.
static func _normalised_to_canonical(v: int) -> int:
	var n: bool = (v & _N) != 0
	var e: bool = (v & _E) != 0
	var s: bool = (v & _S) != 0
	var w: bool = (v & _W) != 0
	var nw: bool = (v & _NW) != 0
	var ne: bool = (v & _NE) != 0
	var sw: bool = (v & _SW) != 0
	var se: bool = (v & _SE) != 0

	var card: int = (1 if n else 0) + (1 if e else 0) + (1 if s else 0) + (1 if w else 0)

	match card:
		0:
			return 0   # isolated

		1:
			# Single-cardinal shapes — no diagonals survive normalisation
			if n: return 1
			if e: return 2
			if s: return 3
			return 4   # w

		2:
			# Opposite pairs — all diagonals cleared by normalisation (other cardinals absent)
			if n and s: return 5
			if e and w: return 6
			# Corner pairs — exactly one inner diagonal survives
			if n and e: return 7 + (1 if ne else 0)   # 7 or 8
			if n and w: return 9 + (1 if nw else 0)   # 9 or 10
			if s and e: return 11 + (1 if se else 0)  # 11 or 12
			# s and w
			return 13 + (1 if sw else 0)              # 13 or 14

		3:
			# T-shapes — two inner diagonals survive (one per corner of the missing cardinal)
			if not n: return 15 + (1 if sw else 0) + (2 if se else 0)  # 15–18
			if not e: return 19 + (1 if nw else 0) + (2 if sw else 0)  # 19–22
			if not s: return 23 + (1 if nw else 0) + (2 if ne else 0)  # 23–26
			# not w
			return 27 + (1 if ne else 0) + (2 if se else 0)            # 27–30

		4:
			# Cross — all four diagonals can independently survive: 16 combos → 31–46
			var diag: int = (1 if nw else 0) + (2 if ne else 0) + (4 if sw else 0) + (8 if se else 0)
			return 31 + diag   # 31..46

	return 0
