#!/usr/bin/env bash

set -euo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
# Freeze the installer for the duration of the test, including its data/helpers.
cp -R "$ROOT/scripts" "$TMP/installer"
INSTALLER="$TMP/installer/install-user-snapshot.sh"

SOURCE="$TMP/source" REMOTE="$TMP/source.git" BIN="$TMP/bin"
mkdir -p "$SOURCE" "$BIN"
mkdir -p "$SOURCE/.agents/skills/plan"
cp "$ROOT/.agents/skills/plan/SKILL.md" "$SOURCE/.agents/skills/plan/SKILL.md"
cp -R "$ROOT/scripts" "$SOURCE/scripts"
mkdir "$SOURCE/.cursor"
ln -s ../.agents/skills "$SOURCE/.cursor/skills"
git -C "$SOURCE" init -q -b master
git -C "$SOURCE" config user.name "Snapshot Test"
git -C "$SOURCE" config user.email "snapshot@example.invalid"
git -C "$SOURCE" add .
git -C "$SOURCE" commit -qm "first"
FIRST="$(git -C "$SOURCE" rev-parse HEAD)"
git clone -q --bare "$SOURCE" "$REMOTE"
printf 'second\n' > "$SOURCE/.agents/skills/release-marker.txt"
git -C "$SOURCE" add .agents/skills/release-marker.txt
git -C "$SOURCE" commit -qm "second"
SECOND="$(git -C "$SOURCE" rev-parse HEAD)"
git -C "$SOURCE" push -q "$REMOTE" master

# Exercise the registrar interface shipped before the snapshot migration. The
# surrounding synthetic commits keep the installer test self-contained while
# preserving the public parser and adapter behavior compatibility must serve.
git -C "$ROOT" show bff57e7afee4ad16670a33b155d4d00bb13e45d6:scripts/register-skills.sh \
  > "$SOURCE/scripts/register-skills.sh"
chmod +x "$SOURCE/scripts/register-skills.sh"
git -C "$SOURCE" add scripts/register-skills.sh
git -C "$SOURCE" commit -qm "v0.1.0 registrar interface"
LEGACY_010="$(git -C "$SOURCE" rev-parse HEAD)"
git -C "$ROOT" show bff57e7afee4ad16670a33b155d4d00bb13e45d6:scripts/register-skills.sh \
  > "$SOURCE/scripts/register-skills.sh"
chmod +x "$SOURCE/scripts/register-skills.sh"
git -C "$SOURCE" add scripts/register-skills.sh
git -C "$SOURCE" commit --allow-empty -qm "v0.1.1 registrar interface"
LEGACY_011="$(git -C "$SOURCE" rev-parse HEAD)"
git -C "$SOURCE" push -q "$REMOTE" master

cat > "$BIN/git" <<'EOF'
#!/usr/bin/env bash
args=()
for arg in "$@"; do
  if [ "$arg" = "https://github.com/marcus-friction/agents.git" ]; then args+=("$AGENTS_ECOSYSTEM_TEST_REMOTE"); else args+=("$arg"); fi
