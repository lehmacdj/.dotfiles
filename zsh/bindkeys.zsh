# backwards search through completions
bindkey -M menuselect '[Z' reverse-menu-complete

# Use vi-mode
bindkey -v

# make backspace work
bindkey '^?' backward-delete-char

# Make editor invoking work
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Bind jk to escape
bindkey -M viins 'jk' vi-cmd-mode
# Make key timeout smaller so switch is faster
export KEYTIMEOUT=10

# Make ^R work as expected
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward
