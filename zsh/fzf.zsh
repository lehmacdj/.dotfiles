# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/devin/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/devin/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */Users/devin/.fzf/man* && -d "/Users/devin/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/Users/devin/.fzf/man"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "$HOME/.fzf/shell/key-bindings.zsh"
