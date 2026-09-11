#!/usr/bin/env bash

destination="$1"
[ ! -L "$destination" ] || exit 1
