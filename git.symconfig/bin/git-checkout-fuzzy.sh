#!/usr/bin/env bash
set -euo pipefail

git for-each-ref --sort=committerdate --format=$'%(refname:short)\t%(committerdate:relative)' refs/heads \
  | awk -F'\t' '{ printf "%-50s %s\n", $1, $2 }' \
  | fzf --tac --no-sort \
  | cut -f 1 -d' ' \
  | xargs -n1 git checkout
