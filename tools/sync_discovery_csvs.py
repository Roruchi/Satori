#!/usr/bin/env python3
"""Export and sync Satori discovery-editor CSV files.

The CSV files are intentionally small editor surfaces. Existing pattern resources
and catalog metadata carry the edge-case details that do not fit those columns.
"""

from __future__ import annotations

import argparse
import csv
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "data" / "discovery_editor"

RITUAL_CSV = CSV_DIR / "rituals.csv.txt"
SPIRIT_CSV = CSV_DIR / "spirit_discoveries.csv.txt"
BIOME_CSV = CSV_DIR / "biome_discoveries.csv.txt"
TILE_CSV = CSV_DIR / "tiles.csv.txt"
MATERIAL_CSV = CSV_DIR / "materials.csv.txt"

RITUAL_FIELDS = [
    "Friendly Name",
    "Type",
    "Ritual ID",
    "Result Kind",
    "Result ID",
    "Discovery ID",
    "Component1",
    "Component2",
    "Component3",
    "Codex Hint 1",
    "Codex Hint 2",
    "Unlock text",
    "Assets Folder",
    "Placement Rules",
]
SPIRIT_FIELDS = [
    "Friendly Name",
    "Min Satori Required",
    "Preferred Biome",
    "Codex Hint 1",
    "Codex Hint 2",
]
BIOME_FIELDS = [
    "Friendly Name",
    "Tier",
    "Required Biome",
    "Codex Hint 1",
    "Codex Hint 2",
    "Unlock text",
    "Assets Folder",
]
TILE_FIELDS = [
    "Tile Name",
    "Biome ID",
    "Seed Name",
    "Seed Recipe ID",
    "Tier",
    "Required Elements",
    "Unlock Requirement",
    "Material Output",
    "Codex Hint",
    "Unlock text",
]
MATERIAL_FIELDS = [
    "Name",
    "Material ID",
    "Icon",
    "Asset",
    "Visual ID",
    "Spawned In Biome",
]

ELEMENT_NAME_TO_ID = {
    "Chi": 0,
    "Sui": 1,
    "Ka": 2,
    "Fu": 3,
    "Fū": 3,
    "Ku": 4,
    "Kū": 4,
}
ELEMENT_ID_TO_NAME = {
    0: "Chi",
    1: "Sui",
    2: "Ka",
    3: "Fū",
    4: "Kū",
}
BIOME_ID_TO_NAME = {
    0: "Stone",
    1: "River",
    2: "Ember Field",
    3: "Meadow",
    4: "Wetlands",
    5: "Badlands",
    6: "Whistling Canyons",
    7: "Prismatic Terraces",
    8: "Frostlands",
    9: "The Ashfall",
    10: "Sacred Stone",
    11: "Moonlit Pool",
    12: "Ember Shrine",
    13: "Cloud Ridge",
    14: "Kū",
}
BIOME_NAME_TO_ID = {name.lower(): biome_id for biome_id, name in BIOME_ID_TO_NAME.items()}
BIOME_NAME_TO_ID["ku"] = 14
BIOME_NAME_TO_ID["fu"] = 3
BIOME_NAME_TO_ID["fū"] = 3

ERA_TO_MIN_SATORI = {
    "stillness": 0,
    "awakening": 500,
    "flow": 1500,
    "satori": 5000,
}

SEED_PRODUCES_BY_KEY = {
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 14,
    "0_1": 4,
    "0_2": 5,
    "0_3": 6,
    "1_2": 7,
    "1_3": 8,
    "2_3": 9,
    "0_4": 10,
    "1_4": 11,
    "2_4": 12,
    "3_4": 13,
}

