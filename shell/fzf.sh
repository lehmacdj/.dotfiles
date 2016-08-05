#!/bin/bash
# Setup fzf
if [[ ! "$PATH" == */Users/devin/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/devin/.fzf/bin"
fi

# Man path
if [[ ! "$MANPATH" == */Users/devin/.fzf/man* && -d "/Users/devin/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/Users/devin/.fzf/man"
fi

if [ -n "$BASH_VERSION" ]; then
    # Auto-completion
    [[ $- == *i* ]] && source "/Users/devin/.fzf/shell/completion.bash" 2> /dev/null

    # Key bindings
    source "/Users/devin/.fzf/shell/key-bindings.bash"
elif [ -n "$ZSH_VERSION" ]; then
    # Auto-completion
    [[ $- == *i* ]] && source "/Users/devin/.fzf/shell/completion.zsh" 2> /dev/null

    # Key bindings
    source "/Users/devin/.fzf/shell/key-bindings.zsh"
fi

# Set the default fzf command
export FZF_DEFAULT_COMMAND='find .'

function vif () {
    vim $(fzf)
}
