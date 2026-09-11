#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

[ ! -e "$ROOT/install-dependencies.sh" ]
[ ! -e "$ROOT/.agents/tools/bootstrap-dependencies.sh" ]
! grep -Eq -- '--deps|--skip-deps|bootstrap-dependencies|install-dependencies' "$ROOT/install.sh"

project="$(mktemp -d)"
trap 'rm -rf -- "$project"' EXIT
if (cd "$project" && bash "$ROOT/install.sh" --deps frontend --from-local "$ROOT") >/dev/null 2>&1; then
  echo "install.sh still accepts host dependency provisioning" >&2
  exit 1
fi
[ ! -e "$project/.agents" ]

echo "Dependency boundary tests passed."