MATERIAL_CATALOG = [
    {
        "Name": "Living Wood",
        "Material ID": "living_wood",
        "Icon": "assets/materials/material_icon_spritesheet.png",
        "Asset": "assets/materials/material_icon_spritesheet.png",
        "Visual ID": "living_wood_tree",
        "Spawned In Biome": "Meadow; Cloud Ridge",
    },
    {
        "Name": "Reed Fiber",
        "Material ID": "reed_fiber",
        "Icon": "assets/materials/material_icon_spritesheet.png",
        "Asset": "assets/materials/material_icon_spritesheet.png",
        "Visual ID": "water_fish_reeds",
        "Spawned In Biome": "River; Wetlands; Moonlit Pool; Prismatic Terraces; Frostlands",
    },
    {
        "Name": "Spirit Stone",
        "Material ID": "spirit_stone",
        "Icon": "assets/materials/material_icon_spritesheet.png",
        "Asset": "assets/materials/material_icon_spritesheet.png",
        "Visual ID": "spirit_stone_minerals",
        "Spawned In Biome": "Stone; Sacred Stone; Badlands; Whistling Canyons",
    },
    {
        "Name": "Ember Clay",
        "Material ID": "ember_clay",
        "Icon": "assets/materials/material_icon_spritesheet.png",
        "Asset": "assets/materials/material_icon_spritesheet.png",
        "Visual ID": "ember_clay_shards",
        "Spawned In Biome": "Ember Field; Ember Shrine; The Ashfall",
    },
]


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def _write_csv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def _read_csv(path: Path, fields: list[str]) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [field for field in fields if field not in (reader.fieldnames or [])]
        if missing:
            raise SystemExit(f"{path} is missing required columns: {', '.join(missing)}")
        return [{field: (row.get(field) or "").strip() for field in fields} for row in reader]


def _slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", normalized).strip("_").lower()
    return slug or "unnamed"


