#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/security-review/SKILL.md"

grep -Eqi 'exploitability.*exposure.*impact.*reversibility' "$SKILL"
grep -Eqi 'control owner|owning boundary' "$SKILL"
grep -Eqi 'disposable.*rebuild|rebuild.*disposable' "$SKILL"
grep -Eqi 'material.*recovery|recovery.*material' "$SKILL"
grep -Eqi '^[-*] \*\*Identity:' "$SKILL"
grep -Eqi '^[-*] \*\*Browser session:' "$SKILL"
grep -Eqi '^[-*] \*\*Token or claim exchange:' "$SKILL"
grep -Eqi '^[-*] \*\*Resource authori[sz]ation:' "$SKILL"

if [ "${RUN_AGENT_SKILL_TESTS:-0}" = 1 ]; then
  : "${AGENT_EVAL_MODEL:?live agent tests require AGENT_EVAL_MODEL}"
  : "${AGENT_EVAL_EXPECTED_SUBJECT_DIGEST:?live agent tests require the subject digest}"
  : "${AGENT_EVAL_EXPECTED_EXECUTOR_SHA256:?live agent tests require the executor digest}"
  : "${AGENT_EVAL_TIMEOUT_SECONDS:?live agent tests require a timeout}"
  : "${AGENT_EVAL_JOBS:?live agent tests require a reviewed job bound}"
  : "${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:?live agent tests require a reviewed rollout limit}"
  : "${AGENT_EVAL_OUTPUT_ROOT:?live agent tests require the prepared evidence root}"
  bash "$ROOT/tests/run-agent-evals.sh" \
    --case v2.security-boundaries.negative --case v2.security-boundaries.positive \
    --comparison-ref HEAD --runs 1 --model "$AGENT_EVAL_MODEL" \
    --timeout-seconds "$AGENT_EVAL_TIMEOUT_SECONDS" \
    --jobs "$AGENT_EVAL_JOBS" \
    --rollout-planned-limit-sum "$AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM" \
    --expected-executor-sha256 "$AGENT_EVAL_EXPECTED_EXECUTOR_SHA256" \
    --expected-subject-digest "$AGENT_EVAL_EXPECTED_SUBJECT_DIGEST" \
    --require-current-pass --output-root "$AGENT_EVAL_OUTPUT_ROOT" >/dev/null
  echo "Security-review live compatibility profile completed"
else
  echo "Security-review offline deterministic contract tests passed"
fi
