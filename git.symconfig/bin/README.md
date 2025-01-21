# git/bin
This directory contains scripts for bulkier git aliases I use. They sourced from `shell/env.sh` and git allows commands named `git-*` to be run as `git *` so they work the same as aliases.

Theoretically it would be possible to reference them from `git.symconfig/config` it is annoying to need to use `$GIT_PREFIX` (as shell commands are run from the repository root) and passing arguments from the git alias to the script losslessly is also annoying.
