#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/update-agents/SKILL.md"
REFERENCE="$ROOT/.agents/skills/update-agents/references/source-and-bulk.md"
ECOSYSTEM_REFERENCE="$ROOT/docs/ecosystem-reference.md"

grep -Eqi 'stable.*full.*commit SHA|full.*commit SHA.*stable' "$SKILL"
grep -Eqi 'stable.*detached|detached.*stable' "$SKILL"
grep -Eqi 'edge.*moving (ref|branch)|moving (ref|branch).*edge' "$SKILL"
grep -Fq -- '--ref <full-commit-sha>' "$SKILL"
grep -Eqi 'edge or local development.*omit `--ref`' "$SKILL"
! grep -Fq 'approved-edge-ref' "$SKILL"
grep -Fq -- '--from-local /path/to/agents' "$SKILL"
grep -Fq '.agents-ecosystem-managed-state-v2' "$SKILL"
grep -Fq 'is not by itself a blocker' "$SKILL"
grep -Eqi 'changed managed path as local' "$SKILL"
grep -Eqi 'retired managed file.*local extension|local extension.*retired managed file' "$SKILL"
grep -Eqi 'active.*legacy project context|legacy.*active project context' "$SKILL"
grep -Eqi 'host packages or runtime dependencies' "$SKILL"
grep -Fq 'commits, pushes, or publication' "$SKILL"
grep -Eqi 'conflict or failure.*stop|stop.*conflict or failure' "$SKILL"
grep -Eqi 'recovery path' "$SKILL"
grep -Fq 'references/source-and-bulk.md' "$SKILL"

[ -f "$REFERENCE" ] && [ ! -L "$REFERENCE" ]
grep -Fq 'https://github.com/marcus-friction/agents.git' "$REFERENCE"
grep -Fq 'fetch --depth 1 --no-tags origin "$AGENTS_ECOSYSTEM_UPDATE_SHA"' "$REFERENCE"
grep -Fq 'checkout --quiet --detach FETCH_HEAD' "$REFERENCE"
grep -Fq -- '--from-local "$AGENTS_ECOSYSTEM_UPDATE_TMP"' "$REFERENCE"
grep -Eqi 'edge.*clone.*moving branch|moving branch.*edge' "$REFERENCE"
grep -Fq -- '--expected-plan-sha256 <reviewed-plan-sha256>' "$REFERENCE"
grep -Eqi 'separate publication effect' "$REFERENCE"
grep -Eqi 'makes no target(-repository)? commit or push' "$REFERENCE"
! grep -Fq -- '--skip-deps' "$SKILL" "$REFERENCE"
! grep -Fq '.agents-ecosystem-managed-state-v1' "$SKILL"

grep -Fq -- '--expected-plan-sha256 <reviewed-plan-sha256>' \
  "$ECOSYSTEM_REFERENCE"
! grep -Fq -- '--apply-plan' "$ECOSYSTEM_REFERENCE"
! grep -Fq -- '--root /absolute/workspace' "$ECOSYSTEM_REFERENCE"

echo "Update-agents immutable-ref contract tests passed"
