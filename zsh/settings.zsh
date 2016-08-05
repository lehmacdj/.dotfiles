# Automatically enter directories without using cd
setopt AUTO_CD
# Allow comments even in interactive shells
setopt INTERACTIVE_COMMENTS
# Allow completion from within a word/phrase
setopt COMPLETE_IN_WORD 
# When completing from the middle of a word, move the cursor to the end of the word
setopt ALWAYS_TO_END            
# Enable expansion of lots of things at the prompt
setopt PROMPT_SUBST
# Get rid of beeping
unsetopt BEEP

# HISTORY
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$DOTFILES/zsh/.zhistory"
HISTIGNORE="ls:ll:bg:fg:history"

# Allow multiple terminal sessions to all append to one zsh command history
setopt APPEND_HISTORY 
# Add comamnds as they are typed, don't wait until shell exit
setopt APPEND_HISTORY 
# Include more information about when the command was executed, etc
setopt EXTENDED_HISTORY
# Do not write events to history that are duplicates of previous events
setopt HIST_IGNORE_DUPS
# When searching history don't display results already cycled through twice
setopt HIST_FIND_NO_DUPS
# Remove extra blanks from each command line being added to history
setopt HIST_REDUCE_BLANKS
