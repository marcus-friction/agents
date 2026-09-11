#!/usr/bin/env bash

resolved_parent="$1"
[ ! -L "$resolved_parent" ] || exit 1
