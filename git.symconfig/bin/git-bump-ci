#!/usr/bin/env bash
set -euo pipefail

if [ -z "$(git status --porcelain)" ]; then
  git commit --allow-empty -m \"force CI to retrigger\" && git push
else
  echo "There are uncommitted changes"
fi
