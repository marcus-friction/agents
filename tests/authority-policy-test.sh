#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RIGOR="${AUTHORITY_POLICY_PATH:-$REPO_ROOT/.agents/skills/review/references/change-rigor.md}"

python3 - "$RIGOR" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
rows = {}
rigor_r3 = ""
for raw_line in path.read_text(encoding="utf-8").splitlines():
    if not raw_line.startswith("|"):
        continue
    cells = [cell.strip() for cell in raw_line.strip().strip("|").split("|")]
    if len(cells) != 3:
        continue
    key = cells[0].strip("`")
    if key.startswith("**R3"):
        rigor_r3 = " ".join(cells).lower()
    if key in {
        "r0-report",
        "bounded-implementation",
        "test-only-failure",
        "r12-project-document",
        "r3-project-document",
        "r3-effect",
        "unchanged-r3-effect",
        "relevant-change",
        "unrelated-change",
    }:
        rows[key] = " ".join(cells[1:]).lower()

expected = {
    "r0-report": ("r0", "zero repository or external writes", "no approval"),
    "bounded-implementation": (
        "r1/r2",
        "supplied scope",
        "without a redundant kickoff",
        "pre-edit patch gate",
    ),
    "test-only-failure": (
        "testing does not authorize a production fix",
        "stop before production mutation",
    ),
    "r12-project-document": ("exact diff", "one combined decision", "revalidate"),
    "r3-project-document": (
        "semantic plan decision",
        "separate exact-diff decision",
        "revalidate",
    ),
    "r3-effect": (
        "publish",
        "publicly disclose",
        "mutate external state",
        "exact target",
        "action",
        "scope",
        "exposure",
        "credential class",
        "recovery path",
        "just-in-time decision",
    ),
    "unchanged-r3-effect": ("reuse", "unchanged", "without a second"),
    "relevant-change": ("invalidate", "reclassify", "regenerate"),
    "unrelated-change": ("preserve", "continue", "do not invalidate or restart"),
}

assert set(rows) == set(expected), (set(expected) - set(rows), set(rows) - set(expected))
for case_id, required in expected.items():
    missing = [phrase for phrase in required if phrase not in rows[case_id]]
    assert not missing, f"{case_id} is missing {missing}: {rows[case_id]}"

for phrase in (
    "deletion",
    "weakened constraint",
    "dirty target",
    "symlink/non-regular/generated target",
    "conflict/unknown ownership",
    "auth/privacy/secret/permission boundary",
    "external mutation",
    "public disclosure",
    "publication",
    "production/deployment effect",
    "irreversible external action",
    "relevant concurrent change",
):
    assert phrase in rigor_r3, f"R3 trigger row is missing {phrase}"
PY

echo "Authority policy case tests passed"
