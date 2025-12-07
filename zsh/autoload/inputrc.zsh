# Use vi-mode
bindkey -v

# S-tab to reverse scroll through completions
bindkey -M menuselect '[Z' reverse-menu-complete

# make backspace work
bindkey '^?' backward-delete-char

# invoke external editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^f' edit-command-line
bindkey -M vicmd '^f' edit-command-line

# incremental search; instead we use fzf incremental search defined in:
# "$DOTFILES"/shell/fzf.sh -> ~/.fzf/shell/key-bindings.zsh
# bindkey -M viins '^r' history-incremental-search-backward
# bindkey -M vicmd '^r' history-incremental-search-backward

# search forward and backward
bindkey -M viins '^k' history-search-backward
bindkey -M vicmd '^k' history-search-backward
bindkey -M viins '^j' history-search-forward
bindkey -M vicmd '^j' history-search-forward

# go forward and backward in insert mode
bindkey -M viins '^n' down-history
bindkey -M viins '^p' up-history

# surround commands
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# Make key timeout smaller so switch is faster
export KEYTIMEOUT=10
