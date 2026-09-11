#!/usr/bin/env bash
# Install one verified user snapshot and register every supported user adapter.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
INSTALLER="$SCRIPT_DIR/scripts/install-user-snapshot.sh"
DEST="${AGENTS_ECOSYSTEM_HOME:-${HOME:-}/.agent-ecosystem}"

if [ -L "$INSTALLER" ] || [ ! -f "$INSTALLER" ]; then
  echo "Error: shared user snapshot installer must be a physical file: $INSTALLER" >&2
  exit 1
fi

exec bash "$INSTALLER" --destination "$DEST" --adapters all "$@"
