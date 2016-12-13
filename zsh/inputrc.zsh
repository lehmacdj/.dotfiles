# Use vi-mode
bindkey -v

# backwards search through completions
bindkey -M menuselect '[Z' reverse-menu-complete
# make backspace work
bindkey '^?' backward-delete-char
# Make editor invoking work
autoload edit-command-line
zle -N edit-command-line
bindkey -M viins '^F' edit-command-line
bindkey -M vicmd '^F' edit-command-line
# Make key timeout smaller so switch is faster
export KEYTIMEOUT=10
# Make ^R work as expected
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward
# Bind make C-j and C-k work correctly
bindkey -M viins '^K' history-search-backward
bindkey -M vicmd '^K' history-search-backward
bindkey -M viins '^J' history-search-forward
bindkey -M vicmd '^J' history-search-forward
