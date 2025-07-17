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

__fzf_select_git__() {
  FZF_DEFAULT_COMMAND='git index-files' \
  FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --scheme=path" "--tiebreak=index -m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) "$@" < /dev/tty | while read -r item; do
    echo -n "${item} "
  done
  local ret=$?
  echo
  return $ret
}

if [ -n "$BASH_VERSION" ]; then
  fzf-git-widget() {
    local selected
    selected="$(__fzf_select_git__ "$@")"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
  }

  bind -m emacs-standard -x '"\C-g": fzf-git-widget'
  bind -m vi-command -x '"\C-g": fzf-git-widget'
  bind -m vi-insert -x '"\C-g": fzf-git-widget'
elif [ -n "$ZSH_VERSION" ]; then
  fzf-git-widget() {
     LBUFFER="${LBUFFER}$(__fzf_select_git__)"
     local ret=$?
     zle reset-prompt
     return $ret
  }

  zle     -N            fzf-git-widget
  bindkey -M emacs '^G' fzf-git-widget
  bindkey -M vicmd '^G' fzf-git-widget
  bindkey -M viins '^G' fzf-git-widget
fi

# cd to directory using fzf
function cf () {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m --height='40%') && cd "$dir" || return 0
}
