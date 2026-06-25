from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterable, Tuple

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CELL_SIZE = 256
VARIANT_COUNT = 4
PIXEL_SAMPLE_SIZE = 64

OUT_ATLAS = ROOT / "assets" / "tiles" / "satori_terrain_tilesheet.png"
OUT_QA = ROOT / "assets" / "tiles" / "qa_contact_sheet.png"
SOURCE_DIR = ROOT / "assets" / "tiles" / "source" / "imagegen"

BIOMES: Tuple[Tuple[str, int], ...] = (
    ("stone", 0),
    ("river", 1),
    ("ember_field", 2),
    ("meadow", 3),
    ("wetlands", 4),
    ("badlands", 5),
    ("whistling_canyons", 6),
    ("prismatic_terraces", 7),
    ("frostlands", 8),
    ("the_ashfall", 9),
    ("sacred_stone", 10),
    ("moonlit_pool", 11),
    ("ember_shrine", 12),
    ("cloud_ridge", 13),
    ("ku", 14),
)

SOURCE_MAP: Dict[str, Tuple[str, int]] = {
    "stone": ("satori_terrain_source_stone_ember_wetlands_badlands.png", 0),
    "ember_field": ("satori_terrain_source_stone_ember_wetlands_badlands.png", 1),
    "wetlands": ("satori_terrain_source_stone_ember_wetlands_badlands.png", 2),
    "badlands": ("satori_terrain_source_stone_ember_wetlands_badlands.png", 3),
    "whistling_canyons": ("satori_terrain_source_canyons_terraces_frost_ashfall.png", 0),
    "prismatic_terraces": ("satori_terrain_source_canyons_terraces_frost_ashfall.png", 1),
    "frostlands": ("satori_terrain_source_canyons_terraces_frost_ashfall.png", 2),
    "the_ashfall": ("satori_terrain_source_canyons_terraces_frost_ashfall.png", 3),
    "sacred_stone": ("satori_terrain_source_sacred_moonlit_ember_shrine_ku.png", 0),
    "moonlit_pool": ("satori_terrain_source_sacred_moonlit_ember_shrine_ku.png", 1),
    "ember_shrine": ("satori_terrain_source_sacred_moonlit_ember_shrine_ku.png", 2),
    "ku": ("satori_terrain_source_sacred_moonlit_ember_shrine_ku.png", 3),
    "meadow": ("satori_terrain_source_meadow_river_cloud_ridge.png", 0),
    "river": ("satori_terrain_source_meadow_river_cloud_ridge.png", 1),
    "cloud_ridge": ("satori_terrain_source_meadow_river_cloud_ridge.png", 2),
}


def source_cell(source_name: str, row: int, column: int) -> Image.Image:
    source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
    cell_w = source.width // VARIANT_COUNT
    cell_h = source.height // 4
    box = (
        column * cell_w,
        row * cell_h,
        (column + 1) * cell_w,
        (row + 1) * cell_h,
    )
    return source.crop(box)


def pixelate(image: Image.Image) -> Image.Image:
    square = image.resize((CELL_SIZE, CELL_SIZE), Image.Resampling.LANCZOS)
    square = ImageEnhance.Color(square).enhance(1.12)
    square = ImageEnhance.Contrast(square).enhance(1.08)
    square = square.filter(ImageFilter.UnsharpMask(radius=1.2, percent=90, threshold=3))
    small = square.resize((PIXEL_SAMPLE_SIZE, PIXEL_SAMPLE_SIZE), Image.Resampling.BICUBIC)
    quantized = small.convert("P", palette=Image.Palette.ADAPTIVE, colors=64).convert("RGBA")
    return quantized.resize((CELL_SIZE, CELL_SIZE), Image.Resampling.NEAREST)


def hex_mask() -> Image.Image:
    margin_x = 18
    margin_y = 8
    points = [
        (CELL_SIZE / 2, margin_y),
        (CELL_SIZE - margin_x, CELL_SIZE * 0.27),
        (CELL_SIZE - margin_x, CELL_SIZE * 0.73),
        (CELL_SIZE / 2, CELL_SIZE - margin_y),
        (margin_x, CELL_SIZE * 0.73),
        (margin_x, CELL_SIZE * 0.27),
    ]
    mask = Image.new("L", (CELL_SIZE, CELL_SIZE), 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon(points, fill=255)
    return mask


def make_hex_tile(source_name: str, row: int, column: int, mask: Image.Image) -> Image.Image:
    tile = pixelate(source_cell(source_name, row, column))
    alpha = Image.new("L", (CELL_SIZE, CELL_SIZE), 0)
    alpha.paste(mask)
    tile.putalpha(alpha)
    return tile


def assemble_atlas() -> Image.Image:
    mask = hex_mask()
    atlas = Image.new("RGBA", (CELL_SIZE * VARIANT_COUNT, CELL_SIZE * len(BIOMES)), (0, 0, 0, 0))
    for atlas_row, (biome_name, _biome_id) in enumerate(BIOMES):
        source_name, source_row = SOURCE_MAP[biome_name]
        for column in range(VARIANT_COUNT):
            tile = make_hex_tile(source_name, source_row, column, mask)
            atlas.alpha_composite(tile, (column * CELL_SIZE, atlas_row * CELL_SIZE))
    return atlas


def draw_qa(atlas: Image.Image) -> Image.Image:
    label_h = 28
    qa = Image.new("RGBA", (atlas.width, atlas.height + label_h * len(BIOMES)), (18, 18, 22, 255))
    font_color = (235, 230, 210, 255)
    draw = ImageDraw.Draw(qa)
    y = 0
    for row, (biome_name, biome_id) in enumerate(BIOMES):
        draw.rectangle((0, y, qa.width, y + label_h), fill=(26, 27, 32, 255))
        draw.text((10, y + 7), f"{biome_id:02d} {biome_name}", fill=font_color)
        row_img = atlas.crop((0, row * CELL_SIZE, atlas.width, (row + 1) * CELL_SIZE))
        qa.alpha_composite(row_img, (0, y + label_h))
        y += label_h + CELL_SIZE
    return qa


def ensure_sources_exist(paths: Iterable[str]) -> None:
    missing = sorted({path for path in paths if not (SOURCE_DIR / path).exists()})
    if missing:
        raise FileNotFoundError("Missing terrain source image(s): " + ", ".join(missing))


def main() -> None:
    ensure_sources_exist(source for source, _row in SOURCE_MAP.values())
    OUT_ATLAS.parent.mkdir(parents=True, exist_ok=True)
    atlas = assemble_atlas()
    atlas.save(OUT_ATLAS)
    draw_qa(atlas).save(OUT_QA)
    print(f"Wrote {OUT_ATLAS}")
    print(f"Wrote {OUT_QA}")


if __name__ == "__main__":
    main()
