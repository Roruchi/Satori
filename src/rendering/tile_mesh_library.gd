## TileMeshLibrary — manages mesh resources for voxel tile rendering.
##
## Maps (biome, canonical 0–12) → Mesh using the 6-bit hex bitmask D6
## canonical reduction from BitmaskAutotiler.
##
## During development, falls back to a generated coloured BoxMesh when no
## .tres asset is found, so the rendering pipeline is always functional.

class_name TileMeshLibrary
extends RefCounted

## Runtime mesh cache:  {biome: int} → Array[Mesh]  (indexed by canonical 0–12)
var _cache: Dictionary = {}
## LOD mesh cache:  {biome: int} → Array[Mesh]
var _cache_lod: Dictionary = {}
## Transition decoration data: {[biome_a, biome_b]: Resource}  (sorted pair)
var _transitions: Dictionary = {}

## Biome name map used for asset path construction.
const _BIOME_NAMES: Dictionary = {
	BiomeType.Value.FOREST:     "forest",
	BiomeType.Value.WATER:      "water",
	BiomeType.Value.STONE:      "stone",
	BiomeType.Value.EARTH:      "earth",
	BiomeType.Value.SWAMP:      "swamp",
	BiomeType.Value.TUNDRA:     "tundra",
	BiomeType.Value.MUDFLAT:    "mudflat",
	BiomeType.Value.MOSSY_CRAG: "mossy_crag",
	BiomeType.Value.SAVANNAH:   "savannah",
	BiomeType.Value.CANYON:     "canyon",
}

## Standard biome colours for fallback box meshes (matches GardenView palette).
const _BIOME_COLORS: Dictionary = {
	BiomeType.Value.FOREST:     Color(0.298, 0.686, 0.314),
	BiomeType.Value.WATER:      Color(0.129, 0.588, 0.953),
	BiomeType.Value.STONE:      Color(0.620, 0.620, 0.620),
	BiomeType.Value.EARTH:      Color(0.757, 0.580, 0.376),
	BiomeType.Value.SWAMP:      Color(0.25, 0.40, 0.20),
	BiomeType.Value.TUNDRA:     Color(0.75, 0.88, 0.95),
	BiomeType.Value.MUDFLAT:    Color(0.42, 0.28, 0.15),
	BiomeType.Value.MOSSY_CRAG: Color(0.45, 0.52, 0.35),
	BiomeType.Value.SAVANNAH:   Color(0.78, 0.65, 0.25),
	BiomeType.Value.CANYON:     Color(0.72, 0.35, 0.18),
}

const ASSET_BASE_PATH: String = "res://assets/meshes/tiles/"


## Initialise the library — call once from VoxelRenderer._ready().
func initialise() -> void:
	for biome in _BIOME_NAMES.keys():
		_cache[biome] = _load_variants(biome, false)
		_cache_lod[biome] = _load_variants(biome, true)


## Return the mesh for (biome, pre-computed canonical 0–12).
## Never returns null — falls back to the isolated fallback mesh if needed.
func get_mesh(biome: int, canonical: int, lod: bool) -> Mesh:
	if not _cache.has(biome):
		push_error("TileMeshLibrary: unknown biome %d" % biome)
		return _make_fallback_box(biome)
	var arr: Array = _cache_lod[biome] if lod else _cache[biome]
	var mesh: Mesh = arr[canonical & 0xF]  # clamp to 0–12 range (0xF = 15)
	if mesh == null:
		mesh = arr[0]  # fallback to isolated
	return mesh


## Return the decoration data for a biome pair, or null if none registered.
func get_transition_mesh(biome_a: int, biome_b: int) -> Resource:
	var key: String = _pair_key(biome_a, biome_b)
	return _transitions.get(key, null)


## Register a transition decoration resource for a biome pair.
func register_transition(biome_a: int, biome_b: int, data: Resource) -> void:
	_transitions[_pair_key(biome_a, biome_b)] = data


## Load the 13 canonical mesh variants for a biome from res://assets/meshes/tiles/.
## Missing assets are filled with a generated BoxMesh fallback.
func _load_variants(biome: int, lod: bool) -> Array:
	var variants: Array = []
	variants.resize(13)
	var biome_name: String = _BIOME_NAMES.get(biome, "unknown")
	var suffix: String = "_lod" if lod else ""

	for canonical in range(13):
		var path: String = ASSET_BASE_PATH + "%s_%02d%s.tres" % [biome_name, canonical, suffix]
		if ResourceLoader.exists(path):
			variants[canonical] = load(path)
		else:
			# Fallback: plain coloured BoxMesh — replaced when art assets arrive
			variants[canonical] = _make_fallback_box(biome)

	return variants


## Generate a simple coloured BoxMesh as a development fallback.
## BoxMesh always has exactly one surface (surface index 0), so `surface_set_material(0, mat)` is safe.
func _make_fallback_box(biome: int) -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.4, 0.9)  # slightly smaller than 1×1 tile footprint
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _BIOME_COLORS.get(biome, Color(0.5, 0.5, 0.5))
	mesh.surface_set_material(0, mat)
	return mesh


static func _pair_key(a: int, b: int) -> String:
	if a <= b:
		return "%d_%d" % [a, b]
	return "%d_%d" % [b, a]
