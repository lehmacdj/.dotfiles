#!/usr/bin/env bash
set -euo pipefail

if [ "$1" == '' ] ; then
  git commit --amend --no-edit
elif [ "$1" == '-a' ]; then
  git commit --amend -a --no-edit
else
  git commit --amend "$@"
fi
