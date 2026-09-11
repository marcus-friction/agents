#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RIGOR="$ROOT/.agents/skills/review/references/change-rigor.md"

bash "$ROOT/tests/authority-policy-test.sh" >/dev/null
grep -Eqi 'no separate' "$ROOT/.agents/skills/onboard-project/SKILL.md"
grep -Eqi 'all five active baseline documents' "$ROOT/.agents/skills/start-project/SKILL.md"
grep -Eqi 'elevated.*independent|independent.*elevated' "$ROOT/.agents/skills/review-plan/SKILL.md"
grep -Eqi 'mode:report-only' "$ROOT/.agents/skills/review/SKILL.md"
grep -zEqi 'They are R0 unless[^.]*tasks\.md[^.]*R1' "$ROOT/.agents/skills/review/SKILL.md"
! rg -q 'R3|R0.R3|R0–R3' \
  "$RIGOR" \
  "$ROOT/.agents/skills/onboard-project/SKILL.md" \
  "$ROOT/.agents/skills/start-project/SKILL.md" \
  "$ROOT/.agents/skills/plan/SKILL.md" \
  "$ROOT/.agents/skills/review-plan/SKILL.md"

if [ "${RUN_AGENT_SKILL_TESTS:-0}" = 1 ]; then
  : "${AGENT_EVAL_MODEL:?live agent tests require AGENT_EVAL_MODEL}"
  : "${AGENT_EVAL_EXPECTED_SUBJECT_DIGEST:?live agent tests require the subject digest}"
  : "${AGENT_EVAL_EXPECTED_EXECUTOR_SHA256:?live agent tests require the executor digest}"
  : "${AGENT_EVAL_TIMEOUT_SECONDS:?live agent tests require a timeout}"
  : "${AGENT_EVAL_JOBS:?live agent tests require a reviewed job bound}"
  : "${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:?live agent tests require a reviewed rollout limit}"
  : "${AGENT_EVAL_OUTPUT_ROOT:?live agent tests require the prepared evidence root}"
  bash "$ROOT/tests/run-agent-evals.sh" \
    --case v2.workflow-rigor.negative \
    --case v2.workflow-rigor.positive \
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
  echo "Workflow-rigor live compatibility profile completed"
else
  echo "Workflow-rigor offline deterministic contract tests passed"
fi
