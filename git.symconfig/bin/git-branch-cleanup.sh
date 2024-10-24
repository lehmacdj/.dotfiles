#!/usr/bin/env bash
set -euo pipefail

while true; do
    branch="$(\
      git for-each-ref --sort=-committerdate --format=$'%(refname:short)\t%(committerdate:relative)' refs/heads \
        | grep -v '^saved/' \
        | awk -F'\t' '{ printf "%-50s %s\n", $1, $2 }' \
        | fzf --tac --no-sort --exit-0)"
    if [ -z "$branch" ]; then
        echo "No branch selected. Exiting."
        break
    fi
    branch_name=$(echo "$branch" | cut -f 1 -d' ')
    git branch -D "$branch_name"
done