done
exec "$AGENTS_ECOSYSTEM_TEST_GIT" "${args[@]}"
EOF
cat > "$BIN/gh" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = auth ] && [ "${2:-}" = git-credential ] && [ "${3:-}" = get ]; then cat >/dev/null; exit 0; fi
exit 1
EOF
cat > "$BIN/mv" <<'EOF'
#!/bin/bash
if [ -n "${AGENTS_ECOSYSTEM_TEST_ACTIVATION_TARGET:-}" ] \
  && [ "${1##*/}" = candidate ] \
  && [ "${2:-}" = "$AGENTS_ECOSYSTEM_TEST_ACTIVATION_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_ACTIVATION_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_ACTIVATION_MARKER"
  mkdir "$AGENTS_ECOSYSTEM_TEST_ACTIVATION_TARGET"
  printf 'concurrent activation owner\n' > "$AGENTS_ECOSYSTEM_TEST_ACTIVATION_TARGET/concurrent.md"
fi
exec "$AGENTS_ECOSYSTEM_TEST_MV" "$@"
EOF
cat > "$BIN/bash" <<'EOF'
#!/bin/bash
if [ -n "${AGENTS_ECOSYSTEM_TEST_MARK_AFTER_REGISTER:-}" ] \
  && [ "${1:-}" = "$AGENTS_ECOSYSTEM_TEST_MARK_AFTER_REGISTER/scripts/register-skills.sh" ]; then
  "$AGENTS_ECOSYSTEM_TEST_BASH" "$@"
  status=$?
  if [ "$status" -eq 0 ] && [ -n "${AGENTS_ECOSYSTEM_TEST_REPLACE_LINK_AFTER_REGISTER:-}" ]; then
    "$AGENTS_ECOSYSTEM_TEST_RM" -f -- "$AGENTS_ECOSYSTEM_TEST_REPLACE_LINK_AFTER_REGISTER"
    "$AGENTS_ECOSYSTEM_TEST_LN" -s -- "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_LINK_SOURCE" \
      "$AGENTS_ECOSYSTEM_TEST_REPLACE_LINK_AFTER_REGISTER"
  fi
  : > "$AGENTS_ECOSYSTEM_TEST_REGISTER_MARKER"
  exit "$status"
fi
if [ -n "${AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER:-}" ] \
  && [ "${1:-}" = "$AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER/scripts/register-skills.sh" ]; then
  "$AGENTS_ECOSYSTEM_TEST_MV" "$AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER" "$AGENTS_ECOSYSTEM_TEST_DISPLACED_ACTIVE"
  mkdir "$AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER"
  printf 'concurrent rollback owner\n' > "$AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER/concurrent.md"
  exit 91
fi
exec "$AGENTS_ECOSYSTEM_TEST_BASH" "$@"
EOF
cat > "$BIN/ln" <<'EOF'
#!/usr/bin/env bash
if [ -n "${AGENTS_ECOSYSTEM_TEST_FAIL_AFTER_LINK:-}" ] && [ "${1:-}" = -P ]; then
  "$AGENTS_ECOSYSTEM_TEST_LN" "$@"
  exit 92
fi
exec "$AGENTS_ECOSYSTEM_TEST_LN" "$@"
EOF
cat > "$BIN/mktemp" <<'EOF'
#!/usr/bin/env bash
if [ -n "${AGENTS_ECOSYSTEM_TEST_FAIL_MKTEMP:-}" ]; then exit 73; fi
exec "$AGENTS_ECOSYSTEM_TEST_MKTEMP" "$@"
EOF
cat > "$BIN/rm" <<'EOF'
#!/usr/bin/env bash
last="${!#}"
if [ -n "${AGENTS_ECOSYSTEM_TEST_FAIL_STAGE_RM:-}" ] \
  && [[ "${last##*/}" = *.agents-ecosystem-stage.* ]]; then
  exit 74
fi
exec "$AGENTS_ECOSYSTEM_TEST_RM" "$@"
EOF
cat > "$BIN/stat" <<'EOF'
#!/usr/bin/env bash
last="${!#}"
if [ -n "${AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH:-}" ] \
  && [ "$last" = "$AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH" ] \
  && { [ -z "${AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_MARKER:-}" ] \
    || [ -e "$AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_MARKER" ]; } \
  && [ "${1:-}" = -c ] && [ "${2:-}" = %u ]; then
  printf '99999\n'
  exit 0
fi
exec "$AGENTS_ECOSYSTEM_TEST_STAT" "$@"
EOF
chmod +x "$BIN/git" "$BIN/gh" "$BIN/mv" "$BIN/bash" "$BIN/ln" \
  "$BIN/mktemp" "$BIN/rm" "$BIN/stat"
REAL_GIT="$(command -v git)"
REAL_MV="$(command -v mv)"
REAL_BASH="$(command -p -v bash)"
REAL_LN="$(command -v ln)"
REAL_MKTEMP="$(command -v mktemp)"
REAL_RM="$(command -v rm)"
REAL_STAT="$(command -v stat)"

install_to() {
  local home="$1" ref="$2"
  mkdir -p "$home"
  HOME="$home" PATH="$BIN:$PATH" AGENTS_ECOSYSTEM_TEST_REMOTE="$REMOTE" AGENTS_ECOSYSTEM_TEST_GIT="$REAL_GIT" \
    AGENTS_ECOSYSTEM_TEST_MV="$REAL_MV" AGENTS_ECOSYSTEM_TEST_BASH="$REAL_BASH" AGENTS_ECOSYSTEM_TEST_LN="$REAL_LN" \
    AGENTS_ECOSYSTEM_TEST_MKTEMP="$REAL_MKTEMP" AGENTS_ECOSYSTEM_TEST_RM="$REAL_RM" \
    AGENTS_ECOSYSTEM_TEST_STAT="$REAL_STAT" \
    bash "$INSTALLER" --destination "$home/.agent-ecosystem" --adapters cursor --ref "$ref"
}

hash_file() { sha256sum "$1" | awk '{print $1}'; }
file_mode() { stat -c '%a' -- "$1"; }

convert_to_legacy_v1() {
  local root="$1" sha="$2" manifest="$1/.agents-ecosystem-content-manifest-v1" entry rel manifest_sha
  rm "$root/.agents-ecosystem-install-state-v2" "$root/.agents-ecosystem-content-manifest-v2"
  printf 'agents-ecosystem-content-manifest-v2\0' > "$manifest"
  while IFS= read -r -d '' entry; do
    rel="${entry#"$root"/}"
    case "$rel" in .agents-ecosystem-install-state-v1|.agents-ecosystem-content-manifest-v1) continue ;; esac
    if [ -d "$entry" ]; then
      printf 'directory\0\0%s\0%s\0' "$(file_mode "$entry")" "$rel" >> "$manifest"
    else
      printf 'file\0%s\0%s\0%s\0' "$(hash_file "$entry")" "$(file_mode "$entry")" "$rel" >> "$manifest"
    fi
  done < <(find "$root" -mindepth 1 \( -type d -o -type f \) -print0)
  chmod 0600 "$manifest"
  manifest_sha="$(hash_file "$manifest")"
  printf '%s\n' \
    'format=agents-ecosystem-user-snapshot-v1' \
    'source=https://github.com/marcus-friction/agents.git' \
    "sha=$sha" \
    'channel=release' \
    'previous_sha=' \
    "manifest_sha256=$manifest_sha" > "$root/.agents-ecosystem-install-state-v1"
  chmod 0600 "$root/.agents-ecosystem-install-state-v1"
}

