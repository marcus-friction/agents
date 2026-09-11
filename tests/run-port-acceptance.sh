#!/usr/bin/env bash

# One-time source-port checks. These intentionally inspect accepted wording or
# payload bytes and therefore do not belong to the normal behavioral CI suite.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TEST_DIR/authority-policy-test.sh"
bash "$TEST_DIR/contribution-policy-consistency-test.sh"
bash "$TEST_DIR/pragmatism-policy-test.sh"
bash "$TEST_DIR/specialty-guidance-contract-test.sh"
bash "$TEST_DIR/specialty-preservation-test.sh"
bash "$TEST_DIR/update-agents-ref-contract-test.sh"

echo "One-time port acceptance checks passed"
