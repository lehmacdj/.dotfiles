# Executed every time that a new interactive shell is created

if [ -f "$HOME/.aliases" ]; then
    # include the alias file
    . "$HOME/.aliases"
fi

# Use vi mode and set a few key bindings
set -o vi
bind -m vi-insert '"jj": vi-movement-mode'
bind -m vi-insert '"jk": vi-movement-mode'

if [ -d "$HOME/.a" ]
    # Create a special shortcut directory
    export CDPATH="~/.a/"
fi

if [ -f "/usr/local/etc/bash_completion" ]; then
    # set up bash-completion
    . "/usr/local/etc/bash_completion"
fi
