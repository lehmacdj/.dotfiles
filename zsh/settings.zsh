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
setopt extended_glob

# HISTORY
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$DOTFILES/zsh/.zhistory"
HISTORY_IGNORE="(ls|ll|bg|fg|history)"

# Allow multiple terminal sessions to all append to one zsh command history
setopt append_history
# Add comamnds as they are typed, don't wait until shell exit
setopt append_history
# Include more information about when the command was executed, etc
setopt extended_history
# Do not write events to history that are duplicates of previous events
setopt hist_ignore_dups
# When searching history don't display results already cycled through twice
setopt hist_find_no_dups
# Remove extra blanks from each command line being added to history
setopt hist_reduce_blanks
