#!/usr/bin/env bash

set -euo pipefail
umask 022

if [ "$#" -ne 3 ]; then
  echo "Usage: create-fixture.sh FIXTURE DESTINATION STATE_DIR" >&2
  exit 1
fi

FIXTURE="$1"
DESTINATION="$2"
STATE_DIR="$3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_ROOT="$(cd "$SCRIPT_DIR/../fixtures" && pwd)"

case "$FIXTURE" in
  mature-monorepo|sparse-python-service|conflicting-deployment|approved-readme-merge|laravel-nuxt-stack)
    ;;
  *)
    echo "Unknown fixture: $FIXTURE" >&2
    exit 1
    ;;
esac

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
  echo "Destination already exists: $DESTINATION" >&2
  exit 1
fi
if [ -e "$STATE_DIR" ] || [ -L "$STATE_DIR" ]; then
  echo "State directory already exists: $STATE_DIR" >&2
  exit 1
fi

mkdir -p "$DESTINATION" "$STATE_DIR"
cp -a "$FIXTURE_ROOT/$FIXTURE/." "$DESTINATION/"

if [ "$FIXTURE" = "approved-readme-merge" ]; then
  mv "$DESTINATION/.expected-README.md" "$STATE_DIR/README.after.md"
fi

if [ "$FIXTURE" = "conflicting-deployment" ]; then
  ln -s docs/architecture.md "$DESTINATION/ARCHITECTURE.md"
fi

git -C "$DESTINATION" init -q
git -C "$DESTINATION" config user.name "Onboarding Eval"
git -C "$DESTINATION" config user.email "onboarding-eval@example.invalid"
git -C "$DESTINATION" add .
git -C "$DESTINATION" commit -qm "fixture baseline"

if [ "$FIXTURE" = "conflicting-deployment" ]; then
  printf '\n- Preserve this uncommitted owner decision.\n' >> \
    "$DESTINATION/AGENTS.md"
fi

manifest="$STATE_DIR/manifest.tsv"
: > "$manifest"
while IFS= read -r -d '' path; do
  relative_path="${path#"$DESTINATION/"}"
  if [ -L "$path" ]; then
    printf 'symlink\t%s\t%s\n' \
      "$relative_path" \
      "$(readlink "$path")" >> "$manifest"
  elif [ -f "$path" ]; then
    printf 'file\t%s\t%s\n' \
      "$relative_path" \
      "$(sha256sum "$path" | cut -d ' ' -f 1)" >> "$manifest"
  fi
done < <(
  find "$DESTINATION" \
    -path "$DESTINATION/.git" -prune -o \
    \( -type f -o -type l \) -print0 | LC_ALL=C sort -z
)

git -C "$DESTINATION" status --porcelain=v1 --untracked-files=all > \
  "$STATE_DIR/git-status.txt"

echo "Created $FIXTURE fixture at $DESTINATION"
