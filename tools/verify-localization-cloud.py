#!/usr/bin/env python3
"""Cloud-friendly localization verification.

This verifier intentionally avoids PowerShell, Windows DLL loading, and Lua.
It is meant for hosted coding agents that usually run in a Linux container.
The Windows verifier remains the stronger runtime smoke path.
"""

from __future__ import annotations

import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TRANSLATIONS = SRC / "Data" / "Translations" / "ko-KR"

ITEM_TYPES = [
    "axe",
    "bow",
    "claw",
    "crossbow",
    "dagger",
    "fishing",
    "flail",
    "focus",
    "mace",
    "spear",
    "staff",
    "sceptre",
    "sword",
    "talisman",
    "wand",
    "body",
    "gloves",
    "helmet",
    "boots",
    "shield",
    "quiver",
    "amulet",
    "ring",
    "belt",
    "jewel",
    "flask",
    "incursionlimb",
]

CSV_FILES = {
    "Gems": {
        "path": TRANSLATIONS / "Gems.csv",
        "domains": {"gem"},
    },
    "ItemBases": {
        "path": TRANSLATIONS / "ItemBases.csv",
        "domains": {"base"},
    },
    "Tree": {
        "path": TRANSLATIONS / "Tree.csv",
        "domains": {"tree_dn", "tree_sd"},
    },
}

HEADER = ["domain", "key", "en", "ko", "aliases"]


@dataclass(frozen=True)
class Candidate:
    domain: str
    key: str
    en: str


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def read_text(path: Path) -> str:
    if not path.exists():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8-sig")


def lua_unescape(value: str) -> str:
    def repl(match: re.Match[str]) -> str:
        token = match.group(1)
        if token == "n":
            return "\n"
        if token == "r":
            return "\r"
        if token == "t":
            return "\t"
        if token == '"':
            return '"'
        if token == "\\":
            return "\\"
        if token.isdigit():
            return chr(int(token, 10))
        return token

    return re.sub(r"\\([nrt\"\\]|\d{1,3})", repl, value)


def find_matching_brace(text: str, open_index: int) -> int:
    depth = 0
    in_string: str | None = None
    escaped = False
    index = open_index
    while index < len(text):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
        else:
            if char in {"'", '"'}:
                in_string = char
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return index
        index += 1
    fail("unterminated Lua table while parsing generated data")
    return -1


def iter_lua_blocks(text: str, pattern: str):
    for match in re.finditer(pattern, text):
        open_index = text.find("{", match.end() - 1)
        if open_index < 0:
            continue
        close_index = find_matching_brace(text, open_index)
        yield match, text[open_index : close_index + 1]


def extract_gems() -> list[Candidate]:
    text = read_text(SRC / "Data" / "Gems.lua")
    candidates: list[Candidate] = []
    pattern = r'\n\t\["((?:\\.|[^"\\])*)"\]\s*=\s*\{'
    for match, block in iter_lua_blocks(text, pattern):
        gem_id = lua_unescape(match.group(1))
        name_match = re.search(r'\n\s*name\s*=\s*"((?:\\.|[^"\\])*)"', block)
        if name_match:
            candidates.append(Candidate("gem", gem_id, lua_unescape(name_match.group(1))))
    return candidates


def extract_item_bases() -> list[Candidate]:
    candidates: list[Candidate] = []
    for item_type in ITEM_TYPES:
        path = SRC / "Data" / "Bases" / f"{item_type}.lua"
        text = read_text(path)
        for match in re.finditer(r'itemBases\["((?:\\.|[^"\\])*)"\]\s*=', text):
            name = lua_unescape(match.group(1))
            candidates.append(Candidate("base", name, name))
    return candidates


def latest_tree_version() -> str:
    text = read_text(SRC / "GameVersions.lua")
    match = re.search(r"treeVersionList\s*=\s*\{([^}]*)\}", text, flags=re.S)
    if not match:
        fail("could not find treeVersionList in GameVersions.lua")
    versions = re.findall(r'"([^"]+)"', match.group(1))
    if not versions:
        fail("treeVersionList is empty")
    return versions[-1]