failures=0
run() { local name="$1"; shift; if ("$@"); then echo "ok - $name"; else echo "not ok - $name"; failures=$((failures + 1)); fi; }

fresh_install() {
  local home="$TMP/fresh/home" dest="$TMP/fresh/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  [ "$(sed -n 's/^sha=//p' "$dest/.agents-ecosystem-install-state-v2")" = "$FIRST" ] \
    && [ -f "$dest/.agents-ecosystem-content-manifest-v2" ] \
    && [ ! -e "$dest/.git" ] \
    && [ -L "$home/.cursor/skills" ] \
    && [ "$(readlink "$home/.cursor/skills")" = "$dest/.agents/skills" ]
}

update_and_idempotence() {
  local home="$TMP/update/home" dest="$TMP/update/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  install_to "$home" "$SECOND" >/dev/null || return 1
  grep -q second "$dest/.agents/skills/release-marker.txt" || return 1
  [ "$(sed -n 's/^previous_sha=//p' "$dest/.agents-ecosystem-install-state-v2")" = "$FIRST" ] || return 1
  install_to "$home" "$SECOND" >/dev/null
}

published_registrar_interfaces_install_and_roll_back() {
  local ref home dest
  for ref in "$LEGACY_010" "$LEGACY_011"; do
    home="$TMP/published-fresh-$ref/home"
    dest="$home/.agent-ecosystem"
    install_to "$home" "$ref" >/dev/null || return 1
    [ "$(sed -n 's/^sha=//p' "$dest/.agents-ecosystem-install-state-v2")" = "$ref" ] || return 1
    [ -L "$home/.cursor/skills" ] \
      && [ "$(readlink "$home/.cursor/skills")" = "$dest/.agents/skills" ] || return 1
  done

  home="$TMP/published-rollback/home"
  dest="$home/.agent-ecosystem"
  install_to "$home" "$SECOND" >/dev/null || return 1
  install_to "$home" "$LEGACY_010" >/dev/null || return 1
  [ "$(sed -n 's/^sha=//p' "$dest/.agents-ecosystem-install-state-v2")" = "$LEGACY_010" ] \
    && [ "$(sed -n 's/^previous_sha=//p' "$dest/.agents-ecosystem-install-state-v2")" = "$SECOND" ] \
    && [ -L "$home/.cursor/skills" ] \
    && [ "$(readlink "$home/.cursor/skills")" = "$dest/.agents/skills" ]
}

