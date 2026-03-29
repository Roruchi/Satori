#!/usr/bin/env python3
"""
Spirit Asset Setup Utility
===========================
Slices a sprite sheet into individual frame PNGs and generates a Godot 4
SpriteFrames .tres resource, wired to the given spirit ID.

Usage
-----
    python tools/spirit_asset_setup.py \\
        --image path/to/sheet.png \\
        --spirit-id spirit_red_fox \\
        [--frame-width W] [--frame-height H] \\
        [--cols N] [--rows N] \\
        [--animations "idle:0:4:8,walk:4:4:8"] \\
        [--fps 8] \\
        [--loop] [--no-loop] \\
        [--dry-run]

Animation config format
-----------------------
  "name:start_frame:frame_count:fps"
  Multiple animations separated by commas, e.g.:
      "idle:0:4:8,walk:4:6:12,appear:10:3:6"

  If --animations is omitted the entire sheet becomes a single "idle" animation.

Output
------
  assets/spirits/<spirit_id>/frames/frame_0000.png  (and so on)
  assets/spirits/<spirit_id>/sprite_frames.tres
  assets/spirits/<spirit_id>/README.md              (integration notes)

Requirements
------------
  pip install Pillow
"""

from __future__ import annotations

import argparse
import os
import random
import re
import string
import sys
from pathlib import Path
from typing import NamedTuple

# ---------------------------------------------------------------------------
# PIL import guard
# ---------------------------------------------------------------------------
try:
    from PIL import Image
except ImportError:
    sys.exit(
        "ERROR: Pillow is required.\n"
        "Install it with:  pip install Pillow\n"
    )


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

class AnimSpec(NamedTuple):
    name: str
    start_frame: int
    frame_count: int
    fps: float
    loop: bool


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_project_root(start: Path) -> Path:
    """Walk upward from *start* until project.godot is found."""
    current = start.resolve()
    for _ in range(10):
        if (current / "project.godot").exists():
            return current
        current = current.parent
    raise FileNotFoundError(
        "Could not locate project.godot — run this script from within the "
        "Satori project directory, or pass --project-root explicitly."
    )


def _godot_uid(seed: str) -> str:
    """Generate a deterministic Godot-style UID string from a seed."""
    rng = random.Random(seed)
    chars = string.ascii_lowercase + string.digits
    # Godot UIDs are ~12 base-62 chars after uid://
    return "uid://" + "".join(rng.choice(chars) for _ in range(12))


def _res_path(project_root: Path, abs_path: Path) -> str:
    """Convert an absolute filesystem path to a Godot res:// path."""
    rel = abs_path.relative_to(project_root)
    return "res://" + rel.as_posix()


def _parse_animations(raw: str, total_frames: int, default_fps: float, default_loop: bool) -> list[AnimSpec]:
    """Parse the --animations string into a list of AnimSpec objects."""
    specs: list[AnimSpec] = []
    for token in raw.split(","):
        token = token.strip()
        if not token:
            continue
        parts = token.split(":")
        if len(parts) < 3:
            sys.exit(
                f"ERROR: Invalid animation spec '{token}'.\n"
                "Expected format: name:start_frame:frame_count[:fps]"
            )
        name = parts[0].strip()
        start = int(parts[1])
        count = int(parts[2])
        fps = float(parts[3]) if len(parts) > 3 else default_fps
        loop = bool(parts[4].lower() in ("1", "true", "yes")) if len(parts) > 4 else default_loop
        if start < 0 or start + count > total_frames:
            sys.exit(
                f"ERROR: Animation '{name}' references frames {start}–{start+count-1} "
                f"but the sheet only has {total_frames} frames (0–{total_frames-1})."
            )
        specs.append(AnimSpec(name=name, start_frame=start, frame_count=count, fps=fps, loop=loop))
    return specs


# ---------------------------------------------------------------------------
# Core operations
# ---------------------------------------------------------------------------

