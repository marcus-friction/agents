#!/usr/bin/env bash

set -euo pipefail

unset RUN_AGENT_SKILL_TESTS AGENT_EVAL_MODEL AGENT_EVAL_CODEX_BIN
unset AGENT_EVAL_EXPECTED_SUBJECT_DIGEST AGENT_EVAL_TOKEN_BUDGET
unset AGENT_EVAL_TIMEOUT_SECONDS START_PROJECT_SKILL_DECISION_FILE
unset SECURITY_REVIEW_DECISION_FILE WORKFLOW_RIGOR_DECISION_FILE
unset TDD_SKILL_DECISION_FILE

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "PROFILE offline-deterministic: live agent and one-time port-acceptance cases are not executed"

bash "$TEST_DIR/ci-workflow-contract-test.sh"
bash "$TEST_DIR/register-skills-test.sh"
bash "$TEST_DIR/sync-managed-tree-test.sh"
bash "$TEST_DIR/installer-ref-contract-test.sh"
bash "$TEST_DIR/install-global-test.sh"
bash "$TEST_DIR/install-cursor-cloud-test.sh"
bash "$TEST_DIR/install-into-repos-test.sh"
bash "$TEST_DIR/install-tool-agnostic-test.sh"
bash "$TEST_DIR/project-docs-preservation-test.sh"
bash "$TEST_DIR/base-architecture-staging-test.sh"
bash "$TEST_DIR/project-template-layout-test.sh"
bash "$TEST_DIR/onboard-project-evals-test.sh"
bash "$TEST_DIR/distribution-text-classification-test.sh"
bash "$TEST_DIR/canonical-skill-portability-test.sh"
bash "$TEST_DIR/skill-catalog-test.sh"
bash "$TEST_DIR/design-md-standard-test.sh"
bash "$TEST_DIR/documentation-interface-test.sh"
bash "$TEST_DIR/edge-quickstart-test.sh"
bash "$TEST_DIR/provenance-contract-test.sh"
bash "$TEST_DIR/plugin-channel-contract-test.sh"
bash "$TEST_DIR/agent-eval-profile-test.sh"
bash "$TEST_DIR/install-dependencies-test.sh"

python3 - "$TEST_DIR/agent-evals/cases.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    count = len(json.load(handle)["cases"])

print(
    "PROFILE SUMMARY offline-deterministic=passed "
    f"live-agent-v2=not-run registered-live-cases={count} "
    "port-acceptance=not-run "
    "captured-evidence=not-distributed"
)
PY