legacy_link_failure_before_journal_rolls_back() {
  local home="$TMP/legacy-link-failure/home" dest="$TMP/legacy-link-failure/home/.agent-ecosystem"
  if AGENTS_ECOSYSTEM_TEST_FAIL_AFTER_LINK=1 install_to "$home" "$LEGACY_010" >/dev/null 2>&1; then
    return 1
  fi
  [ ! -e "$dest" ] && [ ! -e "$home/.cursor/skills" ] && [ ! -L "$home/.cursor/skills" ]
}

early_stage_failure_releases_lock() {
  local home="$TMP/early-stage-failure/home"
  if AGENTS_ECOSYSTEM_TEST_FAIL_MKTEMP=1 install_to "$home" "$FIRST" >/dev/null 2>&1; then
    return 1
  fi
  [ ! -e "$home/.agent-ecosystem.agents-ecosystem-install.lock" ]
}

cleanup_failure_releases_lock() {
  local home="$TMP/cleanup-failure/home" dest="$TMP/cleanup-failure/home/.agent-ecosystem"
  if AGENTS_ECOSYSTEM_TEST_FAIL_STAGE_RM=1 install_to "$home" "$FIRST" >/dev/null 2>&1; then
    return 1
  fi
  [ ! -e "$home/.agent-ecosystem.agents-ecosystem-install.lock" ] \
    && [ -f "$dest/.agents-ecosystem-install-state-v2" ]
}

post_journal_failure_removes_modern_links() {
  local home="$TMP/post-journal-failure/home"
  local dest="$TMP/post-journal-failure/home/.agent-ecosystem"
  local marker="$TMP/post-journal-failure/registered"
  if AGENTS_ECOSYSTEM_TEST_MARK_AFTER_REGISTER="$dest" AGENTS_ECOSYSTEM_TEST_REGISTER_MARKER="$marker" \
    AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH="$dest" AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_MARKER="$marker" \
    install_to "$home" "$FIRST" >/dev/null 2>&1; then
    return 1
  fi
  [ -e "$marker" ] && [ ! -e "$dest" ] \
    && [ ! -e "$home/.cursor/skills" ] && [ ! -L "$home/.cursor/skills" ] \
    && [ ! -e "$home/.agent-ecosystem.agents-ecosystem-install.lock" ]
}

post_journal_failure_restores_prior_snapshot() {
  local home="$TMP/post-journal-prior/home"
  local dest="$TMP/post-journal-prior/home/.agent-ecosystem"
  local marker="$TMP/post-journal-prior/registered"
  install_to "$home" "$FIRST" >/dev/null || return 1
  if AGENTS_ECOSYSTEM_TEST_MARK_AFTER_REGISTER="$dest" AGENTS_ECOSYSTEM_TEST_REGISTER_MARKER="$marker" \
    AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH="$dest" AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_MARKER="$marker" \
    install_to "$home" "$SECOND" >/dev/null 2>&1; then
    return 1
  fi
  [ -e "$marker" ] \
    && grep -Fxq "sha=$FIRST" "$dest/.agents-ecosystem-install-state-v2" \
    && [ -L "$home/.cursor/skills" ] \
    && [ "$(readlink "$home/.cursor/skills")" = "$dest/.agents/skills" ] \
    && [ ! -e "$home/.agent-ecosystem.agents-ecosystem-install.lock" ]
}

post_journal_concurrent_link_replacement_is_preserved() {
  local home="$TMP/post-journal-link-race/home"
  local dest="$TMP/post-journal-link-race/home/.agent-ecosystem"
  local marker="$TMP/post-journal-link-race/registered"
  local replacement="$TMP/post-journal-link-race/concurrent-skills"
  mkdir -p "$replacement"
  if AGENTS_ECOSYSTEM_TEST_MARK_AFTER_REGISTER="$dest" AGENTS_ECOSYSTEM_TEST_REGISTER_MARKER="$marker" \
    AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH="$dest" AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_MARKER="$marker" \
    AGENTS_ECOSYSTEM_TEST_REPLACE_LINK_AFTER_REGISTER="$home/.cursor/skills" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_LINK_SOURCE="$replacement" \
    install_to "$home" "$FIRST" >/dev/null 2>&1; then
    return 1
  fi
  [ -e "$marker" ] && [ ! -e "$dest" ] \
    && [ -L "$home/.cursor/skills" ] \
    && [ "$(readlink "$home/.cursor/skills")" = "$replacement" ] \
    && [ -d "$replacement" ] \
    && [ ! -e "$home/.agent-ecosystem.agents-ecosystem-install.lock" ]
}

