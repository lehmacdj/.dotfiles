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
# Get rid of beeping
unsetopt beep
# extended globbing
setopt extended_glob

# HISTORY
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$DOTFILES/zsh/.zhistory"
HISTORY_IGNORE="(ls|ll|bg|fg)"
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
