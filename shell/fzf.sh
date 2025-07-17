#!/bin/bash
# shellcheck disable=1090

if command -v fzf >/dev/null 2>&1; then
  # Set the default fzf command
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='--multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'

  # setup completion + key bindings
  if [ -n "$BASH_VERSION" ]; then
    eval "$(fzf --bash)"
  elif [ -n "$ZSH_VERSION" ]; then
    eval "$(fzf --zsh)"
  fi
fi

# cd to directory using fzf
function cf () {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m --height='40%') && cd "$dir" || return 0
}
