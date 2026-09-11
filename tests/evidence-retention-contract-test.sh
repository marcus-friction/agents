#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
[ -f "$ROOT/tests/agent-evals/runner.py" ]
for removed in aggregate.py fake_services.py grade.py subject_manifest.py verify.py; do
  [ ! -e "$ROOT/tests/agent-evals/$removed" ]
done

python3 - "$ROOT/tests/agent-evals/cases.json" <<'PY'
import json
from pathlib import Path
import sys

registry = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert all(
    not rule["path"].startswith(".agents/skills/") or "Removed skill" in rule["reason"]
    for rule in registry["deterministic_only"]
), "active skill behavior must not be exempted wholesale"
for case in registry["cases"]:
    supplied = set(case["context_paths"])
    for affected in case["affected_paths"]:
        assert affected["path"] in supplied, (case["id"], affected["path"])
PY

raw="$(find "$ROOT" -path "$ROOT/.git" -prune -o -type f \
  \( -name events.jsonl -o -name transcript.log -o -name executor.stderr \
  -o -name grading.json -o -path '*/snapshots/before.json' \
  -o -path '*/snapshots/after.json' \) -print -quit)"
[ -z "$raw" ] || { echo "raw evaluation artifact is tracked: $raw" >&2; exit 1; }

grep -Fq 'outside the repository by default' "$ROOT/.agents/skills/skill-creator/SKILL.md"
echo "Evidence retention contract tests passed"
