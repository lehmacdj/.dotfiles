#!/usr/bin/env bash
set -euo pipefail

[ "$#" -ne 1 ] && echo "Usage: $0 <zsh-profile-file>" && exit 1
[ ! -f "$1" ] && echo "File not found: $1" && exit 1

folded="$1.folded"
output="$1.flamegraph.svg"
stackcollapse-zsh-profile.py "$1" >"$folded"
command -v flamegraph.pl >/dev/null 2>&1 || {
  >&2 echo "flamegraph.pl not found in PATH"
  >&2 echo "Install it from https://github.com/brendangregg/FlameGraph"
  >&2 echo "then symlink it to a directory in your PATH"
  exit 1
}
flamegraph.pl "$folded" >"$output"
open -a Firefox "$output"