def extract_tree() -> list[Candidate]:
    version = latest_tree_version()
    text = read_text(SRC / "TreeData" / version / "tree.lua")
    nodes_match = re.search(r"(?m)^\tnodes=\{", text)
    if not nodes_match:
        fail(f"could not find nodes table in TreeData/{version}/tree.lua")
    nodes_index = nodes_match.start()
    candidates: list[Candidate] = []
    pattern = r'\n\t\t\[(\d+)\]\s*=\s*\{'
    for match, block in iter_lua_blocks(text[nodes_index:], pattern):
        table_id = match.group(1)
        name_match = re.search(r'(?m)^\t\t\tname\s*=\s*"((?:\\.|[^"\\])*)"', block)
        if not name_match:
            continue
        skill_match = re.search(r'(?m)^\t\t\tskill\s*=\s*(\d+)\s*,?', block)
        id_match = re.search(r'(?m)^\t\t\tid\s*=\s*(\d+)\s*,?', block)
        node_id = skill_match.group(1) if skill_match else (id_match.group(1) if id_match else None)
        if node_id is None:
            continue
        candidates.append(Candidate("tree_dn", node_id, lua_unescape(name_match.group(1))))

        stats_match = re.search(r'(?m)^\t\t\tstats\s*=\s*\{', block)
        if not stats_match:
            continue
        stats_open = block.find("{", stats_match.end() - 1)
        stats_close = find_matching_brace(block, stats_open)
        stats_block = block[stats_open : stats_close + 1]
        for stat_match in re.finditer(r'\[(\d+)\]\s*=\s*"((?:\\.|[^"\\])*)"', stats_block):
            stat_index = stat_match.group(1)
            stat_text = lua_unescape(stat_match.group(2))
            candidates.append(Candidate("tree_sd", f"{node_id}:{stat_index}", stat_text))
    return candidates


def load_csv(path: Path):
    if not path.exists():
        fail(f"missing translation csv: {path.relative_to(ROOT)}")
    rows: dict[tuple[str, str], dict[str, str]] = {}
    duplicates: list[tuple[str, str]] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration:
            fail(f"empty translation csv: {path.relative_to(ROOT)}")
        if header != HEADER:
            fail(f"{path.relative_to(ROOT)} has header {header}, expected {HEADER}")
        for line_number, row in enumerate(reader, start=2):
            if len(row) != len(HEADER):
                fail(f"{path.relative_to(ROOT)}:{line_number} has {len(row)} columns")
            record = dict(zip(HEADER, row))
            key = (record["domain"], record["key"])
            if key in rows:
                duplicates.append(key)
            rows[key] = record
    return rows, duplicates


def validate_file(name: str, candidates: list[Candidate]) -> dict[str, int | str]:
    config = CSV_FILES[name]
    path = config["path"]
    allowed_domains = config["domains"]
    wanted_candidates = [candidate for candidate in candidates if candidate.domain in allowed_domains]
    wanted = {(candidate.domain, candidate.key): candidate for candidate in wanted_candidates}
    rows, duplicates = load_csv(path)

    missing = 0
    stale = 0
    blank = 0
    for key, candidate in wanted.items():
        row = rows.get(key)
        if row is None:
            missing += 1
            continue
        if row["en"] != candidate.en:
            stale += 1
        if row["ko"] == "":
            blank += 1

    orphaned = sum(1 for key in rows if key not in wanted)
    return {
        "name": name,
        "expected": len(wanted),
        "missing": missing,
        "stale": stale,
        "blank": blank,
        "orphaned": orphaned,
        "duplicates": len(duplicates),
        "path": str(path.relative_to(SRC)),
    }


def expect_sample(rows: dict[tuple[str, str], dict[str, str]], domain: str, key: str, english: str) -> None:
    row = rows.get((domain, key))
    if row is None:
        fail(f"missing sample translation {domain}:{key}")
    if row["en"] != english:
        fail(f"sample {domain}:{key} has stale English '{row['en']}', expected '{english}'")
    if row["ko"] == "" or row["ko"] == english:
        fail(f"sample {domain}:{key} does not have a Korean display value")


def main() -> int:
    required_docs = [
        ROOT / "docs" / "localization-runtime-agent-workflow.md",
        ROOT / "docs" / "localization-runtime-cjk-plan.md",
        ROOT / "docs" / "localization.md",
    ]
    for doc in required_docs:
        if not doc.exists():
            fail(f"missing required doc: {doc.relative_to(ROOT)}")

    candidates = extract_gems() + extract_item_bases() + extract_tree()
    unique_candidates = {(candidate.domain, candidate.key) for candidate in candidates}
    print(f"Localization candidates: {len(unique_candidates)}")

    failures = 0
    for name in ("Gems", "ItemBases", "Tree"):
        result = validate_file(name, candidates)
        print(
            "{name}: expected={expected} missing={missing} stale={stale} "
            "blank={blank} orphaned={orphaned} duplicates={duplicates} path={path}".format(**result)
        )
        failures += int(result["missing"]) + int(result["stale"]) + int(result["blank"])
        failures += int(result["orphaned"]) + int(result["duplicates"])

    gem_rows, _ = load_csv(CSV_FILES["Gems"]["path"])
    base_rows, _ = load_csv(CSV_FILES["ItemBases"]["path"])
    tree_rows, _ = load_csv(CSV_FILES["Tree"]["path"])
    expect_sample(gem_rows, "gem", "Metadata/Items/Gems/SkillGemIceNova", "Ice Nova")
    expect_sample(base_rows, "base", "Wooden Club", "Wooden Club")
    expect_sample(tree_rows, "tree_dn", "30", "Gathering Winds")

    if failures:
        fail(f"localization cloud verification failed with {failures} sync issue(s)")
    print("Localization cloud verification passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
