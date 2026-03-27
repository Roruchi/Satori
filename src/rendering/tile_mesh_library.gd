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
	BiomeType.Value.STONE:             "stone",
	BiomeType.Value.RIVER:             "river",
	BiomeType.Value.EMBER_FIELD:       "ember_field",
	BiomeType.Value.MEADOW:            "meadow",
	BiomeType.Value.WETLANDS:          "wetlands",
	BiomeType.Value.BADLANDS:          "badlands",
	BiomeType.Value.WHISTLING_CANYONS: "whistling_canyons",
	BiomeType.Value.PRISMATIC_TERRACES: "prismatic_terraces",
	BiomeType.Value.FROSTLANDS:        "frostlands",
	BiomeType.Value.THE_ASHFALL:       "the_ashfall",
}

## Standard biome colours for fallback box meshes (matches GardenView palette).
const _BIOME_COLORS: Dictionary = {
	BiomeType.Value.STONE:             Color(0.55, 0.56, 0.62),
	BiomeType.Value.RIVER:             Color(0.09, 0.48, 0.88),
	BiomeType.Value.EMBER_FIELD:       Color(0.86, 0.34, 0.18),
	BiomeType.Value.MEADOW:            Color(0.20, 0.58, 0.22),
	BiomeType.Value.WETLANDS:          Color(0.42, 0.56, 0.48),
	BiomeType.Value.BADLANDS:          Color(0.82, 0.69, 0.43),
	BiomeType.Value.WHISTLING_CANYONS: Color(0.90, 0.80, 0.60),
	BiomeType.Value.PRISMATIC_TERRACES: Color(0.67, 0.80, 0.93),
	BiomeType.Value.FROSTLANDS:        Color(0.83, 0.94, 1.0),
	BiomeType.Value.THE_ASHFALL:       Color(0.36, 0.20, 0.18),
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
	mesh.size = Vector3(0.92, 0.45, 0.92)  # slightly taller for chunky voxel look
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _BIOME_COLORS.get(biome, Color(0.5, 0.5, 0.5))
	mat.roughness = 0.82
	mat.metallic = 0.04
	mat.metallic_specular = 0.35
	# Subtle depth cue — slightly darken the sides via a faint shading hint
	mat.vertex_color_use_as_albedo = false
	mesh.surface_set_material(0, mat)
	return mesh


static func _pair_key(a: int, b: int) -> String:
	if a <= b:
		return "%d_%d" % [a, b]
	return "%d_%d" % [b, a]
