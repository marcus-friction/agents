#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
exec env PYTHONDONTWRITEBYTECODE=1 python3 "$SCRIPT_DIR/agent-evals/runner.py" "$@"
