#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import re
import stat
import sys

repo = Path(sys.argv[1])
skills_root = repo / ".agents" / "skills"
catalog_path = repo / "docs" / "ecosystem-reference.md"
errors: list[str] = []

if skills_root.is_symlink() or not skills_root.is_dir():
    raise SystemExit("Skill root must be a physical directory")

skills: dict[str, Path] = {}
directory_name_aliases = {"laravel": "laravel-best-practices"}
for child in sorted(skills_root.iterdir(), key=lambda path: path.name):
    mode = child.lstat().st_mode
    if stat.S_ISLNK(mode):
        errors.append(f"skill entry is a symlink: {child.name}")
        continue
    if not stat.S_ISDIR(mode):
        errors.append(f"skill root contains a non-directory entry: {child.name}")
        continue
    skill_file = child / "SKILL.md"
    try:
        skill_mode = skill_file.lstat().st_mode
    except FileNotFoundError:
        errors.append(f"skill directory has no SKILL.md: {child.name}")
        continue
    if stat.S_ISLNK(skill_mode) or not stat.S_ISREG(skill_mode):
        errors.append(f"SKILL.md must be a physical regular file: {child.name}")
        continue
    text = skill_file.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        errors.append(f"SKILL.md has no frontmatter: {child.name}")
        continue
    name = None
    for line in lines[1:]:
        if line == "---":
            break
        match = re.fullmatch(r"name:\s*['\"]?([^'\"]+?)['\"]?\s*", line)
        if match:
            name = match.group(1)
    expected_name = directory_name_aliases.get(child.name, child.name)
    if name != expected_name:
        errors.append(
            f"frontmatter name does not match directory contract: "
            f"{child.name} expects {expected_name!r}, found {name!r}"
        )
        continue
    if name in skills:
        errors.append(f"duplicate declared skill name: {name}")
        continue
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
        errors.append(f"declared skill name is not canonical kebab-case: {name!r}")
        continue
    skills[name] = skill_file

catalog_lines = catalog_path.read_text(encoding="utf-8").splitlines()
try:
    header_index = catalog_lines.index("| Skill | Purpose | Source |")
except ValueError:
    errors.append("skill catalog table header is missing")
    rows = []
else:
    rows = []
    for line in catalog_lines[header_index + 2 :]:
        if not line.startswith("|"):
            break
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 3:
            errors.append(f"skill catalog row must have three cells: {line}")
            continue
        rows.append(cells)

catalog_names: list[str] = []
for skill_cell, purpose, source in rows:
    match = re.fullmatch(r"`([a-z0-9-]+)`", skill_cell)
    if not match:
        errors.append(f"skill catalog name is not a canonical code literal: {skill_cell}")
        continue
    name = match.group(1)
    catalog_names.append(name)
    if not purpose:
        errors.append(f"skill catalog purpose is empty: {name}")
    if source != "Original" and not re.search(r"\[[^]]+\]\(https://[^)]+\)", source):
        errors.append(f"skill catalog source is not directly resolvable: {name}: {source}")

for name in sorted(set(catalog_names)):
    if catalog_names.count(name) != 1:
        errors.append(f"skill catalog row is not unique: {name}")

skill_names = set(skills)
catalog_name_set = set(catalog_names)
for name in sorted(skill_names - catalog_name_set):
    errors.append(f"skill is missing from catalog: {name}")
for name in sorted(catalog_name_set - skill_names):
    errors.append(f"catalog row has no physical skill: {name}")

if errors:
    for error in sorted(set(errors)):
        print(f"[skill-catalog] {error}", file=sys.stderr)
    raise SystemExit(f"Skill catalog check found {len(set(errors))} violation(s).")

print(f"Skill catalog tests passed ({len(skill_names)} skills).")
PY
