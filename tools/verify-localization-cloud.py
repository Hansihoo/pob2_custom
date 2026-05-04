#!/usr/bin/env python3
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KO_DIR = ROOT / "src" / "Data" / "Translations" / "ko-KR"
FILES = ("Gems.csv", "ItemBases.csv", "Tree.csv")
EXPECTED_HEADER = ("domain", "key", "en", "ko", "aliases")


class CheckError(Exception):
    pass


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if tuple(reader.fieldnames or ()) != EXPECTED_HEADER:
            raise CheckError(f"{path}: header mismatch: {reader.fieldnames} != {list(EXPECTED_HEADER)}")
        return list(reader)


def ensure_non_empty(name: str, rows: list[dict[str, str]]) -> None:
    if not rows:
        raise CheckError(f"{name}: no rows")


def ensure_no_duplicate_keys(name: str, rows: list[dict[str, str]]) -> None:
    seen: dict[tuple[str, str], int] = {}
    for line_no, row in enumerate(rows, start=2):
        key = (row["domain"], row["key"])
        if key in seen:
            raise CheckError(f"{name}: duplicate (domain,key) at line {line_no}, first seen at line {seen[key]}")
        seen[key] = line_no


def ensure_required_values(name: str, rows: list[dict[str, str]]) -> None:
    for line_no, row in enumerate(rows, start=2):
        if not row["domain"] or not row["key"]:
            raise CheckError(f"{name}: blank domain/key at line {line_no}")
        if not row["en"]:
            raise CheckError(f"{name}: blank canonical English(en) at line {line_no}")


def find_translation(rows: list[dict[str, str]], *, domain: str, key: str) -> dict[str, str]:
    for row in rows:
        if row["domain"] == domain and row["key"] == key:
            return row
    raise CheckError(f"missing row for {domain}:{key}")


def verify_stage0_smoke(table: dict[str, list[dict[str, str]]]) -> None:
    # docs/verify-localization-smoke.lua와 같은 canonical 샘플 점검
    gem = find_translation(table["Gems.csv"], domain="gem", key="Metadata/Items/Gems/SkillGemIceNova")
    if gem["en"] != "Ice Nova":
        raise CheckError(f"canonical gem changed: expected 'Ice Nova', got {gem['en']!r}")
    if not gem["ko"]:
        raise CheckError("missing Korean translation for Ice Nova")

    base = find_translation(table["ItemBases.csv"], domain="base", key="Wooden Club")
    if base["en"] != "Wooden Club":
        raise CheckError(f"canonical item base changed: expected 'Wooden Club', got {base['en']!r}")
    if not base["ko"]:
        raise CheckError("missing Korean translation for Wooden Club")

    # Tree는 시즌별 key 변경 가능성이 있어 현재 CSV의 안정 샘플 사용
    tree = find_translation(table["Tree.csv"], domain="tree_dn", key="10029")
    if tree["en"] != "Repulsion":
        raise CheckError(f"canonical tree node changed: expected 'Repulsion', got {tree['en']!r}")
    if not tree["ko"]:
        raise CheckError("missing Korean translation for tree node 10029")


def main() -> int:
    try:
        if not KO_DIR.exists():
            raise CheckError(f"missing directory: {KO_DIR}")

        table: dict[str, list[dict[str, str]]] = {}
        for file_name in FILES:
            path = KO_DIR / file_name
            if not path.exists():
                raise CheckError(f"missing csv: {path}")
            rows = read_rows(path)
            ensure_non_empty(file_name, rows)
            ensure_no_duplicate_keys(file_name, rows)
            ensure_required_values(file_name, rows)
            table[file_name] = rows

        verify_stage0_smoke(table)
    except CheckError as exc:
        print(f"[FAIL] {exc}")
        return 1

    print("Cloud localization verification passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