foreign_owned_snapshot_is_rejected() {
  local home="$TMP/foreign-owner/home" dest="$TMP/foreign-owner/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  if AGENTS_ECOSYSTEM_TEST_FOREIGN_OWNER_PATH="$dest" \
    install_to "$home" "$SECOND" >/dev/null 2>&1; then
    return 1
  fi
  grep -Fxq "sha=$FIRST" "$dest/.agents-ecosystem-install-state-v2"
}

legacy_v1_upgrades_after_verification() {
  local home="$TMP/legacy/home" dest="$TMP/legacy/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  convert_to_legacy_v1 "$dest" "$FIRST"
  install_to "$home" "$FIRST" >/dev/null || return 1
  [ -f "$dest/.agents-ecosystem-install-state-v2" ] \
    && [ -f "$dest/.agents-ecosystem-content-manifest-v2" ] \
    && [ ! -e "$dest/.agents-ecosystem-install-state-v1" ] \
    && [ ! -e "$dest/.agents-ecosystem-content-manifest-v1" ] \
    && grep -Fxq "previous_sha=$FIRST" "$dest/.agents-ecosystem-install-state-v2"
}

modified_legacy_v1_blocks() {
  local home="$TMP/legacy-modified/home" dest="$TMP/legacy-modified/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  convert_to_legacy_v1 "$dest" "$FIRST"
  printf 'local legacy edit\n' >> "$dest/.agents/skills/plan/SKILL.md"
  ! install_to "$home" "$SECOND" >/dev/null 2>&1 \
    && grep -q 'local legacy edit' "$dest/.agents/skills/plan/SKILL.md" \
    && [ -f "$dest/.agents-ecosystem-install-state-v1" ]
}

malformed_legacy_v1_state_blocks() {
  local home="$TMP/legacy-malformed/home" dest="$TMP/legacy-malformed/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  convert_to_legacy_v1 "$dest" "$FIRST"
  printf 'unexpected=true\n' >> "$dest/.agents-ecosystem-install-state-v1"
  ! install_to "$home" "$SECOND" >/dev/null 2>&1 \
    && grep -q 'unexpected=true' "$dest/.agents-ecosystem-install-state-v1" \
    && [ ! -e "$dest/.agents-ecosystem-install-state-v2" ]
}

git_symlink_in_installed_snapshot_blocks() {
  local format home dest external
  for format in v2 v1; do
    home="$TMP/git-symlink-$format/home"
    dest="$home/.agent-ecosystem"
    external="$TMP/git-symlink-$format/external"
    install_to "$home" "$FIRST" >/dev/null || return 1
    [ "$format" = v2 ] || convert_to_legacy_v1 "$dest" "$FIRST"
    mkdir -p "$external"
    ln -s "$external" "$dest/.git"
    ! install_to "$home" "$FIRST" >/dev/null 2>&1 || return 1
    [ -L "$dest/.git" ] || return 1
  done
}

activation_recreation_is_preserved() {
  local home="$TMP/activation-race/home" dest="$TMP/activation-race/home/.agent-ecosystem"
  local marker="$TMP/activation-race/triggered" recovery
  install_to "$home" "$FIRST" >/dev/null || return 1
  if AGENTS_ECOSYSTEM_TEST_ACTIVATION_TARGET="$dest" AGENTS_ECOSYSTEM_TEST_ACTIVATION_MARKER="$marker" \
    install_to "$home" "$SECOND" >/dev/null 2>&1; then return 1; fi
  grep -q 'concurrent activation owner' "$dest/concurrent.md" || return 1
  [ ! -e "$dest/candidate" ] || return 1
  recovery="$(find "$home" -maxdepth 3 -path '*/previous/.agents-ecosystem-install-state-v2' -print -quit)"
  [ -n "$recovery" ] && grep -Fxq "sha=$FIRST" "$recovery"
}

rollback_recreation_is_preserved() {
  local home="$TMP/rollback-race/home" dest="$TMP/rollback-race/home/.agent-ecosystem"
  local displaced="$TMP/rollback-race/displaced" recovery
  install_to "$home" "$FIRST" >/dev/null || return 1
  if AGENTS_ECOSYSTEM_TEST_REPLACE_ACTIVE_ON_REGISTER="$dest" AGENTS_ECOSYSTEM_TEST_DISPLACED_ACTIVE="$displaced" \
    install_to "$home" "$SECOND" >/dev/null 2>&1; then return 1; fi
  grep -q 'concurrent rollback owner' "$dest/concurrent.md" || return 1
  recovery="$(find "$home" -maxdepth 3 -path '*/previous/.agents-ecosystem-install-state-v2' -print -quit)"
  [ -n "$recovery" ] && grep -Fxq "sha=$FIRST" "$recovery"
}

