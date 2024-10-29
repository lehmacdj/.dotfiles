#!/usr/bin/env bash
set -euo pipefail

# Coalesce changes to a file since a given commit.
# This deletes all changes to the file in BASE_COMMIT..HEAD and applies them
# cumulatively in a single commit.

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: git coalesce <BASE_COMMIT> <FILE_PATH>"
  exit 1
fi
BASE_COMMIT="$1"
FILE_PATH="${GIT_PREFIX:-}$2"

if ! git rev-parse --verify "$BASE_COMMIT" >/dev/null 2>&1; then
  echo "Error: Base commit '$BASE_COMMIT' does not exist."
  exit 1
fi
if ! git ls-tree "$BASE_COMMIT" -- "$FILE_PATH" >/dev/null 2>&1; then
  echo "Error: '$FILE_PATH' does not exist at commit '$BASE_COMMIT'."
  exit 1
fi

# save a patch of the changes to the file since the base commit
TEMP_PATCH="$(mktemp)"
if ! git diff --binary "$BASE_COMMIT" -- "$FILE_PATH" > "$TEMP_PATCH"; then
  echo "Failed to generate diff."
  rm "$TEMP_PATCH"
  exit 1
fi

# figure out how we need to filter the branch
LS_TREE_OUTPUT="$(git ls-tree "$BASE_COMMIT" "$FILE_PATH")"
MODE_SHA1="$(echo "$LS_TREE_OUTPUT" | awk '{print $1","$3}')"
TYPE="$(echo "$LS_TREE_OUTPUT" | awk '{print $2}')"
if [ -z "$MODE_SHA1" ] || [ -z "$TYPE" ]; then
  echo "Failed to get mode, type, and/or SHA1 of file at base commit."
  rm "$TEMP_PATCH"
  exit 1
fi
TEMP_VERBOSE_LOG="$(mktemp)"
if [ "$TYPE" = "blob" ]; then
  INDEX_FILTER="git rm -r --cached --ignore-unmatch '$FILE_PATH' >'$TEMP_VERBOSE_LOG' 2>&1;
    git update-index --add --cacheinfo $MODE_SHA1,'$FILE_PATH' >'$TEMP_VERBOSE_LOG' 2>&1"
elif [ "$TYPE" = "tree" ]; then
  INDEX_FILTER="git rm -r --cached --ignore-unmatch '$FILE_PATH' >'$TEMP_VERBOSE_LOG' 2>&1;
    git read-tree --prefix='$FILE_PATH/' '$BASE_COMMIT':'$FILE_PATH' >'$TEMP_VERBOSE_LOG' 2>&1"
else
  echo "Unsupported type '$TYPE' for '$FILE_PATH'"
  rm "$TEMP_PATCH"
  exit 1
fi

# call filter-branch
OLD_COMMITS="$(git rev-list "$BASE_COMMIT"..HEAD)"
if ! FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --prune-empty --index-filter "$INDEX_FILTER" -- "$BASE_COMMIT"..HEAD; then
  echo "Filter-branch failed. Verbose logs are in '$TEMP_VERBOSE_LOG'."
  rm "$TEMP_PATCH"
  exit 1;
fi
rm "$TEMP_VERBOSE_LOG"
NEW_COMMITS="$(git rev-list "$BASE_COMMIT"..HEAD)"
git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
if [ "$OLD_COMMITS" = "$NEW_COMMITS" ]; then
  echo "git coalese: no changes to coalesce"
  exit 0
fi

# apply patch
if [ ! -s "$TEMP_PATCH" ]; then
  echo "No net changes to '$FILE_PATH' since '$BASE_COMMIT'. Intermediate changes have been removed."
  rm "$TEMP_PATCH"
  exit 0
fi
git apply --binary "$TEMP_PATCH" || { echo "Failed to apply cumulative changes."; rm "$TEMP_PATCH"; exit 1; }
git add "$FILE_PATH"
git commit -m "Coalesced changes to $FILE_PATH" || { echo "Failed to commit changes."; rm "$TEMP_PATCH"; exit 1; }
rm "$TEMP_PATCH"
