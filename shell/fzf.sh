#!/bin/bash
# shellcheck disable=1090

if command -v fzf >/dev/null 2>&1; then
  # Set the default fzf command
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_CTRL_T_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='--multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'

  # setup completion + key bindings
  if [ -n "$BASH_VERSION" ]; then
    source <(fzf --bash)
  elif [ -n "$ZSH_VERSION" ]; then
    source <(fzf --zsh)
  fi
fi

__fzf_select_git__() {
  FZF_DEFAULT_COMMAND='git index-files --expand-parents' \
  FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --scheme=path" "--tiebreak=index -m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) "$@" < /dev/tty | while read -r item; do
    echo -n "${item} "
  done
  local ret=$?
  echo
  return $ret
}

__fzf_jj_change__() {
  FZF_DEFAULT_COMMAND="jj log -r 'mutable()' --color=always | perl -pe 's/^(│.*)\n/\$1\0/g'" \
  FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --ansi" "--read0 --tiebreak=index -m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) "$@" < /dev/tty | \
  perl -0 -ne 'if (/([a-z]{8})/) { print "$1 " }'
  local ret=$?
  echo
  return $ret
}

# Define an fzf widget with keybindings for both bash and zsh
# Usage: define-fzf-widget <widget-name> <function-name> <keybinding>
# Example: define-fzf-widget fzf-git-widget __fzf_select_git__ 'g'
# The keybinding should be just the letter (e.g., 'g', 'y'), which will be
# converted to \C-g for bash and ^G for zsh
define-fzf-widget() {
  local widget_name=$1
  local function_name=$2
  local key=$3

  if [ -n "$BASH_VERSION" ] && [[ $- =~ i ]]; then
    eval "${widget_name}() {
      local selected
      selected=\"\$(${function_name} \"\$@\")\"
      READLINE_LINE=\"\${READLINE_LINE:0:\$READLINE_POINT}\$selected\${READLINE_LINE:\$READLINE_POINT}\"
      READLINE_POINT=\$(( READLINE_POINT + \${#selected} ))
    }"

    local bash_key="\\C-${key}"
    bind -m emacs-standard -x "\"${bash_key}\": ${widget_name}"
    bind -m vi-command -x "\"${bash_key}\": ${widget_name}"
    bind -m vi-insert -x "\"${bash_key}\": ${widget_name}"
  elif [ -n "$ZSH_VERSION" ] && [[ -o interactive ]]; then
    eval "${widget_name}() {
      LBUFFER=\"\${LBUFFER}\$(${function_name})\"
      local ret=\$?
      zle reset-prompt
      return \$ret
    }"

    local zsh_key="^${key}"
    zle -N "${widget_name}"
    bindkey -M emacs "${zsh_key}" "${widget_name}"
    bindkey -M vicmd "${zsh_key}" "${widget_name}"
    bindkey -M viins "${zsh_key}" "${widget_name}"
  fi
}

__fzf_jj_bookmark__() {
  FZF_DEFAULT_COMMAND="jj bookmark list --color=always" \
  FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --ansi" "--tiebreak=index -m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) "$@" < /dev/tty | \
  perl -ne 'if (/^(\S+):/) { print "$1 " }'
  local ret=$?
  echo
  return $ret
}

define-fzf-widget fzf-git-widget __fzf_select_git__ 'g'
define-fzf-widget fzf-jj-change-widget __fzf_jj_change__ 'y'
define-fzf-widget fzf-jj-bookmark-widget __fzf_jj_bookmark__ 'b'

# cd to directory using fzf
function cf () {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m --height='40%') && cd "$dir" || return 0
}
