#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/slugify.sh"

actual="$(printf 'Hello   Wide   World\n' | slugify)"
trace="$(dirname "$0")/.tdd-cycle"

if [ "$actual" != "hello-wide-world" ]; then
  printf 'red\n' > "$trace"
  exit 1
fi

if [ -f "$trace" ] && [ "$(sed -n '1p' "$trace")" = "red" ]; then
  printf 'red-green\n' > "$trace"
elif [ ! -f "$trace" ]; then
  printf 'green-without-red\n' > "$trace"
fi
