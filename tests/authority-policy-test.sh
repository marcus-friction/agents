#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RIGOR="${AUTHORITY_POLICY_PATH:-$ROOT/.agents/skills/review/references/change-rigor.md}"

python3 - "$RIGOR" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "R0 — Read-only" in text
assert "R1 — Ordinary" in text
assert "R2 — Elevated" in text
assert "R3" not in text

required = {
    "read-only-report": ["zero repository", "no approval"],
    "planning-artifacts": ["implementation-plan.md", "tasks.md", "does not authorize implementation"],
    "review-tracker": ["existing matching tracker", "do not create a tracker", "fix authority"],
    "ordinary-implementation": ["without a redundant kickoff", "pre-edit patch approval"],
    "test-only-failure": ["does not authorize a production fix", "stop before production mutation"],
    "elevated-effect": ["exact target", "scope", "exposure", "credential", "recovery path"],
    "relevant-change": ["invalidate"],
    "unrelated-change": ["preserve", "continue"],
}
rows = {}
for line in text.splitlines():
    if not line.startswith("|"):
        continue
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    if len(cells) == 3:
        rows[cells[0].strip("`")] = " ".join(cells[1:]).lower()
for key, phrases in required.items():
    assert key in rows, f"missing decision case {key}"
    for phrase in phrases:
        assert phrase in rows[key], f"{key} missing {phrase!r}"

for phrase in ("destruction", "secret", "permission", "privileged", "production", "publication", "irreversible"):
    assert phrase in text.lower(), f"elevated boundary missing {phrase}"
PY

echo "Authority policy case tests passed"
