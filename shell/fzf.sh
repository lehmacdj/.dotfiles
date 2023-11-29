#!/bin/bash
# shellcheck disable=1091
# Setup fzf
if [[ ! "$PATH" == */Users/devin/.fzf/bin* ]]; then
  export PATH="$PATH:$HOME/.fzf/bin"
fi

# Man path
if [[ ! "$MANPATH" == */Users/devin/.fzf/man* && -d "$HOME/.fzf/man" ]]; then
  export MANPATH="$MANPATH:$HOME/.fzf/man"
fi

if [ -n "$BASH_VERSION" ]; then
    # Auto-completion
    [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.bash" 2> /dev/null

    # Key bindings
    source "$HOME/.fzf/shell/key-bindings.bash"
elif [ -n "$ZSH_VERSION" ]; then
    # Auto-completion
    [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

    # Key bindings
    source "$HOME/.fzf/shell/key-bindings.zsh"
fi

# Set the default fzf command
export FZF_DEFAULT_COMMAND='rg --files'
export FZF_DEFAULT_OPTS='--multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'

# open files selected using fzf
function vf () {
  >&2 echo "use ctrl-t to select file as an argument to vim instead"
}

# cd to directory using fzf
function cf () {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m --height='40%') && cd "$dir" || return 0
}
