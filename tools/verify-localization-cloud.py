#!/usr/bin/env python3
"""Cloud-friendly localization verification.

PowerShell/Lua 런타임이 없는 클라우드 환경에서 Stage 0 검증을 수행한다.
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
HEADER = ["domain", "key", "en", "ko", "aliases"]

ITEM_TYPES = [
    "axe", "bow", "claw", "crossbow", "dagger", "fishing", "flail", "focus", "mace", "spear",
    "staff", "sceptre", "sword", "talisman", "wand", "body", "gloves", "helmet", "boots", "shield",
    "quiver", "amulet", "ring", "belt", "jewel", "flask", "incursionlimb",
]

CSV_FILES = {
    "Gems": {"path": TRANSLATIONS / "Gems.csv", "domains": {"gem"}},
    "ItemBases": {"path": TRANSLATIONS / "ItemBases.csv", "domains": {"base"}},
    "Tree": {"path": TRANSLATIONS / "Tree.csv", "domains": {"tree_dn", "tree_sd"}},
}


@dataclass(frozen=True)
class Candidate:
    domain: str
    key: str
    en: str


def fail(message: str) -> None:
    raise SystemExit(f"[FAIL] {message}")


def read_text(path: Path) -> str:
    if not path.exists():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8-sig")


def lua_unescape(value: str) -> str:
    def repl(match: re.Match[str]) -> str:
        token = match.group(1)
        mapping = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\"}
        if token in mapping:
            return mapping[token]
        if token.isdigit():
            return chr(int(token, 10))
        return token

    return re.sub(r"\\([nrt\"\\]|\d{1,3})", repl, value)


def find_matching_brace(text: str, open_index: int) -> int:
    depth = 0
    in_string: str | None = None
    escaped = False
    for index in range(open_index, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
            continue
        if char in {"'", '"'}:
            in_string = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    fail("unterminated Lua table while parsing generated data")


def iter_lua_blocks(text: str, pattern: str):
    for match in re.finditer(pattern, text):
        open_index = text.find("{", match.end() - 1)
        if open_index < 0:
            continue
        close_index = find_matching_brace(text, open_index)
        yield match, text[open_index : close_index + 1]


def extract_gems() -> list[Candidate]:
    text = read_text(SRC / "Data" / "Gems.lua")
    out: list[Candidate] = []
    for match, block in iter_lua_blocks(text, r'\n\t\["((?:\\.|[^"\\])*)"\]\s*=\s*\{'):
        gem_id = lua_unescape(match.group(1))
        name_match = re.search(r'\n\s*name\s*=\s*"((?:\\.|[^"\\])*)"', block)
        if name_match:
            out.append(Candidate("gem", gem_id, lua_unescape(name_match.group(1))))
    return out


def extract_item_bases() -> list[Candidate]:
    out: list[Candidate] = []
    for item_type in ITEM_TYPES:
        text = read_text(SRC / "Data" / "Bases" / f"{item_type}.lua")
        for match in re.finditer(r'itemBases\["((?:\\.|[^"\\])*)"\]\s*=', text):
            name = lua_unescape(match.group(1))
            out.append(Candidate("base", name, name))
    return out


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
    out: list[Candidate] = []
    sub = text[nodes_match.start() :]
    for match, block in iter_lua_blocks(sub, r'\n\t\t\[(\d+)\]\s*=\s*\{'):
        name_match = re.search(r'(?m)^\t\t\tname\s*=\s*"((?:\\.|[^"\\])*)"', block)
        if not name_match:
            continue
        node_id_match = re.search(r'(?m)^\t\t\t(?:skill|id)\s*=\s*(\d+)\s*,?', block)
        if not node_id_match:
            continue
        node_id = node_id_match.group(1)
        out.append(Candidate("tree_dn", node_id, lua_unescape(name_match.group(1))))

        stats_match = re.search(r'(?m)^\t\t\tstats\s*=\s*\{', block)
        if not stats_match:
            continue
        stats_open = block.find("{", stats_match.end() - 1)
        stats_close = find_matching_brace(block, stats_open)
        stats_block = block[stats_open : stats_close + 1]
        for stat_match in re.finditer(r'\[(\d+)\]\s*=\s*"((?:\\.|[^"\\])*)"', stats_block):
            out.append(Candidate("tree_sd", f"{node_id}:{stat_match.group(1)}", lua_unescape(stat_match.group(2))))
    return out


def load_csv(path: Path):
    if not path.exists():
        fail(f"missing translation csv: {path.relative_to(ROOT)}")
    rows: dict[tuple[str, str], dict[str, str]] = {}
    duplicates = 0
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
                duplicates += 1
            rows[key] = record
    return rows, duplicates


def validate_file(name: str, candidates: list[Candidate]) -> int:
    config = CSV_FILES[name]
    wanted = {(c.domain, c.key): c for c in candidates if c.domain in config["domains"]}
    rows, duplicates = load_csv(config["path"])
    missing = stale = blank = 0
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
    print(f"{name}: expected={len(wanted)} missing={missing} stale={stale} blank={blank} orphaned={orphaned} duplicates={duplicates}")
    return missing + stale + blank + orphaned + duplicates


def expect_sample(rows: dict[tuple[str, str], dict[str, str]], domain: str, key: str, english: str) -> None:
    row = rows.get((domain, key))
    if row is None:
        fail(f"missing sample translation {domain}:{key}")
    if row["en"] != english:
        fail(f"sample {domain}:{key} has stale English '{row['en']}', expected '{english}'")
    if row["ko"] == "" or row["ko"] == english:
        fail(f"sample {domain}:{key} does not have a Korean display value")


def main() -> int:
    for doc in [
        ROOT / "docs" / "localization-runtime-agent-workflow.md",
        ROOT / "docs" / "localization-runtime-cjk-plan.md",
        ROOT / "docs" / "localization.md",
    ]:
        if not doc.exists():
            fail(f"missing required doc: {doc.relative_to(ROOT)}")

    candidates = extract_gems() + extract_item_bases() + extract_tree()
    print(f"Localization candidates: {len({(c.domain, c.key) for c in candidates})}")

    failures = 0
    for name in ("Gems", "ItemBases", "Tree"):
        failures += validate_file(name, candidates)

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
