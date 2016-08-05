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
