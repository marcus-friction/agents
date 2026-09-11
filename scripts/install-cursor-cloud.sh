#!/usr/bin/env bash
# Optional Cursor Cloud hook: install a verified snapshot and expose only the
# provider-neutral Agent Skills path plus Cursor discovery.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
INSTALLER="$SCRIPT_DIR/install-user-snapshot.sh"
EXPECTED_UID="$(id -u)"

if [ -z "${HOME:-}" ] || [ -L "$HOME" ] || [ ! -d "$HOME" ] \
  || [ "$(cd "$HOME" && pwd -P)" != "$HOME" ] \
  || [ "$(stat -c '%u' -- "$HOME")" != "$EXPECTED_UID" ]; then
  echo "Error: HOME must be an owned, normalized physical directory." >&2
  exit 1
fi
if [ -L "$INSTALLER" ] || [ ! -f "$INSTALLER" ]; then
  echo "Error: shared user snapshot installer must be a physical file: $INSTALLER" >&2
  exit 1
fi

if [ -n "${AGENTS_ECOSYSTEM_HOME:-}" ]; then
  DEST="$AGENTS_ECOSYSTEM_HOME"
elif [ ! -L /opt ] && [ -d /opt ] && [ -w /opt ] && [ -x /opt ] \
  && [ "$(stat -c '%u' -- /opt)" = "$EXPECTED_UID" ]; then
  DEST="/opt/agent-ecosystem"
else
  DEST="$HOME/.agent-ecosystem"
fi

exec bash "$INSTALLER" \
  --destination "$DEST" \
  --adapters agents,cursor \
  "$@"