modified_snapshot_blocks() {
  local home="$TMP/modified/home" dest="$TMP/modified/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  printf 'local edit\n' >> "$dest/.agents/skills/plan/SKILL.md"
  ! install_to "$home" "$FIRST" >/dev/null 2>&1 \
    && grep -q 'local edit' "$dest/.agents/skills/plan/SKILL.md"
}

modified_state_blocks() {
  local home="$TMP/modified-state/home" dest="$TMP/modified-state/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  printf 'unexpected=true\n' >> "$dest/.agents-ecosystem-install-state-v2"
  ! install_to "$home" "$FIRST" >/dev/null 2>&1 \
    && grep -q 'unexpected=true' "$dest/.agents-ecosystem-install-state-v2"
}

modified_permissions_block() {
  local home="$TMP/modified-mode/home" dest="$TMP/modified-mode/home/.agent-ecosystem"
  install_to "$home" "$FIRST" >/dev/null || return 1
  chmod 0644 "$dest/.agents-ecosystem-install-state-v2"
  ! install_to "$home" "$FIRST" >/dev/null 2>&1 \
    && [ "$(stat -c '%a' "$dest/.agents-ecosystem-install-state-v2")" = 644 ]
}

fresh_registration_collision_rolls_back() {
  local home="$TMP/collision/home" dest="$TMP/collision/home/.agent-ecosystem"
  mkdir -p "$home/.cursor/skills"
  printf 'owner\n' > "$home/.cursor/skills/keep.txt"
  ! install_to "$home" "$FIRST" >/dev/null 2>&1 \
    && [ ! -e "$dest" ] \
    && grep -q owner "$home/.cursor/skills/keep.txt"
}

overlap_lock_blocks() {
  local home="$TMP/lock/home" dest="$TMP/lock/home/.agent-ecosystem"
  mkdir -p "$home/.agent-ecosystem.agents-ecosystem-install.lock"
  ! install_to "$home" "$FIRST" >/dev/null 2>&1 && [ ! -e "$dest" ]
}

invalid_ref_is_rejected() {
  local home="$TMP/ref/home"
  mkdir -p "$home"
  ! HOME="$home" bash "$INSTALLER" --destination "$home/.agent-ecosystem" --ref master >/dev/null 2>&1
}

run "fresh snapshot is verified and registered" fresh_install
run "update records one predecessor and rerun is idempotent" update_and_idempotence
run "published registrar interfaces support fresh install and rollback" published_registrar_interfaces_install_and_roll_back
run "legacy link failure before journal publication rolls back" legacy_link_failure_before_journal_rolls_back
run "early stage failure releases cooperative lock" early_stage_failure_releases_lock
run "cleanup failure releases cooperative lock" cleanup_failure_releases_lock
run "post-journal failure removes modern links" post_journal_failure_removes_modern_links
run "post-journal failure restores the prior snapshot" post_journal_failure_restores_prior_snapshot
run "post-journal cleanup preserves a concurrent link replacement" post_journal_concurrent_link_replacement_is_preserved
run "foreign-owned snapshot is rejected" foreign_owned_snapshot_is_rejected
run "verified legacy v1 snapshot upgrades to v2" legacy_v1_upgrades_after_verification
run "modified legacy v1 snapshot blocks replacement" modified_legacy_v1_blocks
run "malformed legacy v1 state blocks replacement" malformed_legacy_v1_state_blocks
run "installed v1 and v2 snapshots reject a .git symlink" git_symlink_in_installed_snapshot_blocks
run "concurrent activation destination is preserved" activation_recreation_is_preserved
run "concurrent rollback destination is preserved" rollback_recreation_is_preserved
run "locally modified snapshot blocks replacement" modified_snapshot_blocks
run "locally modified snapshot state blocks replacement" modified_state_blocks
run "locally modified snapshot permissions block replacement" modified_permissions_block
run "registration collision rolls back a fresh snapshot" fresh_registration_collision_rolls_back
run "cooperative lock blocks overlapping installs" overlap_lock_blocks
run "release ref must be immutable" invalid_ref_is_rejected

[ "$failures" -eq 0 ] || { echo "$failures snapshot test(s) failed" >&2; exit 1; }
echo "All user snapshot installer tests passed."
