# backwards search through completions
bindkey '^[[Z' reverse-menu-complete

# Use vi-mode
bindkey -v

# make backspace work
bindkey '^?' backward-delete-char

# Bind jk to escape
bindkey -M viins 'jk' vi-cmd-mode
# Make key timeout smaller so switch is faster
export KEYTIMEOUT=10
