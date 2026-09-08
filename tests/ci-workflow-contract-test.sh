#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/ci.yml"

python3 - "$WORKFLOW" <<'PY'
from pathlib import Path
import re
import sys

workflow = Path(sys.argv[1])
if not workflow.is_file() or workflow.is_symlink():
    raise SystemExit("CI workflow must be a physical regular file")

text = workflow.read_text(encoding="utf-8")

if re.search(r"(?m)^permissions:\s*\n(?:[ \t]+[^\n]+\n)*?[ \t]+contents:\s*read\s*$", text) is None:
    raise SystemExit("CI must grant read-only repository contents access")
if re.search(r"(?mi)^\s*[A-Za-z_-]+:\s*write\s*$", text):
    raise SystemExit("CI must not grant write permissions")
if re.search(r"(?mi)^\s*(pull_request_target|workflow_run):\s*$", text):
    raise SystemExit("CI must not use privileged event triggers")
if re.search(r"(?mi)\bsecrets\b|^\s*environment\s*:", text):
    raise SystemExit("Offline CI must not consume secrets or deployment environments")
if re.search(r"(?m)^\s*timeout-minutes:\s*[1-9][0-9]*\s*$", text) is None:
    raise SystemExit("CI must bound job execution time")
if re.search(r"(?m)^\s*run:\s*bash tests/run\.sh\s*$", text) is None:
    raise SystemExit("CI must execute the offline deterministic suite")

uses = re.findall(r"(?m)^\s*- uses:\s*(\S+)\s*$", text)
if not uses:
    raise SystemExit("CI must check out the repository")
for action in uses:
    if not re.fullmatch(r"[^@\s]+@[0-9a-f]{40}", action):
        raise SystemExit(f"CI action is not pinned to a full commit SHA: {action}")

checkout_blocks = re.findall(
    r"(?ms)^\s*- uses:\s*actions/checkout@[0-9a-f]{40}\s*$.*?(?=^\s*- (?:uses|name):|\Z)",
    text,
)
if len(checkout_blocks) != 1:
    raise SystemExit("CI must contain one pinned checkout action")
checkout = checkout_blocks[0]
if "fetch-depth: 0" not in checkout or "persist-credentials: false" not in checkout:
    raise SystemExit("Checkout must fetch history without persisting credentials")

print("CI workflow safety contract passed")
PY
