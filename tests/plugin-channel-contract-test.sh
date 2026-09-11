#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path(sys.argv[1])
version = (root / "VERSION").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", version):
    raise SystemExit("VERSION must contain one canonical semantic version")

plugin = json.loads((root / ".agents/.claude-plugin/plugin.json").read_text(encoding="utf-8"))
if plugin.get("version") != version:
    raise SystemExit("Claude plugin version must match repository VERSION")
if plugin.get("license") != "MIT AND Apache-2.0":
    raise SystemExit("Claude plugin must identify every license in its shipped payload")
if plugin.get("name") != "ma" or plugin.get("repository") != "https://github.com/marcus-friction/agents":
    raise SystemExit("Claude plugin must use the public ma identity")

marketplace = json.loads((root / ".claude-plugin/marketplace.json").read_text(encoding="utf-8"))
entries = marketplace.get("plugins", [])
if len(entries) != 1 or entries[0].get("source") != "./.agents":
    raise SystemExit("edge marketplace must keep its repository-local plugin source")
if marketplace.get("name") != "marcus-friction-plugins" or entries[0].get("name") != "ma":
    raise SystemExit("edge marketplace must expose ma via marcus-friction-plugins")
if entries[0].get("version") != version:
    raise SystemExit("marketplace entry must match repository VERSION")

readme = (root / "README.md").read_text(encoding="utf-8")
reference = (root / "docs/ecosystem-reference.md").read_text(encoding="utf-8")
combined = readme + "\n" + reference
normalized_combined = " ".join(combined.split())
for skill_file in (root / ".agents/skills").glob("*/SKILL.md"):
    if (skill_file.parent / '.claude-plugin/plugin.json').exists():
        raise SystemExit(f"nested plugin overrides ma namespace: {skill_file.parent}")
    declared = re.search(r"(?m)^name:\s*([^\s]+)\s*$", skill_file.read_text(encoding="utf-8"))
    if declared is None or declared.group(1).startswith("ma-"):
        raise SystemExit(f"skill must use an unprefixed declared name: {skill_file}")
    if skill_file.parent.name.startswith("ma-"):
        raise SystemExit(f"skill directory must not encode the plugin prefix: {skill_file.parent}")
if "`ma:review`" not in combined or "ma-review" in combined:
    raise SystemExit("documentation must use the ma: plugin namespace")
if "bash <(curl" in combined:
    raise SystemExit("downloaded installers must be complete before shell execution")
for fragment in (
    "Claude marketplace route is edge-only",
    "marketplace source cannot be pinned to a full commit SHA",
    "Claude Code 2.1.112",
):
    if fragment not in normalized_combined:
        raise SystemExit(f"plugin channel evidence missing: {fragment}")

stable_sections = re.findall(
    r"(?ms)^#{2,4}[^\n]*Stable[^\n]*\n.*?(?=^#{1,4} |\Z)",
    combined,
)
if not stable_sections:
    raise SystemExit("documentation has no stable-channel section")
for section in stable_sections:
    if "/plugin marketplace" in section or "claude plugin marketplace" in section:
        raise SystemExit("stable instructions must not include the edge-only plugin route")
    if "PASTE_THE_40_CHARACTER_SHA_FROM_THE_RELEASE" in section:
        if "raw.githubusercontent.com" in section:
            raise SystemExit("stable bootstrap must not execute a fetched repository script")
        for fragment in ('release_dir="$(mktemp -d)"', 'release_git -C "$release_dir" fetch', "rev-parse 'HEAD^{commit}'", 'symbolic-ref -q HEAD', 'bash "$release_dir'):
            if fragment not in section:
                raise SystemExit(f"stable bootstrap is missing verify-before-execute step: {fragment}")

if "Enable auto-updates" in reference or "auto-update so you never" in reference:
    raise SystemExit("edge plugin guidance must not recommend unattended mutable updates")

print("Plugin channel contract tests passed")
PY
