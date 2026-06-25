#!/usr/bin/env python3
"""Build static spirit SpriteFrames from 2x2 batch source atlases."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops


KEY_COLOR = (255, 0, 255)
FRAME_SIZE = 64
CONTACT_CELL = 96


@dataclass(frozen=True)
class SpiritCell:
    spirit_id: str
    display_name: str
    batch: str
    cell: str


CELL_TO_BOX = {
    "top_left": (0, 0, 0.5, 0.5),
    "top_right": (0.5, 0, 1, 0.5),
    "bottom_left": (0, 0.5, 0.5, 1),
    "bottom_right": (0.5, 0.5, 1, 1),
    "full": (0, 0, 1, 1),
}


def trim_to_subject(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bg = Image.new("RGBA", rgba.size, KEY_COLOR + (255,))
    diff = ImageChops.difference(rgba, bg).convert("L")
    alpha = diff.point(lambda p: 0 if p < 24 else 255)
    rgba.putalpha(alpha)
    bbox = alpha.getbbox()
    if bbox is None:
        return rgba
    pad = 18
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(rgba.width, bbox[2] + pad)
    bottom = min(rgba.height, bbox[3] + pad)
    return rgba.crop((left, top, right, bottom))


def normalize_frame(source: Image.Image) -> Image.Image:
    subject = trim_to_subject(source)
    subject.thumbnail((FRAME_SIZE - 8, FRAME_SIZE - 8), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - subject.width) // 2
    y = (FRAME_SIZE - subject.height) // 2
    frame.alpha_composite(subject, (x, y))
    return frame


def write_spriteframes(project_root: Path, spirit_id: str, frame_path: Path) -> None:
    rel = frame_path.relative_to(project_root).as_posix()
    out_path = project_root / "assets" / "spirits" / spirit_id / "sprite_frames.tres"
    content = "\n".join([
        '[gd_resource type="SpriteFrames" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://{rel}" id="1"]',
        "",
        "[resource]",
        'animations = [{',
        '"frames": [{',
        '"duration": 1.0,',
        '"texture": ExtResource("1")',
        "}],",
        '"loop": true,',
        '"name": &"idle_down",',
        '"speed": 1.0',
        "}]",
        "",
    ])
    out_path.write_text(content, encoding="utf-8")


def write_sprite_sheet_json(spirit_dir: Path, spirit: SpiritCell) -> None:
    data = {
        "entity_id": spirit.spirit_id,
        "frame_width": FRAME_SIZE,
        "frame_height": FRAME_SIZE,
        "directions": ["down"],
        "layout": "static-batch-source",
        "source": f"assets/spirits/source_batches/{spirit.batch}",
        "source_cell": spirit.cell,
        "animations": [
            {
                "name": "idle_down",
                "frames": 1,
                "fps": 1.0,
                "loop": True,
            }
        ],
    }
    (spirit_dir / "sprite_sheet.json").write_text(
        json.dumps(data, indent=2) + "\n",
        encoding="utf-8",
    )


def write_contact_sheet(project_root: Path, spirits: list[SpiritCell]) -> None:
    cols = 6
    rows = (len(spirits) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * CONTACT_CELL, rows * CONTACT_CELL), (32, 32, 36, 255))
    for index, spirit in enumerate(spirits):
        frame_path = project_root / "assets" / "spirits" / spirit.spirit_id / "frames" / "idle" / "down" / "frame_0000.png"
        frame = Image.open(frame_path).convert("RGBA")
        x = (index % cols) * CONTACT_CELL + (CONTACT_CELL - FRAME_SIZE) // 2
        y = (index // cols) * CONTACT_CELL + 8
        sheet.alpha_composite(frame, (x, y))
    out_dir = project_root / "assets" / "spirits" / "source_batches"
    out_dir.mkdir(parents=True, exist_ok=True)
    sheet.save(out_dir / "qa_contact_sheet.png")


def load_map(path: Path) -> list[SpiritCell]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    spirits: list[SpiritCell] = []
    for item in raw["spirits"]:
        spirits.append(SpiritCell(
            spirit_id=item["spirit_id"],
            display_name=item["display_name"],
            batch=item["batch"],
            cell=item["cell"],
        ))
    return spirits


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--map", default="assets/spirits/source_batches/spirit_sprite_batch_map.json")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    spirits = load_map(project_root / args.map)

    for spirit in spirits:
        source_path = project_root / "assets" / "spirits" / "source_batches" / spirit.batch
        source = Image.open(source_path).convert("RGBA")
        rel_box = CELL_TO_BOX[spirit.cell]
        box = (
            int(source.width * rel_box[0]),
            int(source.height * rel_box[1]),
            int(source.width * rel_box[2]),
            int(source.height * rel_box[3]),
        )
        crop = source.crop(box)
        frame = normalize_frame(crop)
        spirit_dir = project_root / "assets" / "spirits" / spirit.spirit_id
        frame_dir = spirit_dir / "frames" / "idle" / "down"
        frame_dir.mkdir(parents=True, exist_ok=True)
        frame_path = frame_dir / "frame_0000.png"
        frame.save(frame_path)
        write_spriteframes(project_root, spirit.spirit_id, frame_path)
        write_sprite_sheet_json(spirit_dir, spirit)

    write_contact_sheet(project_root, spirits)
    print(f"Built static sprites for {len(spirits)} spirits")


if __name__ == "__main__":
    main()
