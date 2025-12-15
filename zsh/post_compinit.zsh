# this file expects to be called after compinit has already been executed
# that's pretty much just bashcompinit + compdef definitions if any are
# necessary

# +X causes autoload to immediately load the function. This causes the command
# to only attempt to be executed if it actually exists (very unnecessary for
# compinit and most likely unnecessary for bashcompinit, but better safe than
# sorry)
# -U ignores aliases
autoload -U +X bashcompinit && bashcompinit

# defines a compdef completion for jj based on its own completion script
source <(COMPLETE=zsh jj)
