# Tile Mesh Assets — Feature 009

This directory contains pre-authored voxel mesh resources for each biome × canonical bitmask variant combination.

## Naming Convention

```
{biome_name}_{canonical_idx:02d}.tres
```

Examples:
- `forest_00.tres` — Forest tile, isolated (no same-biome neighbours)
- `forest_01.tres` — Forest tile, N edge only
- `stone_00.tres`  — Stone tile, isolated

## Canonical Index Range

Values 0–46 correspond to the Wang/blob autotile reduction of the 8-bit (256-value) neighbour bitmask.  
See `specs/009-voxel-rendering-merging/data-model.md` for the full index table.

## LOD Variants

Suffix `_lod` indicates a reduced-vertex LOD mesh:
- `forest_00_lod.tres` — Low-detail isolated Forest tile

If no `_lod` variant exists, `TileMeshLibrary` falls back to the full-detail mesh.

## During Development

Use simple coloured `BoxMesh` resources as stubs while artwork is pending.  
Replace with final `.tres` assets without any code changes — the library loads by name convention.

## Biome Names

| BiomeType.Value | Name |
|---|---|
| 0 | forest |
| 1 | water |
| 2 | stone |
| 3 | earth |
| 4 | swamp |
| 5 | tundra |
| 6 | mudflat |
| 7 | mossy_crag |
| 8 | savannah |
| 9 | canyon |
