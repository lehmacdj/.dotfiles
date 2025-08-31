#!/opt/homebrew/bin/bash -l
# This is a script that is expected to run from a macOS launch agent; thus we
# use an interactive shell so it reads our environment config to get access to
# commands etc.
set -euo pipefail

usage_info () {
    >&2 echo "usage: $0 <log_name> <repo_dir> <bookmark> [--push] [--pre-command <command...>]"
    exit 1
}

if [ $# -lt 3 ]; then
    >&2 echo "error: log name, repo dir, and bookmark are mandatory"
    usage_info
fi

log_name="$1"
repo_dir="$2"
bookmark="$3"

push=
if [ $# -ge 4 ] && [ "$4" = "--push" ]; then
    push=1
    shift
fi

pre_command=
if [ $# -ge 4 ] && [ "$4" = "--pre-command" ]; then
    if [ $# -lt 5 ]; then
        >&2 echo "error: --pre-command requires at least one argument"
        usage_info
    fi
    pre_command="$5"
    shift
elif [ $# -ge 4 ]; then
    >&2 echo "error: unrecognized flag"
    usage_info
fi

printf "Starting autocommit of %s. The date is: " "$log_name"
date -Iseconds

cd "$repo_dir" || { >&2 echo "repo $repo_dir did not exist"; exit 1; }

# we might have a pre_command to run
if [ -n "$pre_command" ]; then
    "$pre_command" "$@"
fi

# check that there are changes and that the message is non-empty
if [ "$(jj show --template 'description' --no-patch | wc -c)" -ne 0 ]; then
    >&2 echo "Current description isn't empty; skipping + creating new change"
    jj new
    exit 0
fi
if [ "$(jj diff --name-only | wc -l)" -eq 0 ]; then
    >&2 echo "Current change is empty; skipping"
    exit 0
fi

# rename the revision; move the bookmark;
jj desc -m "autocommit of changes from the past day"
jj bookmark move "$bookmark" --to=@
if [ -n "$push" ]; then
    jj git push || jj new
else
    jj new
fi