def slice_sheet(
    image_path: Path,
    frame_w: int,
    frame_h: int,
    cols: int,
    rows: int,
    out_dir: Path,
    dry_run: bool,
) -> list[Path]:
    """Slice the sprite sheet and write individual frame PNGs.

    Returns a list of output paths (in order, row-major).
    """
    img = Image.open(image_path)
    sheet_w, sheet_h = img.size

    if frame_w <= 0 or frame_h <= 0:
        sys.exit(f"ERROR: frame dimensions must be positive, got {frame_w}×{frame_h}.")

    actual_cols = sheet_w // frame_w
    actual_rows = sheet_h // frame_h

    if cols and cols != actual_cols:
        print(
            f"WARNING: --cols {cols} doesn't match sheet width {sheet_w} ÷ {frame_w} = {actual_cols}. "
            f"Using {actual_cols}."
        )
    if rows and rows != actual_rows:
        print(
            f"WARNING: --rows {rows} doesn't match sheet height {sheet_h} ÷ {frame_h} = {actual_rows}. "
            f"Using {actual_rows}."
        )

    actual_cols = sheet_w // frame_w
    actual_rows = sheet_h // frame_h
    total = actual_cols * actual_rows

    print(f"  Sheet size : {sheet_w}×{sheet_h} px")
    print(f"  Frame size : {frame_w}×{frame_h} px")
    print(f"  Grid       : {actual_cols} cols × {actual_rows} rows = {total} frames")

    frame_paths: list[Path] = []
    frame_idx = 0
    for row in range(actual_rows):
        for col in range(actual_cols):
            left = col * frame_w
            upper = row * frame_h
            right = left + frame_w
            lower = upper + frame_h
            frame = img.crop((left, upper, right, lower))
            out_path = out_dir / f"frame_{frame_idx:04d}.png"
            frame_paths.append(out_path)
            if not dry_run:
                frame.save(out_path, "PNG")
            frame_idx += 1

    if not dry_run:
        print(f"  Saved {total} frames to {out_dir}")
    else:
        print(f"  [dry-run] Would save {total} frames to {out_dir}")

    return frame_paths


def build_sprite_frames_tres(
    spirit_id: str,
    frame_paths: list[Path],
    animations: list[AnimSpec],
    project_root: Path,
    dry_run: bool,
    out_path: Path,
) -> None:
    """Write a Godot 4 SpriteFrames .tres file."""

    # --- ext_resource block -------------------------------------------------
    # Each unique frame gets an ext_resource entry with a stable id.
    # Use a short deterministic id: 1, 2, 3 ...
    ext_lines: list[str] = []
    resource_id_map: dict[int, str] = {}  # frame_index -> resource id string

    for idx, fp in enumerate(frame_paths):
        res_id = str(idx + 1)
        uid = _godot_uid(f"{spirit_id}:{fp.name}")
        res_path = _res_path(project_root, fp)
        ext_lines.append(
            f'[ext_resource type="Texture2D" uid="{uid}" '
            f'path="{res_path}" id="{res_id}"]'
        )
        resource_id_map[idx] = res_id

    # --- animation blocks ---------------------------------------------------
    anim_dicts: list[str] = []
    for anim in animations:
        frames_list: list[str] = []
        for fi in range(anim.start_frame, anim.start_frame + anim.frame_count):
            rid = resource_id_map[fi]
            frames_list.append(
                '{\n"duration": 1.0,\n'
                f'"texture": ExtResource("{rid}")\n}}'
            )
        frames_joined = ", ".join(frames_list)
        loop_str = "true" if anim.loop else "false"
        anim_dicts.append(
            "{\n"
            f'"frames": [{frames_joined}],\n'
            f'"loop": {loop_str},\n'
            f'"name": &"{anim.name}",\n'
            f'"speed": {anim.fps}\n'
            "}"
        )

    animations_value = "[" + ", ".join(anim_dicts) + "]"

    load_steps = len(frame_paths) + 1  # frames + the resource itself
    resource_uid = _godot_uid(f"{spirit_id}:sprite_frames")

    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3 uid="{resource_uid}"]',
        "",
        *ext_lines,
        "",
        "[resource]",
        f"animations = {animations_value}",
        "",
    ]

    content = "\n".join(lines)

    if not dry_run:
        out_path.write_text(content, encoding="utf-8")
        print(f"  Wrote SpriteFrames -> {out_path}")
    else:
        print(f"  [dry-run] Would write SpriteFrames -> {out_path}")
        print()
        print("  --- preview (first 40 lines) ---")
        for line in content.splitlines()[:40]:
            print("  " + line)
        print("  ...")


