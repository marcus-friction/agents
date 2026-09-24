#!/usr/bin/env bash

set -euo pipefail

unset RUN_AGENT_SKILL_TESTS AGENT_EVAL_MODEL AGENT_EVAL_CODEX_BIN
unset AGENT_EVAL_EXPECTED_SUBJECT_DIGEST AGENT_EVAL_TOKEN_BUDGET
unset AGENT_EVAL_TIMEOUT_SECONDS START_PROJECT_SKILL_DECISION_FILE
unset SECURITY_REVIEW_DECISION_FILE WORKFLOW_RIGOR_DECISION_FILE
unset TDD_SKILL_DECISION_FILE

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "PROFILE offline-deterministic: live agent cases are registered but are not executed"

bash "$TEST_DIR/ci-workflow-contract-test.sh"
PYTHONDONTWRITEBYTECODE=1 python3 "$TEST_DIR/review-boundaries-test.py"
bash "$TEST_DIR/register-skills-test.sh"
bash "$TEST_DIR/sync-managed-tree-test.sh"
bash "$TEST_DIR/installer-ref-contract-test.sh"
bash "$TEST_DIR/install-user-snapshot-test.sh"
bash "$TEST_DIR/install-into-repos-test.sh"
bash "$TEST_DIR/install-tool-agnostic-test.sh"
bash "$TEST_DIR/project-docs-preservation-test.sh"
bash "$TEST_DIR/base-architecture-staging-test.sh"
bash "$TEST_DIR/project-template-layout-test.sh"
bash "$TEST_DIR/evidence-retention-contract-test.sh"
bash "$TEST_DIR/distribution-text-classification-test.sh"
bash "$TEST_DIR/canonical-skill-portability-test.sh"
bash "$TEST_DIR/skill-catalog-test.sh"
bash "$TEST_DIR/design-md-standard-test.sh"
bash "$TEST_DIR/documentation-interface-test.sh"
bash "$TEST_DIR/edge-quickstart-test.sh"
bash "$TEST_DIR/start-project-skill-agent-test.sh"
bash "$TEST_DIR/tool-boundary-test.sh"
bash "$TEST_DIR/base-document-budget-test.sh"
bash "$TEST_DIR/authority-policy-test.sh"
bash "$TEST_DIR/contribution-policy-consistency-test.sh"
bash "$TEST_DIR/provenance-contract-test.sh"
bash "$TEST_DIR/plugin-channel-contract-test.sh"
bash "$TEST_DIR/update-agents-ref-contract-test.sh"
bash "$TEST_DIR/adversarial-review-contract-test.sh"
bash "$TEST_DIR/review-skill-contract-test.sh"
bash "$TEST_DIR/path-contribute-skill-contract-test.sh"
bash "$TEST_DIR/pragmatism-policy-test.sh"
bash "$TEST_DIR/skill-routing-contract-test.sh"
bash "$TEST_DIR/delivery-lifecycle-contract-test.sh"
bash "$TEST_DIR/skill-effects-agent-test.sh"
bash "$TEST_DIR/stack-skills-contract-test.sh"
bash "$TEST_DIR/specialty-guidance-contract-test.sh"
bash "$TEST_DIR/specialty-preservation-test.sh"
bash "$TEST_DIR/onboard-migrate-skill-contract-test.sh"
bash "$TEST_DIR/agent-eval-profile-test.sh"
bash "$TEST_DIR/security-review-skill-agent-test.sh"
bash "$TEST_DIR/workflow-rigor-contract-test.sh"
bash "$TEST_DIR/plan-skill-contract-test.sh"
bash "$TEST_DIR/tdd-skill-agent-test.sh"
bash "$TEST_DIR/dependency-boundary-test.sh"

python3 - "$TEST_DIR/agent-evals/cases.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    count = len(json.load(handle)["cases"])
print(
    "PROFILE SUMMARY offline-deterministic=passed "
    f"live-agent-v2=not-run registered-live-cases={count}"
)
PY
