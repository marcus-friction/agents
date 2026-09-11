#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="${POLICY_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

governance=(
  "$REPO_ROOT/CONTRIBUTING.md"
  "$REPO_ROOT/project-templates/base/CONTRIBUTING.md"
)
agent_guidance=(
  "$REPO_ROOT/AGENTS.md"
  "$REPO_ROOT/project-templates/base/AGENTS.md"
)
public_docs=(
  "$REPO_ROOT/README.md"
  "$REPO_ROOT/docs/ecosystem-reference.md"
)

contains_unqualified_ci_or_staging_claim() {
  grep -Eqi \
    'open (a )?(pull request|PR) to .?staging|promote .?staging|CI covers its required|CI (is|are) (enabled|enforced|required|active)|required checks? (is|are) (enabled|enforced|required|active)|branch protection (is|are) (enabled|enforced|required|active)'
}

contains_active_license_claim() {
  grep -Eqi \
    '^MIT$|License:[[:space:]]*(MIT|Apache|BSD|GPL)|licensed under|MIT[- ]licensed'
}

for file in "${governance[@]}"; do
  document_text="$(tr -s '[:space:]' ' ' < "$file")"
  grep -Eqi 'change-rigor\.md' <<< "$document_text" || {
    echo "$(basename "$file") does not defer detailed authority routing to change-rigor.md" >&2
    exit 1
  }
  grep -Eqi '(CI|required checks?|platform enforcement).*(host|GitHub).*(evidence|confirm)' <<< "$document_text" || {
    echo "$(basename "$file") does not distinguish the CI contract from host enforcement" >&2
    exit 1
  }
  grep -Eqi 'staging.*(do not|unless|only).*adopt|do not.*staging.*unless.*adopt' <<< "$document_text" || {
    echo "$(basename "$file") does not reject an unadopted staging flow" >&2
    exit 1
  }
  grep -Eqi 'R1.*ordinary|ordinary.*R1' <<< "$document_text" || {
    echo "$(basename "$file") omits ordinary reversible work" >&2
    exit 1
  }
  grep -Eqi 'R2.*elevated|elevated.*R2' <<< "$document_text" || {
    echo "$(basename "$file") omits elevated effects" >&2
    exit 1
  }
  if grep -Eq 'R3' <<< "$document_text"; then
    echo "$(basename "$file") still exposes the removed fourth rigor tier" >&2
    exit 1
  fi
  if contains_unqualified_ci_or_staging_claim <<< "$document_text"; then
    echo "$(basename "$file") still makes an affirmative CI or staging claim" >&2
    exit 1
  fi
done

for file in "${agent_guidance[@]}"; do
  document_text="$(tr -s '[:space:]' ' ' < "$file")"
  grep -Eqi 'skills change method,? (never |not )?authority' <<< "$document_text" || {
    echo "$(basename "$file") does not distinguish method from authority" >&2
    exit 1
  }
  grep -Eqi 'read-only requests stay read-only' <<< "$document_text" || {
    echo "$(basename "$file") does not keep read-only requests non-mutating" >&2
    exit 1
  }
  grep -Eqi 'bounded implementation.*scoped edits.*(without|no).*kickoff' <<< "$document_text" || {
    echo "$(basename "$file") does not authorize bounded scoped implementation" >&2
    exit 1
  }
  grep -Eqi 'testing alone never authorizes production mutation' <<< "$document_text" || {
    echo "$(basename "$file") lets test authority imply production mutation" >&2
    exit 1
  }
  grep -Fq 'docs/plans/<YYYY-MM-DD>-<slug>/implementation-plan.md' <<< "$document_text" || {
    echo "$(basename "$file") omits the canonical plan location" >&2
    exit 1
  }
  grep -Eqi 'tasks\.md.*tracker|tracker.*tasks\.md' <<< "$document_text" || {
    echo "$(basename "$file") omits the live task-tracker contract" >&2
    exit 1
  }
done

license_established=0
if [ -f "$REPO_ROOT/LICENSE" ] \
  && [ ! -L "$REPO_ROOT/LICENSE" ] \
  && [ -f "$REPO_ROOT/THIRD_PARTY_NOTICES.md" ] \
  && [ ! -L "$REPO_ROOT/THIRD_PARTY_NOTICES.md" ]; then
  license_established=1
fi

if [ "$license_established" -eq 0 ] \
  && contains_active_license_claim < <(cat "${public_docs[@]}"); then
  echo "Public documentation grants or claims an unverified license" >&2
  exit 1
fi
if [ "$license_established" -eq 1 ] \
  && ! contains_active_license_claim < <(cat "${public_docs[@]}"); then
  echo "Licensed repository does not disclose its active license" >&2
  exit 1
fi

for file in "${public_docs[@]}"; do
  document_text="$(tr -s '[:space:]' ' ' < "$file")"
  if [ "$license_established" -eq 0 ]; then
    grep -Eqi 'licens(e|ing)[^.]{0,80}(unresolved|pending)' <<< "$document_text" || {
      echo "$(basename "$file") does not disclose unresolved licensing" >&2
      exit 1
    }
  elif grep -Eqi 'licens(e|ing)[^.]{0,80}(unresolved|pending)' <<< "$document_text"; then
    echo "$(basename "$file") contradicts the established license files" >&2
    exit 1
  fi
  grep -Eqi 'mutable.*master|master.*mutable' <<< "$document_text" || {
    echo "$(basename "$file") does not disclose the mutable install ref" >&2
    exit 1
  }
  if [ -f "$REPO_ROOT/VERSION" ] && [ ! -L "$REPO_ROOT/VERSION" ]; then
    grep -Eqi '40-character|full SHA|full commit SHA' <<< "$document_text" || {
      echo "$(basename "$file") lacks immutable release-ref guidance" >&2
      exit 1
    }
    grep -Eqi '(not stable until|becomes stable only when)' <<< "$document_text" || {
      echo "$(basename "$file") presents an unpublished version as stable" >&2
      exit 1
    }
  else
    grep -Eqi 'development channel.*(not|no).*immutable|not an immutable.*release|no immutable.*release' <<< "$document_text" || {
      echo "$(basename "$file") implies an immutable release channel exists" >&2
      exit 1
    }
  fi
  if grep -Eqi '(CI|required checks?|branch protection) (is|are) (enabled|enforced|required|active)' <<< "$document_text"; then
    echo "$(basename "$file") implies repository enforcement that is not verified" >&2
    exit 1
  fi
done

if ! contains_unqualified_ci_or_staging_claim <<< \
  'CI is enforced. CI enforcement remains unresolved.'; then
  echo "Contradictory affirmative CI fixture was not rejected" >&2
  exit 1
fi
if ! contains_unqualified_ci_or_staging_claim <<< \
  'Open a PR to staging. The staging flow remains unresolved.'; then
  echo "Contradictory affirmative staging fixture was not rejected" >&2
  exit 1
fi
if ! contains_active_license_claim <<< \
  'Licensed under MIT. Licensing authority remains unresolved.'; then
  echo "Contradictory affirmative licensing fixture was not rejected" >&2
  exit 1
fi

echo "Contribution policy consistency tests passed"
