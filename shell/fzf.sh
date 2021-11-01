#!/bin/bash
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

    # Key bindings -- FIXME: Keybindings don't work correctly
    # source "$HOME/.fzf/shell/key-bindings.bash"
elif [ -n "$ZSH_VERSION" ]; then
    # Auto-completion
    [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

    # Key bindings
    source "$HOME/.fzf/shell/key-bindings.zsh"
fi

# Set the default fzf command
export FZF_DEFAULT_COMMAND='rg --files'

# open files selected using fzf
function vf () {
  IFS='
'
  local files=($(fzf-tmux --query="$1" --select-1 --exit-0 --height='40%'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
  unset IFS
}

# cd to directory using fzf
function cf () {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m --height='40%') && cd "$dir"
}
