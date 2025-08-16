# Automatically enter directories without using cd
setopt auto_cd
# Allow comments even in interactive shells
setopt interactive_comments
# Allow completion from within a word/phrase
setopt complete_in_word
# When completing from the middle of a word, move the cursor to the end of the word
setopt always_to_end
# Enable expansion of lots of things at the prompt
setopt prompt_subst
# Don't confusingly interpret escape sequences in echo commands
setopt BSD_ECHO
# Get rid of beeping
unsetopt beep
# extended globbing
setopt extended_glob
# magic stuff to make urls get quoted automatically and not trigger extended_glob
# recommendation from PL/prolog Alex from Simspacers discord
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# HISTORY
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="$DOTFILES/zsh/.zhistory"
HISTORY_IGNORE="(ls|ll|bg|fg)"
# https://unix.stackexchange.com/questions/562722/ignore-history-when-using-zsh
function zshaddhistory {
    emulate -L zsh
    setopt extendedglob
    [[ $1 != ${~HISTORY_IGNORE} ]]
}
# Share history between zsh sessions (reading history file every time)
# this implies inc_append_history and shouldn't be set together with it
# apparently
setopt share_history
# Include more information about when the command was executed, etc
setopt extended_history
# Do not write events to history that are duplicates of previous events
setopt hist_ignore_dups
# Remove extra blanks from each command line being added to history
setopt hist_reduce_blanks

# autoload plugins
autoload -U zmv
