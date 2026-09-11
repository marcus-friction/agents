#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/start-project/SKILL.md"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

python3 "$ROOT/.agents/skills/skill-creator/scripts/quick_validate.py" \
  "$ROOT/.agents/skills/start-project" >/dev/null

(cd "$TMP" && HOME="$TMP/home" bash "$ROOT/install.sh" --from-local "$ROOT" >/dev/null)
for candidate in README.md AGENTS.md ARCHITECTURE.md CONTRIBUTING.md DESIGN.md; do
  [ -f "$TMP/.agents/templates/$candidate" ]
  [ ! -e "$TMP/$candidate" ]
done

python3 - "$SKILL" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")

assert re.search(r"scaffold.*meaningful product behavior", text, re.I | re.S)
assert re.search(r"one question at a time", text, re.I)
assert "15–20 minute" in text
assert re.search(r"no more than eight questions", text, re.I)
for component in (
    "Laravel 13", "PHP 8.4", "Nuxt 4", "Vue 3", "Tailwind CSS 4",
    "PostgreSQL 17",
):
    assert component in text, f"missing default stack component: {component}"
assert re.search(r"already approved and \*\*Adopted\*\*", text)
assert "Adopted but deferred" in text
assert re.search(r"Only an explicit owner decision may replace or remove", text)
for document in ("README.md", "AGENTS.md", "ARCHITECTURE.md", "CONTRIBUTING.md", "DESIGN.md"):
    assert f".agents/templates/{document}` to `{document}" in text
assert re.search(r"candidate is missing.*stop", text, re.I | re.S)
assert re.search(r"Ask\s+for authority to run `update-agents`", text)
assert "docs/plans/<YYYY-MM-DD>-<slug>/" in text
assert "implementation-plan.md" in text and "tasks.md" in text
assert re.search(r"Always apply `review-plan`", text)
assert re.search(r"Do not require a separate synthesis approval", text)
assert "brainstorm" not in text.lower()
assert "R3" not in text
PY

if [ "${RUN_AGENT_SKILL_TESTS:-0}" = 1 ]; then
  : "${AGENT_EVAL_MODEL:?live agent tests require AGENT_EVAL_MODEL}"
  : "${AGENT_EVAL_EXPECTED_SUBJECT_DIGEST:?live agent tests require the subject digest}"
  : "${AGENT_EVAL_EXPECTED_EXECUTOR_SHA256:?live agent tests require the executor digest}"
  : "${AGENT_EVAL_TIMEOUT_SECONDS:?live agent tests require a timeout}"
  : "${AGENT_EVAL_JOBS:?live agent tests require a reviewed job bound}"
  : "${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:?live agent tests require a reviewed rollout limit}"
  : "${AGENT_EVAL_OUTPUT_ROOT:?live agent tests require the prepared evidence root}"
  bash "$ROOT/tests/run-agent-evals.sh" \
    --case v2.start-project-routing.negative \
    --case v2.start-project-routing.positive \
    --comparison-ref HEAD \
    --runs 1 \
    --model "$AGENT_EVAL_MODEL" \
    --timeout-seconds "$AGENT_EVAL_TIMEOUT_SECONDS" \
    --jobs "$AGENT_EVAL_JOBS" \
    --rollout-planned-limit-sum "$AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM" \
    --expected-executor-sha256 "$AGENT_EVAL_EXPECTED_EXECUTOR_SHA256" \
    --expected-subject-digest "$AGENT_EVAL_EXPECTED_SUBJECT_DIGEST" \
    --require-current-pass \
    --output-root "$AGENT_EVAL_OUTPUT_ROOT" >/dev/null
  echo "Start-project live compatibility profile completed"
else
  echo "Start-project offline deterministic contract tests passed"
fi
