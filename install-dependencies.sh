#!/usr/bin/env bash

set -euo pipefail

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bootstrap="$script_root/.agents/tools/bootstrap-dependencies.sh"

if [ ! -f "$bootstrap" ] || [ -L "$bootstrap" ]; then
  echo "Error: dependency bootstrap is missing or not a physical file: $bootstrap" >&2
  echo "Install or update the agent ecosystem, then retry." >&2
  exit 1
fi

exec bash "$bootstrap" "$@"
