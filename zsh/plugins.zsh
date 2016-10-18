export ANTIGEN_COMPDUMPFILE="$HOME/.dotfiles/zsh/.zcompdump"

# Bundles
antigen bundle git
antigen bundle command-not-found
antigen bundle brew
antigen bundle brew-cask
antigen bundle man
antigen bundle vagrant

# Syntax
antigen bundle zsh-users/zsh-syntax-highlighting

# Apply settings
antigen apply
