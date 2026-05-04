#!/usr/bin/env python3
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KO_DIR = ROOT / "src" / "Data" / "Translations" / "ko-KR"
FILES = ["Gems.csv", "ItemBases.csv", "Tree.csv"]

class CheckError(Exception):
    pass

def read_rows(path: Path):
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        expected = ["domain", "key", "en", "ko", "aliases"]
        if reader.fieldnames != expected:
            raise CheckError(f"{path}: header mismatch: {reader.fieldnames} != {expected}")
        rows = list(reader)
    return rows

def ensure_non_empty(name: str, rows):
    if not rows:
        raise CheckError(f"{name}: no rows")

def ensure_no_duplicate_keys(name: str, rows):
    seen = {}
    for i, row in enumerate(rows, start=2):
        key = (row["domain"], row["key"])
        if key in seen:
            raise CheckError(f"{name}: duplicate domain/key at line {i} and {seen[key]}")
        seen[key] = i

def ensure_required_values(name: str, rows):
    for i, row in enumerate(rows, start=2):
        if not row["domain"] or not row["key"]:
            raise CheckError(f"{name}: blank domain/key at line {i}")
        if not row["en"]:
            raise CheckError(f"{name}: blank canonical English(en) at line {i}")

def find_translation(rows, domain, key):
    for row in rows:
        if row["domain"] == domain and row["key"] == key:
            return row
    raise CheckError(f"missing row for {domain}:{key}")

def main():
    if not KO_DIR.exists():
        raise CheckError(f"missing directory: {KO_DIR}")

    table = {}
    for fn in FILES:
        path = KO_DIR / fn
        if not path.exists():
            raise CheckError(f"missing csv: {path}")
        rows = read_rows(path)
        ensure_non_empty(fn, rows)
        ensure_no_duplicate_keys(fn, rows)
        ensure_required_values(fn, rows)
        table[fn] = rows

    # Stage 0 smoke invariants from docs/verify-localization-smoke.lua
    gem = find_translation(table["Gems.csv"], "gem", "Metadata/Items/Gems/SkillGemIceNova")
    if gem["en"] != "Ice Nova":
        raise CheckError(f"canonical gem changed: expected 'Ice Nova', got {gem['en']!r}")
    if not gem["ko"]:
        raise CheckError("missing Korean translation for Ice Nova")

    base = find_translation(table["ItemBases.csv"], "base", "Wooden Club")
    if base["en"] != "Wooden Club":
        raise CheckError(f"canonical item base changed: expected 'Wooden Club', got {base['en']!r}")
    if not base["ko"]:
        raise CheckError("missing Korean translation for Wooden Club")

    node = find_translation(table["Tree.csv"], "tree_dn", "10029")
    if node["en"] != "Repulsion":
        raise CheckError(f"canonical tree node changed: expected 'Repulsion', got {node['en']!r}")
    if not node["ko"]:
        raise CheckError("missing Korean translation for tree node 10029")

    print("Cloud localization verification passed")

if __name__ == "__main__":
    main()
