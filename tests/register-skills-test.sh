#!/usr/bin/env bash

set -u
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REGISTER="$ROOT/scripts/register-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
failures=0
run() { local name="$1"; shift; if ("$@"); then echo "ok - $name"; else echo "not ok - $name"; failures=$((failures + 1)); fi; }
link_is() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }

project_registration() {
  local project="$TMP/project"
  mkdir -p "$project/.agents/skills"
  bash "$REGISTER" --scope project --project-root "$project" >/dev/null || return 1
  link_is "$project/.cursor/skills" ../.agents/skills \
    && link_is "$project/.claude/skills" ../.agents/skills \
    && [ -f "$project/.agents/templates/adapters/claude/CLAUDE.md" ]
}

user_registration() {
  local base="$TMP/user" source="$TMP/user/source"
  mkdir -p "$base/home" "$source"
  HOME="$base/home" bash "$REGISTER" --scope user --source "$source" >/dev/null || return 1
  link_is "$base/home/.agents/skills" "$source" \
    && link_is "$base/home/.cursor/skills" "$source" \
    && link_is "$base/home/.claude/skills" "$source"
}

filter_and_idempotence() {
  local project="$TMP/filter" output
  mkdir -p "$project/.agents/skills"
  bash "$REGISTER" --scope project --project-root "$project" --adapters cursor >/dev/null || return 1
  output="$(bash "$REGISTER" --scope project --project-root "$project" --adapters cursor)" || return 1
  grep -q '\[Unchanged\]' <<< "$output" && [ ! -e "$project/.claude" ]
}

collision_preflight_is_atomic() {
  local project="$TMP/collision" existing="$TMP/existing" output
  mkdir -p "$project/.agents/skills" "$project/.claude" "$existing"
  ln -s "$existing" "$project/.claude/skills"
  if output="$(bash "$REGISTER" --scope project --project-root "$project" 2>&1)"; then return 1; fi
  grep -q 'points elsewhere' <<< "$output" \
    && link_is "$project/.claude/skills" "$existing" \
    && [ ! -e "$project/.cursor/skills" ]
}

preflight_is_read_only() {
  local project="$TMP/preflight"
  mkdir -p "$project"
  bash "$REGISTER" --scope project --project-root "$project" --preflight-only >/dev/null || return 1
  [ ! -e "$project/.cursor" ] && [ ! -e "$project/.claude" ]
}

journal_lists_created_links() {
  local project="$TMP/journal" journal="$TMP/journal.txt"
  mkdir -p "$project/.agents/skills"; : > "$journal"; chmod 0600 "$journal"
  bash "$REGISTER" --scope project --project-root "$project" --adapters cursor --journal-output "$journal" >/dev/null || return 1
  grep -Fq "$project/.cursor/skills" "$journal" \
    && grep -Fq $'\t../.agents/skills\t' "$journal" \
    && [ "$(awk -F '\t' 'NF != 4 { bad=1 } END { print bad+0 }' "$journal")" -eq 0 ]
}

journal_rejects_hardlink_without_clobbering_peer() {
  local project="$TMP/journal-hardlink/project" owner="$TMP/journal-hardlink/owner.txt"
  local journal="$TMP/journal-hardlink/journal.txt" output
  mkdir -p "$project/.agents/skills"
  printf 'owned content\n' > "$owner"
  chmod 0600 "$owner"
  ln "$owner" "$journal"
  if output="$(bash "$REGISTER" --scope project --project-root "$project" \
      --adapters cursor --journal-output "$journal" 2>&1)"; then return 1; fi
  grep -q 'one link' <<< "$output" \
    && grep -Fxq 'owned content' "$owner" \
    && [ ! -e "$project/.cursor/skills" ]
}

journal_rejects_permissive_mode() {
  local project="$TMP/journal-mode/project" journal="$TMP/journal-mode/journal.txt" output
  mkdir -p "$project/.agents/skills"
  : > "$journal"
  chmod 0644 "$journal"
  if output="$(bash "$REGISTER" --scope project --project-root "$project" \
      --adapters cursor --journal-output "$journal" 2>&1)"; then return 1; fi
  grep -q 'mode 0600' <<< "$output" && [ ! -e "$project/.cursor/skills" ]
}

configure_failure_rolls_back_links() {
  local base="$TMP/failure" project="$TMP/failure/project" script="$TMP/failure/dist/scripts/register-skills.sh"
  mkdir -p "$base/dist/scripts/skill-adapters" "$project/.agents/skills"
  cp "$REGISTER" "$script"
  cp "$ROOT/scripts/skill-adapters/cursor.sh" "$base/dist/scripts/skill-adapters/cursor.sh"
  cat >> "$base/dist/scripts/skill-adapters/cursor.sh" <<'EOF'
skill_adapter_configure() { return 42; }
EOF
  if bash "$script" --scope project --project-root "$project" --adapters cursor >/dev/null 2>&1; then return 1; fi
  [ ! -e "$project/.cursor/skills" ] && [ ! -L "$project/.cursor/skills" ]
}

run "project adapters link canonical skills" project_registration
run "user adapters share one canonical source" user_registration
run "adapter filter is idempotent" filter_and_idempotence
run "collision preflight prevents partial registration" collision_preflight_is_atomic
run "preflight-only makes no changes" preflight_is_read_only
run "journal is readable and scoped" journal_lists_created_links
run "hardlinked journal is rejected without clobbering its peer" journal_rejects_hardlink_without_clobbering_peer
run "permissive journal mode is rejected" journal_rejects_permissive_mode
run "configuration failure rolls back created links" configure_failure_rolls_back_links

[ "$failures" -eq 0 ] || { echo "$failures registration test(s) failed" >&2; exit 1; }
echo "All skill registration tests passed."