def _gd_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _parse_assignment(text: str, name: str) -> str:
    match = re.search(rf"^{re.escape(name)}\s*=\s*(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def _parse_string_assignment(text: str, name: str) -> str:
    raw = _parse_assignment(text, name)
    match = re.match(r'&?"(.*)"$', raw)
    if not match:
        return ""
    return _gd_unescape(match.group(1))


def _gd_unescape(value: str) -> str:
    value = re.sub(
        r"\\u([0-9a-fA-F]{4})",
        lambda match: chr(int(match.group(1), 16)),
        value,
    )
    return value.replace('\\"', '"').replace("\\'", "'").replace("\\\\", "\\")


def _parse_int_assignment(text: str, name: str, default: int = 0) -> int:
    raw = _parse_assignment(text, name)
    try:
        return int(raw)
    except ValueError:
        return default


def _parse_int_array(raw: str) -> list[int]:
    match = re.search(r"\(\[([^\]]*)\]\)", raw)
    if not match:
        matches = re.findall(r"\[([^\]]*)\]", raw)
        match_value = matches[-1] if matches else ""
    else:
        match_value = match.group(1)
    if match_value == "":
        return []
    values: list[int] = []
    for part in match_value.split(","):
        part = part.strip()
        if not part:
            continue
        values.append(int(part))
    return values


def _elements_key(elements: list[int]) -> str:
    return "_".join(str(value) for value in sorted(elements))


def _elements_from_row(row: dict[str, str]) -> list[int]:
    elements: list[int] = []
    for column in ("Component1", "Component2", "Component3"):
        value = row.get(column, "").strip()
        if not value:
            continue
        key = value.replace("ū", "u").replace("ū", "u")
        if value not in ELEMENT_NAME_TO_ID and key.capitalize() not in ELEMENT_NAME_TO_ID:
            raise SystemExit(f"Unknown ritual component '{value}' in {row.get('Friendly Name', '')}")
        elements.append(ELEMENT_NAME_TO_ID.get(value, ELEMENT_NAME_TO_ID[key.capitalize()]))
    return elements


def _biomes_from_field(value: str) -> list[int]:
    if not value.strip():
        return []
    result: list[int] = []
    for part in value.split(";"):
        name = part.strip()
        if not name:
            continue
        key = name.lower()
        if key not in BIOME_NAME_TO_ID:
            raise SystemExit(f"Unknown biome '{name}'")
        result.append(BIOME_NAME_TO_ID[key])
    return result


def _biome_names(values: list[int]) -> str:
    return "; ".join(BIOME_ID_TO_NAME.get(value, str(value)) for value in values)


def _extract_blocks_with_key(text: str, key: str) -> list[str]:
    blocks: list[str] = []
    index = 0
    needle = f'"{key}"'
    while True:
        key_index = text.find(needle, index)
        if key_index == -1:
            break
        start = text.rfind("{", 0, key_index)
        if start == -1:
            index = key_index + len(needle)
            continue
        depth = 0
        end = start
        while end < len(text):
            char = text[end]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    blocks.append(text[start : end + 1])
                    index = end + 1
                    break
            end += 1
        else:
            break
    return blocks


def _field_string(block: str, key: str, default: str = "") -> str:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*"((?:\\"|[^"])*)"', block)
    if not match:
        return default
    return _gd_unescape(match.group(1))


def _field_int(block: str, key: str, default: int = 0) -> int:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*(-?\d+)', block)
    return int(match.group(1)) if match else default


def _field_array_int(block: str, key: str) -> list[int]:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*\[([^\]]*)\]', block)
    if not match:
        return []
    values: list[int] = []
    for part in match.group(1).split(","):
        part = part.strip()
        if part:
            values.append(int(part))
    return values


def _replace_string_field(block: str, key: str, value: str) -> str:
    replacement = rf'\1"{_gd_escape(value)}"'
    if re.search(rf'("{re.escape(key)}"\s*:\s*)"', block):
        return re.sub(rf'("{re.escape(key)}"\s*:\s*)"((?:\\"|[^"])*)"', replacement, block, count=1)
    return block.rstrip("}") + f',\n\t\t\t"{key}": "{_gd_escape(value)}",\n\t\t}}'


def _replace_int_field(block: str, key: str, value: int) -> str:
    if re.search(rf'"{re.escape(key)}"\s*:', block):
        return re.sub(rf'("{re.escape(key)}"\s*:\s*)-?\d+', rf"\g<1>{value}", block, count=1)
    return block.rstrip("}") + f',\n\t\t\t"{key}": {value},\n\t\t}}'


def _replace_int_array_field(block: str, key: str, values: list[int]) -> str:
    value = "[" + ", ".join(str(item) for item in values) + "]"
    if re.search(rf'"{re.escape(key)}"\s*:', block):
        return re.sub(rf'("{re.escape(key)}"\s*:\s*)\[[^\]]*\]', rf"\g<1>{value}", block, count=1)
    return block.rstrip("}") + f',\n\t\t\t"{key}": {value},\n\t\t}}'


def _indent_block(block: str) -> str:
    lines = block.strip().splitlines()
    return "\n".join("\t\t" + line.lstrip() for line in lines)


def _codex_entries_by_id() -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for path in (ROOT / "src/codex/entries").glob("*.tres"):
        text = _read_text(path)
        entry_id = _parse_string_assignment(text, "entry_id")
        if not entry_id:
            continue
        result[entry_id] = {
            "path": str(path),
            "hint_text": _parse_string_assignment(text, "hint_text"),
            "full_name": _parse_string_assignment(text, "full_name"),
            "full_description": _parse_string_assignment(text, "full_description"),
            "category": str(_parse_int_assignment(text, "category")),
        }
    return result


def _write_codex_entry(entry_id: str, category: int, full_name: str, hint: str, description: str) -> None:
    path = _existing_codex_entry_path(entry_id) or ROOT / "src/codex/entries" / f"{entry_id}.tres"
    text = f'''[gd_resource type="Resource" script_class="CodexEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/codex/CodexEntry.gd" id="1"]

[resource]
script = ExtResource("1")
entry_id = &"{_gd_escape(entry_id)}"
category = {category}
hint_text = "{_gd_escape(hint)}"
full_name = "{_gd_escape(full_name)}"
full_description = "{_gd_escape(description)}"
always_hidden = false
'''
    _write_text(path, text)


def _existing_codex_entry_path(entry_id: str) -> Path | None:
    for path in (ROOT / "src/codex/entries").glob("*.tres"):
        if _parse_string_assignment(_read_text(path), "entry_id") == entry_id:
            return path
    return None


def _seed_recipes_by_id() -> dict[str, dict[str, object]]:
    result: dict[str, dict[str, object]] = {}
    for path in (ROOT / "src/seeds/recipes").glob("*.tres"):
        text = _read_text(path)
        recipe_id = _parse_string_assignment(text, "recipe_id")
        if not recipe_id:
            continue
        result[recipe_id] = {
            "path": path,
            "elements": _parse_int_array(_parse_assignment(text, "elements")),
            "tier": _parse_int_assignment(text, "tier", 1),
            "produces_biome": _parse_int_assignment(text, "produces_biome", -1),
            "spirit_unlock_id": _parse_string_assignment(text, "spirit_unlock_id"),
            "codex_hint": _parse_string_assignment(text, "codex_hint"),
        }
    return result


def _write_seed_recipe(recipe_id: str, elements: list[int], hint: str, existing: dict[str, object] | None) -> None:
    key = _elements_key(elements)
    tier = int(existing.get("tier", 1)) if existing else (1 if len(elements) == 1 else 2)
    produces_biome = int(existing.get("produces_biome", SEED_PRODUCES_BY_KEY.get(key, -1))) if existing else SEED_PRODUCES_BY_KEY.get(key, -1)
    spirit_unlock_id = str(existing.get("spirit_unlock_id", "")) if existing else ""
    path = ROOT / "src/seeds/recipes" / f"{recipe_id}.tres"
    text = f'''[gd_resource type="Resource" script_class="SeedRecipe" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/seeds/SeedRecipe.gd" id="1"]

[resource]
script = ExtResource("1")
recipe_id = &"{_gd_escape(recipe_id)}"
elements = Array[int]([{", ".join(str(value) for value in elements)}])
tier = {tier}
produces_biome = {produces_biome}
spirit_unlock_id = &"{_gd_escape(spirit_unlock_id)}"
codex_hint = "{_gd_escape(hint)}"
'''
    _write_text(path, text)


def _parse_building_registers() -> list[dict[str, object]]:
    return []


def _write_phase1_catalog(seed_entries: list[dict[str, object]]) -> None:
    keys = sorted({_elements_key(entry["elements"]) for entry in seed_entries if len(entry["elements"]) <= 2})
    key_lines = "\n".join(f'\t"{key}": true,' for key in keys)
    text = f'''class_name SeedRecipeCatalogPhase1
extends RefCounted

const _ALLOWED_KEYS: Dictionary = {{
{key_lines}
}}

func is_valid_token_count(token_count: int) -> bool:
\treturn token_count == 1 or token_count == 2

func is_allowed_key(key: String) -> bool:
\treturn _ALLOWED_KEYS.has(key)
'''
    _write_text(ROOT / "src/seeds/SeedRecipeCatalogPhase1.gd", text)


def _export_rituals(codex: dict[str, dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for recipe_id, recipe in sorted(_seed_recipes_by_id().items()):
        elements = recipe["elements"]
        components = [ELEMENT_ID_TO_NAME[int(value)] for value in elements]
        entry = codex.get(recipe_id, {})
        friendly = entry.get("full_name") or f"{_biome_names([int(recipe.get('produces_biome', -1))])} Seed"
        rows.append(
            {
                "Friendly Name": friendly,
                "Type": "Seed",
                "Ritual ID": "ritual_%s" % recipe_id.replace("recipe_", ""),
                "Result Kind": "seed",
                "Result ID": recipe_id,
                "Discovery ID": recipe_id,
                "Component1": components[0] if len(components) > 0 else "",
                "Component2": components[1] if len(components) > 1 else "",
                "Component3": components[2] if len(components) > 2 else "",
                "Codex Hint 1": str(recipe.get("codex_hint", "")),
                "Codex Hint 2": entry.get("hint_text", ""),
                "Unlock text": entry.get("full_description", ""),
                "Assets Folder": "",
                "Placement Rules": "",
            }
        )
    rows.append(
        {
            "Friendly Name": "Warm Hollow",
            "Type": "Structure",
            "Ritual ID": "ritual_warm_hollow",
            "Result Kind": "form",
            "Result ID": "form_warm_hollow",
            "Discovery ID": "disc_warm_hollow",
            "Component1": "Living Wood",
            "Component2": "Fire Essence",
            "Component3": "",
            "Codex Hint 1": "Living wood remembers the shape of shelter when warmed by fire.",
            "Codex Hint 2": "Harvest Living Wood from Meadow or Cloud Ridge, then shape it with Fire Essence.",
            "Unlock text": "Shapes a Warm Hollow form that becomes a dwelling when placed in the right biome.",
            "Assets Folder": "assets/structures/house",
            "Placement Rules": "Meadow=building_meadow_dwelling; Ember Field=building_scorched_hollow; Ember Shrine=building_scorched_hollow",
        }
    )
    return rows


def _sync_rituals(rows: list[dict[str, str]], codex: dict[str, dict[str, str]]) -> None:
    existing_seeds = _seed_recipes_by_id()
    seed_by_name = {codex.get(recipe_id, {}).get("full_name", ""): recipe_id for recipe_id in existing_seeds}
    seed_by_key = {_elements_key(seed["elements"]): recipe_id for recipe_id, seed in existing_seeds.items()}
    seed_entries: list[dict[str, object]] = []

    for row in rows:
        friendly = row["Friendly Name"]
        if row["Type"].lower() == "seed":
            elements = _elements_from_row(row)
            element_key = _elements_key(elements)
            recipe_id = seed_by_name.get(friendly) or seed_by_key.get(element_key) or f"recipe_{element_key}"
            existing = existing_seeds.get(recipe_id)
            _write_seed_recipe(recipe_id, elements, row["Codex Hint 1"], existing)
            _write_codex_entry(
                recipe_id,
                0,
                friendly,
                row["Codex Hint 2"] or row["Codex Hint 1"],
                row["Unlock text"] or row["Codex Hint 2"],
            )
            seed_entries.append({"recipe_id": recipe_id, "elements": elements})
        elif row["Type"].lower() == "structure":
            _validate_form_ritual_row(row)
        else:
            raise SystemExit(f"Unknown ritual type '{row['Type']}' for {friendly}")

    _write_phase1_catalog(seed_entries)


def _validate_form_ritual_row(row: dict[str, str]) -> None:
    for required in ("Ritual ID", "Result Kind", "Result ID", "Discovery ID"):
        if not row.get(required, "").strip():
            raise SystemExit(f"Structure ritual '{row['Friendly Name']}' is missing {required}")
    if row["Result Kind"] != "form":
        raise SystemExit(f"Structure ritual '{row['Friendly Name']}' must use Result Kind=form")


def _spirit_blocks_by_name() -> dict[str, str]:
    text = _read_text(ROOT / "src/spirits/spirit_catalog_data.gd")
    blocks = _extract_blocks_with_key(text, "spirit_id")
    return {_field_string(block, "display_name"): block for block in blocks}


def _spirit_blocks_by_id() -> dict[str, str]:
    text = _read_text(ROOT / "src/spirits/spirit_catalog_data.gd")
    blocks = _extract_blocks_with_key(text, "spirit_id")
    return {_field_string(block, "spirit_id"): block for block in blocks}


def _export_spirits(codex: dict[str, dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for spirit_id, block in sorted(_spirit_blocks_by_id().items()):
        display_name = _field_string(block, "display_name")
        codex_entry = codex.get(spirit_id, {})
        era = _field_string(block, "min_era", "stillness")
        rows.append(
            {
                "Friendly Name": display_name,
                "Min Satori Required": str(ERA_TO_MIN_SATORI.get(era, 0)),
                "Preferred Biome": _biome_names(_field_array_int(block, "preferred_biomes")),
                "Codex Hint 1": codex_entry.get("hint_text") or _field_string(block, "riddle_text"),
                "Codex Hint 2": codex_entry.get("full_description", ""),
            }
        )
    return rows


def _era_from_min_satori(value: str) -> str:
    try:
        amount = int(value)
    except ValueError:
        amount = 0
    if amount >= 5000:
        return "satori"
    if amount >= 1500:
        return "flow"
    if amount >= 500:
        return "awakening"
    return "stillness"


def _tier_from_era(era: str) -> int:
    return {"stillness": 1, "awakening": 2, "flow": 3, "satori": 4}.get(era, 1)


def _new_spirit_block(spirit_id: str, row: dict[str, str], biomes: list[int], era: str) -> str:
    return f'''{{
\t\t\t"spirit_id": "{_gd_escape(spirit_id)}",
\t\t\t"display_name": "{_gd_escape(row["Friendly Name"])}",
\t\t\t"riddle_text": "{_gd_escape(row["Codex Hint 1"])}",
\t\t\t"pattern_id": "{_gd_escape(spirit_id)}",
\t\t\t"wander_radius": 4,
\t\t\t"wander_speed": 2.0,
\t\t\t"preferred_biomes": [{", ".join(str(value) for value in biomes)}],
\t\t\t"disliked_biomes": [],
\t\t\t"harmony_partner_id": "",
\t\t\t"tension_partner_id": "",
\t\t\t"gift_type": 0,
\t\t\t"gift_payload": "",
\t\t\t"color_hint": Color(1.0, 1.0, 1.0),
\t\t\t"tier": {_tier_from_era(era)},
\t\t\t"min_era": "{era}",
\t\t}}'''


def _sync_spirits(rows: list[dict[str, str]], codex: dict[str, dict[str, str]]) -> None:
    existing_by_name = _spirit_blocks_by_name()
    output_blocks: list[str] = []
    for row in rows:
        friendly = row["Friendly Name"]
        biomes = _biomes_from_field(row["Preferred Biome"])
        era = _era_from_min_satori(row["Min Satori Required"])
        block = existing_by_name.get(friendly)
        spirit_id = _field_string(block, "spirit_id") if block else f"spirit_{_slugify(friendly)}"
        if block:
            block = _replace_string_field(block, "display_name", friendly)
            block = _replace_string_field(block, "riddle_text", row["Codex Hint 1"])
            block = _replace_string_field(block, "min_era", era)
            block = _replace_int_field(block, "tier", _tier_from_era(era))
            block = _replace_int_array_field(block, "preferred_biomes", biomes)
        else:
            block = _new_spirit_block(spirit_id, row, biomes, era)
        output_blocks.append(block)
        if row["Codex Hint 2"]:
            _write_codex_entry(spirit_id, 2, friendly, row["Codex Hint 1"], row["Codex Hint 2"])

    body = ",\n".join(_indent_block(block) for block in output_blocks)
    text = f'''class_name SpiritCatalogData
extends RefCounted

func get_entries() -> Array[Dictionary]:
\treturn [
{body}
\t]
'''
    _write_text(ROOT / "src/spirits/spirit_catalog_data.gd", text)


def _discovery_blocks_by_name() -> dict[str, str]:
    text = _read_text(ROOT / "src/biomes/discovery_catalog_data.gd")
    blocks = _extract_blocks_with_key(text, "discovery_id")
    return {_field_string(block, "display_name"): block for block in blocks}


def _discovery_blocks_by_id() -> dict[str, str]:
    text = _read_text(ROOT / "src/biomes/discovery_catalog_data.gd")
    blocks = _extract_blocks_with_key(text, "discovery_id")
    return {_field_string(block, "discovery_id"): block for block in blocks}


def _pattern_resource_for_id(discovery_id: str) -> Path | None:
    for path in (ROOT / "src/biomes/patterns").rglob("*.tres"):
        if f'discovery_id = "{discovery_id}"' in _read_text(path):
            return path
    return None


def _pattern_required_biomes(discovery_id: str) -> list[int]:
    path = _pattern_resource_for_id(discovery_id)
    if path == None:
        return []
    return _parse_int_array(_parse_assignment(_read_text(path), "required_biomes"))


def _export_biomes() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for discovery_id, block in sorted(_discovery_blocks_by_id().items()):
        tier = _field_int(block, "tier", 1)
        name = _field_string(block, "display_name")
        asset_slug = discovery_id.removeprefix("disc_")
        asset_path = ROOT / "assets/structures" / asset_slug
        flavor = _field_string(block, "flavor_text")
        rows.append(
            {
                "Friendly Name": name,
                "Tier": str(tier),
                "Required Biome": _biome_names(_pattern_required_biomes(discovery_id)),
                "Codex Hint 1": flavor,
                "Codex Hint 2": "",
                "Unlock text": flavor,
                "Assets Folder": f"assets/structures/{asset_slug}" if asset_path.exists() else "",
            }
        )
    return rows


def _material_outputs_by_biome() -> dict[int, list[str]]:
    result: dict[int, list[str]] = {}
    for material in MATERIAL_CATALOG:
        for biome in _biomes_from_field(material["Spawned In Biome"]):
            result.setdefault(biome, []).append(material["Name"])
    return result


def _tile_unlock_requirement(recipe: dict[str, object]) -> str:
    elements = [int(value) for value in recipe["elements"]]
    element_names = [ELEMENT_ID_TO_NAME[value] for value in elements]
    spirit_unlock_id = str(recipe.get("spirit_unlock_id", ""))
    if spirit_unlock_id:
        return "Requires spirit gift: %s." % spirit_unlock_id
    if 4 in elements:
        return "Requires Kū unlocked by Mist Stag."
    if len(elements) == 1:
        return "Available when %s essence is unlocked." % element_names[0]
    return "Requires %s essences." % " + ".join(element_names)


def _export_tiles(codex: dict[str, dict[str, str]]) -> list[dict[str, str]]:
    material_outputs = _material_outputs_by_biome()
    rows: list[dict[str, str]] = []
    for recipe_id, recipe in sorted(
        _seed_recipes_by_id().items(),
        key=lambda item: (int(item[1].get("produces_biome", -1)), item[0]),
    ):
        biome_id = int(recipe.get("produces_biome", -1))
        entry = codex.get(recipe_id, {})
        elements = [int(value) for value in recipe["elements"]]
        rows.append(
            {
                "Tile Name": _biome_names([biome_id]),
                "Biome ID": str(biome_id),
                "Seed Name": entry.get("full_name") or "%s Seed" % _biome_names([biome_id]),
                "Seed Recipe ID": recipe_id,
                "Tier": str(recipe.get("tier", "")),
                "Required Elements": " + ".join(ELEMENT_ID_TO_NAME[value] for value in elements),
                "Unlock Requirement": _tile_unlock_requirement(recipe),
                "Material Output": "; ".join(material_outputs.get(biome_id, [])),
                "Codex Hint": str(recipe.get("codex_hint", "")) or entry.get("hint_text", ""),
                "Unlock text": entry.get("full_description", ""),
            }
        )
    return rows


def _export_materials() -> list[dict[str, str]]:
    return [entry.copy() for entry in MATERIAL_CATALOG]


def _validate_tiles(rows: list[dict[str, str]]) -> None:
    recipe_ids = set(_seed_recipes_by_id().keys())
    seen_biomes: set[int] = set()
    for row in rows:
        if not row["Tile Name"]:
            raise SystemExit("tiles.csv.txt contains a row without Tile Name")
        recipe_id = row["Seed Recipe ID"]
        if recipe_id not in recipe_ids:
            raise SystemExit(f"tiles.csv.txt references unknown Seed Recipe ID: {recipe_id}")
        try:
            biome_id = int(row["Biome ID"])
        except ValueError:
            raise SystemExit(f"tiles.csv.txt has invalid Biome ID for {row['Tile Name']}")
        if biome_id not in BIOME_ID_TO_NAME:
            raise SystemExit(f"tiles.csv.txt has unknown Biome ID {biome_id} for {row['Tile Name']}")
        seen_biomes.add(biome_id)
    missing = sorted(set(BIOME_ID_TO_NAME.keys()) - seen_biomes)
    if missing:
        raise SystemExit("tiles.csv.txt is missing biome IDs: %s" % ", ".join(str(value) for value in missing))


def _validate_materials(rows: list[dict[str, str]]) -> None:
    for row in rows:
        if not row["Name"]:
            raise SystemExit("materials.csv.txt contains a row without Name")
        if not row["Material ID"]:
            raise SystemExit("materials.csv.txt contains a row without Material ID")
        _biomes_from_field(row["Spawned In Biome"])


def _new_discovery_block(discovery_id: str, row: dict[str, str]) -> str:
    tier = int(row["Tier"] or "1")
    cap = {1: 50, 2: 250, 3: 1000}.get(tier, 50)
    unique = "true" if tier >= 3 else "false"
    return f'''{{
\t\t\t"discovery_id": "{_gd_escape(discovery_id)}",
\t\t\t"display_name": "{_gd_escape(row["Friendly Name"])}",
\t\t\t"flavor_text": "{_gd_escape(row["Codex Hint 1"])}",
\t\t\t"audio_key": "stinger_{_slugify(row["Friendly Name"])}",
\t\t\t"tier": {tier},
\t\t\t"cap_increase": {cap},
\t\t\t"is_unique": {unique},
\t\t\t"effect_type": "dwelling",
\t\t\t"housing_capacity": 1
\t\t}}'''


def _sync_biomes(rows: list[dict[str, str]]) -> None:
    existing_by_name = _discovery_blocks_by_name()
    blocks_by_tier: dict[int, list[str]] = {1: [], 2: [], 3: []}
    for row in rows:
        friendly = row["Friendly Name"]
        block = existing_by_name.get(friendly)
        discovery_id = _field_string(block, "discovery_id") if block else f"disc_{_slugify(friendly)}"
        tier = int(row["Tier"] or "1")
        if block:
            block = _replace_string_field(block, "display_name", friendly)
            block = _replace_string_field(block, "flavor_text", row["Codex Hint 1"])
            block = _replace_int_field(block, "tier", tier)
        else:
            block = _new_discovery_block(discovery_id, row)
        blocks_by_tier.setdefault(tier, []).append(block)
        _ensure_default_pattern(discovery_id, tier, _biomes_from_field(row["Required Biome"]))

    def func(name: str, blocks: list[str]) -> str:
        body = ",\n".join(_indent_block(block) for block in blocks)
        return f'''func {name}() -> Array[Dictionary]:
\treturn [
{body}
\t]
'''

    text = "class_name DiscoveryCatalogData\nextends RefCounted\n\n"
    text += func("get_tier1_entries", blocks_by_tier.get(1, [])) + "\n"
    text += func("get_tier2_entries", blocks_by_tier.get(2, [])) + "\n"
    text += func("get_tier3_entries", blocks_by_tier.get(3, []))
    _write_text(ROOT / "src/biomes/discovery_catalog_data.gd", text)


def _ensure_default_pattern(discovery_id: str, tier: int, biomes: list[int]) -> None:
    if _pattern_resource_for_id(discovery_id) != None or not biomes:
        return
    folder = "tier1" if tier == 1 else ("tier2" if tier == 2 else "tier3")
    path = ROOT / "src/biomes/patterns" / folder / f"{discovery_id.removeprefix('disc_')}.tres"
    cap = {1: 50, 2: 250, 3: 1000}.get(tier, 50)
    text = f'''[gd_resource type="Resource" script_class="PatternDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/biomes/pattern_definition.gd" id="1_{_slugify(discovery_id)}"]

[resource]
script = ExtResource("1_{_slugify(discovery_id)}")
discovery_id = "{_gd_escape(discovery_id)}"
pattern_type = 0
required_biomes = Array[int]([{", ".join(str(value) for value in biomes)}])
forbidden_biomes = Array[int]([])
size_threshold = 10
shape_recipe = Array[Dictionary]([])
neighbour_requirements = {{}}
prerequisite_ids = Array[String]([])
tier = {tier}
cap_increase = {cap}
is_unique = {"true" if tier >= 3 else "false"}
housing_capacity = {1 if tier == 1 else 0}
effect_type = "dwelling"
effect_params = {{}}
'''
    _write_text(path, text)


def export_current() -> None:
    codex = _codex_entries_by_id()
    _write_csv(RITUAL_CSV, RITUAL_FIELDS, _export_rituals(codex))
    _write_csv(SPIRIT_CSV, SPIRIT_FIELDS, _export_spirits(codex))
    _write_csv(BIOME_CSV, BIOME_FIELDS, _export_biomes())
    _write_csv(TILE_CSV, TILE_FIELDS, _export_tiles(codex))
    _write_csv(MATERIAL_CSV, MATERIAL_FIELDS, _export_materials())


def sync_from_csv() -> None:
    codex = _codex_entries_by_id()
    _sync_rituals(_read_csv(RITUAL_CSV, RITUAL_FIELDS), codex)
    _sync_spirits(_read_csv(SPIRIT_CSV, SPIRIT_FIELDS), codex)
    _sync_biomes(_read_csv(BIOME_CSV, BIOME_FIELDS))
    _validate_tiles(_read_csv(TILE_CSV, TILE_FIELDS))
    _validate_materials(_read_csv(MATERIAL_CSV, MATERIAL_FIELDS))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export-current", action="store_true", help="write CSV files from the current game catalogs")
    parser.add_argument("--sync", action="store_true", help="write game catalogs/resources from the CSV files")
    args = parser.parse_args()

    if not args.export_current and not args.sync:
        parser.error("choose --export-current and/or --sync")
    if args.export_current:
        export_current()
    if args.sync:
        sync_from_csv()


if __name__ == "__main__":
    main()
