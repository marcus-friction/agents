#!/usr/bin/env bash
# Backward-compatible entry point for user-scoped skill registration.
# New callers should use register-skills.sh directly.
#
# Usage: link-user-skills.sh /absolute/path/to/agents

set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 /absolute/path/to/agents"
  exit 1
fi

AGENTS_ROOT="$1"
SKILLS_SOURCE="$AGENTS_ROOT/.agents/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRAR="$SCRIPT_DIR/register-skills.sh"

if [ ! -d "$SKILLS_SOURCE" ]; then
  echo "Error: skills directory not found at $SKILLS_SOURCE"
  exit 1
fi

if [ ! -f "$REGISTRAR" ]; then
  echo "Error: skill adapter registrar not found at $REGISTRAR"
  exit 1
fi

bash "$REGISTRAR" \
  --scope user \
  --source "$SKILLS_SOURCE"
