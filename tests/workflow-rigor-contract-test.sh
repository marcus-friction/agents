#!/usr/bin/env bash

# Compatibility wrapper for the opt-in live-agent profile.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
agent_eval_rollout_limit_sum="${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:-${AGENT_EVAL_ROLLOUT_UNIT_BUDGET:-${AGENT_EVAL_TOKEN_BUDGET:-}}}"

if [ "${RUN_AGENT_SKILL_TESTS:-0}" != "1" ]; then
  echo "Workflow-rigor live agent cases not run"
  exit 0
fi

for variable in AGENT_EVAL_MODEL AGENT_EVAL_EXPECTED_SUBJECT_DIGEST \
  AGENT_EVAL_EXPECTED_EXECUTOR_SHA256 AGENT_EVAL_TIMEOUT_SECONDS; do
  [ -n "${!variable:-}" ] || {
    echo "Error: live agent tests require $variable." >&2
    exit 1
  }
done
[ -n "$agent_eval_rollout_limit_sum" ] || {
  echo "Error: live agent tests require a rollout limit sum." >&2
  exit 1
}

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
bash "$REPO_ROOT/tests/run-agent-evals.sh" \
  --case v2.workflow-rigor.negative \
  --case v2.workflow-rigor.positive \
  --comparison-ref HEAD \
  --runs 1 \
  --model "$AGENT_EVAL_MODEL" \
  --rollout-planned-limit-sum "$agent_eval_rollout_limit_sum" \
  --timeout-seconds "$AGENT_EVAL_TIMEOUT_SECONDS" \
  --expected-executor-sha256 "$AGENT_EVAL_EXPECTED_EXECUTOR_SHA256" \
  --expected-subject-digest "$AGENT_EVAL_EXPECTED_SUBJECT_DIGEST" \
  --require-current-pass \
  --output-root "$test_root/live-evidence" >/dev/null

echo "Workflow-rigor live agent cases passed"
