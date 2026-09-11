#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/test-driven-development/SKILL.md"
REFERENCE="$ROOT/.agents/skills/test-driven-development/references/writing-good-tests.md"

python3 "$ROOT/.agents/skills/skill-creator/scripts/quick_validate.py" \
  "$ROOT/.agents/skills/test-driven-development"
[ -f "$REFERENCE" ] && [ ! -L "$REFERENCE" ]

grep -Eqi '100%.*line.*branch.*testable' "$SKILL"
grep -Eqi 'characteri[sz]e.*existing' "$SKILL"
grep -Eqi 'generated.*declarative.*unreachable.*behavior-free' "$SKILL"
if grep -Eqi 'Every new function|Every new method|Delete code\. Start over|Delete means delete' "$SKILL"; then
  echo "TDD skill mandates ceremony independent of observable behavior" >&2
  exit 1
fi
if grep -Eqi 'superpowers:|your human partner' "$REFERENCE"; then
  echo "TDD reference depends on unavailable or conversational context" >&2
  exit 1
fi
if grep -Eqi 'The mock earns no assertions|Mirror real data completely' "$REFERENCE"; then
  echo "TDD reference retains over-broad mock rules" >&2
  exit 1
fi

if [ "${RUN_AGENT_SKILL_TESTS:-0}" = 1 ]; then
  : "${AGENT_EVAL_MODEL:?live agent tests require AGENT_EVAL_MODEL}"
  : "${AGENT_EVAL_EXPECTED_SUBJECT_DIGEST:?live agent tests require the subject digest}"
  : "${AGENT_EVAL_EXPECTED_EXECUTOR_SHA256:?live agent tests require the executor digest}"
  : "${AGENT_EVAL_TIMEOUT_SECONDS:?live agent tests require a timeout}"
  : "${AGENT_EVAL_JOBS:?live agent tests require a reviewed job bound}"
  : "${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:?live agent tests require a reviewed rollout limit}"
  : "${AGENT_EVAL_OUTPUT_ROOT:?live agent tests require the prepared evidence root}"
  bash "$ROOT/tests/run-agent-evals.sh" \
    --case v2.tdd-behavior.negative --case v2.tdd-behavior.positive \
    --comparison-ref HEAD --runs 1 --model "$AGENT_EVAL_MODEL" \
    --timeout-seconds "$AGENT_EVAL_TIMEOUT_SECONDS" \
    --jobs "$AGENT_EVAL_JOBS" \
    --rollout-planned-limit-sum "$AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM" \
    --expected-executor-sha256 "$AGENT_EVAL_EXPECTED_EXECUTOR_SHA256" \
    --expected-subject-digest "$AGENT_EVAL_EXPECTED_SUBJECT_DIGEST" \
    --require-current-pass --output-root "$AGENT_EVAL_OUTPUT_ROOT" >/dev/null
  echo "TDD live compatibility profile completed"
else
  echo "TDD offline deterministic contract tests passed"
fi
