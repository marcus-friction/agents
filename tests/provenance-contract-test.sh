#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import hashlib
import json
import sys

root = Path(sys.argv[1])
license_text = (root / "LICENSE").read_text(encoding="utf-8")
notices = (root / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
normalized_notices = " ".join(notices.split())
reference = (root / "docs/ecosystem-reference.md").read_text(encoding="utf-8")
readme = (root / "README.md").read_text(encoding="utf-8")

if "MIT License" not in license_text or "Agents Ecosystem contributors" not in license_text:
    raise SystemExit("root LICENSE does not grant the approved contributor-owned MIT license")
if "TomFit AG for portions identified" not in license_text:
    raise SystemExit("root LICENSE does not retain scoped TomFit AG attribution")

for name in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
    distributed = root / ".agents/legal" / name
    if distributed.read_bytes() != (root / name).read_bytes():
        raise SystemExit(f"installed legal payload differs from root {name}")
marker = root / ".agents/legal/.agents-ecosystem-managed"
if marker.is_symlink() or not marker.is_file() or "manages this directory" not in marker.read_text(encoding="utf-8"):
    raise SystemExit("installed legal payload lacks its physical ownership marker")

lock_path = root / ".agents/legal/retained-provenance.json"
if lock_path.is_symlink() or not lock_path.is_file():
    raise SystemExit("retained provenance lock must be a physical distributed file")
lock = json.loads(lock_path.read_text(encoding="utf-8"))
if lock.get("format") != "agents-ecosystem-retained-provenance-v1":
    raise SystemExit("retained provenance lock has an unsupported format")
entries = lock.get("entries")
if not isinstance(entries, list):
    raise SystemExit("retained provenance lock entries must be an array")
expected_retained_counts = {
    "Superpowers": 3,
    "Jezweb Claude Skills": 7,
    "Anthropic Skills": 13,
    "Agentic SEO Skill": 1,
    "Marketing Skills": 1,
}
actual_retained_counts = {name: 0 for name in expected_retained_counts}
seen_local_paths = set()
for index, entry in enumerate(entries):
    if not isinstance(entry, dict):
        raise SystemExit(f"retained provenance entry {index} is not an object")
    expected_fields = {
        "source", "sourceUrl", "revision", "upstreamPath",
        "upstreamGitBlob", "localPath", "sha256",
    }
    if set(entry) != expected_fields:
        raise SystemExit(f"retained provenance entry {index} has unexpected fields")
    source = entry["source"]
    if source not in actual_retained_counts:
        raise SystemExit(f"retained provenance entry has unsupported source: {source}")
    actual_retained_counts[source] += 1
    relative = entry["localPath"]
    if relative in seen_local_paths or relative.startswith("/") or ".." in Path(relative).parts:
        raise SystemExit(f"invalid or duplicate retained local path: {relative}")
    seen_local_paths.add(relative)
    local = root / relative
    if local.is_symlink() or not local.is_file():
        raise SystemExit(f"retained local path is not a physical file: {relative}")
    payload = local.read_bytes()
    if hashlib.sha256(payload).hexdigest() != entry["sha256"]:
        raise SystemExit(f"retained SHA-256 mismatch: {relative}")
    git_blob = hashlib.sha1(
        f"blob {len(payload)}\0".encode("ascii") + payload
    ).hexdigest()
    if git_blob != entry["upstreamGitBlob"]:
        raise SystemExit(f"retained upstream Git blob mismatch: {relative}")
    if entry["revision"] not in notices or entry["sourceUrl"] not in notices:
        raise SystemExit(f"retained provenance source is absent from notices: {relative}")
if actual_retained_counts != expected_retained_counts:
    raise SystemExit(
        f"retained provenance counts changed: {actual_retained_counts}"
    )
if "retained-provenance.json" not in notices:
    raise SystemExit("third-party notice does not identify its retained-file lock")

distribution = json.loads(
    (root / "tests/distribution-manifest.json").read_text(encoding="utf-8")
)
for exception in distribution.get("exceptions", []):
    if exception.get("path_kind") != "exact":
        continue
    reason = exception.get("reason", "").lower()
    owner = exception.get("owner", "").lower()
    claims_retained_upstream = (
        "byte-preserved" in reason
        or "byte-identical" in reason
        or owner.startswith("upstream ")
        or "sha256" in exception
    )
    if not claims_retained_upstream:
        continue
    relative = exception.get("path")
    if relative not in seen_local_paths:
        raise SystemExit(
            f"retained upstream distribution entry is absent from lock: {relative}"
        )
    if exception.get("sha256") not in (None, hashlib.sha256((root / relative).read_bytes()).hexdigest()):
        raise SystemExit(f"distribution manifest digest disagrees with retained lock: {relative}")

components = {
    "TomFit Agent Ecosystem": ("037860a575a41ca36db2569ba1eb957832d0d515", "MIT"),
    "gstack": ("1211b6b40becb684eaf29b0f30a650a8a9b222a5", "MIT"),
    "Compound Engineering": ("b36047e1b4b2123df2f3529bf04b5f2a7c5f84e4", "MIT"),
    "Superpowers": ("b36e0829c6d0140e93cfef2ca599b1b07d4a7797", "MIT"),
    "Jezweb Claude Skills": ("bf917575ed6b65eb98307ced903f469020d8cd0a", "MIT"),
    "shadcn/ui": ("7c9eaba1c0a6404c990c144a654792e3313c650d", "MIT"),
    "Anthropic Skills": ("b9e19e6f44773509fbdd7001d77ff41a49a486c1", "Apache-2.0"),
    "Agentic SEO Skill": ("337069435d16c68071523f488841b882e35d9767", "MIT"),
    "Marketing Skills": ("0d586e4952494d58ed5c60926aa5982311e41044", "MIT"),
    "Google Labs DESIGN.md": ("89012cc4d140530d60742f76be04768585c1aa3a", "Apache-2.0"),
    "Vue.js AI Skills": ("f3dd1bf4d3ac78331bdc903e4519d561c538ca6a", "MIT"),
    "VueUse Skills": ("5706f866118f04a6238bf77368dafa4a2c34b96b", "MIT"),
}
for name, (revision, license_id) in components.items():
    for value in (name, revision, license_id):
        if value not in notices:
            raise SystemExit(f"third-party notice missing {value}")

if "Release: `v0.2.0`" not in notices:
    raise SystemExit("third-party notice missing the TomFit v0.2.0 release pin")

for fragment in (
    "SheetJS 0.20.3",
    "Google Fonts",
    "runtime downloads, not vendored files",
    "Material not identified below is maintained by Agents Ecosystem contributors",
    "does not claim that TomFit AG authored the entire repository",
    "MIT permission notice",
):
    if fragment not in normalized_notices:
        raise SystemExit(f"third-party notice missing classification: {fragment}")

modified = (
    ".agents/skills/skill-creator/SKILL.md",
    ".agents/skills/skill-creator/eval-viewer/viewer.html",
    ".agents/skills/skill-creator/references/schemas.md",
    ".agents/skills/skill-creator/scripts/generate_report.py",
    "project-templates/base/DESIGN.md",
)
for relative in modified:
    text = (root / relative).read_text(encoding="utf-8")
    if "Modified by TomFit AG" not in text:
        raise SystemExit(f"Apache-derived file lacks a prominent modification notice: {relative}")

anthropic_license = (root / ".agents/skills/skill-creator/LICENSE.txt").read_text(encoding="utf-8")
if "Copyright [yyyy] [name of copyright owner]" not in anthropic_license:
    raise SystemExit("Apache license copy does not retain its canonical Appendix placeholder")
if "Copyright 2026 Anthropic, PBC." in anthropic_license:
    raise SystemExit("Apache license terms were altered to carry a source notice")
if "Copyright 2026 Anthropic, PBC." not in notices:
    raise SystemExit("Anthropic copyright notice is not retained separately")

for stale in ("Vercel Skills.sh", "**v2.0.0**", "**v1.5.0+**"):
    if stale in reference:
        raise SystemExit(f"ecosystem reference retains an unsupported provenance/release claim: {stale}")

for fragment in ("LICENSE", "THIRD_PARTY_NOTICES.md", "1.7.0"):
    if fragment not in readme:
        raise SystemExit(f"README lacks release/licensing reference: {fragment}")

print("Provenance and licensing contract tests passed")
PY