def write_readme(
    spirit_id: str,
    animations: list[AnimSpec],
    out_dir: Path,
    dry_run: bool,
) -> None:
    """Write a short integration README alongside the assets."""
    anim_list = "\n".join(
        f"  - `{a.name}` — frames {a.start_frame}–{a.start_frame + a.frame_count - 1}, "
        f"{a.fps} fps, loop={a.loop}"
        for a in animations
    )
    content = f"""\
# Spirit Assets — `{spirit_id}`

Generated by `tools/spirit_asset_setup.py`.

## Animations

{anim_list}

## Integration

To use sprite-based rendering instead of the procedural draw in `SpiritWanderer`:

1. Add an `AnimatedSprite2D` node as a child of `SpiritWanderer`.
2. Assign `res://assets/spirits/{spirit_id}/sprite_frames.tres` to its
   `SpriteFrames` property.
3. In `SpiritWanderer.setup()`, call `$AnimatedSprite2D.play("idle")`.
4. Optionally suppress the procedural `_draw()` by clearing `_display_color`
   to `Color.TRANSPARENT` or adding a guard flag.

## Re-generating

Re-run the setup script (will overwrite existing files):

```
python tools/spirit_asset_setup.py \\
    --image <sheet>.png \\
    --spirit-id {spirit_id} \\
    --frame-width W --frame-height H \\
    --animations "<anim config>"
```
"""
    out_path = out_dir / "README.md"
    if not dry_run:
        out_path.write_text(content, encoding="utf-8")
        print(f"  Wrote README     -> {out_path}")
    else:
        print(f"  [dry-run] Would write README -> {out_path}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Spirit Asset Setup — slice a sprite sheet and generate Godot resources.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("--image", required=True, metavar="PATH",
                   help="Path to the source sprite sheet (PNG/WEBP/etc.)")
    p.add_argument("--spirit-id", required=True, metavar="ID",
                   help="Spirit identifier, e.g. spirit_red_fox")
    p.add_argument("--frame-width", type=int, default=0, metavar="W",
                   help="Width of a single frame in pixels (required unless --cols given)")
    p.add_argument("--frame-height", type=int, default=0, metavar="H",
                   help="Height of a single frame in pixels (required unless --rows given)")
    p.add_argument("--cols", type=int, default=0, metavar="N",
                   help="Number of columns in the sheet (alternative to --frame-width)")
    p.add_argument("--rows", type=int, default=1, metavar="N",
                   help="Number of rows in the sheet (alternative to --frame-height)")
    p.add_argument("--animations", metavar="SPEC",
                   help='Animation config: "name:start:count[:fps],..." '
                        '(default: single "idle" covering all frames)')
    p.add_argument("--fps", type=float, default=8.0, metavar="FPS",
                   help="Default animation speed in frames/sec (default: 8)")
    p.add_argument("--no-loop", dest="loop", action="store_false", default=True,
                   help="Disable looping for all animations (default: loop=true)")
    p.add_argument("--project-root", metavar="DIR",
                   help="Godot project root (default: auto-detect from project.godot)")
    p.add_argument("--dry-run", action="store_true",
                   help="Preview actions without writing any files")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    # --- resolve project root -----------------------------------------------
    if args.project_root:
        project_root = Path(args.project_root).resolve()
        if not (project_root / "project.godot").exists():
            sys.exit(f"ERROR: No project.godot found at {project_root}")
    else:
        try:
            project_root = _find_project_root(Path(__file__).parent)
        except FileNotFoundError as exc:
            sys.exit(f"ERROR: {exc}")

    print(f"\nSatori Spirit Asset Setup")
    print(f"  Project root : {project_root}")

    # --- validate spirit ID -------------------------------------------------
    if not re.fullmatch(r"spirit_[a-z][a-z0-9_]*", args.spirit_id):
        sys.exit(
            f"ERROR: spirit ID must match 'spirit_<snake_case>', got '{args.spirit_id}'."
        )

    # --- resolve image path -------------------------------------------------
    image_path = Path(args.image).resolve()
    if not image_path.exists():
        sys.exit(f"ERROR: Image not found: {image_path}")

    print(f"  Spirit ID    : {args.spirit_id}")
    print(f"  Source image : {image_path}")

    # --- resolve frame dimensions -------------------------------------------
    img_probe = Image.open(image_path)
    sheet_w, sheet_h = img_probe.size

    frame_w = args.frame_width
    frame_h = args.frame_height

    if frame_w <= 0 and args.cols > 0:
        if sheet_w % args.cols != 0:
            sys.exit(
                f"ERROR: Sheet width {sheet_w} is not evenly divisible by --cols {args.cols}."
            )
        frame_w = sheet_w // args.cols

    if frame_h <= 0 and args.rows > 0:
        if sheet_h % args.rows != 0:
            sys.exit(
                f"ERROR: Sheet height {sheet_h} is not evenly divisible by --rows {args.rows}."
            )
        frame_h = sheet_h // args.rows

    if frame_w <= 0:
        sys.exit(
            "ERROR: Could not determine frame width. "
            "Provide --frame-width W or --cols N."
        )
    if frame_h <= 0:
        sys.exit(
            "ERROR: Could not determine frame height. "
            "Provide --frame-height H or --rows N."
        )

    # --- prepare output directories -----------------------------------------
    spirit_dir = project_root / "assets" / "spirits" / args.spirit_id
    frames_dir = spirit_dir / "frames"

    if not args.dry_run:
        frames_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n[1/4] Slicing sprite sheet")
    frame_paths = slice_sheet(
        image_path=image_path,
        frame_w=frame_w,
        frame_h=frame_h,
        cols=args.cols,
        rows=args.rows,
        out_dir=frames_dir,
        dry_run=args.dry_run,
    )

    total_frames = len(frame_paths)

    # --- parse animations ---------------------------------------------------
    print(f"\n[2/4] Resolving animations")
    if args.animations:
        animations = _parse_animations(
            args.animations, total_frames, args.fps, args.loop
        )
    else:
        animations = [AnimSpec(
            name="idle",
            start_frame=0,
            frame_count=total_frames,
            fps=args.fps,
            loop=args.loop,
        )]

    for anim in animations:
        print(
            f"  {anim.name:12s}  frames {anim.start_frame}–"
            f"{anim.start_frame + anim.frame_count - 1}  "
            f"@ {anim.fps} fps  loop={anim.loop}"
        )

    # --- write SpriteFrames .tres -------------------------------------------
    print(f"\n[3/4] Generating SpriteFrames resource")
    tres_path = spirit_dir / "sprite_frames.tres"
    build_sprite_frames_tres(
        spirit_id=args.spirit_id,
        frame_paths=frame_paths,
        animations=animations,
        project_root=project_root,
        dry_run=args.dry_run,
        out_path=tres_path,
    )

    # --- write README -------------------------------------------------------
    print(f"\n[4/4] Writing integration notes")
    write_readme(
        spirit_id=args.spirit_id,
        animations=animations,
        out_dir=spirit_dir,
        dry_run=args.dry_run,
    )

    # --- summary ------------------------------------------------------------
    print()
    if args.dry_run:
        print("Dry run complete — no files were written.")
    else:
        print("Done. Next steps:")
        print(f"  1. Open Godot and let it import the new PNGs in")
        print(f"     assets/spirits/{args.spirit_id}/frames/")
        print(f"  2. Add an AnimatedSprite2D child to SpiritWanderer.")
        print(f"     Assign: res://assets/spirits/{args.spirit_id}/sprite_frames.tres")
        print(f"  3. See assets/spirits/{args.spirit_id}/README.md for wiring details.")
    print()


if __name__ == "__main__":
    main()
